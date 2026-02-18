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
      body: SafeArea(
        child: Column(
          children: [
            if (appBar != null) appBar!,
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class POSAppBar extends StatelessWidget {
  final String? storeName;
  final String? staffName;
  final String? shiftStatus;
  final VoidCallback? onEndWork;
  final VoidCallback? onLogout;

  const POSAppBar({super.key, this.storeName, this.staffName, this.shiftStatus, this.onEndWork, this.onLogout});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 600;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 24, vertical: isSmall ? 10 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: isSmall ? _buildMobileLayout() : _buildTabletLayout(),
    );
  }

  Widget _buildTabletLayout() {
    return Row(
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
        if (onLogout != null) ...[
          OutlinedButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout),
            label: const Text('ออกจากระบบ'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
              side: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          const SizedBox(width: 12),
        ],
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
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'POS ME',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
            ),
            const Spacer(),
            if (onLogout != null)
              IconButton(
                onPressed: onLogout,
                icon: Icon(Icons.logout, color: Colors.grey.shade700, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            if (onEndWork != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: onEndWork,
                icon: Icon(Icons.exit_to_app, color: Colors.red.shade700, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            if (storeName != null) _buildInfo(Icons.store, storeName!, small: true),
            if (staffName != null) _buildInfo(Icons.person, staffName!, small: true),
            if (shiftStatus != null) _buildInfo(Icons.schedule, shiftStatus!, small: true),
          ],
        ),
      ],
    );
  }

  Widget _buildInfo(IconData icon, String text, {bool small = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: small ? 14 : 20, color: Colors.grey.shade600),
        SizedBox(width: small ? 4 : 8),
        Text(
          text,
          style: TextStyle(fontSize: small ? 12 : 14, color: Colors.grey.shade800, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
