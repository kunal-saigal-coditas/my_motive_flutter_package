/// Domain enum representing BLE adapter state.
/// Abstracts flutter_blue_plus BluetoothAdapterState.
library;

enum BleAdapterState {
  unknown('Unknown'),
  unavailable('Unavailable'),
  unauthorized('Unauthorized'),
  turningOn('Turning On'),
  on('On'),
  turningOff('Turning Off'),
  off('Off');

  const BleAdapterState(this.displayName);
  final String displayName;

  bool get isOn => this == BleAdapterState.on;
  bool get isOff => this == BleAdapterState.off;
  bool get isAvailable => this == BleAdapterState.on;
}

/// Domain enum representing BLE connection state.
/// Abstracts flutter_blue_plus BluetoothConnectionState.
enum BleConnectionState {
  disconnected('Disconnected'),
  connecting('Connecting'),
  connected('Connected'),
  disconnecting('Disconnecting');

  const BleConnectionState(this.displayName);
  final String displayName;

  bool get isConnected => this == BleConnectionState.connected;
  bool get isDisconnected => this == BleConnectionState.disconnected;
}

/// Domain enum representing BLE device status (from controller status byte).
enum BleDeviceStatus {
  idle('Idle'),
  stimulating('Stim'),
  batteryLow('BatLow'),
  fault('Fault'),
  poweringOff('Poweroff'),
  updatingFirmware('OAD'),
  charging('Charging'),
  unknown('Unknown');

  const BleDeviceStatus(this.displayName);
  final String displayName;

  /// Create from status byte value
  static BleDeviceStatus fromByte(final int statusByte) {
    switch (statusByte) {
      case 0:
        return BleDeviceStatus.idle;
      case 1:
        return BleDeviceStatus.stimulating;
      case 2:
        return BleDeviceStatus.batteryLow;
      case 3:
        return BleDeviceStatus.fault;
      case 4:
        return BleDeviceStatus.poweringOff;
      case 5:
        return BleDeviceStatus.updatingFirmware;
      case 6:
        return BleDeviceStatus.charging;
      default:
        return BleDeviceStatus.unknown;
    }
  }
}
