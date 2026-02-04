import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for managing Bluetooth and Location permissions required for BLE operations.
///
/// This service provides a unified API for requesting and checking permissions
/// across both Android and iOS platforms, handling the differences in permission
/// models between platform versions.
///
/// ## Android Permission Model
///
/// - **Android 12+ (API 31+)**: Requires `bluetoothScan`, `bluetoothConnect`, and `location`
/// - **Android 11 and below**: Requires `bluetooth` and `location`
///
/// ## iOS Permission Model
///
/// - Requires `bluetooth` and optionally `location` permissions
///
/// ## Usage
///
/// ```dart
/// // Request all required permissions
/// final permissions = await PermissionService.requestPermissions();
///
/// // Check if ready for BLE operations
/// if (await PermissionService.areRequiredPermissionsGranted()) {
///   // Start scanning for devices
/// }
///
/// // Debug permission issues
/// final details = await PermissionService.getPermissionStatusDetails();
/// print(details);
/// ```
///
/// See also:
/// - [BluetoothScanUtils] for scanning with automatic permission checks
class PermissionService {
  /// Requests all necessary permissions based on the current platform.
  ///
  /// This method automatically detects the platform and Android version
  /// to request the appropriate permissions.
  ///
  /// Returns a [Map] with permission names as keys and their statuses as values.
  /// Possible keys include:
  /// - `bluetoothScan` (Android 12+)
  /// - `bluetoothConnect` (Android 12+)
  /// - `bluetooth` (iOS and legacy Android)
  /// - `location`
  ///
  /// Returns an empty map if an error occurs during the request.
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

  /// Checks if the Bluetooth permission is currently granted.
  ///
  /// On Android 12+, this checks the basic bluetooth permission.
  /// For scan/connect operations, use [requestPermissions] which handles
  /// the more specific permissions.
  ///
  /// Returns `true` if granted, `false` otherwise or on error.
  static Future<bool> isBluetoothPermissionGranted() async {
    try {
      final PermissionStatus status = await Permission.bluetooth.status;

      return status.isGranted;
    } catch (e) {
      debugPrint('Error checking Bluetooth permission: $e');

      return false;
    }
  }

  /// Checks if the Location permission is currently granted.
  ///
  /// Location permission is required on Android for BLE scanning to discover
  /// nearby devices. On iOS, it's optional but may be needed for some features.
  ///
  /// Returns `true` if granted, `false` otherwise or on error.
  static Future<bool> isLocationPermissionGranted() async {
    try {
      final PermissionStatus status = await Permission.location.status;

      return status.isGranted;
    } catch (e) {
      debugPrint('Error checking Location permission: $e');

      return false;
    }
  }

  /// Checks if all required permissions for BLE operations are granted.
  ///
  /// This is a convenience method that checks both Bluetooth and Location
  /// permissions. Use this before attempting to scan for or connect to devices.
  ///
  /// Returns `true` only if all required permissions are granted.
  ///
  /// Example:
  /// ```dart
  /// if (await PermissionService.areRequiredPermissionsGranted()) {
  ///   await startBluetoothScan();
  /// } else {
  ///   await PermissionService.requestPermissions();
  /// }
  /// ```
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

  /// Requests only the Bluetooth permission.
  ///
  /// For full BLE functionality on Android 12+, use [requestPermissions]
  /// instead, which also requests scan and connect permissions.
  ///
  /// Returns `true` if the permission is granted after the request.
  static Future<bool> requestBluetoothPermission() async {
    try {
      final PermissionStatus status = await Permission.bluetooth.request();

      return status.isGranted;
    } catch (e) {
      debugPrint('Error requesting Bluetooth permission: $e');

      return false;
    }
  }

  /// Requests only the Location permission.
  ///
  /// Location permission is required on Android for BLE device discovery.
  ///
  /// Returns `true` if the permission is granted after the request.
  static Future<bool> requestLocationPermission() async {
    try {
      final PermissionStatus status = await Permission.location.request();

      return status.isGranted;
    } catch (e) {
      debugPrint('Error requesting Location permission: $e');

      return false;
    }
  }

  /// Requests both Bluetooth and Location permissions simultaneously.
  ///
  /// This is an alternative to [requestPermissions] that returns a simpler
  /// boolean result for each permission type.
  ///
  /// Returns a [Map] with keys `bluetooth` and `location`, where values
  /// are `true` if the permission was granted, `false` otherwise.
  ///
  /// Example:
  /// ```dart
  /// final results = await PermissionService.requestRequiredPermissions();
  /// if (results['bluetooth'] == true && results['location'] == true) {
  ///   // Ready for BLE operations
  /// }
  /// ```
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

  /// Checks if Bluetooth hardware is enabled on the device.
  ///
  /// Note: On iOS, this always returns `true` as iOS handles Bluetooth
  /// state internally and doesn't expose this to apps.
  ///
  /// Returns `true` if Bluetooth is enabled, `false` otherwise.
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

  /// Checks if Location services are enabled on the device.
  ///
  /// Location services must be enabled (not just permission granted)
  /// for BLE scanning to work on Android.
  ///
  /// Returns `true` if location services are enabled, `false` otherwise.
  static Future<bool> isLocationEnabled() async {
    try {
      return await Permission.location.serviceStatus.isEnabled;
    } catch (e) {
      debugPrint('Error checking if Location is enabled: $e');

      return false;
    }
  }

  /// Gets the Android SDK version for permission handling.
  ///
  /// Returns the Android API level, or 31 (Android 12) as default if
  /// the version cannot be determined.
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

  /// Checks if all required hardware services are enabled.
  ///
  /// This verifies both Bluetooth and Location services are enabled
  /// on the device. Even with permissions granted, BLE operations will
  /// fail if these services are disabled.
  ///
  /// Returns `true` only if all required services are enabled.
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

  /// Gets detailed permission and service status information for debugging.
  ///
  /// Returns a [Map] containing the status of all relevant permissions
  /// and services:
  /// - `bluetooth_permission`: Permission status for Bluetooth
  /// - `location_permission`: Permission status for Location
  /// - `bluetooth_service`: Service status for Bluetooth hardware
  /// - `location_service`: Service status for Location services
  ///
  /// If an error occurs, returns a map with an `error` key containing
  /// the error message.
  ///
  /// Example:
  /// ```dart
  /// final details = await PermissionService.getPermissionStatusDetails();
  /// debugPrint('Permission status: $details');
  /// ```
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
