import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:my_motive_package/core/utils/ble_command_utils.dart';

class MotiveBleService {
  MotiveBleService();

  // BLE UUIDs for Motive device
  final String _controllerServiceUuid = 'cece1130-0101-0000-a000-000000000000';
  final String _controllerCommandCharacteristicUuid =
      'cece1141-0101-0000-b000-000000000000';

  static const String _controllerStatusCharacteristicUuid =
      'cece1131-0101-0000-b000-000000000000';

  static const String _controllerProductInfoCharacteristicUuid =
      'cece1132-0101-0000-b000-000000000000';

  BluetoothCharacteristic? _controllerCommandCharacteristic;
  BluetoothCharacteristic? _controllerStatusCharacteristic;
  BluetoothCharacteristic? _controllerProductInfoCharacteristic;

  BluetoothDevice? device;
  int? _authCode;

  // Stream controllers for status and product info
  final StreamController<List<int>> _statusStreamController =
      StreamController<List<int>>.broadcast();
  final StreamController<List<int>> _productInfoStreamController =
      StreamController<List<int>>.broadcast();

  // Stream subscriptions
  StreamSubscription<List<int>>? _statusSubscription;
  StreamSubscription<List<int>>? _productInfoSubscription;

  // Public streams
  /// Stream of raw status data from the device
  Stream<List<int>> get statusStream => _statusStreamController.stream;

  /// Stream of raw product info data from the device
  Stream<List<int>> get productInfoStream =>
      _productInfoStreamController.stream;

  BluetoothCharacteristic? get controllerCommandCharacteristic =>
      _controllerCommandCharacteristic;

  BluetoothCharacteristic? get controllerStatusCharacteristic =>
      _controllerStatusCharacteristic;

  BluetoothCharacteristic? get controllerProductInfoCharacteristic =>
      _controllerProductInfoCharacteristic;

  int? get authCode => _authCode;

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

  /// Start listening to device status updates
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

  /// Stop listening to device status updates
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

  /// Start listening to product info updates
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

  /// Stop listening to product info updates
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

  /// Read product info once (for initial read)
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

  /// Dispose of all resources
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
