import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kiosk_payment/kiosk_payment.dart';
import '../bloc/payment_bloc.dart';
import '../bloc/payment_event.dart';
import '../bloc/payment_state.dart';
import '../widgets/build_card.dart';
import '../widgets/gradient_button.dart';

class CardInteractionScreen extends StatefulWidget {
  final double amount;
  final String currency;

  const CardInteractionScreen({
    super.key,
    required this.amount,
    this.currency = 'USD',
  });

  @override
  State<CardInteractionScreen> createState() => _CardInteractionScreenState();
}

class _CardInteractionScreenState extends State<CardInteractionScreen> {
  @override
  void initState() {
    super.initState();
    // Start the transaction (ready for payment) when this screen opens
    context.read<PaymentBloc>().add(RestartReaderEvent());
  }

  @override
  void dispose() {
    // Cancel the transaction when leaving this screen (back to idle)
    // We add this event to the bloc, but since we are disposing,
    // we should ensure the bloc provider context is still valid or use a cached reference?
    // context.read() is safe in dispose as long as the widget is in the tree when dispose is called (it is).
    // However, if the bloc is provided above, it's fine.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      onPopInvoked: (didPop) {
        if (didPop) {
          context.read<PaymentBloc>().add(CancelTransactionEvent());
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Complete Payment'),
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
              if (state.lastTransaction != null) {
                // Navigate back if payment successful or failed (details shown in previous screen)
                // Or stay here to show success?
                // User asked for UI to tap and dip card.
              }
            },
            builder: (context, state) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Amount Display
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Total Amount',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.outline,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '\$${widget.amount}',
                            style: theme.textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),

                    if (state.displayMessage != null &&
                        state.displayMessage!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: BuildCard(
                          color: colorScheme.primaryContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: colorScheme.primary),
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
                                Icon(Icons.error_outline,
                                    color: colorScheme.error),
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
                    // Generated Token
                    if (state.generatedToken != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: BuildCard(
                          color: Colors.green.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle_outline,
                                        color: Colors.green),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Token Generated Successfully',
                                      style: TextStyle(
                                        color: Colors.green.shade900,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SelectableText(
                                  state.generatedToken!,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    color: Colors.green.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    // Interaction Options
                    Row(
                      children: [
                        Expanded(
                          child: _InteractionCard(
                            title: 'Tap Card',
                            icon: Icons.contactless_outlined,
                            description: 'Hold card near the top of the reader',
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _InteractionCard(
                            title: 'Dip Card',
                            icon: Icons.credit_card,
                            description: 'Insert card into the bottom slot',
                            color: colorScheme.secondary,
                          ),
                        ),
                      ],
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
}

class _InteractionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;
  final Color color;

  const _InteractionCard({
    required this.title,
    required this.icon,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BuildCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
