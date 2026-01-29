import 'dart:typed_data';

/// Creates BLE therapy commands for the Motive device
class TherapyCommands {
  // Command templates
  static const List<int> _startTreatmentTemplate = [0x10, 0xFF, 0x00, 0x08, 0x07];
  static const List<int> _changeLevelTemplate = [0x11, 0xFF, 0x00, 0x00];
  static const List<int> _exitAdjustTemplate = [0x12, 0xFF];
  static const List<int> _pauseTreatmentTemplate = [0x13, 0xFF];
  static const List<int> _resumeTreatmentTemplate = [0x14, 0xFF];
  static const List<int> _zeroBothStimLevelsTemplate = [0x15, 0xFF];
  static const List<int> _stopTemplate = [0x30, 0xFF];

  /// Create start treatment command
  static Uint8List createStartTreatmentCommand(int authCode, int durationSeconds) {
    final command = List<int>.from(_startTreatmentTemplate);
    command[1] = authCode;
    command[3] = durationSeconds % 256;
    command[4] = durationSeconds ~/ 256;
    return Uint8List.fromList(command);
  }

  /// Create change level command
  static Uint8List createChangeLevelCommand(int authCode, int kneeDelta, int thighDelta) {
    final command = List<int>.from(_changeLevelTemplate);
    command[1] = authCode;
    command[2] = kneeDelta;
    command[3] = thighDelta;
    return Uint8List.fromList(command);
  }

  /// Create exit adjust command
  static Uint8List createExitAdjustCommand(int authCode) {
    return _createSimpleCommand(_exitAdjustTemplate, authCode);
  }

  /// Create pause treatment command
  static Uint8List createPauseTreatmentCommand(int authCode) {
    return _createSimpleCommand(_pauseTreatmentTemplate, authCode);
  }

  /// Create resume treatment command
  static Uint8List createResumeTreatmentCommand(int authCode) {
    return _createSimpleCommand(_resumeTreatmentTemplate, authCode);
  }

  /// Create zero both stim levels command
  static Uint8List createZeroBothStimLevelsCommand(int authCode) {
    return _createSimpleCommand(_zeroBothStimLevelsTemplate, authCode);
  }

  /// Create stop command
  static Uint8List createStopCommand(int authCode) {
    return _createSimpleCommand(_stopTemplate, authCode);
  }

  static Uint8List _createSimpleCommand(List<int> template, int authCode) {
    final command = List<int>.from(template);
    for (int i = 0; i < command.length; i++) {
      if (command[i] == 0xFF) {
        command[i] = authCode;
      }
    }
    return Uint8List.fromList(command);
  }
}

/// Utility functions for BLE command operations
class BleCommandUtils {
  /// Calculate authentication code from manufacturer data
  static int calculateAuthCode(List<int> manufacturerData) {
    try {
      final controllerId = extractControllerId(manufacturerData);
      if (controllerId == null) return 0x42;

      int computedValue = 0;
      int i = 1;
      for (int j = 0; j < controllerId.length; j++) {
        computedValue += controllerId.codeUnitAt(j) * i;
        i++;
      }
      return computedValue % 256;
    } catch (e) {
      return 0x42;
    }
  }

  /// Extract controller ID from manufacturer data
  static String? extractControllerId(List<int> manufacturerData) {
    try {
      final dataString = String.fromCharCodes(manufacturerData);
      if (dataString.length > 2) {
        return dataString.substring(2);
      }
      return dataString;
    } catch (e) {
      return null;
    }
  }

  /// Convert int to hex string for debugging
  static String toHexString(int value) {
    return '0x${value.toRadixString(16).padLeft(2, '0').toUpperCase()}';
  }
}
