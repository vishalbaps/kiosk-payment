import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kiosk_payment/kiosk_payment.dart';
import '../bloc/payment_bloc.dart';
import '../bloc/payment_event.dart';
import '../bloc/payment_state.dart';
import 'payment_screen.dart';
import '../widgets/build_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/device_tile.dart';

class DeviceListScreen extends StatelessWidget {
  const DeviceListScreen({super.key});

  void _onDeviceSelected(BuildContext context, PaymentDevice device) {
    context.read<PaymentBloc>().add(SelectDeviceEvent(device));
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PaymentScreen(),
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
          child: BlocConsumer<PaymentBloc, PaymentState>(
            listener: (context, state) {
              if (state.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.errorMessage!)),
                );
              }
            },
            builder: (context, state) {
              return CustomScrollView(
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
                        // Search Button
                        BuildCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: GradientButton(
                              onPressed: state.isScanning
                                  ? null
                                  : () {
                                      context
                                          .read<PaymentBloc>()
                                          .add(SearchDevicesEvent());
                                    },
                              icon: Icons.search,
                              label: state.isScanning
                                  ? 'Scanning...'
                                  : 'Search Devices',
                              colors: [
                                colorScheme.primary,
                                colorScheme.secondary,
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Error Message
                        if (state.errorMessage != null)
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
                                        state.errorMessage!,
                                        style:
                                            TextStyle(color: colorScheme.error),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // Device List
                        if (state.isScanning && state.devices.isEmpty)
                          const Center(
                              child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ))
                        else if (state.devices.isNotEmpty)
                          ...state.devices.map((device) => Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: DeviceTile(
                                  device: device,
                                  onTap: () =>
                                      _onDeviceSelected(context, device),
                                ),
                              )),
                      ]),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
