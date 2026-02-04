/// Domain enums for BLE state management.
///
/// These enums abstract the flutter_blue_plus types to provide
/// a cleaner domain model with additional utility methods.
///
/// ## Available Enums
///
/// - [BleAdapterState]: Bluetooth adapter on/off/availability state
/// - [BleConnectionState]: Device connection lifecycle state
/// - [BleDeviceStatus]: Device operating status from status byte
library;

/// Represents the Bluetooth adapter state.
///
/// Abstracts [BluetoothAdapterState] from flutter_blue_plus for
/// domain layer independence.
///
/// ## Utility Getters
///
/// - [isOn]: True when adapter is on and ready
/// - [isOff]: True when adapter is turned off
/// - [isAvailable]: True when BLE operations can proceed
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

/// Represents the BLE connection state with a device.
///
/// Abstracts [BluetoothConnectionState] from flutter_blue_plus.
///
/// ## Utility Getters
///
/// - [isConnected]: True when fully connected and ready
/// - [isDisconnected]: True when not connected
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

/// Operating status of the BLE device from the controller status byte.
///
/// These values are parsed from byte 0 of the device status data.
///
/// ## Status Byte Mapping
///
/// | Byte Value | Status |
/// |------------|--------|
/// | 0 | Idle |
/// | 1 | Stimulating |
/// | 2 | Battery Low |
/// | 3 | Fault |
/// | 4 | Powering Off |
/// | 5 | Updating Firmware (OAD) |
/// | 6 | Charging |
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

  /// Creates a [BleDeviceStatus] from the raw status byte value.
  ///
  /// Returns [BleDeviceStatus.unknown] for unrecognized byte values.
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
