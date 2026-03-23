import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kiosk_payment/kiosk_payment.dart';
import '../bloc/payment_bloc.dart';
import '../bloc/payment_event.dart';
import '../bloc/payment_state.dart';
import '../widgets/build_card.dart';
import '../widgets/gradient_button.dart';
import 'card_interaction_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController _amountController = TextEditingController(text: '10.00');
  String _selectedCurrency = 'USD';
  int? _selectedAmount;

  @override
  void initState() {
    super.initState();
    // Auto-connect when entering the screen
    context.read<PaymentBloc>().add(ConnectDeviceEvent());
    // Clear previous transaction results
    context.read<PaymentBloc>().add(ClearTransactionEvent());
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _processPayment() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    context.read<PaymentBloc>().add(ProcessPaymentEvent(
          amount: amount,
          currency: _selectedCurrency,
        ));
  }

  Color _getStatusColor(DeviceStatus status, ColorScheme colorScheme) {
    switch (status) {
      case DeviceStatus.connected:
      case DeviceStatus.readyForCard:
      case DeviceStatus.processing:
        return Colors.green;
      case DeviceStatus.connecting:
        return Colors.orange;
      case DeviceStatus.error:
        return colorScheme.error;
      default:
        return colorScheme.surfaceContainerHighest;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      onPopInvoked: (didPop) {
        if (didPop) {
          context.read<PaymentBloc>().add(DisconnectDeviceEvent());
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: BlocBuilder<PaymentBloc, PaymentState>(
            builder: (context, state) {
              return Text(state.selectedDevice?.name ?? 'Device Payment');
            },
          ),
          backgroundColor: colorScheme.surface,
        ),
        body: Container(
          height: double.infinity,
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
          child: BlocConsumer<PaymentBloc, PaymentState>(
            listener: (context, state) {
              if (state.errorMessage != null && !state.isProcessingPayment) {
                // Show errors not related to payment processing immediately
                // Or maybe all errors?
              }
            },
            builder: (context, state) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Connection Status
                    BuildCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _isConnected(state.connectionStatus)
                                      ? Icons.bluetooth_connected
                                      : Icons.bluetooth_disabled,
                                  color: _isConnected(state.connectionStatus) ? Colors.green : colorScheme.outline,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Status',
                                        style: theme.textTheme.titleSmall,
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(state.connectionStatus, colorScheme),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          _getStatusString(state.connectionStatus).toUpperCase(),
                                          style: TextStyle(
                                            color: _isConnected(state.connectionStatus)
                                                ? Colors.white
                                                : colorScheme.onSurfaceVariant,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_isConnected(state.connectionStatus))
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      context.read<PaymentBloc>().add(RestartReaderEvent());
                                    },
                                    icon: const Icon(Icons.refresh, size: 18),
                                    label: const Text('Restart Reader'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colorScheme.primaryContainer,
                                      foregroundColor: colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Payment Form
                    if (_isConnected(state.connectionStatus))
                      BuildCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Make Payment',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedAmount = 2;
                                        });
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => const CardInteractionScreen(amount: 2),
                                          ),
                                        );
                                      },
                                      child: Card(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          side: BorderSide(
                                            color: _selectedAmount == 2
                                                ? Theme.of(context).colorScheme.primary
                                                : Colors.transparent,
                                            width: 2,
                                          ),
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 20),
                                          alignment: Alignment.center,
                                          child: const Text(
                                            '\$2',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedAmount = 5;
                                        });
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => const CardInteractionScreen(amount: 5),
                                          ),
                                        );
                                      },
                                      child: Card(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          side: BorderSide(
                                            color: _selectedAmount == 5
                                                ? Theme.of(context).colorScheme.primary
                                                : Colors.transparent,
                                            width: 2,
                                          ),
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 20),
                                          alignment: Alignment.center,
                                          child: const Text(
                                            '\$5',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  bool _isConnected(DeviceStatus status) {
    return status == DeviceStatus.connected ||
        status == DeviceStatus.readyForCard ||
        status == DeviceStatus.processing ||
        status == DeviceStatus.cardRemoved ||
        status == DeviceStatus.removeCardRequested ||
        status == DeviceStatus.transactionCompleted;
  }

  String _getStatusString(DeviceStatus status) {
    if (_isConnected(status)) return 'Connected';
    switch (status) {
      case DeviceStatus.disconnected:
        return 'Disconnected';
      case DeviceStatus.connecting:
        return 'Connecting...';
      case DeviceStatus.configuring:
        return 'Configuring...';
      case DeviceStatus.scanning:
        return 'Scanning...';
      case DeviceStatus.error:
        return 'Error';
      default:
        return 'Unknown';
    }
  }
}
