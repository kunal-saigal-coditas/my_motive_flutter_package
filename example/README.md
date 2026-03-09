# Motive Package Example

A demo app showing how to use the `my_motive_package` for Bluetooth connectivity with Motive therapy devices.

## Setup

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Platform Configuration

#### Android

The following permissions are already configured in `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Android 12+ (API 31+) -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

<!-- Android 11 and below -->
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- BLE feature requirement -->
<uses-feature android:name="android.hardware.bluetooth_le" android:required="true" />
```

**Note**: Minimum SDK is set to 21 for BLE support.

#### iOS

The following keys are already configured in `ios/Runner/Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app uses Bluetooth to connect to and control your Motive therapy device.</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app uses Bluetooth to connect to and control your Motive therapy device.</string>
```

**Note**: Minimum iOS version is set to 13.0.

## Running the App

```bash
# Run on connected device
flutter run

# Run on specific device
flutter run -d <device_id>
```

## Features

### Device Screen
- **Scan**: Discover nearby Motive devices
- **Connect**: Establish BLE connection
- **Status Tab**: View battery, stimulation levels, device state, skin contact
- **Product Info Tab**: View firmware version details

### Therapy Screen
- **Start/Stop**: Control therapy sessions
- **Pause/Resume**: Temporarily pause therapy
- **Duration**: Set session length (5-60 minutes)
- **Stimulation Control**: Adjust knee and thigh levels

## Code Examples

### Basic Connection

```dart
import 'package:my_motive_package/my_motive_library.dart';

final bleService = MotiveBleService();

// Request permissions
await PermissionService.requestBluetoothPermission();

// Scan for devices
await FlutterBluePlus.startScan(
  timeout: Duration(seconds: 10),
  withServices: [Guid('cece1130-0101-0000-a000-000000000000')],
);

// Connect to device
await device.connect();
await bleService.initialize(
  device: device,
  manufacturerData: advertisementData.manufacturerData.values.first,
);

// Listen to status
bleService.statusStream.listen((status) {
  print('Battery: ${status.batteryLevel}%');
});
```

### Therapy Control

```dart
// Create therapy commands from service
final commands = TherapyCommands.fromService(bleService);

// Start 30-minute therapy
await commands.sendStart(minutes: 30);

// Adjust stimulation
await commands.sendChangeLevel(knee: 10, thigh: 5);

// Pause/Resume
await commands.sendPause();
await commands.sendResume();

// Stop therapy
await commands.sendStop();
```

## Troubleshooting

### Permissions Denied
- Ensure Bluetooth is enabled on the device
- Grant location permission on Android (required for BLE scanning)
- Check that the app has Bluetooth permission in device settings

### Device Not Found
- Make sure the Motive device is powered on
- Ensure the device is not connected to another app
- Try restarting Bluetooth on your phone

### Connection Failed
- Move closer to the device
- Restart the Motive device
- Clear Bluetooth cache on Android (Settings > Apps > Bluetooth > Clear Cache)
