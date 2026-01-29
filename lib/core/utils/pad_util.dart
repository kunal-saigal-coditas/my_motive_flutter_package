import 'package:my_motive_package/core/enum/motive_enums.dart';

/// Utility class for managing therapy pad life calculations and updates
abstract class PadUtil {
  /// Maximum pad lifetime in seconds (8 hours = 28,800 seconds)
  /// Matching MAX_LIFETIME_SECONDS from React Native
  static const int maxLifetimeSeconds = 28800;

  /// Warning threshold percentage (15%)
  static const int warningThreshold = 15;

  /// Calculates remaining pad life percentage
  /// Based on lifetimeHelpers.lifetimePercentUsage from React Native
  static double calculateRemainingLifePercentage(final int usageSeconds) {
    if (usageSeconds >= maxLifetimeSeconds) {
      return 0.0;
    }

    // Formula: 100 - ((usageSeconds * 100) / maxLifetimeSeconds)
    final double usagePercentage = (usageSeconds * 100.0) / maxLifetimeSeconds;
    final double remainingPercentage = 100.0 - usagePercentage;

    // Round to match React Native .toFixed() behavior
    return double.tryParse(remainingPercentage.toStringAsFixed(0)) ?? 0.0;
  }

  /// Checks if threshold warning is reached
  /// Based on getIsThresholdReached from React Native
  static bool isThresholdReached(final int usageSeconds) {
    final double remainingPercentage = calculateRemainingLifePercentage(
      usageSeconds,
    );

    return remainingPercentage < warningThreshold;
  }

  /// Formats remaining time as human-readable string
  static String formatRemainingTime(final int remainingSeconds) {
    if (remainingSeconds <= 0) {
      return '0h 0m';
    }

    final int hours = remainingSeconds ~/ 3600;
    final int minutes = (remainingSeconds % 3600) ~/ 60;

    return '${hours}h ${minutes}m';
  }

  /// Updates pad life after therapy completion using Map {TherapyPadType, int}
  /// This is the main function that handles all pad life logic
  ///
  /// Parameters:
  /// - [padType]: The type of therapy pad being used
  /// - [previousUsageSeconds]: Current usage map for the pad
  /// - [therapyDurationSeconds]: Duration of completed therapy in seconds
  /// - [onUsageUpdate]: Callback to update usage in storage
  ///
  /// Returns: [PadLifeResult] with all calculated values
  static Future<Map<TherapyPadType, int>> updatePadLife({
    required final TherapyPadType padType,
    required final int therapyDurationSeconds,
    required final int previousUsageSeconds,
    required final Future<void> Function(Map<TherapyPadType, int> updatedUsage)
    onUsageUpdate,
  }) async {
    // Validate inputs
    if (therapyDurationSeconds < 0) {
      throw ArgumentError(
        'Therapy duration cannot be negative: $therapyDurationSeconds',
      );
    }

    // Calculate new usage
    final int newUsageSeconds = previousUsageSeconds + therapyDurationSeconds;

    // Ensure usage doesn't exceed maximum
    final int cappedUsageSeconds = newUsageSeconds.clamp(0, maxLifetimeSeconds);

    // Calculate life percentages and thresholds
    final double remainingLifePercentage = calculateRemainingLifePercentage(
      cappedUsageSeconds,
    );

    return <TherapyPadType, int>{padType: remainingLifePercentage.round()};
  }

  /// Checks if any pads need replacement (convenience method)
  static List<TherapyPadType> checkPadsNeedingReplacement(
    final Map<TherapyPadType, int> usage,
  ) {
    final List<TherapyPadType> needReplacement = <TherapyPadType>[];

    for (final MapEntry<TherapyPadType, int> entry in usage.entries) {
      final TherapyPadType padType = entry.key;
      final int usageSeconds = entry.value;

      if (isThresholdReached(usageSeconds)) {
        needReplacement.add(padType);
      }
    }

    return needReplacement;
  }

  /// Gets pad life summary for all pad types
  static Map<TherapyPadType, Map<String, dynamic>> getPadLifeSummary(
    final Map<TherapyPadType, int> usage,
  ) {
    final Map<TherapyPadType, Map<String, dynamic>> summary =
        <TherapyPadType, Map<String, dynamic>>{};

    for (final MapEntry<TherapyPadType, int> entry in usage.entries) {
      final TherapyPadType padType = entry.key;
      final int usageSeconds = entry.value;

      final double remainingPercentage = calculateRemainingLifePercentage(
        usageSeconds,
      );
      final bool thresholdReached = isThresholdReached(usageSeconds);
      final int remainingSeconds = (maxLifetimeSeconds - usageSeconds).clamp(
        0,
        maxLifetimeSeconds,
      );

      summary[padType] = <String, dynamic>{
        'usageSeconds': usageSeconds,
        'remainingPercentage': remainingPercentage,
        'thresholdReached': thresholdReached,
        'isExpired': usageSeconds >= maxLifetimeSeconds,
        'remainingTime': formatRemainingTime(remainingSeconds),
        'padType': padType.displayName,
      };
    }

    return summary;
  }

  /// Creates a sample usage map for testing
  static Map<TherapyPadType, int> createSampleUsage({
    final int leftKneeUsage = 0,
    final int rightKneeUsage = 0,
    final int backLowerUsage = 0,
  }) {
    return <TherapyPadType, int>{
      TherapyPadType.leftKnee: leftKneeUsage,
      TherapyPadType.rightKnee: rightKneeUsage,
      TherapyPadType.backLower: backLowerUsage,
    };
  }

  /// Gets usage for a specific pad type with default value
  static int getUsageForPadType(
    final Map<TherapyPadType, int> usage,
    final TherapyPadType padType,
  ) {
    return usage[padType] ?? 0;
  }

  /// Updates usage for a specific pad type
  static Map<TherapyPadType, int> updateUsageForPadType(
    final Map<TherapyPadType, int> currentUsage,
    final TherapyPadType padType,
    final int newUsageSeconds,
  ) {
    final Map<TherapyPadType, int> updatedUsage = Map<TherapyPadType, int>.from(
      currentUsage,
    );

    updatedUsage[padType] = newUsageSeconds.clamp(0, maxLifetimeSeconds);

    return updatedUsage;
  }
}
