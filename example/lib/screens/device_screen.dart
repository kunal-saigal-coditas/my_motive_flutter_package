import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:my_motive_package/my_motive_library.dart';
import 'package:motive_example/screens/therapy_screen.dart';
import 'package:motive_example/widgets/device_list_tile.dart';
import 'package:motive_example/widgets/status_tab.dart';
import 'package:motive_example/widgets/product_info_tab.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen>
    with SingleTickerProviderStateMixin {
  final MotiveBleService _bleService = MotiveBleService();

  late TabController _tabController;

  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  bool _isConnected = false;
  String? _connectedDeviceName;

  StreamSubscription<DeviceStatus>? _statusSubscription;

  DeviceStatus? _deviceStatus;
  ProductInfo? _productInfo;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkPermissions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _statusSubscription?.cancel();
    _bleService.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    // Request all required permissions (Bluetooth + Location for Android)
    final permissions = await PermissionService.requestRequiredPermissions();

    final allGranted = permissions.values.every((granted) => granted);

    if (!allGranted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Permissions required: ${permissions.entries.where((e) => !e.value).map((e) => e.key).join(", ")}',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _startScan() async {
    if (_isScanning) return;

    debugPrint('[Scan] Starting scan...');

    // Check if Bluetooth is on
    final adapterState = await FlutterBluePlus.adapterState.first;
    debugPrint('[Scan] Bluetooth adapter state: $adapterState');

    if (adapterState != BluetoothAdapterState.on) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please turn on Bluetooth'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Turn On',
              onPressed: () => FlutterBluePlus.turnOn(),
            ),
          ),
        );
      }
      return;
    }

    setState(() {
      _isScanning = true;
      _scanResults = [];
    });

    try {
      // Set up listener BEFORE starting scan
      final subscription = FlutterBluePlus.scanResults.listen((results) {
        debugPrint('[Scan] Found ${results.length} total BLE devices');

        if (mounted) {
          // Filter ONLY Motive devices by name
          final motiveDevices = results.where((r) {
            // Check if device name contains "motive" (case-insensitive)
            final isMotiveDevice =
                r.device.platformName.toLowerCase().contains('motive');

            if (isMotiveDevice) {
              debugPrint('[Scan] ✓ MOTIVE DEVICE: ${r.device.platformName} '
                  '(${r.device.remoteId}) RSSI: ${r.rssi}');
            }

            return isMotiveDevice;
          }).toList();

          // Sort by signal strength
          motiveDevices.sort((a, b) => b.rssi.compareTo(a.rssi));

          setState(() => _scanResults = motiveDevices);
          debugPrint('[Scan] Found ${motiveDevices.length} Motive device(s)');
        }
      });

      debugPrint('[Scan] Starting scan for Motive devices...');

      // Scan for all devices, filter by name
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        androidUsesFineLocation: true,
      );

      debugPrint('[Scan] Scan started, waiting 15 seconds...');

      // Wait for scan to complete
      await Future.delayed(const Duration(seconds: 15));

      await subscription.cancel();
      debugPrint('[Scan] Scan complete. Found ${_scanResults.length} devices');
    } catch (e, stack) {
      debugPrint('[Scan] Error: $e');
      debugPrint('[Scan] Stack: $stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scan error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      await FlutterBluePlus.stopScan();
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  Future<void> _connectToDevice(ScanResult result) async {
    setState(() => _isScanning = true);

    try {
      // Connect to the device first
      await result.device.connect();

      // Get manufacturer data
      final manufacturerData = result.advertisementData.manufacturerData;
      final List<int> mfrData =
          manufacturerData.isNotEmpty ? manufacturerData.values.first : <int>[];

      // Initialize BLE service
      await _bleService.initialize(
        device: result.device,
        manufacturerData: mfrData,
      );

      _statusSubscription = _bleService.statusStream.listen((status) {
        if (mounted) {
          setState(() => _deviceStatus = status);
        }
      });

      await _bleService.startStatusStream();

      // One-time read of product info
      final info = await _bleService.readProductInfo();
      if (mounted) {
        setState(() => _productInfo = info);
      }

      if (mounted) {
        setState(() {
          _isConnected = true;
          _connectedDeviceName = result.device.platformName;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to ${result.device.platformName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  Future<void> _disconnect() async {
    await _statusSubscription?.cancel();
    await _bleService.dispose();

    if (mounted) {
      setState(() {
        _isConnected = false;
        _connectedDeviceName = null;
        _deviceStatus = null;
        _productInfo = null;
      });
    }
  }

  void _navigateToTherapy() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TherapyScreen(bleService: _bleService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Motive Device'),
        actions: [
          if (_isConnected)
            IconButton(
              icon: const Icon(Icons.medical_services),
              tooltip: 'Therapy Controls',
              onPressed: _navigateToTherapy,
            ),
        ],
        bottom: _isConnected
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.monitor_heart), text: 'Status'),
                  Tab(icon: Icon(Icons.info_outline), text: 'Product Info'),
                ],
              )
            : null,
      ),
      body: _isConnected ? _buildConnectedView() : _buildScanView(),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildScanView() {
    if (_isScanning) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Scanning for Motive devices...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${_scanResults.length} Motive device(s) found',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      );
    }

    if (_scanResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bluetooth_searching,
                size: 80,
                color: Theme.of(context).colorScheme.primary.withAlpha(128),
              ),
              const SizedBox(height: 16),
              Text(
                'No Motive devices found',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Troubleshooting:',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      const Text('• Ensure Bluetooth is turned ON'),
                      const Text('• Power ON your Motive therapy device'),
                      const Text('• Move closer to the Motive device'),
                      const Text('• Grant location permission (Android)'),
                      const Text('• Disconnect device from other apps'),
                      const Text('• Try restarting the Motive device'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _scanResults.length,
      itemBuilder: (context, index) {
        final result = _scanResults[index];

        return DeviceListTile(
          result: result,
          onTap: () => _connectToDevice(result),
        );
      },
    );
  }

  Widget _buildConnectedView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Row(
            children: [
              const Icon(Icons.bluetooth_connected, color: Colors.green),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _connectedDeviceName ?? 'Unknown Device',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Connected',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.green,
                          ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _disconnect,
                icon: const Icon(Icons.link_off, size: 18),
                label: const Text('Disconnect'),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              StatusTab(status: _deviceStatus),
              ProductInfoTab(productInfo: _productInfo),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFAB() {
    if (_isConnected) {
      return FloatingActionButton.extended(
        onPressed: _navigateToTherapy,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start Therapy'),
      );
    }

    return FloatingActionButton.extended(
      onPressed: _isScanning ? null : _startScan,
      icon: _isScanning
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.search),
      label: Text(_isScanning ? 'Scanning...' : 'Scan for Motive'),
    );
  }
}
