import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DeviceHelpers {
  /// Extract a unique identifier for the controller
  static String extractControllerId(final BluetoothDevice device) {
    final String name = device.platformName;

    if (name.toLowerCase().contains('motive')) {
      // For Motive devices, use the device ID as controller ID
      return device.remoteId.str;
    }

    return device.remoteId.str;
  }

  /// Filter for BLE devices (devices with specific BLE characteristics)
  static List<ScanResult> getBleDevices(final List<ScanResult> scanResults) {
    return scanResults.where(
      (final ScanResult result) {
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
      },
    ).toList();
  }

  /// Filter for Classic Bluetooth devices
  static List<ScanResult> getClassicDevices(
    final List<ScanResult> scanResults,
  ) {
    return scanResults.where(
      (final ScanResult result) {
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
      },
    ).toList();
  }

  /// Filter specifically for Motive devices
  static List<ScanResult> getMotiveDevices(final List<ScanResult> scanResults) {
    return scanResults.where(
      (final ScanResult result) {
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
      },
    ).toList();
  }

  /// Get devices that don't fit either category
  static List<ScanResult> getOtherDevices(final List<ScanResult> scanResults) {
    final List<ScanResult> bleDevices = getBleDevices(scanResults);
    final List<ScanResult> classicDevices = getClassicDevices(scanResults);

    return scanResults.where(
      (final ScanResult result) {
        return !bleDevices.contains(result) && !classicDevices.contains(result);
      },
    ).toList();
  }

  /// Check if a device is a Motive device
  static bool isMotiveDevice(final BluetoothDevice device) {
    final String name = device.platformName.toLowerCase();

    return name.contains('motive');
  }

  /// Format ISO date string to readable format
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
