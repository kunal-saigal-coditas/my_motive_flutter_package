import 'package:my_motive_package/my_motive_package.dart';

class BleDataMapper {
  /// Parse battery level (7-bit resolution, 0-127)
  static int parseBatteryLevel(final List<int> data) {
    if (data.length < 2) return -1;

    final int rawBatteryLevel = data[1] & 0x7f;

    return (rawBatteryLevel / 127 * 100).round();
  }

  /// Parse charging status (bit 7 of byte 1)
  static bool parseIsCharging(final List<int> data) {
    if (data.length < 2) return false;

    return (data[1] & 0x80) != 0;
  }

  /// Parse controller temperature (byte 2)
  static int parseTemperature(final List<int> data) {
    if (data.length < 3) return 0;

    return data[2];
  }

  /// Parse device status string from byte 0
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
