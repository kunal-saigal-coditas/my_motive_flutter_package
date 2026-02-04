/// Enumerations for the Motive therapy device package.
///
/// This library contains all enum types used throughout the package,
/// organized into the following categories:
///
/// ## Device Enums
/// - [BleState] - Bluetooth adapter on/off state
/// - [DeviceErrorType] - Device error conditions
/// - [DeviceMonitorStep] - Steps in device monitoring flow
///
/// ## Assembly & Storage
/// - [AssembleDeviceStep] - Steps for assembling the device
/// - [StoreDeviceSteps] - Steps for storing the device
///
/// ## Pads & Sheets
/// - [SheetStatus] - Therapy pad docking status
/// - [TherapyPadType] - Types of therapy pads
/// - [ExternalPadStatus] - External pad validation results
///
/// ## Controller
/// - [ControllerStatus] - Device controller states
/// - [ControllerConnectedState] - BLE connection states
/// - [Channel] - Stimulation channels
///
/// ## Therapy & Treatment
/// - [TherapyEvent] - Events during therapy session
/// - [FirstStimulationSteps] - Initial stimulation flow
/// - [KneeSideTabs] - Knee side selection
/// - [TherapyTabs] - Therapy view tabs
///
/// ## User Interface
/// - [ChartType] - Progress chart types
/// - [CalendarSelectorTabs] - Time range selections
/// - [ProgressInsightsVariants] - Progress view variants
library;

// ═══════════════════════════════════════════════════════════════════════════
// DEVICE ENUMS
// ═══════════════════════════════════════════════════════════════════════════

/// Represents the Bluetooth adapter state.
enum BleState {
  bleOff('BleOff'),
  bleOn('BleOn');

  const BleState(this.value);
  final String value;
}

/// Types of device errors that can occur during operation.
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

/// Steps in the device monitoring setup flow.
enum DeviceMonitorStep {
  connection('CONNECTION'),
  seat('SEAT'),
  skinContact('SKIN_CONTACT'),
  finished('FINISHED');

  const DeviceMonitorStep(this.value);
  final String value;
}

/// Steps in the device assembly instruction flow.
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

/// Steps in the device storage instruction flow.
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

// ═══════════════════════════════════════════════════════════════════════════
// PAD & SHEET ENUMS
// ═══════════════════════════════════════════════════════════════════════════

/// Therapy pad/sheet docking status on the controller.
///
/// Indicates which pad is currently docked to the controller,
/// or if there's an error condition.
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

/// Types of therapy pads available for treatment.
///
/// Each pad type has:
/// - [code]: Single letter identifier used in QR codes
/// - [displayName]: Human-readable name for UI
/// - [firestoreName]: Backend database identifier
enum TherapyPadType {
  leftKnee('L', 'Left Knee', 'KNEE-LEFT'),
  rightKnee('R', 'Right Knee', 'KNEE-RIGHT'),
  backLower('B', 'Back Lower', 'BACK-LOWER');

  const TherapyPadType(this.code, this.displayName, this.firestoreName);

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

/// Type of instruction flow being displayed.
enum InstructionType {
  /// Device assembly instructions.
  assembly,

  /// Device storage instructions.
  storage,
}

/// Results from external pad validation API.
enum ExternalPadStatus {
  padNew('PAD_NEW'),
  padUsedByOther('PAD_USED_BY_OTHER'),
  padUsedBySelf('PAD_USED_BY_SELF'),
  padNotFound('PAD_NOT_FOUND'),
  padMalformed('PAD_MALFORMED');

  const ExternalPadStatus(this.value);
  final String value;
}

// ═══════════════════════════════════════════════════════════════════════════
// CONTROLLER ENUMS
// ═══════════════════════════════════════════════════════════════════════════

/// Operating status of the therapy controller.
///
/// These values correspond to the status byte received from the device.
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

/// BLE connection state of the controller.
enum ControllerConnectedState {
  disconnected('Disconnected'),
  connecting('Connecting'),
  ready('Ready');

  const ControllerConnectedState(this.value);
  final String value;
}

/// Stimulation channel identifiers.
enum Channel {
  knee('Knee'),
  thigh('Thigh');

  const Channel(this.value);
  final String value;
}

// ═══════════════════════════════════════════════════════════════════════════
// USER PROFILE & MEDICAL ENUMS
// ═══════════════════════════════════════════════════════════════════════════

/// User's knee condition for therapy customization.
enum KneeCondition {
  healthy('Healthy'),
  arthritis('Arthritis'),
  kneePain('KneePain'),
  other('Other');

  const KneeCondition(this.value);
  final String value;
}

/// Scale for rating mobility condition severity.
enum MobilityConditionScale {
  none('None'),
  mild('Mild'),
  moderate('Moderate'),
  severe('Severe'),
  extreme('Extreme');

  const MobilityConditionScale(this.value);
  final String value;
}

/// Pain level scale (0-10) for therapy tracking.
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

// ═══════════════════════════════════════════════════════════════════════════
// UI & DATA VISUALIZATION ENUMS
// ═══════════════════════════════════════════════════════════════════════════

/// Types of progress charts displayed in the app.
enum ChartType {
  pain('Pain'),
  minutes('Minutes'),
  stimLevel('StimLevel');

  const ChartType(this.value);
  final String value;
}

/// Time range tabs for calendar/date selection.
enum CalendarSelectorTabs {
  week('Week'),
  month('Month'),
  year('Year');

  const CalendarSelectorTabs(this.value);
  final String value;
}

/// Variants for progress insights display.
enum ProgressInsightsVariants {
  week('week'),
  month('month');

  const ProgressInsightsVariants(this.value);
  final String value;
}

// ═══════════════════════════════════════════════════════════════════════════
// THERAPY & TREATMENT ENUMS
// ═══════════════════════════════════════════════════════════════════════════

/// Events that occur during a therapy session.
///
/// These events are logged for analytics and session tracking.
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

/// Steps in the first-time stimulation calibration flow.
enum FirstStimulationSteps {
  generalIntro('GENERAL_INTRO'),
  kneeIntro('KNEE_INTRO'),
  kneeStimulation('KNEE_STIMULATION'),
  thighIntro('THIGH_INTRO'),
  thighStimulation('THIGH_STIMULATION');

  const FirstStimulationSteps(this.value);
  final String value;
}

/// Tabs for selecting which knee to treat.
enum KneeSideTabs {
  leftKnee('LeftKnee'),
  rightKnee('RightKnee');

  const KneeSideTabs(this.value);
  final String value;
}

/// Tabs in the therapy view for different metrics.
enum TherapyTabs {
  minutes('Minutes'),
  stimLevel('Stimulation Level');

  const TherapyTabs(this.value);
  final String value;
}

// ═══════════════════════════════════════════════════════════════════════════
// OTHER ENUMS
// ═══════════════════════════════════════════════════════════════════════════

/// User's onboarding completion status.
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

/// Layout types for the stimulation bar component.
enum StimulationBarLayoutType {
  /// Standard layout.
  default_,

  /// Layout with custom component alongside the bar.
  withCustomComponentSideWithBar,
}

/// Types of events that interrupt a therapy session.
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
