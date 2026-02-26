import 'package:flutter/material.dart';
import '../../app/theme.dart';

class ResponsiveScaffold extends StatelessWidget {
  final Widget? appBar;
  final Widget body;
  final Color? backgroundColor;

  const ResponsiveScaffold({super.key, this.appBar, required this.body, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? POSTheme.backgroundColor,
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
  final VoidCallback? onDeleteAccount;

  const POSAppBar({
    super.key,
    this.storeName,
    this.staffName,
    this.shiftStatus,
    this.onEndWork,
    this.onLogout,
    this.onDeleteAccount,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 600;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 28, vertical: isSmall ? 12 : 14),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: isSmall ? _buildMobileLayout() : _buildTabletLayout(),
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        const Text(
          'POS ME',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF4F46E5), letterSpacing: -0.5),
        ),
        const SizedBox(width: 28),
        if (storeName != null) ...[_buildChip(Icons.store_rounded, storeName!), const SizedBox(width: 8)],
        if (staffName != null) ...[_buildChip(Icons.person_rounded, staffName!), const SizedBox(width: 8)],
        if (shiftStatus != null) _buildStatusBadge(shiftStatus!),
        const Spacer(),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
          offset: const Offset(0, 45),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          itemBuilder: (context) => [
            if (onEndWork != null)
              PopupMenuItem<String>(
                value: 'end_work',
                child: const Row(
                  children: [
                    Icon(Icons.exit_to_app_rounded, size: 20, color: Color(0xFF64748B)),
                    SizedBox(width: 12),
                    Text('สิ้นสุดงาน'),
                  ],
                ),
              ),
            if (onLogout != null)
              PopupMenuItem<String>(
                value: 'logout',
                child: const Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 20, color: Color(0xFF64748B)),
                    SizedBox(width: 12),
                    Text('ออกจากระบบ'),
                  ],
                ),
              ),
            if (onDeleteAccount != null)
              PopupMenuItem<String>(
                value: 'delete_account',
                child: const Row(
                  children: [
                    Icon(Icons.delete_forever_rounded, size: 20, color: Color(0xFFDC2626)),
                    SizedBox(width: 12),
                    Text('ลบบัญชี', style: TextStyle(color: Color(0xFFDC2626))),
                  ],
                ),
              ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'end_work':
                onEndWork?.call();
                break;
              case 'logout':
                onLogout?.call();
                break;
              case 'delete_account':
                onDeleteAccount?.call();
                break;
            }
          },
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Row(
      children: [
        const Text(
          'POS ME',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF4F46E5), letterSpacing: -0.3),
        ),
        const SizedBox(width: 10),
        if (storeName != null)
          Expanded(
            child: Text(
              storeName!,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        const Spacer(),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
          offset: const Offset(0, 45),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          itemBuilder: (context) => [
            if (staffName != null)
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staffName!,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                    ),
                    if (shiftStatus != null) ...[
                      const SizedBox(height: 4),
                      Text(shiftStatus!, style: const TextStyle(fontSize: 12, color: Color(0xFF10B981))),
                    ],
                    const Divider(height: 16),
                  ],
                ),
              ),
            if (onEndWork != null)
              PopupMenuItem<String>(
                value: 'end_work',
                child: const Row(
                  children: [
                    Icon(Icons.exit_to_app_rounded, size: 20, color: Color(0xFF64748B)),
                    SizedBox(width: 12),
                    Text('สิ้นสุดงาน'),
                  ],
                ),
              ),
            if (onLogout != null)
              PopupMenuItem<String>(
                value: 'logout',
                child: const Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 20, color: Color(0xFF64748B)),
                    SizedBox(width: 12),
                    Text('ออกจากระบบ'),
                  ],
                ),
              ),
            if (onDeleteAccount != null)
              PopupMenuItem<String>(
                value: 'delete_account',
                child: const Row(
                  children: [
                    Icon(Icons.delete_forever_rounded, size: 20, color: Color(0xFFDC2626)),
                    SizedBox(width: 12),
                    Text('ลบบัญชี', style: TextStyle(color: Color(0xFFDC2626))),
                  ],
                ),
              ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'end_work':
                onEndWork?.call();
                break;
              case 'logout':
                onLogout?.call();
                break;
              case 'delete_account':
                onDeleteAccount?.call();
                break;
            }
          },
        ),
      ],
    );
  }

  Widget _buildChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: const Border.fromBorderSide(BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(fontSize: 13, color: Color(0xFF374151), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(8),
        border: const Border.fromBorderSide(BorderSide(color: Color(0xFFBBF7D0))),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 12, color: Color(0xFF15803D), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
