import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:my_motive_package/mappers/therapy_command_mapper.dart';
import 'package:my_motive_package/services/motive_ble_service.dart';

/// Simplified API for creating and sending therapy commands.
///
/// This class provides an easy-to-use interface for BLE therapy control
/// without needing to understand byte formats or manage characteristics directly.
///
/// ## Usage
///
/// ```dart
/// // Create instance from BLE service (recommended)
/// final commands = TherapyCommands.fromService(bleService);
///
/// // Send commands directly
/// await commands.sendStart(minutes: 30);
/// await commands.sendChangeLevel(knee: 10, thigh: 5);
/// await commands.sendPause();
/// await commands.sendResume();
/// await commands.sendStop();
///
/// // Or get command bytes to send yourself
/// final bytes = commands.start(minutes: 30);
/// await characteristic.write(bytes);
/// ```
///
/// ## Available Commands
///
/// | Send Method | Bytes Method | Description |
/// |-------------|--------------|-------------|
/// | `sendStart()` | `start()` | Start therapy session |
/// | `sendStop()` | `stop()` | Stop therapy completely |
/// | `sendPause()` | `pause()` | Pause therapy (can resume) |
/// | `sendResume()` | `resume()` | Resume paused therapy |
/// | `sendChangeLevel()` | `changeLevel()` | Adjust stimulation |
/// | `sendZeroLevels()` | `zeroLevels()` | Set both to zero |
class TherapyCommands {
  /// Authentication code for the connected device.
  final int authCode;

  /// BLE characteristic for writing commands.
  final BluetoothCharacteristic? _characteristic;

  /// Creates a new [TherapyCommands] instance with explicit parameters.
  ///
  /// Prefer using [TherapyCommands.fromService] instead.
  ///
  /// Parameters:
  /// - [authCode]: Device authentication code
  /// - [characteristic]: Command characteristic for sending
  ///
  /// If [characteristic] is null, only the bytes methods will work.
  const TherapyCommands({
    required this.authCode,
    BluetoothCharacteristic? characteristic,
  }) : _characteristic = characteristic;

  /// Creates [TherapyCommands] from a [MotiveBleService] instance.
  ///
  /// This is the recommended way to create a TherapyCommands instance.
  /// It automatically extracts the auth code and command characteristic.
  ///
  /// Example:
  /// ```dart
  /// final commands = TherapyCommands.fromService(bleService);
  /// await commands.sendStart(minutes: 30);
  /// ```
  ///
  /// Throws [StateError] if the device is not connected (authCode is null).
  factory TherapyCommands.fromService(MotiveBleService service) {
    final authCode = service.authCode;
    if (authCode == null) {
      throw StateError(
        'Cannot create TherapyCommands: device not connected. '
        'Connect to a device first using MotiveBleService.initBLEService().',
      );
    }
    return TherapyCommands(
      authCode: authCode,
      characteristic: service.controllerCommandCharacteristic,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SEND METHODS (async, sends to device)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Sends a start therapy command to the device.
  ///
  /// Specify duration using ONE of:
  /// - [minutes]: Duration in minutes (e.g., 30 for 30-minute session)
  /// - [seconds]: Duration in seconds (e.g., 1800 for 30-minute session)
  ///
  /// Default is 30 minutes if neither is specified.
  ///
  /// Example:
  /// ```dart
  /// await commands.sendStart(minutes: 30);
  /// await commands.sendStart(minutes: 45);
  /// ```
  Future<void> sendStart({int? minutes, int? seconds}) async {
    await _writeCommand(start(minutes: minutes, seconds: seconds));
  }

  /// Sends a stop therapy command to the device.
  ///
  /// This immediately ends the session. Unlike pause, a stopped
  /// session cannot be resumed.
  ///
  /// Example:
  /// ```dart
  /// await commands.sendStop();
  /// ```
  Future<void> sendStop() async {
    await _writeCommand(stop());
  }

  /// Sends a pause therapy command to the device.
  ///
  /// Temporarily suspends stimulation while preserving the session.
  ///
  /// Example:
  /// ```dart
  /// await commands.sendPause();
  /// ```
  Future<void> sendPause() async {
    await _writeCommand(pause());
  }

  /// Sends a resume therapy command to the device.
  ///
  /// Continues a previously paused session.
  ///
  /// Example:
  /// ```dart
  /// await commands.sendResume();
  /// ```
  Future<void> sendResume() async {
    await _writeCommand(resume());
  }

  /// Sends a change stimulation level command to the device.
  ///
  /// Parameters:
  /// - [knee]: Change for knee/left channel (-100 to +100)
  /// - [thigh]: Change for thigh/right channel (-100 to +100)
  ///
  /// Example:
  /// ```dart
  /// await commands.sendChangeLevel(knee: 10, thigh: 5);
  /// await commands.sendChangeLevel(knee: -5, thigh: 0);
  /// ```
  Future<void> sendChangeLevel({required int knee, required int thigh}) async {
    await _writeCommand(changeLevel(knee: knee, thigh: thigh));
  }

  /// Sends a command to set both stimulation levels to zero.
  ///
  /// Example:
  /// ```dart
  /// await commands.sendZeroLevels();
  /// ```
  Future<void> sendZeroLevels() async {
    await _writeCommand(zeroLevels());
  }

  /// Sends a command to exit adjustment mode.
  ///
  /// Example:
  /// ```dart
  /// await commands.sendExitAdjust();
  /// ```
  Future<void> sendExitAdjust() async {
    await _writeCommand(exitAdjust());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BYTES METHODS (returns command bytes)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Creates a start therapy command.
  ///
  /// Specify duration using ONE of:
  /// - [minutes]: Duration in minutes
  /// - [seconds]: Duration in seconds
  ///
  /// Default is 30 minutes if neither is specified.
  List<int> start({int? minutes, int? seconds}) {
    final int durationSeconds = minutes != null
        ? minutes * 60
        : (seconds ?? 1800);
    return TherapyCommandMapper.createStartTreatmentCommand(
      authCode,
      durationSeconds,
    ).toList();
  }

  /// Creates a stop therapy command.
  List<int> stop() {
    return TherapyCommandMapper.createStopCommand(authCode).toList();
  }

  /// Creates a pause therapy command.
  List<int> pause() {
    return TherapyCommandMapper.createPauseTreatmentCommand(authCode).toList();
  }

  /// Creates a resume therapy command.
  List<int> resume() {
    return TherapyCommandMapper.createResumeTreatmentCommand(authCode).toList();
  }

  /// Creates a change stimulation level command.
  ///
  /// Parameters:
  /// - [knee]: Change for knee/left channel (-100 to +100)
  /// - [thigh]: Change for thigh/right channel (-100 to +100)
  List<int> changeLevel({required int knee, required int thigh}) {
    return TherapyCommandMapper.createChangeLevelCommand(
      authCode,
      knee,
      thigh,
    ).toList();
  }

  /// Creates a command to set both stimulation levels to zero.
  List<int> zeroLevels() {
    return TherapyCommandMapper.createZeroBothStimLevelsCommand(
      authCode,
    ).toList();
  }

  /// Creates a command to exit adjustment mode.
  List<int> exitAdjust() {
    return TherapyCommandMapper.createExitAdjustCommand(authCode).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RAW ACCESS (returns Uint8List)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Creates a start command as Uint8List.
  Uint8List startRaw({int? minutes, int? seconds}) {
    final int durationSeconds = minutes != null
        ? minutes * 60
        : (seconds ?? 1800);
    return TherapyCommandMapper.createStartTreatmentCommand(
      authCode,
      durationSeconds,
    );
  }

  /// Creates a stop command as Uint8List.
  Uint8List stopRaw() => TherapyCommandMapper.createStopCommand(authCode);

  /// Creates a pause command as Uint8List.
  Uint8List pauseRaw() =>
      TherapyCommandMapper.createPauseTreatmentCommand(authCode);

  /// Creates a resume command as Uint8List.
  Uint8List resumeRaw() =>
      TherapyCommandMapper.createResumeTreatmentCommand(authCode);

  /// Creates a change level command as Uint8List.
  Uint8List changeLevelRaw({int knee = 0, int thigh = 0}) {
    return TherapyCommandMapper.createChangeLevelCommand(authCode, knee, thigh);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _writeCommand(List<int> command) async {
    if (_characteristic == null) {
      throw StateError(
        'Cannot send command: characteristic not set. '
        'Create TherapyCommands with a characteristic parameter.',
      );
    }
    await _characteristic.write(command);
  }
}
