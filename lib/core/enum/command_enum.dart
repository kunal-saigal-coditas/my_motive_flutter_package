/// Types of BLE commands that can be sent to the Motive device.
///
/// Each command type corresponds to a specific operation:
/// - [startTreatment]: Begin a new therapy session
/// - [changeLevel]: Adjust stimulation intensity
/// - [pauseTreatment]: Temporarily pause therapy
/// - [resumeTreatment]: Resume a paused session
/// - [stop]: End the current session
/// - [powerOff]: Turn off the device
/// - [clearEvent]: Clear error/event states
/// - [overTheAirUpdate]: Initiate firmware update
/// - [custom]: Custom/experimental commands
enum CommandType {
  /// Start a new therapy treatment session.
  startTreatment,

  /// Change stimulation level for one or both channels.
  changeLevel,

  /// Temporarily pause the current treatment.
  pauseTreatment,

  /// Resume a paused treatment session.
  resumeTreatment,

  /// Stop and end the current treatment.
  stop,

  /// Power off the device completely.
  powerOff,

  /// Clear device events or error states.
  clearEvent,

  /// Initiate over-the-air firmware update.
  overTheAirUpdate,

  /// Custom command for testing or special operations.
  custom,
}

/// Priority levels for command queue processing.
///
/// Higher priority commands are processed before lower priority ones.
/// Use [critical] sparingly for emergency stop scenarios.
enum CommandPriority {
  /// Lowest priority, for background tasks like OTA updates.
  low,

  /// Standard priority for most operations.
  normal,

  /// Elevated priority for stop commands.
  high,

  /// Highest priority for emergency situations.
  critical,
}
