import 'package:flutter/material.dart';
import 'package:kiosk_payment/kiosk_payment.dart';
import 'payment_screen.dart';
import '../widgets/build_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/device_tile.dart';

class DeviceListScreen extends StatefulWidget {
  const DeviceListScreen({super.key});

  @override
  State<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  // We keep the instance here and pass it to the next screen.
  final KioskPayment _kioskPayment = KioskPayment();
  
  List<PaymentDevice> _devices = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    _initPlatformState();
  }

  Future<void> _initPlatformState() async {
    String platformVersion;
    try {
      platformVersion = await _kioskPayment.getPlatformVersion() ??
          'Unknown platform version';
    } catch (e) {
      platformVersion = 'Failed to get platform version.';
    }

    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Future<void> _discoverDevices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _devices = []; // Clear previous list
    });

    try {
      final devices = await _kioskPayment.discoverDevices();
      setState(() {
        _devices = devices;
      });
      if (devices.isEmpty) {
        setState(() {
          _errorMessage = "No devices found.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to discover devices: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onDeviceSelected(PaymentDevice device) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          kioskPayment: _kioskPayment,
          device: device,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainerHighest,
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                pinned: true,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'Select Device',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primaryContainer.withOpacity(0.5),
                          colorScheme.secondaryContainer.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Platform Info
                    BuildCard(
                      child: ListTile(
                        leading: Icon(Icons.info_outline,
                            color: colorScheme.primary),
                        title: const Text('Platform Version'),
                        subtitle: Text(_platformVersion),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Search Button
                    BuildCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: GradientButton(
                          onPressed: _isLoading ? null : _discoverDevices,
                          icon: Icons.search,
                          label: 'Search Devices',
                          colors: [
                            colorScheme.primary,
                            colorScheme.secondary,
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Error Message
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: BuildCard(
                          color: colorScheme.errorContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline,
                                    color: colorScheme.error),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(color: colorScheme.error),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Device List
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_devices.isNotEmpty)
                      ..._devices.map((device) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: DeviceTile(
                              device: device,
                              onTap: () => _onDeviceSelected(device),
                            ),
                          )),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
