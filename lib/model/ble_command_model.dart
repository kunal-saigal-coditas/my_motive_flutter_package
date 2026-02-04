/// BLE command models for Motive therapy device communication.
///
/// This library defines the data models for all BLE commands that can be
/// sent to Motive therapy devices. Each command type is represented by a
/// concrete class extending [BleCommand].
///
/// ## Available Commands
///
/// - [StartTreatmentCommand] - Begin a therapy session
/// - [ChangeLevelCommand] - Adjust stimulation intensity
/// - [PauseTreatmentCommand] - Temporarily pause therapy
/// - [ResumeTreatmentCommand] - Resume paused therapy
/// - [StopCommand] - Stop the current therapy session
/// - [PowerOffCommand] - Power off the device
/// - [ClearEventCommand] - Clear device events/errors
/// - [OverTheAirUpdateCommand] - Initiate firmware update
/// - [CustomCommand] - Send custom commands
///
/// ## Serialization
///
/// All commands support JSON serialization via `toJson()` and `fromJson()`
/// methods for storage or transmission.
///
/// See also:
/// - [TherapyCommandMapper] for creating raw BLE byte commands
/// - [CommandType] for command type enumeration
/// - [CommandPriority] for priority levels
library;

import 'package:my_motive_package/core/enum/command_enum.dart';

/// Abstract base class for all BLE commands.
///
/// This class provides the common structure for all therapy device commands,
/// including raw byte data, command type, timing, and priority information.
///
/// Subclasses must implement [toJson] for serialization. The static [fromJson]
/// method handles deserialization by detecting the command type.
///
/// ## Properties
///
/// - [rawBytes]: The actual bytes to be sent over BLE
/// - [type]: The command type classification
/// - [timestamp]: When the command was created/executed
/// - [requiresAcknowledgment]: Whether the device should acknowledge receipt
/// - [priority]: Command priority for queue ordering
/// - [metadata]: Additional contextual data
abstract class BleCommand {
  /// Raw bytes representing the BLE command.
  ///
  /// These bytes are written directly to the command characteristic.
  List<int>? rawBytes;

  /// The type classification of this command.
  CommandType? type;

  /// Timestamp when this command was created or executed.
  DateTime? timestamp;

  /// Whether this command requires an acknowledgment from the device.
  ///
  /// If `true`, the sender should wait for a response before considering
  /// the command complete. Defaults to `false`.
  bool requiresAcknowledgment;

  /// Priority level for command queue ordering.
  ///
  /// Higher priority commands are processed before lower priority ones.
  /// Defaults to [CommandPriority.normal].
  CommandPriority priority;

  /// Optional metadata for additional context.
  ///
  /// Can include session ID, user ID, device ID, or other tracking info.
  Map<String, dynamic>? metadata;

  /// Creates a new [BleCommand] with the specified properties.
  BleCommand({
    this.rawBytes,
    this.type,
    this.timestamp,
    this.requiresAcknowledgment = false,
    this.priority = CommandPriority.normal,
    this.metadata,
  });
}

/// Command to start a therapy treatment session.
///
/// This command initiates a new therapy session on the device with the
/// specified duration and optional protocol/therapy identifiers.
///
/// ## Example
///
/// ```dart
/// final command = StartTreatmentCommand(
///   duration: 1800, // 30 minutes in seconds
///   protocolId: 1,
///   therapyId: 'session-123',
/// );
/// ```
class StartTreatmentCommand extends BleCommand {
  /// Duration of the therapy session in seconds.
  int? duration;

  /// Protocol identifier for the therapy type.
  int? protocolId;

  /// Unique identifier for this therapy session.
  String? therapyId;

  StartTreatmentCommand({
    this.duration,
    this.protocolId,
    this.therapyId,
    super.rawBytes,
    super.type,
    super.timestamp,
    super.requiresAcknowledgment = false,
    super.priority = CommandPriority.normal,
    super.metadata,
  });
}

/// Command to change stimulation intensity levels.
///
/// This command adjusts the stimulation level for a specific channel
/// or all channels. The adjustment can be positive (increase) or
/// negative (decrease).
///
/// ## Channels
///
/// - Channel 0: Knee stimulation
/// - Channel 1: Thigh stimulation
///
/// ## Example
///
/// ```dart
/// // Increase knee stimulation by 5
/// final command = ChangeLevelCommand(
///   channel: 0,
///   adjustment: 5,
///   currentLevels: [10, 15], // Current knee and thigh levels
/// );
/// ```
class ChangeLevelCommand extends BleCommand {
  /// Target channel index (0 = knee, 1 = thigh).
  int? channel;

  /// Amount to adjust the level (positive to increase, negative to decrease).
  int? adjustment;

  /// Current stimulation levels before adjustment [knee, thigh].
  List<int>? currentLevels;

  ChangeLevelCommand({
    this.channel,
    this.adjustment,
    this.currentLevels,
    super.rawBytes,
    super.type,
    super.timestamp,
    super.requiresAcknowledgment = false,
    super.priority = CommandPriority.normal,
    super.metadata,
  });
}

/// Command to pause an active therapy session.
///
/// Pausing preserves the current session state including elapsed time
/// and stimulation levels. Use [ResumeTreatmentCommand] to continue.
///
/// ## Example
///
/// ```dart
/// final command = PauseTreatmentCommand(
///   timestamp: DateTime.now(),
/// );
/// ```
class PauseTreatmentCommand extends BleCommand {
  PauseTreatmentCommand({
    super.rawBytes,
    super.type,
    super.timestamp,
    super.requiresAcknowledgment = false,
    super.priority = CommandPriority.normal,
    super.metadata,
  });
}

/// Command to resume a paused therapy session.
///
/// Resumes therapy from where it was paused, restoring previous
/// stimulation levels and continuing the session timer.
class ResumeTreatmentCommand extends BleCommand {
  ResumeTreatmentCommand({
    super.rawBytes,
    super.type,
    super.timestamp,
    super.requiresAcknowledgment = false,
    super.priority = CommandPriority.normal,
    super.metadata,
  });
}

/// Command to stop the current therapy session.
///
/// This command immediately stops all stimulation and ends the session.
/// Unlike pause, a stopped session cannot be resumed.
///
/// Defaults to [CommandPriority.high] to ensure immediate processing.
class StopCommand extends BleCommand {
  StopCommand({
    super.rawBytes,
    super.type,
    super.timestamp,
    super.requiresAcknowledgment = false,
    super.priority = CommandPriority.high,
    super.metadata,
  });
}

/// Command to power off the therapy device.
///
/// This command shuts down the device completely. The device will need
/// to be manually powered on again before use.
///
/// Defaults to [CommandPriority.high] to ensure immediate processing.
class PowerOffCommand extends BleCommand {
  PowerOffCommand({
    super.rawBytes,
    super.type,
    super.timestamp,
    super.requiresAcknowledgment = false,
    super.priority = CommandPriority.high,
    super.metadata,
  });
}

/// Command to clear device events or error states.
///
/// Use this command to acknowledge and clear error conditions or
/// pending events on the device.
class ClearEventCommand extends BleCommand {
  ClearEventCommand({
    super.rawBytes,
    super.type,
    super.timestamp,
    super.requiresAcknowledgment = false,
    super.priority = CommandPriority.normal,
    super.metadata,
  });
}

/// Command to initiate an over-the-air firmware update.
///
/// This command puts the device into OTA mode and prepares it to
/// receive a firmware update. The actual firmware transfer is handled
/// separately.
///
/// Defaults to [CommandPriority.low] as updates are not time-critical.
class OverTheAirUpdateCommand extends BleCommand {
  /// Target firmware version for the update.
  String? firmwareVersion;

  OverTheAirUpdateCommand({
    this.firmwareVersion,
    super.rawBytes,
    super.type,
    super.timestamp,
    super.requiresAcknowledgment = false,
    super.priority = CommandPriority.low,
    super.metadata,
  });
}

/// Command for sending custom/experimental commands.
///
/// Use this for commands not covered by the standard command types.
/// The [rawBytes] property must be set with the actual command data.
class CustomCommand extends BleCommand {
  /// Human-readable name for this custom command.
  String? commandName;

  CustomCommand({
    this.commandName,
    super.rawBytes,
    super.type,
    super.timestamp,
    super.requiresAcknowledgment = false,
    super.priority = CommandPriority.normal,
    super.metadata,
  });
}

/// Metadata attached to BLE commands for tracking and retry logic.
///
/// This class provides contextual information about a command including
/// session tracking, retry configuration, and optional parameters.
///
/// ## Example
///
/// ```dart
/// final metadata = CommandMetadata(
///   sessionId: 'therapy-session-123',
///   userId: 'user-456',
///   deviceId: 'device-789',
///   maxRetries: 5,
/// );
/// ```
class CommandMetadata {
  /// Unique identifier for the therapy session.
  String? sessionId;

  /// Unique identifier for the user.
  String? userId;

  /// Unique identifier for the connected device.
  String? deviceId;

  /// Additional command-specific parameters.
  Map<String, dynamic>? parameters;

  /// Human-readable description of the command purpose.
  String? description;

  /// When this command should be considered expired.
  DateTime? expiresAt;

  /// Current retry attempt number (starts at 1).
  int retryCount;

  /// Maximum number of retry attempts allowed.
  int maxRetries;

  /// Creates a new [CommandMetadata] instance.
  CommandMetadata({
    this.sessionId,
    this.userId,
    this.deviceId,
    this.parameters,
    this.description,
    this.expiresAt,
    this.retryCount = 1,
    this.maxRetries = 3,
  });
}
