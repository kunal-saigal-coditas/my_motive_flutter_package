library;

import 'package:my_motive_package/my_motive_package.dart';

/// Mapper for parsing raw BLE device status data.
/// Centralizes byte parsing logic that was previously in the presentation layer.
class DeviceStatusMapper {
  // ─────────────────────────────────────────────────────────────────────────
  // BATTERY & CHARGING
  // ─────────────────────────────────────────────────────────────────────────

  /// Parse battery level from raw BLE data (7-bit resolution, 0-127 → 0-100%)
  static int parseBatteryLevel(final List<int> data) {
    if (data.length < 2) return -1;

    final int rawBatteryLevel = data[1] & 0x7f;

    return (rawBatteryLevel / 127 * 100).round();
  }

  /// Parse charging status from raw BLE data (bit 7 of byte 1)
  static bool parseIsCharging(final List<int> data) {
    if (data.length < 2) return false;

    return (data[1] & 0x80) != 0;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TEMPERATURE
  // ─────────────────────────────────────────────────────────────────────────

  /// Parse controller temperature from raw BLE data (byte 2)
  static int parseTemperature(final List<int> data) {
    if (data.length < 3) return 0;

    return data[2];
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SHEET STATUS & SKIN CONTACT
  // ─────────────────────────────────────────────────────────────────────────

  /// Parse sheet status from device data (byte 3, lower 6 bits)
  static SheetStatus? parseSheetStatus(final List<int> data) {
    if (data.length < 4) return null;

    final int byte3 = data[3];
    final int statusByte = byte3 & 0x3F;

    switch (statusByte) {
      case 0:
        return SheetStatus.undocked;

      case 1:
        return SheetStatus.left;

      case 2:
        return SheetStatus.right;

      case 62:
        return SheetStatus.fault;

      case 63:
        return SheetStatus.unknown;

      default:
        return SheetStatus.unknown;
    }
  }

  /// Parse skin contact from device data (byte 3, bits 6-7)
  static List<bool> parseSkinContact(final List<int> data) {
    if (data.length < 4) return <bool>[false, false];

    final int byte3 = data[3];
    final bool leftSkinContact = (byte3 & 0x80) != 0;
    final bool rightSkinContact = (byte3 & 0x40) != 0;

    return <bool>[leftSkinContact, rightSkinContact];
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STIMULATION
  // ─────────────────────────────────────────────────────────────────────────

  /// Parse stimulation levels from raw BLE data (bytes 6-7)
  static List<int> parseStimulationLevels(final List<int> data) {
    if (data.length < 8) return <int>[0, 0];

    return <int>[data[6], data[7]];
  }

  /// Parse stimulation index from raw BLE data
  static int? parseStimIndex(final List<int> data) {
    if (data.isEmpty) return null;

    // Check treatment active flag (bit 0 of byte 0)
    if ((data[0] & 0x01) != 0 && data.length > 9) {
      return data[8] + data[9] * 256;
    } else if ((data[0] & 0x01) == 0 && data.length > 5) {
      return data[4] + data[5] * 256;
    }

    return null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DEVICE STATE
  // ─────────────────────────────────────────────────────────────────────────

  /// Check if treatment is currently active (bit 0 of byte 0)
  static bool parseTreatmentActive(final List<int> data) {
    if (data.isEmpty) return false;

    return (data[0] & 0x01) != 0;
  }

  /// Check if device is ready for commands (bit 0 of byte 0)
  static bool parseIsDeviceReady(final List<int> data) {
    if (data.isEmpty) return false;

    return (data[0] & 0x01) != 0;
  }

  /// Get controller status string from device state byte
  static String parseControllerStatus(final List<int> data) {
    if (data.isEmpty) return 'Unknown';

    final int deviceState = data[0];
    final int statusBits = deviceState & 0xF0;

    const Map<int, String> controllerStatusMap = <int, String>{
      0x00: 'Idle',
      0x10: 'Stim',
      0x20: 'Batlow',
      0x30: 'Fault',
      0x40: 'Poweroff',
      0x50: 'Oad',
      0x60: 'Charging',
    };

    return controllerStatusMap[statusBits] ??
        'Unknown (0x${deviceState.toRadixString(16)})';
  }
}
