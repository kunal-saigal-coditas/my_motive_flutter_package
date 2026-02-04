import 'dart:typed_data';

/// Mapper for creating BLE therapy commands from high-level parameters.
///
/// This class generates properly formatted byte arrays that can be written
/// to the command characteristic to control the Motive therapy device.
///
/// ## Command Format
///
/// All commands follow a similar structure:
/// - Byte 0: Command opcode
/// - Byte 1: Authentication code
/// - Bytes 2+: Command-specific parameters
///
/// ## Opcodes
///
/// | Opcode | Command |
/// |--------|---------|
/// | 0x10 | Start treatment |
/// | 0x11 | Change stimulation level |
/// | 0x12 | Exit adjustment mode |
/// | 0x13 | Pause treatment |
/// | 0x14 | Resume treatment |
/// | 0x15 | Zero both stimulation levels |
/// | 0x30 | Stop treatment |
///
/// ## Example
///
/// ```dart
/// // Create a start treatment command
/// final authCode = bleService.authCode ?? 0x42;
/// final command = TherapyCommandMapper.createStartTreatmentCommand(
///   authCode,
///   1800, // 30 minutes in seconds
/// );
///
/// // Write to the device
/// await bleService.controllerCommandCharacteristic?.write(command);
/// ```
///
/// See also:
/// - [MotiveBleService] for obtaining auth code and characteristics
/// - [BleCommand] for command model representations
class TherapyCommandMapper {
  // ─────────────────────────────────────────────────────────────────────────
  // COMMAND TEMPLATES
  // ─────────────────────────────────────────────────────────────────────────

  /// Start treatment command template.
  ///
  /// Format: [opcode, AUTH_PLACEHOLDER, 0x00, durationLow, durationHigh]
  /// - 0x10: Start treatment opcode
  /// - 0xFF: Auth code placeholder (replaced at runtime)
  /// - 0x00: Reserved
  /// - 0x08, 0x07: Default duration (1800 seconds = 30 minutes)
  static const List<int> _startTreatmentTemplate = <int>[
    0x10,
    0xFF,
    0x00,
    0x08,
    0x07,
  ];

  /// Change stimulation level command template.
  ///
  /// Format: [opcode, AUTH_PLACEHOLDER, kneeDelta, thighDelta]
  static const List<int> _changeLevelTemplate = <int>[0x11, 0xFF, 0x00, 0x00];

  /// Exit adjustment mode command template.
  static const List<int> _exitAdjustTemplate = <int>[0x12, 0xFF];

  /// Pause treatment command template.
  static const List<int> _pauseTreatmentTemplate = <int>[0x13, 0xFF];

  /// Resume treatment command template.
  static const List<int> _resumeTreatmentTemplate = <int>[0x14, 0xFF];

  /// Zero both stimulation levels command template.
  static const List<int> _zeroBothStimLevelsTemplate = <int>[0x15, 0xFF];

  /// Stop treatment command template.
  static const List<int> _stopTemplate = <int>[0x30, 0xFF];

  // ─────────────────────────────────────────────────────────────────────────
  // COMMAND BUILDERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Creates a start treatment command with authentication and duration.
  ///
  /// The duration is encoded as a 16-bit little-endian value:
  /// - Byte 3: Lower 8 bits (durationSeconds % 256)
  /// - Byte 4: Upper 8 bits (durationSeconds ~/ 256)
  ///
  /// Example: 1800 seconds (30 min) → bytes [0x08, 0x07] because:
  /// (7 × 256) + 8 = 1800
  ///
  /// Parameters:
  /// - [authCode]: Device authentication code from manufacturer data
  /// - [durationSeconds]: Treatment duration in seconds (max 65535)
  ///
  /// Returns a [Uint8List] ready to write to the command characteristic.
  static Uint8List createStartTreatmentCommand(
    final int authCode,
    final int durationSeconds,
  ) {
    final List<int> command = List<int>.from(_startTreatmentTemplate);
    command[1] = authCode;
    command[3] = durationSeconds % 256; // lower 8 bits
    command[4] = durationSeconds ~/ 256; // upper 8 bits
    return Uint8List.fromList(command);
  }

  /// Creates a change stimulation level command.
  ///
  /// Adjusts the stimulation intensity for knee and thigh channels.
  /// Positive values increase intensity, negative values decrease it.
  ///
  /// Parameters:
  /// - [authCode]: Device authentication code
  /// - [kneeDelta]: Change in knee stimulation (-100 to +100)
  /// - [thighDelta]: Change in thigh stimulation (-100 to +100)
  ///
  /// Returns a [Uint8List] ready to write to the command characteristic.
  static Uint8List createChangeLevelCommand(
    final int authCode,
    final int kneeDelta,
    final int thighDelta,
  ) {
    final List<int> command = List<int>.from(_changeLevelTemplate);

    command[1] = authCode;
    command[2] = kneeDelta;
    command[3] = thighDelta;

    return Uint8List.fromList(command);
  }

  /// Creates an exit adjustment mode command.
  ///
  /// Exits the stimulation level adjustment mode and locks in the
  /// current levels for the remainder of the treatment.
  static Uint8List createExitAdjustCommand(final int authCode) {
    return _createSimpleCommand(_exitAdjustTemplate, authCode);
  }

  /// Creates a pause treatment command.
  ///
  /// Temporarily pauses the current therapy session. Stimulation stops
  /// but the session timer and levels are preserved.
  static Uint8List createPauseTreatmentCommand(final int authCode) {
    return _createSimpleCommand(_pauseTreatmentTemplate, authCode);
  }

  /// Creates a resume treatment command.
  ///
  /// Resumes a paused therapy session, restoring previous stimulation
  /// levels and continuing the session timer.
  static Uint8List createResumeTreatmentCommand(final int authCode) {
    return _createSimpleCommand(_resumeTreatmentTemplate, authCode);
  }

  /// Creates a command to zero both stimulation levels.
  ///
  /// Sets both knee and thigh stimulation to zero intensity.
  /// The treatment session continues but no stimulation is delivered.
  static Uint8List createZeroBothStimLevelsCommand(final int authCode) {
    return _createSimpleCommand(_zeroBothStimLevelsTemplate, authCode);
  }

  /// Creates a stop treatment command.
  ///
  /// Immediately stops the current therapy session. Unlike pause,
  /// a stopped session cannot be resumed and must be restarted.
  static Uint8List createStopCommand(final int authCode) {
    return _createSimpleCommand(_stopTemplate, authCode);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Creates a command from a template by replacing the auth placeholder.
  ///
  /// Scans the template for 0xFF bytes and replaces them with the
  /// provided authentication code.
  static Uint8List _createSimpleCommand(
    final List<int> template,
    final int authCode,
  ) {
    final List<int> command = List<int>.from(template);

    for (int i = 0; i < command.length; i++) {
      if (command[i] == 0xFF) {
        command[i] = authCode;
      }
    }

    return Uint8List.fromList(command);
  }

  /// Converts a list of integers to a [Uint8List].
  ///
  /// Utility method for converting command data to the format
  /// required by BLE write operations.
  static Uint8List toUint8List(final List<int> data) {
    return Uint8List.fromList(data);
  }
}
