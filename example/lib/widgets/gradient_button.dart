import 'package:flutter/material.dart';

class GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final List<Color> colors;

  const GradientButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;

    return Container(
      decoration: BoxDecoration(
        gradient: isEnabled
            ? LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isEnabled ? null : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: colors.first.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isEnabled ? Colors.white : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isEnabled ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
