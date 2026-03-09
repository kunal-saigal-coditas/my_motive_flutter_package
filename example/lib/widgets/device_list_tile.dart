import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DeviceListTile extends StatelessWidget {
  final ScanResult result;
  final VoidCallback onTap;

  const DeviceListTile({
    super.key,
    required this.result,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final deviceName = result.device.platformName.isNotEmpty
        ? result.device.platformName
        : 'Unknown Device';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.bluetooth,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          deviceName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.device.remoteId.str,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildSignalIndicator(context, result.rssi),
                const SizedBox(width: 8),
                Text(
                  '${result.rssi} dBm',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        trailing: FilledButton(
          onPressed: onTap,
          child: const Text('Connect'),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
      ),
    );
  }

  Widget _buildSignalIndicator(BuildContext context, int rssi) {
    final Color color;
    final int bars;

    if (rssi >= -60) {
      color = Colors.green;
      bars = 4;
    } else if (rssi >= -70) {
      color = Colors.lightGreen;
      bars = 3;
    } else if (rssi >= -80) {
      color = Colors.orange;
      bars = 2;
    } else {
      color = Colors.red;
      bars = 1;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        return Container(
          width: 4,
          height: 8 + (index * 3).toDouble(),
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: index < bars ? color : Colors.grey.withAlpha(77),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
