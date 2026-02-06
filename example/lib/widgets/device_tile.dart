import 'package:flutter/material.dart';
import 'package:kiosk_payment/kiosk_payment.dart';
import 'build_card.dart';

class DeviceTile extends StatelessWidget {
  final PaymentDevice device;
  final VoidCallback onTap;

  const DeviceTile({super.key, required this.device, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BuildCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
               Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  device.type == DeviceType.bluetooth ? Icons.bluetooth : Icons.usb,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${device.type.name.toUpperCase()} • ${device.id}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
