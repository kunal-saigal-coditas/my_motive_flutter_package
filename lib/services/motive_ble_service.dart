import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:my_motive_package/core/utils/ble_command_utils.dart';
import 'package:my_motive_package/model/device_status_model.dart';
import 'package:my_motive_package/model/product_info_model.dart';

/// Service for managing BLE communication with Motive therapy devices.
///
/// This service handles the low-level Bluetooth Low Energy (BLE) communication
/// with Motive controllers, including:
/// - Service and characteristic discovery
/// - Authentication code calculation
/// - Device status streaming (real-time)
/// - Product info reading (one-time read)
/// - Notification management
///
/// ## Usage
///
/// ```dart
/// final bleService = MotiveBleService();
///
/// // Initialize with a connected device
/// await bleService.initialize(
///   device: connectedDevice,
///   manufacturerData: advertisementData,
/// );
///
/// // Listen to device status updates - already parsed into DeviceStatus model!
/// bleService.statusStream.listen((status) {
///   print('Battery: ${status.batteryLevel}%');
///   print('Charging: ${status.isCharging}');
///   print('Temperature: ${status.temperature}°C');
///   print('Knee level: ${status.kneeStimLevel}');
///   print('Thigh level: ${status.thighStimLevel}');
///   print('Treatment active: ${status.isTreatmentActive}');
///
///   if (status.isBatteryLow) {
///     showLowBatteryWarning();
///   }
/// });
///
/// // Clean up when done
/// await bleService.dispose();
/// ```
///
/// ## BLE UUIDs
///
/// The service uses the following Motive-specific UUIDs:
/// - **Service UUID**: `cece1130-0101-0000-a000-000000000000`
/// - **Command Characteristic**: `cece1141-0101-0000-b000-000000000000`
/// - **Status Characteristic**: `cece1131-0101-0000-b000-000000000000`
/// - **Product Info Characteristic**: `cece1132-0101-0000-b000-000000000000`
///
/// See also:
/// - [DeviceStatusMapper] for parsing status data
/// - [ProductInfoMapper] for parsing product info data
/// - [TherapyCommandMapper] for creating BLE commands
class MotiveBleService {
  /// Creates a new instance of [MotiveBleService].
  MotiveBleService();

  // ─────────────────────────────────────────────────────────────────────────────
  // BLE UUIDs
  // ─────────────────────────────────────────────────────────────────────────────

  /// UUID for the main Motive controller service.
  final String _controllerServiceUuid = 'cece1130-0101-0000-a000-000000000000';

  /// UUID for the command characteristic (write commands to device).
  final String _controllerCommandCharacteristicUuid =
      'cece1141-0101-0000-b000-000000000000';

  /// UUID for the status characteristic (device status notifications).
  static const String _controllerStatusCharacteristicUuid =
      'cece1131-0101-0000-b000-000000000000';

  /// UUID for the product info characteristic (firmware version, etc.).
  static const String _controllerProductInfoCharacteristicUuid =
      'cece1132-0101-0000-b000-000000000000';

  // ─────────────────────────────────────────────────────────────────────────────
  // BLE Characteristics
  // ─────────────────────────────────────────────────────────────────────────────

  BluetoothCharacteristic? _controllerCommandCharacteristic;
  BluetoothCharacteristic? _controllerStatusCharacteristic;
  BluetoothCharacteristic? _controllerProductInfoCharacteristic;

  /// The currently connected Bluetooth device.
  BluetoothDevice? device;

  /// Authentication code calculated from manufacturer data.
  int? _authCode;

  // ─────────────────────────────────────────────────────────────────────────────
  // Stream Controllers
  // ─────────────────────────────────────────────────────────────────────────────

  /// Stream controller for broadcasting parsed device status updates.
  final StreamController<DeviceStatus> _statusStreamController =
      StreamController<DeviceStatus>.broadcast();

  // Stream subscriptions
  StreamSubscription<List<int>>? _statusSubscription;

  // ─────────────────────────────────────────────────────────────────────────────
  // Public Streams
  // ─────────────────────────────────────────────────────────────────────────────

  /// Stream of parsed [DeviceStatus] updates from the device.
  ///
  /// This stream emits [DeviceStatus] objects containing all device information
  /// already parsed into readable properties. No manual byte parsing needed!
  ///
  /// The status includes:
  /// - `batteryLevel`: Battery percentage (0-100)
  /// - `isCharging`: Whether device is charging
  /// - `temperature`: Controller temperature in Celsius
  /// - `kneeStimLevel`: Knee stimulation level (0-100)
  /// - `thighStimLevel`: Thigh stimulation level (0-100)
  /// - `isTreatmentActive`: Whether therapy is running
  /// - `controllerStatus`: Status string (Idle, Stim, Charging, etc.)
  /// - `sheetStatus`: Pad docking status
  /// - `leftSkinContact` / `rightSkinContact`: Skin detection
  ///
  /// Convenience getters:
  /// - `isBatteryLow`: Battery below 20%
  /// - `isBatteryCritical`: Battery below 10%
  /// - `hasBothSkinContact`: Both pads have skin contact
  /// - `isIdle`, `isStimulating`, `isFaulted`: Quick status checks
  ///
  /// Example:
  /// ```dart
  /// bleService.statusStream.listen((status) {
  ///   print('Battery: ${status.batteryLevel}%');
  ///   print('Charging: ${status.isCharging}');
  ///   print('Knee level: ${status.kneeStimLevel}');
  ///   print('Thigh level: ${status.thighStimLevel}');
  ///   print('Treatment active: ${status.isTreatmentActive}');
  ///
  ///   if (status.isBatteryLow) {
  ///     showLowBatteryWarning();
  ///   }
  /// });
  /// ```
  Stream<DeviceStatus> get statusStream => _statusStreamController.stream;


  // ─────────────────────────────────────────────────────────────────────────────
  // Getters
  // ─────────────────────────────────────────────────────────────────────────────

  /// Returns the command characteristic for writing therapy commands.
  ///
  /// Returns `null` if the service has not been initialized or if
  /// the characteristic was not found during service discovery.
  BluetoothCharacteristic? get controllerCommandCharacteristic =>
      _controllerCommandCharacteristic;

  /// Returns the status characteristic for receiving device status updates.
  ///
  /// Returns `null` if the service has not been initialized or if
  /// the characteristic was not found during service discovery.
  BluetoothCharacteristic? get controllerStatusCharacteristic =>
      _controllerStatusCharacteristic;

  /// Returns the product info characteristic for receiving firmware info.
  ///
  /// Returns `null` if the service has not been initialized or if
  /// the characteristic was not found during service discovery.
  BluetoothCharacteristic? get controllerProductInfoCharacteristic =>
      _controllerProductInfoCharacteristic;

  /// Returns the calculated authentication code for the connected device.
  ///
  /// The auth code is derived from the manufacturer data in the device's
  /// advertisement and is required for all therapy commands.
  ///
  /// Returns `null` if the service has not been initialized.
  int? get authCode => _authCode;

  // ─────────────────────────────────────────────────────────────────────────────
  // Initialization
  // ─────────────────────────────────────────────────────────────────────────────

  /// Initializes the BLE service with a connected device.
  ///
  /// This method performs the following operations:
  /// 1. Discovers all BLE services on the device
  /// 2. Calculates the authentication code from manufacturer data
  /// 3. Locates and stores references to required characteristics
  /// 4. Starts listening to status and product info notifications
  ///
  /// Parameters:
  /// - [device]: The connected [BluetoothDevice] to communicate with
  /// - [manufacturerData]: Raw manufacturer data from the device's advertisement,
  ///   used to calculate the authentication code
  ///
  /// Throws an exception if service discovery fails or required characteristics
  /// are not found. Errors are logged but not rethrown.
  ///
  /// Example:
  /// ```dart
  /// final scanResult = await FlutterBluePlus.scanResults.first;
  /// final device = scanResult.device;
  /// await device.connect();
  ///
  /// final manufacturerData = scanResult.advertisementData.manufacturerData;
  /// await bleService.initialize(
  ///   device: device,
  ///   manufacturerData: manufacturerData.values.first,
  /// );
  /// ```
  Future<void> initialize({
    required final BluetoothDevice device,
    required final List<int> manufacturerData,
    void Function(Object e, StackTrace s)? errorCallback,
  }) async {
    try {
      final BluetoothConnectionState state = await device.connectionState.first;

      if (state != BluetoothConnectionState.connected) {
        debugPrint('[BLE] Device not connected, skipping service discovery');
        return;
      }

      final List<BluetoothService> services = await device.discoverServices();
      _authCode = BleCommandUtils.calculateAuthCode(manufacturerData);

      _controllerCommandCharacteristic = services
          .firstWhere(
            (final BluetoothService service) =>
                service.uuid.toString() == _controllerServiceUuid,
          )
          .characteristics
          .firstWhere(
            (final BluetoothCharacteristic characteristic) =>
                characteristic.uuid.toString() ==
                _controllerCommandCharacteristicUuid,
          );

      _controllerStatusCharacteristic = services
          .firstWhere(
            (final BluetoothService service) =>
                service.uuid.toString() == _controllerServiceUuid,
          )
          .characteristics
          .firstWhere(
            (final BluetoothCharacteristic characteristic) =>
                characteristic.uuid.toString() ==
                _controllerStatusCharacteristicUuid,
          );

      _controllerProductInfoCharacteristic = services
          .firstWhere(
            (final BluetoothService service) =>
                service.uuid.toString() == _controllerServiceUuid,
          )
          .characteristics
          .firstWhere(
            (final BluetoothCharacteristic characteristic) =>
                characteristic.uuid.toString() ==
                _controllerProductInfoCharacteristicUuid,
          );

      // Start listening to status stream
      await startStatusStream();
    } catch (e, s) {
      errorCallback?.call(e, s);
      debugPrint('Error initializing Motive BLE service: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Status Stream Management
  // ─────────────────────────────────────────────────────────────────────────────

  /// Starts listening to device status updates via BLE notifications.
  ///
  /// This method enables notifications on the status characteristic and
  /// forwards parsed [DeviceStatus] objects to [statusStream].
  ///
  /// The status characteristic provides real-time updates about:
  /// - Battery level and charging state
  /// - Device temperature
  /// - Pad/sheet status
  /// - Skin contact detection
  /// - Stimulation levels
  /// - Treatment state
  ///
  /// Returns immediately if the status characteristic is not available.
  ///
  /// Example:
  /// ```dart
  /// await bleService.startStatusStream();
  /// bleService.statusStream.listen((status) {
  ///   print('Battery: ${status.batteryLevel}%');
  ///   print('Treatment active: ${status.isTreatmentActive}');
  /// });
  /// ```
  Future<void> startStatusStream({
    void Function(Object e, StackTrace s)? errorCallback,
  }) async {
    if (_controllerStatusCharacteristic == null) return;

    try {
      // Enable notifications
      await _controllerStatusCharacteristic!.setNotifyValue(true);

      // Cancel existing subscription if any
      await _statusSubscription?.cancel();

      // Listen to status updates
      _statusSubscription = _controllerStatusCharacteristic!.lastValueStream
          .listen(
            (final List<int> data) {
              if (data.isNotEmpty && !_statusStreamController.isClosed) {
                final status = DeviceStatus.fromRawData(data);
                _statusStreamController.add(status);
              }
            },
            onError: (final dynamic error) {
              debugPrint('Status stream error: $error');
              errorCallback?.call(error, StackTrace.current);
            },
          );
    } catch (e, s) {
      errorCallback?.call(e, s);
      debugPrint('Error starting status stream: $e');
    }
  }

  /// Stops listening to device status updates.
  ///
  /// This method cancels the status subscription and disables notifications
  /// on the status characteristic to conserve device battery.
  ///
  /// Safe to call even if status streaming was never started.
  Future<void> stopStatusStream({
    void Function(Object e, StackTrace s)? errorCallback,
  }) async {
    await _statusSubscription?.cancel();
    _statusSubscription = null;

    try {
      await _controllerStatusCharacteristic?.setNotifyValue(false);
    } catch (e, s) {
      errorCallback?.call(e, s);
      debugPrint('Error stopping status notifications: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Product Info (One-Time Read)
  // ─────────────────────────────────────────────────────────────────────────────

  /// Reads product info from the device as a one-time BLE read.
  ///
  /// Performs a direct read of the product info characteristic and returns
  /// a parsed [ProductInfo] model containing firmware version details.
  ///
  /// Returns [ProductInfo.unknown] if the characteristic is not available
  /// or the read fails.
  ///
  /// The product info includes:
  /// - `major`, `minor`, `release`, `build`: Version components
  /// - `firmwareVersion`: Formatted version string (e.g., "01.02.03.04")
  /// - `shortVersion`: Short format (e.g., "1.2.3")
  ///
  /// Convenience methods:
  /// - `meetsMinimumVersion(version)`: Check version compatibility
  /// - `isNewerThan(other)` / `isOlderThan(other)`: Compare versions
  ///
  /// Example:
  /// ```dart
  /// final info = await bleService.readProductInfo();
  /// print('Firmware: ${info.firmwareVersion}');
  ///
  /// if (!info.meetsMinimumVersion('2.0.0')) {
  ///   showUpdatePrompt();
  /// }
  /// ```
  Future<ProductInfo> readProductInfo({
    void Function(Object e, StackTrace s)? errorCallback,
  }) async {
    if (_controllerProductInfoCharacteristic == null) {
      debugPrint('[BLE] Product info characteristic not available');
      return ProductInfo.unknown();
    }

    try {
      final List<int> data =
          await _controllerProductInfoCharacteristic!.read();
      debugPrint('[BLE] Product info raw data: $data (${data.length} bytes)');

      if (data.isEmpty) return ProductInfo.unknown();

      return ProductInfo.fromRawData(data);
    } catch (e, s) {
      errorCallback?.call(e, s);
      debugPrint('[BLE] Error reading product info: $e');
      return ProductInfo.unknown();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Cleanup
  // ─────────────────────────────────────────────────────────────────────────────

  /// Disposes of all resources and cleans up the service.
  ///
  /// This method should be called when the BLE service is no longer needed.
  /// It performs the following cleanup:
  /// 1. Stops all notification subscriptions
  /// 2. Closes stream controllers
  /// 3. Clears characteristic references
  /// 4. Resets device and auth code
  ///
  /// After calling this method, the service must be re-initialized before
  /// it can be used again.
  ///
  /// Example:
  /// ```dart
  /// // When disconnecting from device
  /// await bleService.dispose();
  /// await device.disconnect();
  /// ```
  Future<void> dispose() async {
    await stopStatusStream();

    if (!_statusStreamController.isClosed) {
      await _statusStreamController.close();
    }

    _controllerCommandCharacteristic = null;
    _controllerStatusCharacteristic = null;
    _controllerProductInfoCharacteristic = null;
    device = null;
    _authCode = null;
  }
}
