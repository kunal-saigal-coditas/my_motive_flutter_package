/// Mapper for parsing product information from raw BLE data.
///
/// This mapper extracts firmware version and other product details
/// from the product info characteristic data.
///
/// ## Data Format
///
/// Product info is stored starting at byte 9:
/// - Byte 9: Major version
/// - Byte 10: Minor version
/// - Byte 11: Release number
/// - Byte 12: Build number
///
/// ## Example
///
/// ```dart
/// final data = await bleService.readProductInfo();
/// if (data != null) {
///   final info = ProductInfoMapper.parse(data);
///   print('Firmware: ${info.firmwareVersion}'); // e.g., "01.02.03.04"
/// }
/// ```
class ProductInfoMapper {
  /// Parses firmware version from raw BLE product info data.
  ///
  /// Extracts version components from bytes 9-12 and formats them
  /// as a version string: "major.minor.release.build" with zero-padding.
  ///
  /// Returns a default [ProductInfoData] with "Unknown" firmware version
  /// if the data is insufficient (< 13 bytes).
  static ProductInfoData parseProductInfo(final List<int> data) {
    if (data.length < 13) {
      return const ProductInfoData(
        major: 0,
        minor: 0,
        release: 0,
        build: 0,
        firmwareVersion: 'Unknown',
      );
    }

    final int major = data[9];
    final int minor = data[10];
    final int release = data[11];
    final int build = data[12];

    final String firmwareVersion =
        '${major.toString().padLeft(2, '0')}.'
        '${minor.toString().padLeft(2, '0')}.'
        '${release.toString().padLeft(2, '0')}.'
        '${build.toString().padLeft(2, '0')}';

    return ProductInfoData(
      major: major,
      minor: minor,
      release: release,
      build: build,
      firmwareVersion: firmwareVersion,
    );
  }
}

/// Structured representation of parsed product information.
///
/// Contains the firmware version components and a formatted version string.
class ProductInfoData {
  /// Major version number (significant changes).
  final int major;

  /// Minor version number (feature additions).
  final int minor;

  /// Release number (bug fixes).
  final int release;

  /// Build number (internal tracking).
  final int build;

  /// Formatted firmware version string (e.g., "01.02.03.04").
  final String firmwareVersion;

  /// Creates a new [ProductInfoData] with the specified version components.
  const ProductInfoData({
    required this.major,
    required this.minor,
    required this.release,
    required this.build,
    required this.firmwareVersion,
  });
}
