import 'package:my_motive_package/mappers/device_status_mapper.dart';
import 'package:my_motive_package/core/enum/motive_enums.dart';

/// Represents the current status of a connected Motive device.
///
/// This model provides parsed, human-readable values from the raw BLE
/// status characteristic data. All byte manipulation is handled internally,
/// so users don't need to deal with raw byte data.
///
/// ## Example
///
/// ```dart
/// bleService.statusStream.listen((status) {
///   print('Battery: ${status.batteryLevel}%');
///   print('Charging: ${status.isCharging}');
///   print('Temperature: ${status.temperature}°C');
///   print('Knee level: ${status.kneeStimLevel}');
///   print('Thigh level: ${status.thighStimLevel}');
///   print('Treatment active: ${status.isTreatmentActive}');
///   print('Controller status: ${status.controllerStatus}');
///   
///   if (status.isBatteryLow) {
///     showLowBatteryWarning();
///   }
/// });
/// ```
class DeviceStatus {
  /// Battery level as percentage (0-100).
  final int batteryLevel;

  /// Whether the device is currently charging.
  final bool isCharging;

  /// Controller temperature in Celsius.
  final int temperature;

  /// Current knee (left channel) stimulation level (0-100).
  final int kneeStimLevel;

  /// Current thigh (right channel) stimulation level (0-100).
  final int thighStimLevel;

  /// Whether a therapy treatment is currently active.
  final bool isTreatmentActive;

  /// Whether the device is ready for commands.
  final bool isReady;

  /// Controller status string (Idle, Stim, Charging, BatLow, Fault, etc.).
  final String controllerStatus;

  /// Current sheet/pad docking status.
  final SheetStatus sheetStatus;

  /// Skin contact detection for left pad.
  final bool leftSkinContact;

  /// Skin contact detection for right pad.
  final bool rightSkinContact;

  /// Stimulation index (elapsed time in treatment).
  final int? stimIndex;

  /// Raw status data from the device (for debugging or advanced use).
  final List<int> rawData;

  const DeviceStatus({
    required this.batteryLevel,
    required this.isCharging,
    required this.temperature,
    required this.kneeStimLevel,
    required this.thighStimLevel,
    required this.isTreatmentActive,
    required this.isReady,
    required this.controllerStatus,
    required this.sheetStatus,
    required this.leftSkinContact,
    required this.rightSkinContact,
    this.stimIndex,
    required this.rawData,
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Convenience Getters
  // ═══════════════════════════════════════════════════════════════════════════

  /// Whether the battery is considered low (below 20%).
  bool get isBatteryLow => batteryLevel < 20;

  /// Whether the battery is critically low (below 10%).
  bool get isBatteryCritical => batteryLevel < 10;

  /// Whether the battery is full (100%).
  bool get isBatteryFull => batteryLevel >= 100;

  /// Whether skin contact is detected on both pads.
  bool get hasBothSkinContact => leftSkinContact && rightSkinContact;

  /// Whether any skin contact is detected.
  bool get hasAnySkinContact => leftSkinContact || rightSkinContact;

  /// Whether the device is in a fault state.
  bool get isFaulted => controllerStatus.toLowerCase().contains('fault');

  /// Whether the device is idle and ready for therapy.
  bool get isIdle => controllerStatus.toLowerCase() == 'idle';

  /// Whether stimulation is currently being delivered.
  bool get isStimulating => controllerStatus.toLowerCase() == 'stim';

  /// Whether a pad/sheet is docked.
  bool get isPadDocked => sheetStatus != SheetStatus.undocked && 
                           sheetStatus != SheetStatus.unknown;

  // ═══════════════════════════════════════════════════════════════════════════
  // Factory Constructors
  // ═══════════════════════════════════════════════════════════════════════════

  /// Creates an empty/default status (used when no data is available).
  factory DeviceStatus.empty() => const DeviceStatus(
    batteryLevel: 0,
    isCharging: false,
    temperature: 0,
    kneeStimLevel: 0,
    thighStimLevel: 0,
    isTreatmentActive: false,
    isReady: false,
    controllerStatus: 'Unknown',
    sheetStatus: SheetStatus.unknown,
    leftSkinContact: false,
    rightSkinContact: false,
    stimIndex: null,
    rawData: [],
  );

  /// Creates a [DeviceStatus] from raw BLE data bytes.
  ///
  /// This factory method handles all byte parsing internally using
  /// [DeviceStatusMapper], so consumers don't need to understand
  /// the raw data format.
  ///
  /// Example:
  /// ```dart
  /// final status = DeviceStatus.fromRawData(rawBytes);
  /// print('Battery: ${status.batteryLevel}%');
  /// ```
  factory DeviceStatus.fromRawData(List<int> data) {
    if (data.isEmpty) return DeviceStatus.empty();

    final skinContact = DeviceStatusMapper.parseSkinContact(data);
    final stimLevels = DeviceStatusMapper.parseStimulationLevels(data);

    return DeviceStatus(
      batteryLevel: DeviceStatusMapper.parseBatteryLevel(data),
      isCharging: DeviceStatusMapper.parseIsCharging(data),
      temperature: DeviceStatusMapper.parseTemperature(data),
      kneeStimLevel: stimLevels.isNotEmpty ? stimLevels[0] : 0,
      thighStimLevel: stimLevels.length > 1 ? stimLevels[1] : 0,
      isTreatmentActive: DeviceStatusMapper.parseTreatmentActive(data),
      isReady: DeviceStatusMapper.parseIsDeviceReady(data),
      controllerStatus: DeviceStatusMapper.parseControllerStatus(data),
      sheetStatus: DeviceStatusMapper.parseSheetStatus(data) ?? SheetStatus.unknown,
      leftSkinContact: skinContact.isNotEmpty ? skinContact[0] : false,
      rightSkinContact: skinContact.length > 1 ? skinContact[1] : false,
      stimIndex: DeviceStatusMapper.parseStimIndex(data),
      rawData: data,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Copy With
  // ═══════════════════════════════════════════════════════════════════════════

  /// Creates a copy with updated values.
  DeviceStatus copyWith({
    int? batteryLevel,
    bool? isCharging,
    int? temperature,
    int? kneeStimLevel,
    int? thighStimLevel,
    bool? isTreatmentActive,
    bool? isReady,
    String? controllerStatus,
    SheetStatus? sheetStatus,
    bool? leftSkinContact,
    bool? rightSkinContact,
    int? stimIndex,
    List<int>? rawData,
  }) {
    return DeviceStatus(
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isCharging: isCharging ?? this.isCharging,
      temperature: temperature ?? this.temperature,
      kneeStimLevel: kneeStimLevel ?? this.kneeStimLevel,
      thighStimLevel: thighStimLevel ?? this.thighStimLevel,
      isTreatmentActive: isTreatmentActive ?? this.isTreatmentActive,
      isReady: isReady ?? this.isReady,
      controllerStatus: controllerStatus ?? this.controllerStatus,
      sheetStatus: sheetStatus ?? this.sheetStatus,
      leftSkinContact: leftSkinContact ?? this.leftSkinContact,
      rightSkinContact: rightSkinContact ?? this.rightSkinContact,
      stimIndex: stimIndex ?? this.stimIndex,
      rawData: rawData ?? this.rawData,
    );
  }

  @override
  String toString() => 'DeviceStatus('
      'battery: $batteryLevel%, '
      'charging: $isCharging, '
      'temp: $temperature°C, '
      'knee: $kneeStimLevel, '
      'thigh: $thighStimLevel, '
      'active: $isTreatmentActive, '
      'status: $controllerStatus)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceStatus &&
          runtimeType == other.runtimeType &&
          batteryLevel == other.batteryLevel &&
          isCharging == other.isCharging &&
          temperature == other.temperature &&
          kneeStimLevel == other.kneeStimLevel &&
          thighStimLevel == other.thighStimLevel &&
          isTreatmentActive == other.isTreatmentActive &&
          controllerStatus == other.controllerStatus;

  @override
  int get hashCode =>
      batteryLevel.hashCode ^
      isCharging.hashCode ^
      temperature.hashCode ^
      kneeStimLevel.hashCode ^
      thighStimLevel.hashCode ^
      isTreatmentActive.hashCode ^
      controllerStatus.hashCode;
}
