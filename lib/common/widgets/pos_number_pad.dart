import 'package:flutter/material.dart';

class POSNumberPad extends StatelessWidget {
  final ValueChanged<String> onNumberPressed;
  final VoidCallback onBackspace;
  final VoidCallback? onClear;
  final bool showDecimal;
  final String currentValue;

  const POSNumberPad({
    super.key,
    required this.onNumberPressed,
    required this.onBackspace,
    this.onClear,
    this.showDecimal = false,
    this.currentValue = '',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRow(['1', '2', '3']),
        const SizedBox(height: 12),
        _buildRow(['4', '5', '6']),
        const SizedBox(height: 12),
        _buildRow(['7', '8', '9']),
        const SizedBox(height: 12),
        _buildRow([if (showDecimal) '.' else '', '0', 'backspace']),
      ],
    );
  }

  Widget _buildRow(List<String> buttons) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: buttons.map((button) {
        if (button.isEmpty) {
          return const SizedBox(width: 80, height: 64);
        }
        return Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: _buildButton(button));
      }).toList(),
    );
  }

  Widget _buildButton(String button) {
    if (button == 'backspace') {
      return SizedBox(
        width: 80,
        height: 64,
        child: ElevatedButton(
          onPressed: onBackspace,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: Colors.grey.shade200,
            foregroundColor: Colors.black87,
          ),
          child: const Icon(Icons.backspace_outlined, size: 24),
        ),
      );
    }

    return SizedBox(
      width: 80,
      height: 64,
      child: ElevatedButton(
        onPressed: () => onNumberPressed(button),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: Text(button, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
