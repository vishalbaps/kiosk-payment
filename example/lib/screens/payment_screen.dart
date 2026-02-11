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
                                  state.connectionStatus == DeviceStatus.connected
                                      ? Icons.bluetooth_connected
                                      : Icons.bluetooth_disabled,
                                  color: state.connectionStatus == DeviceStatus.connected
                                      ? Colors.green
                                      : colorScheme.outline,
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
                                          state.connectionStatus.name.toUpperCase(),
                                          style: TextStyle(
                                            color: state.connectionStatus == DeviceStatus.connected
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
                                if (state.connectionStatus == DeviceStatus.connected)
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

                    // Display Message from Device
                    if (state.displayMessage != null && state.displayMessage!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: BuildCard(
                          color: colorScheme.primaryContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: colorScheme.primary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    state.displayMessage!,
                                    style: TextStyle(
                                      color: colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

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
                                Icon(Icons.error_outline, color: colorScheme.error),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    state.errorMessage!,
                                    style: TextStyle(color: colorScheme.error),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Payment Form
                    if (state.connectionStatus == DeviceStatus.connected)
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
                              /*const SizedBox(height: 20),
                              ßSizedBox(
                                width: double.infinity,
                                height: 56,
                                child: GradientButton(
                                  onPressed: state.isProcessingPayment ? null : _processPayment,
                                  icon: Icons.credit_card,
                                  label: state.isProcessingPayment ? 'Processing...' : 'Process Payment',
                                  colors: [
                                    const Color(0xFF10B981), // Emerald
                                    const Color(0xFF059669),
                                  ],
                                ),
                              ),*/
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Transaction Result
                    if (state.lastTransaction != null)
                      BuildCard(
                        color: state.lastTransaction!.isSuccess
                            ? Colors.green.withOpacity(0.1)
                            : colorScheme.errorContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    state.lastTransaction!.isSuccess ? Icons.check_circle : Icons.error,
                                    color: state.lastTransaction!.isSuccess ? Colors.green : colorScheme.error,
                                    size: 32,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          state.lastTransaction!.isSuccess ? 'Payment Successful' : 'Payment Failed',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: state.lastTransaction!.isSuccess ? Colors.green : colorScheme.error,
                                          ),
                                        ),
                                        if (state.lastTransaction!.transactionId != null)
                                          Text(
                                            'ID: ${state.lastTransaction!.transactionId}',
                                            style: theme.textTheme.bodySmall,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (state.lastTransaction!.isSuccess) ...[
                                const SizedBox(height: 16),
                                const Divider(),
                                const SizedBox(height: 16),
                                _buildTransactionDetail(context, 'Card Type', state.lastTransaction!.cardType ?? 'N/A'),
                                _buildTransactionDetail(
                                    context, 'Card Number', state.lastTransaction!.maskedCardNumber ?? 'N/A'),
                                _buildTransactionDetail(context, 'Amount',
                                    '${state.lastTransaction!.amount} ${state.lastTransaction!.currency}'),
                                _buildTransactionDetail(
                                    context, 'Auth Code', state.lastTransaction!.authorizationCode ?? 'N/A'),
                              ],
                              if (state.lastTransaction!.errorMessage != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Text(
                                    'Error: ${state.lastTransaction!.errorMessage}',
                                    style: TextStyle(color: colorScheme.error),
                                  ),
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

  Widget _buildTransactionDetail(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
