import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request all necessary permissions based on platform
  static Future<Map<String, PermissionStatus>> requestPermissions() async {
    try {
      debugPrint('Requesting permissions...');

      if (Platform.isAndroid) {
        final int androidVersion = await _getAndroidVersion();

        debugPrint('Android version: $androidVersion');

        if (androidVersion >= 31) {
          // Android 12+ permissions
          debugPrint('Requesting Android 12+ permissions...');

          final PermissionStatus scanResult = await Permission.bluetoothScan
              .request();
          final PermissionStatus connectResult = await Permission
              .bluetoothConnect
              .request();
          final PermissionStatus locationResult = await Permission.location
              .request();

          debugPrint(
            'Bluetooth Scan: $scanResult, Bluetooth Connect: $connectResult, Location: $locationResult',
          );

          return <String, PermissionStatus>{
            'bluetoothScan': scanResult,
            'bluetoothConnect': connectResult,
            'location': locationResult,
          };
        } else {
          // Legacy Android permissions
          debugPrint('Requesting legacy Android permissions...');

          final PermissionStatus bluetoothResult = await Permission.bluetooth
              .request();
          final PermissionStatus locationResult = await Permission.location
              .request();

          debugPrint('Bluetooth: $bluetoothResult, Location: $locationResult');

          return <String, PermissionStatus>{
            'bluetooth': bluetoothResult,
            'location': locationResult,
          };
        }
      } else if (Platform.isIOS) {
        // iOS permissions
        final PermissionStatus bluetoothResult = await Permission.bluetooth
            .request();
        final PermissionStatus locationResult = await Permission.location
            .request();

        debugPrint('Bluetooth: $bluetoothResult, Location: $locationResult');

        return <String, PermissionStatus>{
          'bluetooth': bluetoothResult,
          'location': locationResult,
        };
      }

      return <String, PermissionStatus>{};
    } catch (e) {
      debugPrint('Error requesting permissions: $e');

      return <String, PermissionStatus>{};
    }
  }

  /// Check if Bluetooth permission is granted
  static Future<bool> isBluetoothPermissionGranted() async {
    try {
      final PermissionStatus status = await Permission.bluetooth.status;

      return status.isGranted;
    } catch (e) {
      debugPrint('Error checking Bluetooth permission: $e');

      return false;
    }
  }

  /// Check if Location permission is granted
  static Future<bool> isLocationPermissionGranted() async {
    try {
      final PermissionStatus status = await Permission.location.status;

      return status.isGranted;
    } catch (e) {
      debugPrint('Error checking Location permission: $e');

      return false;
    }
  }

  /// Check if both Bluetooth and Location permissions are granted
  static Future<bool> areRequiredPermissionsGranted() async {
    try {
      final bool bluetoothGranted = await isBluetoothPermissionGranted();
      final bool locationGranted = await isLocationPermissionGranted();

      return bluetoothGranted && locationGranted;
    } catch (e) {
      debugPrint('Error checking required permissions: $e');

      return false;
    }
  }

  /// Request Bluetooth permission
  static Future<bool> requestBluetoothPermission() async {
    try {
      final PermissionStatus status = await Permission.bluetooth.request();

      return status.isGranted;
    } catch (e) {
      debugPrint('Error requesting Bluetooth permission: $e');

      return false;
    }
  }

  /// Request Location permission
  static Future<bool> requestLocationPermission() async {
    try {
      final PermissionStatus status = await Permission.location.request();

      return status.isGranted;
    } catch (e) {
      debugPrint('Error requesting Location permission: $e');

      return false;
    }
  }

  /// Request both Bluetooth and Location permissions
  static Future<Map<String, bool>> requestRequiredPermissions() async {
    try {
      final Map<Permission, PermissionStatus> statuses =
          await <PermissionWithService>[
            Permission.bluetooth,
            Permission.location,
          ].request();

      return <String, bool>{
        'bluetooth': statuses[Permission.bluetooth]?.isGranted ?? false,
        'location': statuses[Permission.location]?.isGranted ?? false,
      };
    } catch (e) {
      debugPrint('Error requesting required permissions: $e');

      return <String, bool>{'bluetooth': false, 'location': false};
    }
  }

  /// Check if Bluetooth is enabled on the device
  static Future<bool> isBluetoothEnabled() async {
    try {
      // For Android, we can check if Bluetooth is enabled
      // For iOS, this will always return true as iOS handles Bluetooth internally
      if (defaultTargetPlatform == TargetPlatform.android) {
        return await Permission.bluetoothConnect.isGranted;
      }

      return true; // iOS handles Bluetooth internally
    } catch (e) {
      debugPrint('Error checking if Bluetooth is enabled: $e');

      return false;
    }
  }

  /// Check if Location services are enabled on the device
  static Future<bool> isLocationEnabled() async {
    try {
      return await Permission.location.serviceStatus.isEnabled;
    } catch (e) {
      debugPrint('Error checking if Location is enabled: $e');

      return false;
    }
  }

  /// Get Android version for permission handling
  static Future<int> _getAndroidVersion() async {
    try {
      // This would need platform-specific implementation
      // For now, return a default value
      return 31; // Assume Android 12+ by default
    } catch (e) {
      debugPrint('Error getting Android version: $e');

      return 31; // Default to Android 12+
    }
  }

  /// Check if both Bluetooth and Location services are enabled
  static Future<bool> areRequiredServicesEnabled() async {
    try {
      final bool bluetoothEnabled = await isBluetoothEnabled();
      final bool locationEnabled = await isLocationEnabled();

      return bluetoothEnabled && locationEnabled;
    } catch (e) {
      debugPrint('Error checking required services: $e');

      return false;
    }
  }

  /// Get permission status details for debugging
  static Future<Map<String, String>> getPermissionStatusDetails() async {
    try {
      final Map<String, String> details = <String, String>{};

      // Bluetooth permission status
      final PermissionStatus bluetoothStatus =
          await Permission.bluetooth.status;
      details['bluetooth_permission'] = bluetoothStatus.toString();

      // Location permission status
      final PermissionStatus locationStatus = await Permission.location.status;
      details['location_permission'] = locationStatus.toString();

      // Service status
      final ServiceStatus bluetoothService =
          await Permission.bluetooth.serviceStatus;
      details['bluetooth_service'] = bluetoothService.toString();

      final ServiceStatus locationService =
          await Permission.location.serviceStatus;
      details['location_service'] = locationService.toString();

      return details;
    } catch (e) {
      debugPrint('Error getting permission status details: $e');

      return <String, String>{'error': e.toString()};
    }
  }
}
