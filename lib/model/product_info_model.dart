import 'package:my_motive_package/mappers/product_info_mapper.dart';

/// Represents product/firmware information from a Motive device.
///
/// This model contains version information about the connected device's
/// firmware, useful for compatibility checks and support diagnostics.
///
/// ## Example
///
/// ```dart
/// bleService.productInfoStream.listen((info) {
///   print('Firmware: ${info.firmwareVersion}');
///   print('Version: ${info.major}.${info.minor}.${info.release}.${info.build}');
///   
///   if (!info.meetsMinimumVersion('2.0.0')) {
///     showUpdatePrompt();
///   }
/// });
/// ```
class ProductInfo {
  /// Major version number (significant/breaking changes).
  final int major;

  /// Minor version number (feature additions).
  final int minor;

  /// Release number (bug fixes/patches).
  final int release;

  /// Build number (internal tracking).
  final int build;

  /// Formatted firmware version string (e.g., "01.02.03.04").
  final String firmwareVersion;

  /// Raw data from the device (for debugging or advanced use).
  final List<int> rawData;

  const ProductInfo({
    required this.major,
    required this.minor,
    required this.release,
    required this.build,
    required this.firmwareVersion,
    this.rawData = const [],
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Convenience Getters
  // ═══════════════════════════════════════════════════════════════════════════

  /// Short version string without build (e.g., "1.2.3").
  String get shortVersion => '$major.$minor.$release';

  /// Whether the firmware version is known/valid.
  bool get isKnown => firmwareVersion != 'Unknown' && major > 0;

  // ═══════════════════════════════════════════════════════════════════════════
  // Version Comparison
  // ═══════════════════════════════════════════════════════════════════════════

  /// Checks if the firmware version meets a minimum requirement.
  ///
  /// The [minVersion] should be in format "major.minor.release" or
  /// "major.minor" or just "major".
  ///
  /// Example:
  /// ```dart
  /// if (info.meetsMinimumVersion('2.0.0')) {
  ///   // Feature available in 2.0.0+
  /// }
  /// ```
  bool meetsMinimumVersion(String minVersion) {
    final parts = minVersion.split('.').map(int.tryParse).toList();
    
    final minMajor = parts.isNotEmpty ? (parts[0] ?? 0) : 0;
    final minMinor = parts.length > 1 ? (parts[1] ?? 0) : 0;
    final minRelease = parts.length > 2 ? (parts[2] ?? 0) : 0;

    if (major > minMajor) return true;
    if (major < minMajor) return false;
    
    if (minor > minMinor) return true;
    if (minor < minMinor) return false;
    
    return release >= minRelease;
  }

  /// Compares this version with another.
  /// Returns: negative if this < other, 0 if equal, positive if this > other.
  int compareTo(ProductInfo other) {
    if (major != other.major) return major - other.major;
    if (minor != other.minor) return minor - other.minor;
    if (release != other.release) return release - other.release;
    return build - other.build;
  }

  /// Whether this version is newer than [other].
  bool isNewerThan(ProductInfo other) => compareTo(other) > 0;

  /// Whether this version is older than [other].
  bool isOlderThan(ProductInfo other) => compareTo(other) < 0;

  /// Whether this version equals [other] (ignoring build number).
  bool isSameVersion(ProductInfo other) =>
      major == other.major && minor == other.minor && release == other.release;

  // ═══════════════════════════════════════════════════════════════════════════
  // Factory Constructors
  // ═══════════════════════════════════════════════════════════════════════════

  /// Creates an unknown/default product info (used when no data is available).
  factory ProductInfo.unknown() => const ProductInfo(
    major: 0,
    minor: 0,
    release: 0,
    build: 0,
    firmwareVersion: 'Unknown',
  );

  /// Creates a [ProductInfo] from raw BLE data bytes.
  ///
  /// This factory method handles all byte parsing internally using
  /// [ProductInfoMapper], so consumers don't need to understand
  /// the raw data format.
  ///
  /// Example:
  /// ```dart
  /// final info = ProductInfo.fromRawData(rawBytes);
  /// print('Firmware: ${info.firmwareVersion}');
  /// ```
  factory ProductInfo.fromRawData(List<int> data) {
    if (data.isEmpty) return ProductInfo.unknown();

    final parsed = ProductInfoMapper.parseProductInfo(data);
    return ProductInfo(
      major: parsed.major,
      minor: parsed.minor,
      release: parsed.release,
      build: parsed.build,
      firmwareVersion: parsed.firmwareVersion,
      rawData: data,
    );
  }

  /// Creates a [ProductInfo] from version components.
  factory ProductInfo.fromVersion({
    required int major,
    required int minor,
    required int release,
    int build = 0,
  }) {
    final firmwareVersion =
        '${major.toString().padLeft(2, '0')}.'
        '${minor.toString().padLeft(2, '0')}.'
        '${release.toString().padLeft(2, '0')}.'
        '${build.toString().padLeft(2, '0')}';

    return ProductInfo(
      major: major,
      minor: minor,
      release: release,
      build: build,
      firmwareVersion: firmwareVersion,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Copy With
  // ═══════════════════════════════════════════════════════════════════════════

  /// Creates a copy with updated values.
  ProductInfo copyWith({
    int? major,
    int? minor,
    int? release,
    int? build,
    String? firmwareVersion,
    List<int>? rawData,
  }) {
    return ProductInfo(
      major: major ?? this.major,
      minor: minor ?? this.minor,
      release: release ?? this.release,
      build: build ?? this.build,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      rawData: rawData ?? this.rawData,
    );
  }

  @override
  String toString() => 'ProductInfo(firmware: $firmwareVersion)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductInfo &&
          runtimeType == other.runtimeType &&
          major == other.major &&
          minor == other.minor &&
          release == other.release &&
          build == other.build;

  @override
  int get hashCode =>
      major.hashCode ^ minor.hashCode ^ release.hashCode ^ build.hashCode;
}
