import 'package:flutter/material.dart';

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;
  final bool ghost;

  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.fullWidth = false,
    this.ghost = false,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: fullWidth ? const Size(double.infinity, 52) : const Size(120, 52),
        foregroundColor: ghost ? Colors.white : Theme.of(context).colorScheme.primary,
        side: BorderSide(
          color: ghost ? Colors.white.withOpacity(0.5) : Theme.of(context).colorScheme.primary,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: isLoading
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ghost ? Colors.white : Theme.of(context).colorScheme.primary,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
                Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
    );
  }
}
