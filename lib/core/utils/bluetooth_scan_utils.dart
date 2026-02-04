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
/// // Stop scanning manually if needed
/// await BluetoothScanUtils.stopScan();
/// ```
///
/// See also:
/// - [PermissionService] for permission management
/// - [DeviceHelpers] for filtering scan results
class BluetoothScanUtils {
  /// Default scan timeout in seconds.
  static const int _scanTimeoutSeconds = 30;

  /// Delay after attempting to turn on Bluetooth adapter.
  static const int _adapterTurnOnDelaySeconds = 2;

  /// Flag to prevent multiple error snackbars from showing simultaneously.
  static bool _isShowingSnackbar = false;

  /// Starts a BLE scan with full error handling and precondition checks.
  ///
  /// This method performs the following:
  /// 1. Verifies BLE support on the device
  /// 2. Checks and requests required permissions
  /// 3. Ensures Bluetooth adapter is enabled
  /// 4. Starts the scan with a 30-second timeout
  ///
  /// Parameters:
  /// - [context]: BuildContext for showing error snackbars
  /// - [onScanStarted]: Called when scan successfully begins
  /// - [onScanCompleted]: Called when scan finishes or times out
  /// - [onScanError]: Called if scan cannot be started
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
        androidUsesFineLocation: true,
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
  /// Safe to call even if no scan is in progress.
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
  /// Checks:
  /// 1. BLE hardware support
  /// 2. Bluetooth adapter availability
  /// 3. Required permissions (platform-specific)
  /// 4. Bluetooth adapter is turned on
  ///
  /// Returns `true` if all preconditions pass, `false` otherwise.
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

  /// Checks that all required permissions are granted.
  ///
  /// Platform-specific requirements:
  /// - Android 12+: bluetoothScan, bluetoothConnect, location
  /// - Android 11-: bluetooth, location
  /// - iOS: bluetooth
  ///
  /// Returns `true` if all permissions are granted.
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

        final PermissionStatus locationStatus =
            await Permission.location.status;

        debugPrint(
          'Permission statuses - Scan: $scanStatus, Connect: $connectStatus, Location: $locationStatus',
        );

        if (!scanStatus.isGranted ||
            !connectStatus.isGranted ||
            !locationStatus.isGranted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showPermissionError(
              context,
              scanStatus,
              connectStatus,
              locationStatus,
            );
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

  /// Ensures the Bluetooth adapter is turned on.
  ///
  /// On Android, attempts to programmatically turn on Bluetooth if off.
  /// On iOS, prompts the user to enable Bluetooth in settings.
  ///
  /// Returns `true` if adapter is on after the check.
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

  /// Gets the Android SDK version for permission handling.
  ///
  /// Uses a method channel to query the actual SDK version.
  /// Returns 31 (Android 12) as default if detection fails.
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

  /// Shows a detailed error message for missing permissions.
  ///
  /// Lists each missing permission and provides a button to
  /// request them via [PermissionService].
  static void _showPermissionError(
    final BuildContext context,
    final PermissionStatus scanStatus,
    final PermissionStatus connectStatus,
    final PermissionStatus locationStatus,
  ) {
    String permissionMessage = 'Required permissions:\n';

    if (!scanStatus.isGranted) permissionMessage += '• Bluetooth Scan\n';
    if (!connectStatus.isGranted) permissionMessage += '• Bluetooth Connect\n';
    if (!locationStatus.isGranted) permissionMessage += '• Location\n';

    _showErrorSnackBar(
      context,
      permissionMessage,
      action: SnackBarAction(
        label: 'Grant',
        onPressed: () => PermissionService.requestRequiredPermissions(),
      ),
    );
  }

  /// Shows an error snackbar with an optional action button.
  ///
  /// Prevents multiple snackbars from displaying simultaneously
  /// using the [_isShowingSnackbar] flag.
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

  /// Shows a context-aware error message for scan failures.
  ///
  /// Parses the error to provide specific, actionable messages
  /// for common issues like permissions, Bluetooth state, etc.
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
