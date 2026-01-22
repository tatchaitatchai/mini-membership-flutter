import 'package:flutter/material.dart';
import 'primary_button.dart';
import 'secondary_button.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback? onConfirm;
  final bool isDanger;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'ยืนยัน',
    this.cancelText = 'ยกเลิก',
    this.onConfirm,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        SecondaryButton(text: cancelText, onPressed: () => Navigator.of(context).pop(false)),
        const SizedBox(width: 12),
        PrimaryButton(
          text: confirmText,
          onPressed: () {
            Navigator.of(context).pop(true);
            onConfirm?.call();
          },
        ),
      ],
    );
  }

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'ยืนยัน',
    String cancelText = 'ยกเลิก',
    bool isDanger = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        isDanger: isDanger,
      ),
    );
    return result ?? false;
  }
}
