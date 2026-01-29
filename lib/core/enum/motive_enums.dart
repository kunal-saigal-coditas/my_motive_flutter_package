/// Enums Used for Device
library;

enum BleState {
  bleOff('BleOff'),
  bleOn('BleOn');

  const BleState(this.value);
  final String value;
}

enum DeviceErrorType {
  ok('OK'),
  disconnected('DISCONNECTED'),
  unseated('UNSEATED'),
  wrongLeg('WRONG_LEG'),
  noSkinContact('NO_SKIN_CONTACT'),
  undefined('UNDEFINED');

  const DeviceErrorType(this.value);
  final String value;
}

enum DeviceMonitorStep {
  connection('CONNECTION'),
  seat('SEAT'),
  skinContact('SKIN_CONTACT'),
  finished('FINISHED');

  const DeviceMonitorStep(this.value);
  final String value;
}

enum AssembleDeviceStep {
  start('START'),
  prepSkin('PREP_SKIN'),
  peelPad('PEEL_PAD'),
  applyPad('APPLY_PAD'),
  putOnWrap('PUT_ON_WRAP'),
  placeDevice('PLACE_DEVICE');

  const AssembleDeviceStep(this.value);
  final String value;
}

enum StoreDeviceSteps {
  intro('INTRO'),
  removeDevice('REMOVE_DEVICE'),
  removeWrap('REMOVE_WRAP'),
  peelOffPad('PEEL_OFF_PAD'),
  replacePadCover('REPLACE_PAD_COVER'),
  chargeDevice('CHARGE_DEVICE');

  const StoreDeviceSteps(this.value);
  final String value;
}

/// QR related

enum QRValidationStatus { initial, scanning, validating, valid, invalid, error }

enum ValidationError {
  invalidLength('QR code must be exactly 23 characters'),
  invalidPrefix('QR code must start with L, R, or B'),
  invalidFormat('Invalid QR code format'),
  alreadyRegistered('This pad type is already registered'),
  invalidSerial('Invalid therapy pad serial'),
  wrongPadType('Wrong pad type for current therapy session'),
  apiError('Failed to validate with external API'),
  networkError('Network connection error');

  const ValidationError(this.message);
  final String message;
}

/// Enums Used for Sheets/Pads

enum SheetStatus {
  undocked('Undocked'),
  left('Left'),
  right('Right'),
  unknown('Unknown'),
  fault('Fault');

  const SheetStatus(this.value);
  final String value;

  /// Convert SheetStatus to JSON
  String toJson() {
    return value;
  }

  /// Create SheetStatus from JSON
  static SheetStatus fromJson(final String json) {
    switch (json) {
      case 'Undocked':
        return SheetStatus.undocked;

      case 'Left':
        return SheetStatus.left;

      case 'Right':
        return SheetStatus.right;

      case 'Unknown':
        return SheetStatus.unknown;

      case 'Fault':
        return SheetStatus.fault;

      default:
        return SheetStatus.unknown;
    }
  }
}

enum TherapyPadType {
  leftKnee('L', 'Left Knee', 'KNEE-LEFT'),
  rightKnee('R', 'Right Knee', 'KNEE-RIGHT'),
  backLower('B', 'Back Lower', 'BACK-LOWER');

  const TherapyPadType(
    this.code,
    this.displayName,
    this.firestoreName,
  );

  final String code;
  final String displayName;
  final String firestoreName;

  static TherapyPadType? fromCode(final String code) {
    return TherapyPadType.values.firstWhere(
      (final TherapyPadType type) => type.code == code,

      orElse: () => throw ArgumentError('Invalid pad type code: $code'),
    );
  }

  static TherapyPadType fromDisplayName(final String displayName) {
    return TherapyPadType.values.firstWhere(
      (final TherapyPadType type) => type.displayName == displayName,

      orElse: () =>
          throw ArgumentError('Invalid pad type displayName: $displayName'),
    );
  }
}

enum InstructionType { assembly, storage }

enum ExternalPadStatus {
  padNew('PAD_NEW'),
  padUsedByOther('PAD_USED_BY_OTHER'),
  padUsedBySelf('PAD_USED_BY_SELF'),
  padNotFound('PAD_NOT_FOUND'),
  padMalformed('PAD_MALFORMED');

  const ExternalPadStatus(this.value);
  final String value;
}

/// Enums Used for Controller

enum ControllerStatus {
  idle('Idle'),
  stim('Stim'),
  batLow('BatLow'),
  fault('Fault'),
  poweroff('Poweroff'),
  oad('OAD'),
  charging('Charging');

  const ControllerStatus(this.value);
  final String value;
}

enum ControllerConnectedState {
  disconnected('Disconnected'),
  connecting('Connecting'),
  ready('Ready');

  const ControllerConnectedState(this.value);
  final String value;
}

enum Channel {
  knee('Knee'),
  thigh('Thigh');

  const Channel(this.value);
  final String value;
}

/// Enums Used for User Profile/Medical

enum KneeCondition {
  healthy('Healthy'),
  arthritis('Arthritis'),
  kneePain('KneePain'),
  other('Other');

  const KneeCondition(this.value);
  final String value;
}

enum MobilityConditionScale {
  none('None'),
  mild('Mild'),
  moderate('Moderate'),
  severe('Severe'),
  extreme('Extreme');

  const MobilityConditionScale(this.value);
  final String value;
}

enum PainLevel {
  unset(0),
  one(1),
  two(2),
  three(3),
  four(4),
  five(5),
  six(6),
  seven(7),
  eight(8),
  nine(9),
  ten(10);

  const PainLevel(this.value);
  final int value;
}

/// Enums Used for UI/Charts/Data

enum ChartType {
  pain('Pain'),
  minutes('Minutes'),
  stimLevel('StimLevel');

  const ChartType(this.value);
  final String value;
}

enum CalendarSelectorTabs {
  week('Week'),
  month('Month'),
  year('Year');

  const CalendarSelectorTabs(this.value);
  final String value;
}

enum ProgressInsightsVariants {
  week('week'),
  month('month');

  const ProgressInsightsVariants(this.value);
  final String value;
}

///Enums Used for Treatment/Therapy

enum TherapyEvent {
  start('Start'),
  canceled('Canceled'),
  completed('Completed'),
  userPause('UserPause'),
  userExit('UserExit'),
  startTiming('StartTiming'),
  interrupted(
    'Interrupted',
  ), // undocked, no skin, ble disconnected, ble dropped
  resume('Resume'),
  undock('Undock'),
  changeLevel('ChangeLevel'), // {knee: number, thigh: number}
  background('Background'),
  foreground('Foreground'),
  serviceStarted('ForegroundServiceStarted'),
  serviceStopped('ForegroundServiceStopped');

  const TherapyEvent(this.value);
  final String value;

  static TherapyEvent fromString(final String value) {
    return TherapyEvent.values.firstWhere(
      (final TherapyEvent e) => e.value == value,
    );
  }
}

enum FirstStimulationSteps {
  generalIntro('GENERAL_INTRO'),
  kneeIntro('KNEE_INTRO'),
  kneeStimulation('KNEE_STIMULATION'),
  thighIntro('THIGH_INTRO'),
  thighStimulation('THIGH_STIMULATION');

  const FirstStimulationSteps(this.value);
  final String value;
}

enum KneeSideTabs {
  leftKnee('LeftKnee'),
  rightKnee('RightKnee');

  const KneeSideTabs(this.value);
  final String value;
}

enum TherapyTabs {
  minutes('Minutes'),
  stimLevel('Stimulation Level');

  const TherapyTabs(this.value);
  final String value;
}

/// Rest (Other Enums)

enum OnboardingStatus {
  notFinished('NOT FINISHED'),
  finished('FINISHED');

  const OnboardingStatus(this.value);
  final String value;

  static OnboardingStatus fromString(final String value) {
    return OnboardingStatus.values.firstWhere(
      (final OnboardingStatus e) => e.value == value,
    );
  }
}

enum StimulationBarLayoutType { default_, withCustomComponentSideWithBar }

/// Interrupt event types
enum InterruptEvent {
  undocked('Undocked'),
  noSkin('No Skin'),
  bleDisconnected('Ble Disconnected'),
  bleDropped('Ble Dropped');

  const InterruptEvent(this.value);
  final String value;

  static InterruptEvent fromString(final String value) {
    return InterruptEvent.values.firstWhere(
      (final InterruptEvent e) => e.value == value,
    );
  }
}
