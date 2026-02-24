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

  const POSAppBar({super.key, this.storeName, this.staffName, this.shiftStatus, this.onEndWork, this.onLogout});

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
        if (onLogout != null) ...[
          _buildTextButton(Icons.logout_rounded, 'ออกจากระบบ', onLogout!, danger: false),
          const SizedBox(width: 8),
        ],
        if (onEndWork != null) _buildTextButton(Icons.exit_to_app_rounded, 'สิ้นสุดงาน', onEndWork!, danger: true),
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
        if (onLogout != null) _buildIconBtn(Icons.logout_rounded, onLogout!),
        if (onEndWork != null) ...[
          const SizedBox(width: 4),
          _buildIconBtn(Icons.exit_to_app_rounded, onEndWork!, danger: true),
        ],
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

  Widget _buildTextButton(IconData icon, String label, VoidCallback onTap, {required bool danger}) {
    final color = danger ? const Color(0xFFDC2626) : const Color(0xFF64748B);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          border: Border.all(color: danger ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(8),
          color: danger ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconBtn(IconData icon, VoidCallback onTap, {bool danger = false}) {
    final color = danger ? const Color(0xFFDC2626) : const Color(0xFF64748B);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: danger ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(8),
          color: danger ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
        ),
        child: Icon(icon, size: 17, color: color),
      ),
    );
  }
}
