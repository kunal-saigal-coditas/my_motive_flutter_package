/// Mapper for parsing raw BLE product info data.
/// Centralizes byte parsing logic that was previously in the presentation layer.
class ProductInfoMapper {
  /// Parse firmware version from raw BLE data
  /// Format: major.minor.release.build (each as 2-digit padded)
  static ProductInfoData parse(final List<int> data) {
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

/// Structured representation of parsed product info
class ProductInfoData {
  final int major;
  final int minor;
  final int release;
  final int build;
  final String firmwareVersion;

  const ProductInfoData({
    required this.major,
    required this.minor,
    required this.release,
    required this.build,
    required this.firmwareVersion,
  });
}
