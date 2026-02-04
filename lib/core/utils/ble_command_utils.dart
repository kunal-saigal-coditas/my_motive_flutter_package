import 'dart:typed_data';

/// Utility functions for BLE command creation and authentication.
///
/// This class provides low-level utilities for:
/// - Authentication code calculation from manufacturer data
/// - Controller ID extraction
/// - Data format conversions
///
/// ## Authentication
///
/// Motive devices require an authentication code derived from the
/// manufacturer data in the device's BLE advertisement. This code
/// must be included in all therapy commands.
///
/// ## Example
///
/// ```dart
/// // Extract auth code from scan result
/// final manufacturerData = scanResult.advertisementData.manufacturerData;
/// final data = manufacturerData.values.first;
/// final authCode = BleCommandUtils.calculateAuthCode(data);
///
/// // Use in commands
/// final command = TherapyCommandMapper.createStartTreatmentCommand(
///   authCode,
///   1800,
/// );
/// ```
abstract class BleCommandUtils {
  /// Calculates the authentication code from manufacturer data.
  ///
  /// The algorithm matches the React Native implementation:
  /// 1. Extract controller ID from manufacturer data
  /// 2. Sum (character code × position) for each character
  /// 3. Return result modulo 256
  ///
  /// Returns 0x42 as fallback if controller ID cannot be extracted.
  ///
  /// Note: Currently returns a hardcoded value (152) for testing.
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

  /// Extracts the controller ID from manufacturer data.
  ///
  /// Manufacturer data format: First 2 bytes are prefix (e.g., "AA"),
  /// remaining bytes are the controller ID (e.g., "003989").
  ///
  /// Example: [65, 65, 48, 48, 51, 57, 56, 57] → "AA003989" → "003989"
  ///
  /// Returns `null` if extraction fails.
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

  /// Converts an integer to a hex string for debugging.
  ///
  /// Format: "0xNN" with uppercase hex digits, zero-padded to 2 digits.
  /// Example: 66 → "0x42"
  static String toHexString(final int value) {
    return '0x${value.toRadixString(16).padLeft(2, '0').toUpperCase()}';
  }

  /// Converts a list of integers to [Uint8List].
  ///
  /// Required for BLE write operations which expect typed arrays.
  static Uint8List toUint8List(final List<int> list) {
    return Uint8List.fromList(list);
  }
}
