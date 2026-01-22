import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/formatters.dart';

class MoneyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  const MoneyTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.enabled = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText ?? '0.00',
        prefixText: '\$ ',
        suffixIcon: enabled ? IconButton(icon: const Icon(Icons.clear), onPressed: () => controller.clear()) : null,
      ),
    );
  }
}
