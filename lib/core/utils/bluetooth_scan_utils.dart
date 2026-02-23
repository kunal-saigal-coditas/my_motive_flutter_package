import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:my_motive_package/services/permission_service.dart';
import 'package:permission_handler/permission_handler.dart';

/// Utility class for managing Bluetooth Low Energy scanning operations.
///
/// This class handles the complete scan lifecycle including:
/// - Permission verification and requests
/// - Bluetooth adapter state management
/// - Error handling with user-friendly messages
/// - Scan timeout management
///
/// ## Prerequisites
///
/// Before scanning can begin, the following must be true:
/// - Device supports BLE
/// - Bluetooth is enabled
/// - Required permissions are granted (Bluetooth + Location on Android)
///
/// ## Platform-Specific Requirements
///
/// ### Android
/// - **Android 12+ (API 31+)**: Requires `BLUETOOTH_SCAN` and `BLUETOOTH_CONNECT`
/// - **Android 11 and below**: Requires `BLUETOOTH` and `ACCESS_FINE_LOCATION`
///
/// ### iOS
/// - Requires `NSBluetoothAlwaysUsageDescription` in Info.plist
/// - Bluetooth permission must be granted
///
/// ## Example
///
/// ```dart
/// await BluetoothScanUtils.startScan(
///   context: context,
///   onScanStarted: () => setState(() => isScanning = true),
///   onScanCompleted: () => setState(() => isScanning = false),
///   onScanError: () => showError('Scan failed'),
/// );
///
/// // Listen to scan results
/// FlutterBluePlus.scanResults.listen((results) {
///   for (final result in results) {
///     print('Found device: ${result.device.platformName}');
///   }
/// });
///
/// // Stop scanning manually if needed
/// await BluetoothScanUtils.stopScan();
/// ```
///
/// See also:
/// - [PermissionService] for permission management
/// - [DeviceHelpers] for filtering scan results
class BluetoothScanUtils {
  /// Default scan timeout in seconds.
  ///
  /// Scanning will automatically stop after this duration.
  static const int _scanTimeoutSeconds = 30;

  /// Delay in seconds after attempting to turn on the Bluetooth adapter.
  ///
  /// This gives the adapter time to fully initialize before checking state.
  static const int _adapterTurnOnDelaySeconds = 2;

  /// Flag to prevent multiple error snackbars from showing simultaneously.
  static bool _isShowingSnackbar = false;

  /// Starts a BLE scan with full error handling and precondition checks.
  ///
  /// This method performs the following steps:
  /// 1. Verifies BLE hardware support on the device
  /// 2. Checks Bluetooth adapter availability
  /// 3. Verifies and requests required permissions
  /// 4. Ensures the Bluetooth adapter is turned on
  /// 5. Starts the scan with the configured timeout
  ///
  /// ## Parameters
  ///
  /// - [context]: BuildContext for showing error snackbars
  /// - [onScanStarted]: Callback invoked when scan successfully begins
  /// - [onScanCompleted]: Callback invoked when scan finishes or times out
  /// - [onScanError]: Callback invoked if scan cannot be started
  ///
  /// ## Error Handling
  ///
  /// All errors are caught and displayed via snackbar with actionable
  /// messages. Common errors include:
  /// - Missing permissions
  /// - Bluetooth disabled
  /// - BLE not supported
  /// - Scan already in progress
  ///
  /// ## Example
  ///
  /// ```dart
  /// await BluetoothScanUtils.startScan(
  ///   context: context,
  ///   onScanStarted: () {
  ///     setState(() => _isScanning = true);
  ///   },
  ///   onScanCompleted: () {
  ///     setState(() => _isScanning = false);
  ///   },
  ///   onScanError: () {
  ///     setState(() => _isScanning = false);
  ///     showErrorDialog('Failed to start scan');
  ///   },
  /// );
  /// ```
  static Future<void> startScan({
    required final BuildContext context,
    required final VoidCallback onScanStarted,
    required final VoidCallback onScanCompleted,
    required final VoidCallback onScanError,
  }) async {
    try {
      debugPrint('Starting BLE scan...');

      // Check preconditions
      final bool ready = await _ensureScanPreconditions(context);

      if (!ready) {
        onScanError();

        return;
      }

      // Clear previous results and start scan
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: _scanTimeoutSeconds),
      );

      debugPrint('Scan started successfully');

      onScanStarted();

      // Set up timeout handler
      Timer(const Duration(seconds: _scanTimeoutSeconds + 1), () {
        if (context.mounted) {
          debugPrint('Scan timeout reached');

          _showScanError(context, 'Scan timeout reached');
        }
      });
    } catch (e) {
      debugPrint('Error starting scan: $e');

      if (context.mounted) {
        _showScanError(context, e);
      }

      onScanError();
    }
  }

  /// Stops an active Bluetooth scan.
  ///
  /// This method is safe to call even if no scan is currently in progress.
  /// Any errors during stop are logged but not thrown.
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Stop scan when user navigates away
  /// @override
  /// void dispose() {
  ///   BluetoothScanUtils.stopScan();
  ///   super.dispose();
  /// }
  /// ```
  static Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();

      debugPrint('Scan stopped successfully');
    } catch (e) {
      debugPrint('Error stopping scan: $e');
    }
  }

  /// Ensures all preconditions for scanning are met.
  ///
  /// This method performs a series of checks in order:
  /// 1. **BLE Support**: Verifies the device hardware supports BLE
  /// 2. **Adapter Availability**: Checks Bluetooth is not restricted
  /// 3. **Permissions**: Verifies all required permissions are granted
  /// 4. **Adapter State**: Ensures Bluetooth is turned on
  ///
  /// If any check fails, an appropriate error message is shown via snackbar.
  ///
  /// Returns `true` if all preconditions pass and scanning can proceed.
  static Future<bool> _ensureScanPreconditions(
    final BuildContext context,
  ) async {
    try {
      // Check BLE support
      if (!await FlutterBluePlus.isSupported) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showErrorSnackBar(
            context,
            'This device does not support Bluetooth Low Energy',
          );
        });

        return false;
      }

      // Check Bluetooth availability
      try {
        final BluetoothAdapterState adapterState =
            await FlutterBluePlus.adapterState.first;

        if (adapterState == BluetoothAdapterState.unavailable) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showErrorSnackBar(
              context,
              'Bluetooth is not available. Check if airplane mode is enabled or Bluetooth is restricted.',
            );
          });

          return false;
        }
      } catch (e) {
        debugPrint('Error checking Bluetooth availability: $e');

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showErrorSnackBar(
            context,
            'Error checking Bluetooth availability: $e',
          );
        });

        return false;
      }

      // Check permissions
      if (!await _checkPermissions(context)) {
        return false;
      }

      // Ensure adapter is ON
      if (!await _ensureAdapterOn(context)) {
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Error checking scan preconditions: $e');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorSnackBar(context, 'Error checking permissions: $e');
      });

      return false;
    }
  }

  /// Checks that all required Bluetooth permissions are granted.
  ///
  /// Platform-specific permission requirements:
  ///
  /// ### Android 12+ (API 31+)
  /// - `BLUETOOTH_SCAN`: Required for discovering nearby devices
  /// - `BLUETOOTH_CONNECT`: Required for connecting to devices
  ///
  /// ### Android 11 and below
  /// - `BLUETOOTH`: Basic Bluetooth access
  /// - `ACCESS_FINE_LOCATION`: Required for BLE scanning
  ///
  /// ### iOS
  /// - `bluetooth`: Core Bluetooth permission
  ///
  /// Returns `true` if all required permissions are granted.
  static Future<bool> _checkPermissions(final BuildContext context) async {
    if (Platform.isAndroid) {
      final int androidVersion = await _getAndroidVersion();

      debugPrint('Checking Android $androidVersion permissions...');

      if (androidVersion >= 31) {
        // Android 12+ permissions
        final PermissionStatus scanStatus =
            await Permission.bluetoothScan.status;

        final PermissionStatus connectStatus =
            await Permission.bluetoothConnect.status;

        debugPrint(
          'Permission statuses - Scan: $scanStatus, Connect: $connectStatus, ',
        );

        if (!scanStatus.isGranted || !connectStatus.isGranted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showPermissionError(context, scanStatus, connectStatus);
          });

          return false;
        }
      } else {
        // Legacy Android permissions
        final PermissionStatus bluetoothStatus =
            await Permission.bluetooth.status;
        final PermissionStatus locationStatus =
            await Permission.location.status;

        debugPrint(
          'Permission statuses - Bluetooth: $bluetoothStatus, Location: $locationStatus',
        );

        if (!bluetoothStatus.isGranted || !locationStatus.isGranted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showErrorSnackBar(
              context,
              'Bluetooth and Location permissions are required',
            );
          });

          return false;
        }
      }
    } else if (Platform.isIOS) {
      final PermissionStatus bluetoothStatus =
          await Permission.bluetooth.status;

      debugPrint('iOS Bluetooth permission status: $bluetoothStatus');

      if (!bluetoothStatus.isGranted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showErrorSnackBar(context, 'Bluetooth permission is required');
        });

        return false;
      }
    }

    return true;
  }

  /// Ensures the Bluetooth adapter is turned on and ready.
  ///
  /// On Android, this method will attempt to programmatically turn on
  /// Bluetooth if it's currently off. On iOS, the user must manually
  /// enable Bluetooth in Settings.
  ///
  /// After attempting to turn on Bluetooth, the method waits for
  /// [_adapterTurnOnDelaySeconds] to allow the adapter to initialize.
  ///
  /// Returns `true` if the adapter is on after the check/attempt.
  static Future<bool> _ensureAdapterOn(final BuildContext context) async {
    final BluetoothAdapterState current =
        await FlutterBluePlus.adapterState.first;

    debugPrint('Current Bluetooth adapter state: $current');

    if (current != BluetoothAdapterState.on) {
      debugPrint('Bluetooth adapter is not ON, attempting to turn on...');

      if (Platform.isAndroid) {
        try {
          await FlutterBluePlus.turnOn();
          await Future.delayed(
            const Duration(seconds: _adapterTurnOnDelaySeconds),
          );

          debugPrint('Bluetooth turn on command sent');
        } catch (e) {
          debugPrint('Error turning on Bluetooth: $e');
        }
      }

      // Check again after attempting to turn on
      final BluetoothAdapterState newState =
          await FlutterBluePlus.adapterState.first;

      debugPrint('Bluetooth adapter state after turn on attempt: $newState');

      if (newState != BluetoothAdapterState.on) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showErrorSnackBar(
            context,
            'Please turn on Bluetooth to scan for devices',
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => openAppSettings(),
            ),
          );
        });

        return false;
      }
    } else {
      debugPrint('Bluetooth adapter is already ON');
    }

    return true;
  }

  /// Gets the Android SDK version for determining permission requirements.
  ///
  /// Uses a MethodChannel to query the actual device SDK version.
  /// Returns 31 (Android 12) as the default if detection fails, which
  /// ensures the more restrictive permission model is used.
  ///
  /// For non-Android platforms, returns 100 to skip Android-specific checks.
  static Future<int> _getAndroidVersion() async {
    try {
      if (Platform.isAndroid) {
        // Use MethodChannel to get the Android SDK version if DeviceInfoPlugin is not available
        const MethodChannel channel = MethodChannel('bluetooth_scan_utils');
        final int? sdkInt = await channel.invokeMethod<int>('getAndroidSdkInt');

        return sdkInt ?? 31;
      } else {
        // Not Android, so the concept doesn't apply, return a high value
        return 100;
      }
    } catch (e) {
      debugPrint('Error getting Android version: $e');
      return 31; // Default to Android 12+ (API 31)
    }
  }

  /// Shows a detailed error message for missing Bluetooth permissions.
  ///
  /// Lists each missing permission specifically and provides an action
  /// button to request permissions via [PermissionService].
  ///
  /// Parameters:
  /// - [context]: BuildContext for showing the snackbar
  /// - [scanStatus]: Current status of BLUETOOTH_SCAN permission
  /// - [connectStatus]: Current status of BLUETOOTH_CONNECT permission
  static void _showPermissionError(
    final BuildContext context,
    final PermissionStatus scanStatus,
    final PermissionStatus connectStatus,
  ) {
    String permissionMessage = 'Required permissions:\n';

    if (!scanStatus.isGranted) permissionMessage += '• Bluetooth Scan\n';
    if (!connectStatus.isGranted) permissionMessage += '• Bluetooth Connect\n';

    _showErrorSnackBar(
      context,
      permissionMessage,
      action: SnackBarAction(
        label: 'Grant',
        onPressed: () => PermissionService.requestRequiredPermissions(),
      ),
    );
  }

  /// Shows an error message in a snackbar with an optional action button.
  ///
  /// Implements a debounce mechanism via [_isShowingSnackbar] to prevent
  /// multiple snackbars from stacking when errors occur rapidly.
  ///
  /// Parameters:
  /// - [context]: BuildContext for showing the snackbar
  /// - [message]: Error message to display
  /// - [action]: Optional action button (e.g., "Settings", "Grant")
  static void _showErrorSnackBar(
    final BuildContext context,
    final String message, {
    final SnackBarAction? action,
  }) {
    if (_isShowingSnackbar) return; // Prevent multiple snackbars

    _isShowingSnackbar = true;

    ScaffoldMessenger.of(context)
        .showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 5),
            action: action,
          ),
        )
        .closed
        .then((_) {
          _isShowingSnackbar = false; // Reset flag when snackbar closes
        });
  }

  /// Shows a context-aware error message based on the error type.
  ///
  /// Parses the error message to provide specific, actionable feedback:
  ///
  /// | Error Contains | Message Shown |
  /// |----------------|---------------|
  /// | "permission" | Permission request guidance |
  /// | "bluetooth" | Enable Bluetooth prompt |
  /// | "location" | Location permission needed |
  /// | "timeout" | Retry suggestion |
  /// | "not supported" | BLE not available |
  /// | "already scanning" | Scan in progress |
  /// | "unavailable" | Check airplane mode |
  /// | "turning on/off" | Wait and retry |
  /// | "denied" | Settings redirect |
  /// | "restricted" | Check device settings |
  ///
  /// All errors include a "Settings" action button to open app settings.
  static void _showScanError(final BuildContext context, final dynamic error) {
    String errorMessage = 'Failed to start scan: $error';

    if (error.toString().contains('permission')) {
      errorMessage =
          'Bluetooth permissions are required. Please grant all permissions in Settings.';
    } else if (error.toString().contains('bluetooth')) {
      errorMessage = 'Bluetooth is not available. Please turn on Bluetooth.';
    } else if (error.toString().contains('location')) {
      errorMessage = 'Location permission is required for Bluetooth scanning.';
    } else if (error.toString().contains('timeout')) {
      errorMessage = 'Scan timed out. Please try again.';
    } else if (error.toString().contains('not supported')) {
      errorMessage = 'This device does not support Bluetooth Low Energy.';
    } else if (error.toString().contains('already scanning')) {
      errorMessage = 'Scan is already in progress.';
    } else if (error.toString().contains('unavailable')) {
      errorMessage =
          'Bluetooth is unavailable. Check airplane mode and Bluetooth restrictions.';
    } else if (error.toString().contains('turning on')) {
      errorMessage = 'Bluetooth is turning on. Please wait and try again.';
    } else if (error.toString().contains('turning off')) {
      errorMessage = 'Bluetooth is turning off. Please wait and try again.';
    } else if (error.toString().contains('denied')) {
      errorMessage = 'Permission denied. Please grant permissions in Settings.';
    } else if (error.toString().contains('restricted')) {
      errorMessage = 'Bluetooth access is restricted. Check device settings.';
    }

    _showErrorSnackBar(
      context,
      errorMessage,
      action: SnackBarAction(
        label: 'Settings',
        onPressed: () => openAppSettings(),
      ),
    );
  }
}
