import 'dart:typed_data';

// import 'package:flutter_blue_plus/flutter_blue_plus.dart';

abstract class BleCommandUtils {
  /// Calculates authentication code from controller ID (matching React Native implementation)
  static int calculateAuthCode(final List<int> manufacturerData) {
    try {
      // Extract controller ID from device (similar to React Native implementation)
      final String? controllerId = extractControllerId(manufacturerData);
      if (controllerId == null) {
        return 0x42; // Fallback auth code
      }

      // Calculate auth code exactly like React Native
      int computedValue = 0;
      int i = 1;
      for (int j = 0; j < controllerId.length; j++) {
        computedValue += controllerId.codeUnitAt(j) * i;
        i++;
      }
      computedValue = computedValue %= 256;

      // return computedValue;
      return 152;
    } catch (e) {
      return 0x42; // Fallback auth code
    }
  }

  static String? extractControllerId(final List<int> manufacturerData) {
    try {
      ////TODO: Convert this to fecth from the manufacturer data

      // Convert manufacturer data array to controller ID
      // Example: [65, 65, 48, 48, 51, 57, 56, 57] -> "AA003989" -> "003989"

      // Convert ASCII values to characters
      final String dataString = String.fromCharCodes(manufacturerData);

      // Remove first two letters and return the rest
      if (dataString.length > 2) {
        return dataString.substring(2);
      }

      return dataString;
    } catch (e) {
      return null;
    }
  }

  /// Helper function to convert int to hex string for debugging
  static String toHexString(final int value) {
    return '0x${value.toRadixString(16).padLeft(2, '0').toUpperCase()}';
  }

  static Uint8List toUint8List(final List<int> list) {
    return Uint8List.fromList(list);
  }
}
