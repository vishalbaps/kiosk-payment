import 'package:flutter/material.dart';
import 'package:kiosk_payment/kiosk_payment.dart';
import '../widgets/build_card.dart';
import '../widgets/gradient_button.dart';

class PaymentScreen extends StatefulWidget {
  final KioskPayment kioskPayment;
  final PaymentDevice device;

  const PaymentScreen({
    super.key,
    required this.kioskPayment,
    required this.device,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  DeviceStatus _deviceStatus = DeviceStatus.disconnected;
  TransactionResult? _lastTransaction;
  bool _isLoading = false;
  String? _errorMessage;

  final TextEditingController _amountController =
      TextEditingController(text: '10.00');
  String _selectedCurrency = 'USD';

  @override
  void initState() {
    super.initState();
    _setupListeners();
    _connectToDevice();
  }

  void _setupListeners() {
    widget.kioskPayment.deviceStatusStream.listen((status) {
      if (mounted) {
        setState(() {
          _deviceStatus = status;
        });
      }
    });

    widget.kioskPayment.transactionStatusStream.listen((status) {
      debugPrint('Transaction status: $status');
    });
  }

  Future<void> _connectToDevice() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await widget.kioskPayment.connect(deviceId: widget.device.id);
      if (success) {
        // Status update handled by stream
      } else {
        setState(() {
           _errorMessage = 'Connection failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to connect: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _disconnect() async {
     try {
      await widget.kioskPayment.disconnect();
    } catch (e) {
      debugPrint("Error disconnecting: $e");
    }
  }

  Future<void> _processPayment() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      setState(() {
        _errorMessage = 'Please enter a valid amount';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _lastTransaction = null;
    });

    try {
      final result = await widget.kioskPayment.processPayment(
        amount: amount,
        currency: _selectedCurrency,
      );
      setState(() {
        _lastTransaction = result;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Payment failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _disconnect(); // Disconnect when leaving this screen
    _amountController.dispose();
    super.dispose();
  }

  Color _getStatusColor(ColorScheme colorScheme) {
    switch (_deviceStatus) {
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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Connection Status
              BuildCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        _deviceStatus == DeviceStatus.connected
                            ? Icons.bluetooth_connected
                            : Icons.bluetooth_disabled,
                        color: _deviceStatus == DeviceStatus.connected
                            ? Colors.green
                            : colorScheme.outline,
                      ),
                      const SizedBox(width: 12),
                      Column(
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
                              color: _getStatusColor(colorScheme),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _deviceStatus.name.toUpperCase(),
                              style: TextStyle(
                                color: _deviceStatus == DeviceStatus.connected
                                    ? Colors.white
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
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
                          Icon(Icons.error_outline, color: colorScheme.error),
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

              // Payment Form
              if (_deviceStatus == DeviceStatus.connected)
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
                              flex: 2,
                              child: TextField(
                                controller: _amountController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'Amount',
                                  prefixIcon: const Icon(Icons.attach_money),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: colorScheme.surfaceContainerHighest
                                      .withOpacity(0.5),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedCurrency,
                                decoration: InputDecoration(
                                  labelText: 'Currency',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: colorScheme.surfaceContainerHighest
                                      .withOpacity(0.5),
                                ),
                                items: ['USD', 'EUR', 'GBP', 'INR']
                                    .map((c) => DropdownMenuItem(
                                        value: c, child: Text(c)))
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedCurrency = value;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: GradientButton(
                            onPressed: _isLoading ? null : _processPayment,
                            icon: Icons.credit_card,
                            label: 'Process Payment',
                            colors: [
                              const Color(0xFF10B981), // Emerald
                              const Color(0xFF059669),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Transaction Result
              if (_lastTransaction != null)
                BuildCard(
                  color: _lastTransaction!.isSuccess
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
                              _lastTransaction!.isSuccess
                                  ? Icons.check_circle
                                  : Icons.error,
                              color: _lastTransaction!.isSuccess
                                  ? Colors.green
                                  : colorScheme.error,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _lastTransaction!.isSuccess
                                        ? 'Payment Successful'
                                        : 'Payment Failed',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: _lastTransaction!.isSuccess
                                          ? Colors.green
                                          : colorScheme.error,
                                    ),
                                  ),
                                  if (_lastTransaction!.transactionId != null)
                                    Text(
                                      'ID: ${_lastTransaction!.transactionId}',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (_lastTransaction!.isSuccess) ...[
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          _buildTransactionDetail(
                              context, 'Card Type', _lastTransaction!.cardType ?? 'N/A'),
                          _buildTransactionDetail(context, 'Card Number',
                              _lastTransaction!.maskedCardNumber ?? 'N/A'),
                          _buildTransactionDetail(context, 'Amount',
                              '${_lastTransaction!.amount} ${_lastTransaction!.currency}'),
                          _buildTransactionDetail(context, 'Auth Code',
                              _lastTransaction!.authorizationCode ?? 'N/A'),
                        ],
                        if (_lastTransaction!.errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              'Error: ${_lastTransaction!.errorMessage}',
                              style: TextStyle(color: colorScheme.error),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
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
