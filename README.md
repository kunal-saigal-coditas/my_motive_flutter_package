# Motive Device SDK

A Flutter package for integrating Motive therapy devices via Bluetooth Low Energy (BLE).

## Features

- 🔍 **Device Discovery** - Scan and discover Motive devices
- 🔗 **Connection Management** - Connect/disconnect with automatic reconnection
- 📊 **Real-time Status** - Stream device status (battery, temperature, pad status)
- ⚡ **Therapy Control** - Start, pause, resume, and stop therapy sessions
- 🎚️ **Stimulation Control** - Adjust knee and thigh stimulation levels
- 📱 **Cross-platform** - Works on iOS and Android

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  my_motive_package:
    path: https://github.com/kunal-saigal-coditas/my_motive_flutter_package.git  # For local development
    # Or for Git:
    # git:
    #   url: https://github.com/your-org/my_motive_package.git
    #   ref: main
```

## Platform Setup

### Android

Add these permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

### iOS

Add these to `ios/Runner/Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app needs Bluetooth to connect to your Motive device</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app needs Bluetooth to connect to your Motive device</string>
```

## Usage

### Basic Usage

```dart
import 'package:my_motive_package/my_motive_package.dart';

// Get SDK instance (singleton)
final sdk = MotiveDeviceSDK.instance;

// Set up callbacks
sdk.onDeviceConnected((device) {
  print('Connected to ${device.name}');
});

sdk.onDeviceDisconnected(() {
  print('Device disconnected');
});

sdk.onDeviceStatus((status) {
  print('Battery: ${status.batteryLevel}%');
  print('Sheet Status: ${status.sheetStatus.value}');
  print('Treatment Active: ${status.isTreatmentActive}');
});

sdk.onTherapyCompleted(() {
  print('Therapy session completed!');
});

sdk.onError((error) {
  print('Error: ${error.message}');
});
```

### Scanning for Devices

```dart
// Check permissions first
final hasPermissions = await sdk.checkPermissions();
if (!hasPermissions) {
  // Handle permission denial
  return;
}

// Scan for devices (10 second timeout)
final devices = await sdk.scanForDevices(
  timeout: Duration(seconds: 10),
);

// Or listen to scan results stream
sdk.scanResults.listen((devices) {
  for (final device in devices) {
    print('Found: ${device.name} (${device.id})');
  }
});
```

### Connecting to a Device

```dart
if (devices.isNotEmpty) {
  final success = await sdk.connect(devices.first);
  if (success) {
    print('Connected successfully!');
  }
}

// Or use the connection state stream
sdk.connectionState.listen((state) {
  switch (state) {
    case BleConnectionState.connecting:
      print('Connecting...');
      break;
    case BleConnectionState.connected:
      print('Connected!');
      break;
    case BleConnectionState.disconnected:
      print('Disconnected');
      break;
    default:
      break;
  }
});
```

### Therapy Control

```dart
// Start a 30-minute therapy session
await sdk.startTherapy(
  durationMinutes: 30,
  initialKneeLevel: 20,
  initialThighLevel: 15,
);

// Adjust stimulation levels during therapy
await sdk.changeStimulationLevel(
  kneeDelta: 5,   // Increase knee by 5
  thighDelta: -3, // Decrease thigh by 3
);

// Pause therapy
await sdk.pauseTherapy();

// Resume therapy
await sdk.resumeTherapy();

// Stop therapy
await sdk.stopTherapy();

// Zero all stimulation levels
await sdk.zeroStimulationLevels();
```

### Reading Device Status

```dart
// Get current status
final status = sdk.deviceStatus;
print('Battery: ${status.batteryLevel}%');
print('Charging: ${status.isCharging}');
print('Temperature: ${status.temperature}°C');
print('Sheet: ${status.sheetStatus.value}');
print('Skin Contact: ${status.hasGoodSkinContact}');
print('Knee Level: ${status.kneeLevel}');
print('Thigh Level: ${status.thighLevel}');

// Or use quick accessors
print('Battery: ${sdk.batteryLevel}%');
print('Charging: ${sdk.isCharging}');
print('Treatment Active: ${sdk.isTreatmentActive}');
```

### Disconnecting

```dart
await sdk.disconnect();
```

### Cleanup

```dart
// When done with the SDK
await sdk.dispose();
```

## API Reference

### MotiveDeviceSDK

| Property | Type | Description |
|----------|------|-------------|
| `instance` | `MotiveDeviceSDK` | Singleton instance |
| `isConnected` | `bool` | Whether a device is connected |
| `connectedDevice` | `MotiveDevice?` | The connected device |
| `deviceStatus` | `DeviceStatus` | Current device status |
| `batteryLevel` | `int` | Battery level (0-100) |
| `isCharging` | `bool` | Whether device is charging |
| `sheetStatus` | `SheetStatus` | Current pad/sheet status |
| `isTreatmentActive` | `bool` | Whether therapy is active |

| Method | Return | Description |
|--------|--------|-------------|
| `checkPermissions()` | `Future<bool>` | Check BLE permissions |
| `scanForDevices()` | `Future<List<MotiveDevice>>` | Scan for devices |
| `stopScan()` | `Future<void>` | Stop scanning |
| `connect(device)` | `Future<bool>` | Connect to device |
| `disconnect()` | `Future<void>` | Disconnect |
| `startTherapy()` | `Future<bool>` | Start therapy |
| `pauseTherapy()` | `Future<bool>` | Pause therapy |
| `resumeTherapy()` | `Future<bool>` | Resume therapy |
| `stopTherapy()` | `Future<bool>` | Stop therapy |
| `changeStimulationLevel()` | `Future<bool>` | Change levels |

### DeviceStatus

| Property | Type | Description |
|----------|------|-------------|
| `batteryLevel` | `int` | Battery percentage (0-100) |
| `isCharging` | `bool` | Charging status |
| `temperature` | `int` | Device temperature |
| `sheetStatus` | `SheetStatus` | Pad docking status |
| `skinContact` | `List<bool>` | Skin contact per channel |
| `stimulationLevels` | `List<int>` | Current stim levels |
| `isTreatmentActive` | `bool` | Treatment status |
| `hasGoodSkinContact` | `bool` | Both channels have contact |
| `isDocked` | `bool` | Whether pad is docked |

## Error Handling

```dart
sdk.onError((error) {
  switch (error.type) {
    case MotiveErrorType.bluetoothOff:
      // Prompt user to enable Bluetooth
      break;
    case MotiveErrorType.permissionDenied:
      // Request permissions again
      break;
    case MotiveErrorType.connectionFailed:
      // Retry connection
      break;
    case MotiveErrorType.connectionLost:
      // Handle unexpected disconnect
      break;
    case MotiveErrorType.commandFailed:
      // Handle command failure
      break;
    default:
      print('Unknown error: ${error.message}');
  }
});
```

## License

MIT License - see LICENSE file for details.
