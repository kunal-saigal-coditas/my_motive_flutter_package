import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:my_motive_package/core/utils/ble_command_utils.dart';

/// Service for managing BLE communication with Motive therapy devices.
///
/// This service handles the low-level Bluetooth Low Energy (BLE) communication
/// with Motive controllers, including:
/// - Service and characteristic discovery
/// - Authentication code calculation
/// - Status and product info streaming
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
/// // Listen to device status updates
/// bleService.statusStream.listen((data) {
///   final batteryLevel = DeviceStatusMapper.parseBatteryLevel(data);
///   print('Battery: $batteryLevel%');
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

  /// Stream controller for broadcasting device status updates.
  final StreamController<List<int>> _statusStreamController =
      StreamController<List<int>>.broadcast();

  /// Stream controller for broadcasting product info updates.
  final StreamController<List<int>> _productInfoStreamController =
      StreamController<List<int>>.broadcast();

  // Stream subscriptions
  StreamSubscription<List<int>>? _statusSubscription;
  StreamSubscription<List<int>>? _productInfoSubscription;

  // ─────────────────────────────────────────────────────────────────────────────
  // Public Streams
  // ─────────────────────────────────────────────────────────────────────────────

  /// Stream of raw status data from the device.
  ///
  /// This stream emits byte arrays containing device status information
  /// whenever the device sends a notification. Use [DeviceStatusMapper]
  /// to parse the raw data into meaningful values.
  ///
  /// The status data includes:
  /// - Battery level and charging status
  /// - Controller temperature
  /// - Sheet/pad status and skin contact
  /// - Stimulation levels
  /// - Treatment active state
  ///
  /// Example:
  /// ```dart
  /// bleService.statusStream.listen((data) {
  ///   final battery = DeviceStatusMapper.parseBatteryLevel(data);
  ///   final isCharging = DeviceStatusMapper.parseIsCharging(data);
  ///   print('Battery: $battery%, Charging: $isCharging');
  /// });
  /// ```
  Stream<List<int>> get statusStream => _statusStreamController.stream;

  /// Stream of raw product info data from the device.
  ///
  /// This stream emits byte arrays containing product information
  /// whenever the device sends a notification. Use [ProductInfoMapper]
  /// to parse the raw data into firmware version and other details.
  ///
  /// Example:
  /// ```dart
  /// bleService.productInfoStream.listen((data) {
  ///   final info = ProductInfoMapper.parse(data);
  ///   print('Firmware: ${info.firmwareVersion}');
  /// });
  /// ```
  Stream<List<int>> get productInfoStream =>
      _productInfoStreamController.stream;

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

      // Start listening to status and product info streams
      await startStatusStream();
      await startProductInfoStream();
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
  /// forwards all received data to [statusStream]. Any existing subscription
  /// is cancelled before creating a new one.
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
  /// bleService.statusStream.listen((data) {
  ///   // Process status data
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
                _statusStreamController.add(data);
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
  // Product Info Stream Management
  // ─────────────────────────────────────────────────────────────────────────────

  /// Starts listening to product info updates via BLE notifications.
  ///
  /// This method enables notifications on the product info characteristic
  /// and forwards all received data to [productInfoStream]. Any existing
  /// subscription is cancelled before creating a new one.
  ///
  /// Product info includes:
  /// - Firmware version (major.minor.release.build)
  /// - Device model information
  ///
  /// Returns immediately if the product info characteristic is not available.
  Future<void> startProductInfoStream({
    void Function(Object e, StackTrace s)? errorCallback,
  }) async {
    if (_controllerProductInfoCharacteristic == null) return;

    try {
      // Enable notifications
      await _controllerProductInfoCharacteristic!.setNotifyValue(true);

      // Cancel existing subscription if any
      await _productInfoSubscription?.cancel();

      // Listen to product info updates
      _productInfoSubscription = _controllerProductInfoCharacteristic!
          .lastValueStream
          .listen(
            (final List<int> data) {
              if (data.isNotEmpty && !_productInfoStreamController.isClosed) {
                _productInfoStreamController.add(data);
              }
            },
            onError: (final dynamic error) {
              debugPrint('Product info stream error: $error');
              errorCallback?.call(error, StackTrace.current);
            },
          );
    } catch (e, s) {
      errorCallback?.call(e, s);
      debugPrint('Error starting product info stream: $e');
    }
  }

  /// Stops listening to product info updates.
  ///
  /// This method cancels the product info subscription and disables
  /// notifications on the characteristic to conserve device battery.
  ///
  /// Safe to call even if product info streaming was never started.
  Future<void> stopProductInfoStream({
    void Function(Object e, StackTrace s)? errorCallback,
  }) async {
    await _productInfoSubscription?.cancel();
    _productInfoSubscription = null;

    try {
      await _controllerProductInfoCharacteristic?.setNotifyValue(false);
    } catch (e, s) {
      errorCallback?.call(e, s);
      debugPrint('Error stopping product info notifications: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Direct Reads
  // ─────────────────────────────────────────────────────────────────────────────

  /// Reads product info directly from the device (one-time read).
  ///
  /// Use this method for an initial read of product info before notifications
  /// are enabled, or when you need to explicitly request the current values.
  ///
  /// Returns the raw byte array containing product info data, or `null` if:
  /// - The product info characteristic is not available
  /// - The read operation fails
  ///
  /// Example:
  /// ```dart
  /// final data = await bleService.readProductInfo();
  /// if (data != null) {
  ///   final info = ProductInfoMapper.parse(data);
  ///   print('Firmware version: ${info.firmwareVersion}');
  /// }
  /// ```
  Future<List<int>?> readProductInfo({
    void Function(Object e, StackTrace s)? errorCallback,
  }) async {
    if (_controllerProductInfoCharacteristic == null) return null;

    try {
      return await _controllerProductInfoCharacteristic!.read();
    } catch (e, s) {
      errorCallback?.call(e, s);
      debugPrint('Error reading product info: $e');
      return null;
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
    await stopProductInfoStream();

    if (!_statusStreamController.isClosed) {
      await _statusStreamController.close();
    }
    if (!_productInfoStreamController.isClosed) {
      await _productInfoStreamController.close();
    }

    _controllerCommandCharacteristic = null;
    _controllerStatusCharacteristic = null;
    _controllerProductInfoCharacteristic = null;
    device = null;
    _authCode = null;
  }
}
