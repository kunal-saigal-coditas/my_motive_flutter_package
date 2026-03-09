import 'package:flutter/material.dart';
import 'package:my_motive_package/my_motive_library.dart';

class TherapyScreen extends StatefulWidget {
  final MotiveBleService bleService;

  const TherapyScreen({super.key, required this.bleService});

  @override
  State<TherapyScreen> createState() => _TherapyScreenState();
}

class _TherapyScreenState extends State<TherapyScreen> {
  late TherapyCommands _commands;

  bool _isTherapyActive = false;
  bool _isPaused = false;
  bool _isLoading = false;
  int _durationMinutes = 30;
  int _kneeLevel = 0;
  int _thighLevel = 0;

  @override
  void initState() {
    super.initState();
    _commands = TherapyCommands.fromService(widget.bleService);
  }

  Future<void> _executeCommand(Future<void> Function() command) async {
    setState(() => _isLoading = true);
    try {
      await command();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _startTherapy() async {
    await _executeCommand(() async {
      await _commands.sendStart(minutes: _durationMinutes);
      setState(() {
        _isTherapyActive = true;
        _isPaused = false;
      });
    });
  }

  Future<void> _stopTherapy() async {
    await _executeCommand(() async {
      await _commands.sendStop();
      setState(() {
        _isTherapyActive = false;
        _isPaused = false;
        _kneeLevel = 0;
        _thighLevel = 0;
      });
    });
  }

  Future<void> _pauseTherapy() async {
    await _executeCommand(() async {
      await _commands.sendPause();
      setState(() => _isPaused = true);
    });
  }

  Future<void> _resumeTherapy() async {
    await _executeCommand(() async {
      await _commands.sendResume();
      setState(() => _isPaused = false);
    });
  }

  Future<void> _changeLevel({int knee = 0, int thigh = 0}) async {
    await _executeCommand(() async {
      await _commands.sendChangeLevel(knee: knee, thigh: thigh);
      setState(() {
        _kneeLevel = (_kneeLevel + knee).clamp(0, 100);
        _thighLevel = (_thighLevel + thigh).clamp(0, 100);
      });
    });
  }

  Future<void> _zeroLevels() async {
    await _executeCommand(() async {
      await _commands.sendZeroLevels();
      setState(() {
        _kneeLevel = 0;
        _thighLevel = 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Therapy Control'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 16),
            if (!_isTherapyActive) _buildDurationSelector(),
            if (!_isTherapyActive) const SizedBox(height: 16),
            _buildSessionControls(),
            if (_isTherapyActive) const SizedBox(height: 16),
            if (_isTherapyActive) _buildStimulationControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              _isTherapyActive
                  ? (_isPaused ? Icons.pause_circle : Icons.play_circle)
                  : Icons.stop_circle,
              size: 64,
              color: _isTherapyActive
                  ? (_isPaused ? Colors.orange : Colors.green)
                  : Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              _isTherapyActive
                  ? (_isPaused ? 'Therapy Paused' : 'Therapy Active')
                  : 'Therapy Inactive',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (_isTherapyActive) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildLevelIndicator('Knee', _kneeLevel),
                  _buildLevelIndicator('Thigh', _thighLevel),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLevelIndicator(String label, int level) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
          child: Center(
            child: Text(
              '$level',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session Duration',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _durationMinutes.toDouble(),
                    min: 5,
                    max: 60,
                    divisions: 11,
                    label: '$_durationMinutes min',
                    onChanged: (value) {
                      setState(() => _durationMinutes = value.toInt());
                    },
                  ),
                ),
                Container(
                  width: 80,
                  alignment: Alignment.center,
                  child: Text(
                    '$_durationMinutes min',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session Controls',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (!_isTherapyActive)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _startTherapy,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow),
                  label: const Text('Start Therapy'),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _isPaused
                        ? FilledButton.icon(
                            onPressed: _isLoading ? null : _resumeTherapy,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Resume'),
                          )
                        : FilledButton.tonalIcon(
                            onPressed: _isLoading ? null : _pauseTherapy,
                            icon: const Icon(Icons.pause),
                            label: const Text('Pause'),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _stopTherapy,
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStimulationControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stimulation Controls',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildChannelControl(
                    'Knee',
                    _kneeLevel,
                    onIncrease: () => _changeLevel(knee: 5),
                    onDecrease: () => _changeLevel(knee: -5),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildChannelControl(
                    'Thigh',
                    _thighLevel,
                    onIncrease: () => _changeLevel(thigh: 5),
                    onDecrease: () => _changeLevel(thigh: -5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => _changeLevel(knee: 5, thigh: 5),
                    icon: const Icon(Icons.add),
                    label: const Text('Both +5'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => _changeLevel(knee: -5, thigh: -5),
                    icon: const Icon(Icons.remove),
                    label: const Text('Both -5'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _isLoading ? null : _zeroLevels,
                icon: const Icon(Icons.exposure_zero),
                label: const Text('Zero All Levels'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelControl(
    String label,
    int level, {
    required VoidCallback onIncrease,
    required VoidCallback onDecrease,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            '$level',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filled(
                onPressed: _isLoading ? null : onDecrease,
                icon: const Icon(Icons.remove),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _isLoading ? null : onIncrease,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
