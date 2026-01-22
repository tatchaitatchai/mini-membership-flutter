import 'package:flutter/material.dart';

class ResponsiveScaffold extends StatelessWidget {
  final Widget? appBar;
  final Widget body;
  final Color? backgroundColor;

  const ResponsiveScaffold({super.key, this.appBar, required this.body, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? Colors.grey.shade50,
      body: Column(
        children: [
          if (appBar != null) appBar!,
          Expanded(child: body),
        ],
      ),
    );
  }
}

class POSAppBar extends StatelessWidget {
  final String? storeName;
  final String? staffName;
  final String? shiftStatus;
  final VoidCallback? onEndWork;

  const POSAppBar({super.key, this.storeName, this.staffName, this.shiftStatus, this.onEndWork});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          const Text(
            'POS ME',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
          ),
          const SizedBox(width: 32),
          if (storeName != null) ...[_buildInfo(Icons.store, storeName!), const SizedBox(width: 24)],
          if (staffName != null) ...[_buildInfo(Icons.person, staffName!), const SizedBox(width: 24)],
          if (shiftStatus != null) ...[_buildInfo(Icons.schedule, shiftStatus!)],
          const Spacer(),
          if (onEndWork != null)
            ElevatedButton.icon(
              onPressed: onEndWork,
              icon: const Icon(Icons.exit_to_app),
              label: const Text('สิ้นสุดงาน'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red.shade700,
                elevation: 0,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade800, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
