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
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonSize = (screenWidth < 400)
        ? 56.0
        : (screenWidth < 600)
        ? 64.0
        : 80.0;
    final buttonHeight = buttonSize * 0.8;
    final gap = (screenWidth < 400)
        ? 6.0
        : (screenWidth < 600)
        ? 8.0
        : 12.0;
    final fontSize = (screenWidth < 400)
        ? 18.0
        : (screenWidth < 600)
        ? 20.0
        : 24.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRow(['1', '2', '3'], buttonSize, buttonHeight, gap, fontSize),
        SizedBox(height: gap),
        _buildRow(['4', '5', '6'], buttonSize, buttonHeight, gap, fontSize),
        SizedBox(height: gap),
        _buildRow(['7', '8', '9'], buttonSize, buttonHeight, gap, fontSize),
        SizedBox(height: gap),
        _buildRow([if (showDecimal) '.' else '', '0', 'backspace'], buttonSize, buttonHeight, gap, fontSize),
      ],
    );
  }

  Widget _buildRow(List<String> buttons, double size, double height, double gap, double fontSize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: buttons.map((button) {
        if (button.isEmpty) {
          return SizedBox(width: size, height: height);
        }
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: gap / 2),
          child: _buildButton(button, size, height, fontSize),
        );
      }).toList(),
    );
  }

  Widget _buildButton(String button, double size, double height, double fontSize) {
    if (button == 'backspace') {
      return SizedBox(
        width: size,
        height: height,
        child: ElevatedButton(
          onPressed: onBackspace,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: Colors.grey.shade200,
            foregroundColor: Colors.black87,
          ),
          child: Icon(Icons.backspace_outlined, size: fontSize),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: height,
      child: ElevatedButton(
        onPressed: () => onNumberPressed(button),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: Text(
          button,
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
