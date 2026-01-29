/// A Flutter package for integrating Motive therapy devices via BLE.
///
/// ## Getting Started
///
/// ```dart
/// import 'package:my_motive_package/my_motive_package.dart';
///
/// // Get SDK instance
/// final sdk = MotiveDeviceSDK.instance;
///
/// // Set up callbacks
/// sdk.onDeviceConnected((device) => print('Connected to ${device.name}'));
/// sdk.onDeviceDisconnected(() => print('Device disconnected'));
/// sdk.onDeviceStatus((status) => print('Battery: ${status.batteryLevel}%'));
/// sdk.onError((error) => print('Error: ${error.message}'));
///
/// // Scan for devices
/// final devices = await sdk.scanForDevices();
///
/// // Connect to a device
/// if (devices.isNotEmpty) {
///   await sdk.connect(devices.first);
/// }
///
/// // Start therapy
/// await sdk.startTherapy(durationMinutes: 30);
///
/// // Control stimulation
/// await sdk.changeStimulationLevel(kneeDelta: 10, thighDelta: 5);
///
/// // Stop therapy
/// await sdk.stopTherapy();
///
/// // Disconnect
/// await sdk.disconnect();
library;

// Core SDK
export 'services/motive_ble_service.dart';

// Models
export 'model/ble_command_model.dart';

// Enums
export 'core/enum/motive_enums.dart';
export 'core/enum/ble_enums.dart';
export 'core/enum/command_enum.dart';

// Mapper
export 'mappers/ble_data_mapper.dart';
export 'mappers/device_status_mapper.dart';
