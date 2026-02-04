import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Helper utilities for Bluetooth device identification and filtering.
///
/// This class provides methods to:
/// - Extract controller identifiers from devices
/// - Filter scan results by device type (BLE, Classic, Motive)
/// - Check device characteristics
/// - Format device information
///
/// ## Device Filtering
///
/// The class categorizes scanned devices into:
/// - **Motive devices**: Devices with "motive" in their name
/// - **BLE devices**: Medical/IoT devices with BLE characteristics
/// - **Classic devices**: Audio devices, phones, computers, etc.
///
/// ## Example
///
/// ```dart
/// FlutterBluePlus.scanResults.listen((results) {
///   final motiveDevices = DeviceHelpers.getMotiveDevices(results);
///   final bleDevices = DeviceHelpers.getBleDevices(results);
///
///   for (final result in motiveDevices) {
///     final id = DeviceHelpers.extractControllerId(result.device);
///     print('Found Motive device: $id');
///   }
/// });
/// ```
class DeviceHelpers {
  /// Extracts a unique identifier for the controller.
  ///
  /// For Motive devices, returns the remote ID string.
  /// Falls back to remote ID for other device types.
  static String extractControllerId(final BluetoothDevice device) {
    final String name = device.platformName;

    if (name.toLowerCase().contains('motive')) {
      // For Motive devices, use the device ID as controller ID
      return device.remoteId.str;
    }

    return device.remoteId.str;
  }

  /// Filters scan results to include only BLE/IoT devices.
  ///
  /// Identifies BLE devices by name patterns including:
  /// - Medical devices (MD-, BP-, HR-, ECG, pulse, oximeter, glucose, etc.)
  /// - IoT devices (sensor, monitor, smart, ble, iot)
  /// - Devices with short names (≤8 characters)
  /// - Devices with no name (common for BLE peripherals)
  /// - Alphanumeric names without spaces
  static List<ScanResult> getBleDevices(final List<ScanResult> scanResults) {
    return scanResults.where((final ScanResult result) {
      final BluetoothDevice device = result.device;
      final String name = device.platformName.toLowerCase();

      // Medical devices often have names like "MD-", "BP-", "HR-", etc.
      if (name.contains('md-') ||
          name.contains('bp-') ||
          name.contains('hr-') ||
          name.contains('ecg') ||
          name.contains('pulse') ||
          name.contains('oximeter') ||
          name.contains('glucose') ||
          name.contains('thermometer') ||
          name.contains('scale') ||
          name.contains('monitor') ||
          name.contains('sensor') ||
          name.contains('device') ||
          name.contains('ble') ||
          name.contains('iot') ||
          name.contains('smart')) {
        return true;
      }

      // BLE devices typically have shorter names
      if (name.length <= 8 && name.isNotEmpty) {
        return true;
      }

      // Include devices with no name (often BLE devices)
      if (device.platformName.isEmpty) {
        return true;
      }

      // Check if device name looks like a BLE device (no spaces, alphanumeric)
      if (name.isNotEmpty &&
          !name.contains(' ') &&
          RegExp(r'^[a-zA-Z0-9\-_]+$').hasMatch(name)) {
        return true;
      }

      return false;
    }).toList();
  }

  /// Filters scan results to include only Classic Bluetooth devices.
  ///
  /// Identifies classic devices by name patterns including:
  /// - Audio devices (headphone, speaker, earbud, airpod, soundbar)
  /// - Consumer electronics (phone, laptop, computer, TV, car)
  /// - Devices with long names containing spaces
  /// - Names longer than 15 characters
  static List<ScanResult> getClassicDevices(
    final List<ScanResult> scanResults,
  ) {
    return scanResults.where((final ScanResult result) {
      final BluetoothDevice device = result.device;
      final String name = device.platformName.toLowerCase();

      // Classic devices typically have longer names and are audio devices
      if (name.contains('headphone') ||
          name.contains('speaker') ||
          name.contains('earbud') ||
          name.contains('airpod') ||
          name.contains('galaxy') ||
          name.contains('iphone') ||
          name.contains('android') ||
          name.contains('phone') ||
          name.contains('laptop') ||
          name.contains('computer') ||
          name.contains('tv') ||
          name.contains('soundbar') ||
          name.contains('car') ||
          name.contains('vehicle') ||
          name.contains('audio') ||
          name.contains('music')) {
        return true;
      }

      // Devices with longer names and spaces are usually classic
      if (name.length > 8 && name.contains(' ')) {
        return true;
      }

      // Devices with very long names are usually classic
      if (name.length > 15) {
        return true;
      }

      return false;
    }).toList();
  }

  /// Filters scan results to include only Motive therapy devices.
  ///
  /// Identifies Motive devices by checking if the name contains "motive"
  /// (case-insensitive). Found devices are logged for debugging.
  static List<ScanResult> getMotiveDevices(final List<ScanResult> scanResults) {
    return scanResults.where((final ScanResult result) {
      final BluetoothDevice device = result.device;
      final String name = device.platformName;
      final String localName =
          device.platformName; // Flutter Blue Plus uses platformName for both

      // Check if device name contains 'Motive' (case-insensitive)
      if (name.toLowerCase().contains('motive') ||
          localName.toLowerCase().contains('motive')) {
        debugPrint('Found Motive device: $name (${device.remoteId})');

        return true;
      }

      return false;
    }).toList();
  }

  /// Gets devices that don't fit BLE or Classic categories.
  ///
  /// Returns scan results that are not identified as either BLE or
  /// Classic Bluetooth devices by the filtering heuristics.
  static List<ScanResult> getOtherDevices(final List<ScanResult> scanResults) {
    final List<ScanResult> bleDevices = getBleDevices(scanResults);
    final List<ScanResult> classicDevices = getClassicDevices(scanResults);

    return scanResults.where((final ScanResult result) {
      return !bleDevices.contains(result) && !classicDevices.contains(result);
    }).toList();
  }

  /// Checks if a device is a Motive therapy device.
  ///
  /// Returns `true` if the device name contains "motive" (case-insensitive).
  static bool isMotiveDevice(final BluetoothDevice device) {
    final String name = device.platformName.toLowerCase();

    return name.contains('motive');
  }

  /// Formats an ISO date string to a readable format.
  ///
  /// Converts ISO 8601 dates to "DD/MM/YYYY HH:MM" format.
  /// Returns "Unknown" for null input or "Invalid date" on parse failure.
  static String formatDate(final String? isoDate) {
    if (isoDate == null) return 'Unknown';

    try {
      final DateTime date = DateTime.parse(isoDate);

      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }
}
