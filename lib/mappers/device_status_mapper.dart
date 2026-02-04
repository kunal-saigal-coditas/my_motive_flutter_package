/// Mapper for parsing detailed device status data from raw BLE responses.
///
/// This class provides comprehensive parsing of all device status fields
/// including battery, temperature, pad status, skin contact, stimulation
/// levels, and treatment state.
///
/// ## Byte Layout
///
/// | Byte | Description |
/// |------|-------------|
/// | 0 | Device state (treatment active, status bits) |
/// | 1 | Battery level (7 bits) + charging flag (bit 7) |
/// | 2 | Controller temperature |
/// | 3 | Sheet status (6 bits) + skin contact (2 bits) |
/// | 4-5 | Stim index (when treatment inactive) |
/// | 6-7 | Stimulation levels [knee, thigh] |
/// | 8-9 | Stim index (when treatment active) |
///
/// ## Example
///
/// ```dart
/// bleService.statusStream.listen((data) {
///   final battery = DeviceStatusMapper.parseBatteryLevel(data);
///   final isCharging = DeviceStatusMapper.parseIsCharging(data);
///   final temp = DeviceStatusMapper.parseTemperature(data);
///   final levels = DeviceStatusMapper.parseStimulationLevels(data);
///   final isActive = DeviceStatusMapper.parseTreatmentActive(data);
///
///   print('Battery: $battery%, Temp: $temp°C');
///   print('Stim levels: knee=${levels[0]}, thigh=${levels[1]}');
///   print('Treatment active: $isActive');
/// });
/// ```
///
/// See also:
/// - [BleDataMapper] for simpler data parsing
/// - [MotiveBleService.statusStream] for receiving status data
library;

import 'package:my_motive_package/my_motive_package.dart';

/// Mapper for parsing raw BLE device status data.
///
/// Centralizes byte parsing logic for device status information,
/// providing type-safe access to all status fields.
class DeviceStatusMapper {
  // ─────────────────────────────────────────────────────────────────────────
  // BATTERY & CHARGING
  // ─────────────────────────────────────────────────────────────────────────

  /// Parses battery level from raw BLE data.
  ///
  /// Battery level is stored in the lower 7 bits of byte 1, with
  /// values 0-127 representing 0-100% charge.
  ///
  /// Returns -1 if data is insufficient (< 2 bytes).
  static int parseBatteryLevel(final List<int> data) {
    if (data.length < 2) return -1;

    final int rawBatteryLevel = data[1] & 0x7f;

    return (rawBatteryLevel / 127 * 100).round();
  }

  /// Parses charging status from raw BLE data.
  ///
  /// Charging is indicated by bit 7 of byte 1 being set.
  /// Returns `false` if data is insufficient.
  static bool parseIsCharging(final List<int> data) {
    if (data.length < 2) return false;

    return (data[1] & 0x80) != 0;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TEMPERATURE
  // ─────────────────────────────────────────────────────────────────────────

  /// Parses the controller temperature from raw BLE data.
  ///
  /// Temperature is stored in byte 2 as an integer value in Celsius.
  /// Returns 0 if data is insufficient.
  static int parseTemperature(final List<int> data) {
    if (data.length < 3) return 0;

    return data[2];
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SHEET STATUS & SKIN CONTACT
  // ─────────────────────────────────────────────────────────────────────────

  /// Parses the therapy pad/sheet docking status.
  ///
  /// Sheet status is stored in the lower 6 bits of byte 3:
  /// - 0: Undocked
  /// - 1: Left pad docked
  /// - 2: Right pad docked
  /// - 62: Fault condition
  /// - 63: Unknown
  ///
  /// Returns `null` if data is insufficient.
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

  /// Parses skin contact detection status for both pads.
  ///
  /// Skin contact is indicated by the upper 2 bits of byte 3:
  /// - Bit 7: Left pad skin contact
  /// - Bit 6: Right pad skin contact
  ///
  /// Returns a list [leftContact, rightContact] where `true` indicates
  /// skin contact is detected.
  ///
  /// Returns [false, false] if data is insufficient.
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

  /// Parses current stimulation levels from raw BLE data.
  ///
  /// Stimulation levels are stored in bytes 6-7:
  /// - Byte 6: Knee stimulation level (0-100)
  /// - Byte 7: Thigh stimulation level (0-100)
  ///
  /// Returns [0, 0] if data is insufficient.
  static List<int> parseStimulationLevels(final List<int> data) {
    if (data.length < 8) return <int>[0, 0];

    return <int>[data[6], data[7]];
  }

  /// Parses the stimulation index (elapsed time) from raw BLE data.
  ///
  /// The stim index location depends on treatment state:
  /// - Treatment active: bytes 8-9 (little-endian)
  /// - Treatment inactive: bytes 4-5 (little-endian)
  ///
  /// Returns `null` if data is insufficient or treatment state cannot
  /// be determined.
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

  /// Checks if a therapy treatment is currently active.
  ///
  /// Treatment active state is indicated by bit 0 of byte 0.
  /// Returns `false` if data is empty.
  static bool parseTreatmentActive(final List<int> data) {
    if (data.isEmpty) return false;

    return (data[0] & 0x01) != 0;
  }

  /// Checks if the device is ready to receive commands.
  ///
  /// Device readiness is indicated by bit 0 of byte 0.
  /// Returns `false` if data is empty.
  static bool parseIsDeviceReady(final List<int> data) {
    if (data.isEmpty) return false;

    return (data[0] & 0x01) != 0;
  }

  /// Parses the controller status as a human-readable string.
  ///
  /// Status is derived from the upper nibble of byte 0:
  /// - 0x00: Idle - Device ready but not stimulating
  /// - 0x10: Stim - Actively delivering stimulation
  /// - 0x20: Batlow - Battery is low
  /// - 0x30: Fault - Error condition detected
  /// - 0x40: Poweroff - Device is powering off
  /// - 0x50: Oad - Firmware update mode
  /// - 0x60: Charging - Battery is charging
  ///
  /// Returns 'Unknown' with hex value if status is not recognized.
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

  /// Parses the device status as a human-readable string from byte 0.
  ///
  /// Maps the status byte to [ControllerStatus] enum values:
  /// - 0: Idle
  /// - 1: Stim (stimulating)
  /// - 2: BatLow (battery low)
  /// - 3: Fault
  /// - 4: Poweroff
  /// - 5: OAD (firmware update mode)
  /// - 6: Charging
  ///
  /// Returns 'Unknown' if data is empty, or 'Error' on parsing failure.
  static String parseDeviceStatusString(final List<int> data) {
    if (data.isEmpty) return 'Unknown';

    try {
      final int statusByte = data[0];

      switch (statusByte) {
        case 0:
          return ControllerStatus.idle.value;

        case 1:
          return ControllerStatus.stim.value;

        case 2:
          return ControllerStatus.batLow.value;

        case 3:
          return ControllerStatus.fault.value;

        case 4:
          return ControllerStatus.poweroff.value;

        case 5:
          return ControllerStatus.oad.value;

        case 6:
          return ControllerStatus.charging.value;

        default:
          return 'Unknown($statusByte)';
      }
    } catch (e) {
      return 'Error';
    }
  }
}
