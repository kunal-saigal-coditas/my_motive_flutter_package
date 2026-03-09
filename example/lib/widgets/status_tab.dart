import 'package:flutter/material.dart';
import 'package:my_motive_package/my_motive_library.dart';

class StatusTab extends StatelessWidget {
  final DeviceStatus? status;

  const StatusTab({super.key, this.status});

  @override
  Widget build(BuildContext context) {
    if (status == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Waiting for device status...'),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildBatteryCard(context),
        const SizedBox(height: 12),
        _buildStimulationCard(context),
        const SizedBox(height: 12),
        _buildDeviceStateCard(context),
        const SizedBox(height: 12),
        _buildContactCard(context),
      ],
    );
  }

  Widget _buildBatteryCard(BuildContext context) {
    final batteryLevel = status!.batteryLevel;
    final isCharging = status!.isCharging;

    Color batteryColor;
    if (batteryLevel > 50) {
      batteryColor = Colors.green;
    } else if (batteryLevel > 20) {
      batteryColor = Colors.orange;
    } else {
      batteryColor = Colors.red;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCharging ? Icons.battery_charging_full : Icons.battery_std,
                  color: batteryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Battery',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: batteryLevel / 100,
                      minHeight: 20,
                      backgroundColor: Colors.grey.withAlpha(51),
                      valueColor: AlwaysStoppedAnimation(batteryColor),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$batteryLevel%',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            if (isCharging)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.bolt, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Charging',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.amber,
                          ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStimulationCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.electric_bolt),
                const SizedBox(width: 8),
                Text(
                  'Stimulation Levels',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildLevelMeter(
                    context,
                    'Knee',
                    status!.kneeStimLevel,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildLevelMeter(
                    context,
                    'Thigh',
                    status!.thighStimLevel,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelMeter(BuildContext context, String label, int level) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).colorScheme.primary,
              width: 4,
            ),
          ),
          child: Center(
            child: Text(
              '$level',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceStateCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings),
                const SizedBox(width: 8),
                Text(
                  'Device State',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatusRow(
              context,
              'Controller',
              status!.controllerStatus,
            ),
            _buildStatusRow(
              context,
              'Sheet',
              status!.sheetStatus.toString().split('.').last,
            ),
            _buildStatusRow(
              context,
              'Temperature',
              '${status!.temperature}°C',
            ),
            _buildStatusRow(
              context,
              'Stim Index',
              '${status!.stimIndex}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.touch_app),
                const SizedBox(width: 8),
                Text(
                  'Skin Contact',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildContactIndicator(
                    context,
                    'Left',
                    status!.leftSkinContact,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildContactIndicator(
                    context,
                    'Right',
                    status!.rightSkinContact,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactIndicator(
      BuildContext context, String label, bool contact) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: contact ? Colors.green.withAlpha(26) : Colors.red.withAlpha(26),
      ),
      child: Column(
        children: [
          Icon(
            contact ? Icons.check_circle : Icons.cancel,
            color: contact ? Colors.green : Colors.red,
            size: 32,
          ),
          const SizedBox(height: 4),
          Text(label),
          Text(
            contact ? 'Connected' : 'No Contact',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: contact ? Colors.green : Colors.red,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
