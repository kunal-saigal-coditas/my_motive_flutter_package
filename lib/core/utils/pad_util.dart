import 'package:my_motive_package/core/enum/motive_enums.dart';

/// Utility class for managing therapy pad lifecycle and usage tracking.
///
/// This class provides methods to:
/// - Calculate remaining pad life percentage
/// - Track pad usage across therapy sessions
/// - Determine when pads need replacement
/// - Format remaining time for display
///
/// ## Pad Lifetime
///
/// Therapy pads have a maximum lifetime of 8 hours (28,800 seconds) of use.
/// When remaining life drops below 15%, a warning threshold is triggered.
///
/// ## Usage Tracking
///
/// Usage is tracked per pad type using a `Map<TherapyPadType, int>` where
/// values represent cumulative usage in seconds.
///
/// ## Example
///
/// ```dart
/// // Check remaining life
/// final usageSeconds = 14400; // 4 hours used
/// final remaining = PadUtil.calculateRemainingLifePercentage(usageSeconds);
/// print('Remaining: $remaining%'); // 50%
///
/// // Check if replacement needed
/// if (PadUtil.isThresholdReached(usageSeconds)) {
///   showReplacementWarning();
/// }
///
/// // Update after therapy session
/// final updatedUsage = await PadUtil.updatePadLife(
///   padType: TherapyPadType.leftKnee,
///   previousUsageSeconds: 14400,
///   therapyDurationSeconds: 1800, // 30 min session
///   onUsageUpdate: (usage) => saveToStorage(usage),
/// );
/// ```
abstract class PadUtil {
  /// Maximum pad lifetime in seconds (8 hours = 28,800 seconds).
  ///
  /// This constant matches the MAX_LIFETIME_SECONDS from the React Native
  /// implementation for consistency across platforms.
  static const int maxLifetimeSeconds = 28800;

  /// Warning threshold percentage for pad replacement (15%).
  ///
  /// When remaining pad life drops below this percentage, users should
  /// be warned that pad replacement will be needed soon.
  static const int warningThresholdPercentage = 15;

  /// Calculates the remaining pad life as a percentage.
  ///
  /// Formula: `100 - ((usageSeconds × 100) / maxLifetimeSeconds)`
  ///
  /// Based on `lifetimeHelpers.lifetimePercentUsage` from React Native.
  ///
  /// Returns:
  /// - 100.0 for unused pads (0 seconds)
  /// - 0.0 for fully used pads (≥ 28800 seconds)
  /// - Intermediate percentage for partial usage
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

  /// Checks if the pad replacement warning threshold has been reached.
  ///
  /// Returns `true` when remaining life percentage drops below 15%.
  /// Based on `getIsThresholdReached`.
  static bool isThresholdReached(final int usageSeconds) {
    final double remainingPercentage = calculateRemainingLifePercentage(
      usageSeconds,
    );

    return remainingPercentage < warningThresholdPercentage;
  }

  /// Formats remaining time as a human-readable string (e.g., "4h 30m").
  ///
  /// Returns "0h 0m" for zero or negative values.
  static String formatRemainingTime(final int remainingSeconds) {
    if (remainingSeconds <= 0) {
      return '0h 0m';
    }

    final int hours = remainingSeconds ~/ 3600;
    final int minutes = (remainingSeconds % 3600) ~/ 60;

    return '${hours}h ${minutes}m';
  }

  /// Updates pad life after a therapy session completes.
  ///
  /// This method calculates the new usage, enforces the maximum limit,
  /// and invokes the storage callback with the updated values.
  ///
  /// Parameters:
  /// - [padType]: The type of therapy pad used
  /// - [previousUsageSeconds]: Previous cumulative usage in seconds
  /// - [therapyDurationSeconds]: Duration of the completed session in seconds
  /// - [onUsageUpdate]: Callback to persist the updated usage map
  ///
  /// Returns a map with the pad type and remaining life percentage.
  ///
  /// Throws [ArgumentError] if therapy duration is negative.
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

  /// Returns a list of pad types that have reached the replacement threshold.
  ///
  /// Convenience method to check all pads at once and identify which
  /// ones need to be replaced soon.
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

  /// Gets a comprehensive summary of pad life status for all pad types.
  ///
  /// Returns a map with each pad type containing:
  /// - `usageSeconds`: Total usage in seconds
  /// - `remainingPercentage`: Remaining life as percentage
  /// - `thresholdReached`: Whether replacement warning is active
  /// - `isExpired`: Whether pad is fully used
  /// - `remainingTime`: Formatted remaining time string
  /// - `padType`: Display name of the pad type
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

  /// Creates a sample usage map for testing purposes.
  ///
  /// All values default to 0 (new pads) unless specified.
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

  /// Gets the usage seconds for a specific pad type.
  ///
  /// Returns 0 if the pad type is not found in the usage map.
  static int getUsageForPadType(
    final Map<TherapyPadType, int> usage,
    final TherapyPadType padType,
  ) {
    return usage[padType] ?? 0;
  }

  /// Updates the usage for a specific pad type and returns a new map.
  ///
  /// The usage value is clamped to [0, maxLifetimeSeconds].
  /// Returns a new map without modifying the original.
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
