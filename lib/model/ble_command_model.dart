library;

import 'package:my_motive_package/core/enum/command_enum.dart';

/// Base class
abstract class BleCommand {
  List<int>? rawBytes;
  CommandType? type;
  DateTime? timestamp;
  bool requiresAcknowledgment;
  CommandPriority priority;
  Map<String, dynamic>? metadata;

  BleCommand({
    this.rawBytes,
    this.type,
    this.timestamp,
    this.requiresAcknowledgment = false,
    this.priority = CommandPriority.normal,
    this.metadata,
  });

  Map<String, dynamic> toJson();
  static BleCommand fromJson(final Map<String, dynamic> json) {
    switch (json['runtimeType']) {
      case 'startTreatment':
        return StartTreatmentCommand.fromJson(json);

      case 'changeLevel':
        return ChangeLevelCommand.fromJson(json);

      case 'pauseTreatment':
        return PauseTreatmentCommand.fromJson(json);

      case 'resumeTreatment':
        return ResumeTreatmentCommand.fromJson(json);

      case 'stop':
        return StopCommand.fromJson(json);

      case 'powerOff':
        return PowerOffCommand.fromJson(json);

      case 'clearEvent':
        return ClearEventCommand.fromJson(json);

      case 'overTheAirUpdate':
        return OverTheAirUpdateCommand.fromJson(json);

      case 'custom':
        return CustomCommand.fromJson(json);

      default:
        throw Exception("Unknown BleCommand type: ${json['runtimeType']}");
    }
  }
}

/// Start Treatment Command
class StartTreatmentCommand extends BleCommand {
  int? duration;
  int? protocolId;
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

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    "runtimeType": "startTreatment",
    "duration": duration,
    "protocolId": protocolId,
    "therapyId": therapyId,
    "rawBytes": rawBytes,
    "type": type?.toString(),
    "timestamp": timestamp?.toIso8601String(),
    "requiresAcknowledgment": requiresAcknowledgment,
    "priority": priority.toString(),
    "metadata": metadata,
  };

  factory StartTreatmentCommand.fromJson(final Map<String, dynamic> json) =>
      StartTreatmentCommand(
        duration: json["duration"],
        protocolId: json["protocolId"],
        therapyId: json["therapyId"],
        rawBytes: (json["rawBytes"] as List<dynamic>?)?.cast<int>(),
        type: json["type"] != null
            ? CommandType.values.firstWhere(
                (final CommandType e) => e.toString() == json["type"],
              )
            : null,
        timestamp: json["timestamp"] != null
            ? DateTime.parse(json["timestamp"])
            : null,
        requiresAcknowledgment: json["requiresAcknowledgment"] ?? false,
        priority: _priorityFromString(json["priority"]),
        metadata: json["metadata"] as Map<String, dynamic>?,
      );
}

/// Change Level Command
class ChangeLevelCommand extends BleCommand {
  int? channel;
  int? adjustment;
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

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    "runtimeType": "changeLevel",
    "channel": channel,
    "adjustment": adjustment,
    "currentLevels": currentLevels,
    "rawBytes": rawBytes,
    "type": type?.toString(),
    "timestamp": timestamp?.toIso8601String(),
    "requiresAcknowledgment": requiresAcknowledgment,
    "priority": priority.toString(),
    "metadata": metadata,
  };

  factory ChangeLevelCommand.fromJson(final Map<String, dynamic> json) =>
      ChangeLevelCommand(
        channel: json["channel"],
        adjustment: json["adjustment"],
        currentLevels: (json["currentLevels"] as List<dynamic>?)?.cast<int>(),
        rawBytes: (json["rawBytes"] as List<dynamic>?)?.cast<int>(),
        type: json["type"] != null
            ? CommandType.values.firstWhere(
                (final CommandType e) => e.toString() == json["type"],
              )
            : null,
        timestamp: json["timestamp"] != null
            ? DateTime.parse(json["timestamp"])
            : null,
        requiresAcknowledgment: json["requiresAcknowledgment"] ?? false,
        priority: _priorityFromString(json["priority"]),
        metadata: json["metadata"] as Map<String, dynamic>?,
      );
}

/// Pause Treatment Command
class PauseTreatmentCommand extends BleCommand {
  PauseTreatmentCommand({
    super.rawBytes,
    super.type,
    super.timestamp,
    super.requiresAcknowledgment = false,
    super.priority = CommandPriority.normal,
    super.metadata,
  });

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    "runtimeType": "pauseTreatment",
    "rawBytes": rawBytes,
    "type": type?.toString(),
    "timestamp": timestamp?.toIso8601String(),
    "requiresAcknowledgment": requiresAcknowledgment,
    "priority": priority.toString(),
    "metadata": metadata,
  };

  factory PauseTreatmentCommand.fromJson(final Map<String, dynamic> json) =>
      PauseTreatmentCommand(
        rawBytes: (json["rawBytes"] as List<dynamic>?)?.cast<int>(),
        type: json["type"] != null
            ? CommandType.values.firstWhere(
                (final CommandType e) => e.toString() == json["type"],
              )
            : null,
        timestamp: json["timestamp"] != null
            ? DateTime.parse(json["timestamp"])
            : null,
        requiresAcknowledgment: json["requiresAcknowledgment"] ?? false,
        priority: _priorityFromString(json["priority"]),
        metadata: json["metadata"] as Map<String, dynamic>?,
      );
}

/// Resume Treatment Command
class ResumeTreatmentCommand extends BleCommand {
  ResumeTreatmentCommand({
    super.rawBytes,
    super.type,
    super.timestamp,
    super.requiresAcknowledgment = false,
    super.priority = CommandPriority.normal,
    super.metadata,
  });

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    "runtimeType": "resumeTreatment",
    "rawBytes": rawBytes,
    "type": type?.toString(),
    "timestamp": timestamp?.toIso8601String(),
    "requiresAcknowledgment": requiresAcknowledgment,
    "priority": priority.toString(),
    "metadata": metadata,
  };

  factory ResumeTreatmentCommand.fromJson(final Map<String, dynamic> json) =>
      ResumeTreatmentCommand(
        rawBytes: (json["rawBytes"] as List<dynamic>?)?.cast<int>(),
        type: json["type"] != null
            ? CommandType.values.firstWhere(
                (final CommandType e) => e.toString() == json["type"],
              )
            : null,
        timestamp: json["timestamp"] != null
            ? DateTime.parse(json["timestamp"])
            : null,
        requiresAcknowledgment: json["requiresAcknowledgment"] ?? false,
        priority: _priorityFromString(json["priority"]),
        metadata: json["metadata"] as Map<String, dynamic>?,
      );
}

/// Stop Command
class StopCommand extends BleCommand {
  StopCommand({
    super.rawBytes,
    super.type,
    super.timestamp,
    super.requiresAcknowledgment = false,
    super.priority = CommandPriority.high,
    super.metadata,
  });

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    "runtimeType": "stop",
    "rawBytes": rawBytes,
    "type": type?.toString(),
    "timestamp": timestamp?.toIso8601String(),
    "requiresAcknowledgment": requiresAcknowledgment,
    "priority": priority.toString(),
    "metadata": metadata,
  };

  factory StopCommand.fromJson(final Map<String, dynamic> json) => StopCommand(
    rawBytes: (json["rawBytes"] as List<dynamic>?)?.cast<int>(),
    type: json["type"] != null
        ? CommandType.values.firstWhere(
            (final CommandType e) => e.toString() == json["type"],
          )
        : null,
    timestamp: json["timestamp"] != null
        ? DateTime.parse(json["timestamp"])
        : null,
    requiresAcknowledgment: json["requiresAcknowledgment"] ?? false,
    priority: _priorityFromString(json["priority"]),
    metadata: json["metadata"] as Map<String, dynamic>?,
  );
}

/// Power Off Command
class PowerOffCommand extends BleCommand {
  PowerOffCommand({
    super.rawBytes,
    super.type,
    super.timestamp,
    super.requiresAcknowledgment = false,
    super.priority = CommandPriority.high,
    super.metadata,
  });

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    "runtimeType": "powerOff",
    "rawBytes": rawBytes,
    "type": type?.toString(),
    "timestamp": timestamp?.toIso8601String(),
    "requiresAcknowledgment": requiresAcknowledgment,
    "priority": priority.toString(),
    "metadata": metadata,
  };

  factory PowerOffCommand.fromJson(final Map<String, dynamic> json) =>
      PowerOffCommand(
        rawBytes: (json["rawBytes"] as List<dynamic>?)?.cast<int>(),
        type: json["type"] != null
            ? CommandType.values.firstWhere(
                (final CommandType e) => e.toString() == json["type"],
              )
            : null,
        timestamp: json["timestamp"] != null
            ? DateTime.parse(json["timestamp"])
            : null,
        requiresAcknowledgment: json["requiresAcknowledgment"] ?? false,
        priority: _priorityFromString(json["priority"]),
        metadata: json["metadata"] as Map<String, dynamic>?,
      );
}

/// Clear Event Command
class ClearEventCommand extends BleCommand {
  ClearEventCommand({
    super.rawBytes,
    super.type,
    super.timestamp,
    super.requiresAcknowledgment = false,
    super.priority = CommandPriority.normal,
    super.metadata,
  });

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    "runtimeType": "clearEvent",
    "rawBytes": rawBytes,
    "type": type?.toString(),
    "timestamp": timestamp?.toIso8601String(),
    "requiresAcknowledgment": requiresAcknowledgment,
    "priority": priority.toString(),
    "metadata": metadata,
  };

  factory ClearEventCommand.fromJson(final Map<String, dynamic> json) =>
      ClearEventCommand(
        rawBytes: (json["rawBytes"] as List<dynamic>?)?.cast<int>(),
        type: json["type"] != null
            ? CommandType.values.firstWhere(
                (final CommandType e) => e.toString() == json["type"],
              )
            : null,
        timestamp: json["timestamp"] != null
            ? DateTime.parse(json["timestamp"])
            : null,
        requiresAcknowledgment: json["requiresAcknowledgment"] ?? false,
        priority: _priorityFromString(json["priority"]),
        metadata: json["metadata"] as Map<String, dynamic>?,
      );
}

/// OTA Update Command
class OverTheAirUpdateCommand extends BleCommand {
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

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    "runtimeType": "overTheAirUpdate",
    "firmwareVersion": firmwareVersion,
    "rawBytes": rawBytes,
    "type": type?.toString(),
    "timestamp": timestamp?.toIso8601String(),
    "requiresAcknowledgment": requiresAcknowledgment,
    "priority": priority.toString(),
    "metadata": metadata,
  };

  factory OverTheAirUpdateCommand.fromJson(final Map<String, dynamic> json) =>
      OverTheAirUpdateCommand(
        firmwareVersion: json["firmwareVersion"],
        rawBytes: (json["rawBytes"] as List<dynamic>?)?.cast<int>(),
        type: json["type"] != null
            ? CommandType.values.firstWhere(
                (final CommandType e) => e.toString() == json["type"],
              )
            : null,
        timestamp: json["timestamp"] != null
            ? DateTime.parse(json["timestamp"])
            : null,
        requiresAcknowledgment: json["requiresAcknowledgment"] ?? false,
        priority: _priorityFromString(json["priority"]),
        metadata: json["metadata"] as Map<String, dynamic>?,
      );
}

/// Custom Command
class CustomCommand extends BleCommand {
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

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    "runtimeType": "custom",
    "commandName": commandName,
    "rawBytes": rawBytes,
    "type": type?.toString(),
    "timestamp": timestamp?.toIso8601String(),
    "requiresAcknowledgment": requiresAcknowledgment,
    "priority": priority.toString(),
    "metadata": metadata,
  };

  factory CustomCommand.fromJson(final Map<String, dynamic> json) =>
      CustomCommand(
        commandName: json["commandName"],
        rawBytes: (json["rawBytes"] as List<dynamic>?)?.cast<int>(),
        type: json["type"] != null
            ? CommandType.values.firstWhere(
                (final CommandType e) => e.toString() == json["type"],
              )
            : null,
        timestamp: json["timestamp"] != null
            ? DateTime.parse(json["timestamp"])
            : null,
        requiresAcknowledgment: json["requiresAcknowledgment"] ?? false,
        priority: _priorityFromString(json["priority"]),
        metadata: json["metadata"] as Map<String, dynamic>?,
      );
}

/// Metadata
class CommandMetadata {
  String? sessionId;
  String? userId;
  String? deviceId;
  Map<String, dynamic>? parameters;
  String? description;
  DateTime? expiresAt;
  int retryCount;
  int maxRetries;

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

  Map<String, dynamic> toJson() => <String, dynamic>{
    "sessionId": sessionId,
    "userId": userId,
    "deviceId": deviceId,
    "parameters": parameters,
    "description": description,
    "expiresAt": expiresAt?.toIso8601String(),
    "retryCount": retryCount,
    "maxRetries": maxRetries,
  };

  factory CommandMetadata.fromJson(final Map<String, dynamic> json) =>
      CommandMetadata(
        sessionId: json["sessionId"],
        userId: json["userId"],
        deviceId: json["deviceId"],
        parameters: json["parameters"] as Map<String, dynamic>?,
        description: json["description"],
        expiresAt: json["expiresAt"] != null
            ? DateTime.parse(json["expiresAt"])
            : null,
        retryCount: json["retryCount"] ?? 1,
        maxRetries: json["maxRetries"] ?? 3,
      );
}

/// Helper: Convert string to enum
CommandPriority _priorityFromString(final String? value) {
  if (value == null) return CommandPriority.normal;

  return CommandPriority.values.firstWhere(
    (final CommandPriority e) => e.toString() == value,

    orElse: () => CommandPriority.normal,
  );
}
