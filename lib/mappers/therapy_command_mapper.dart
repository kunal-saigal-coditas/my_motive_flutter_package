import 'dart:typed_data';

/// Mapper for creating BLE therapy commands.
/// Centralizes BLE command byte manipulation that was previously in the presentation layer.
class TherapyCommandMapper {
  // ─────────────────────────────────────────────────────────────────────────
  // COMMAND TEMPLATES
  // ─────────────────────────────────────────────────────────────────────────

  /// Start treatment command template: [0x10, AUTH, 0x00, durationLow, durationHigh]
  static const List<int> _startTreatmentTemplate = <int>[
    0x10,
    0xFF,
    0x00,
    0x08,
    0x07,
  ];

  /// Change level command template: [0x11, AUTH, kneeDelta, thighDelta]
  static const List<int> _changeLevelTemplate = <int>[
    0x11,
    0xFF,
    0x00,
    0x00,
  ];

  /// Exit adjust command template: [0x12, AUTH]
  static const List<int> _exitAdjustTemplate = <int>[0x12, 0xFF];

  /// Pause treatment command template: [0x13, AUTH]
  static const List<int> _pauseTreatmentTemplate = <int>[0x13, 0xFF];

  /// Resume treatment command template: [0x14, AUTH]
  static const List<int> _resumeTreatmentTemplate = <int>[0x14, 0xFF];

  /// Zero both stim levels command template: [0x15, AUTH]
  static const List<int> _zeroBothStimLevelsTemplate = <int>[0x15, 0xFF];

  /// Stop command template: [0x30, AUTH]
  static const List<int> _stopTemplate = <int>[0x30, 0xFF];

  // ─────────────────────────────────────────────────────────────────────────
  // COMMAND BUILDERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Create start treatment command with auth code and duration.
  ///
  /// Duration is split into two 8-bit bytes (little-endian).
  /// Example: 1800 seconds → [0x08, 0x07] because (7 * 256) + 8 = 1800
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

  /// Create change level command with auth code and level deltas.
  ///
  /// [kneeDelta] - Change in knee stimulation level
  /// [thighDelta] - Change in thigh stimulation level
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

  /// Create exit adjust command with auth code
  static Uint8List createExitAdjustCommand(final int authCode) {
    return _createSimpleCommand(_exitAdjustTemplate, authCode);
  }

  /// Create pause treatment command with auth code
  static Uint8List createPauseTreatmentCommand(final int authCode) {
    return _createSimpleCommand(_pauseTreatmentTemplate, authCode);
  }

  /// Create resume treatment command with auth code
  static Uint8List createResumeTreatmentCommand(final int authCode) {
    return _createSimpleCommand(_resumeTreatmentTemplate, authCode);
  }

  /// Create zero both stim levels command with auth code
  static Uint8List createZeroBothStimLevelsCommand(final int authCode) {
    return _createSimpleCommand(_zeroBothStimLevelsTemplate, authCode);
  }

  /// Create stop command with auth code
  static Uint8List createStopCommand(final int authCode) {
    return _createSimpleCommand(_stopTemplate, authCode);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Create a simple command by replacing 0xFF placeholder with auth code
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

  /// Convert a list of ints to Uint8List
  static Uint8List toUint8List(final List<int> data) {
    return Uint8List.fromList(data);
  }
}
