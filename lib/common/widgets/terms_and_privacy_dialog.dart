import 'package:flutter/material.dart';

class TermsAndPrivacyDialog extends StatefulWidget {
  const TermsAndPrivacyDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const TermsAndPrivacyDialog(),
    );
  }

  @override
  State<TermsAndPrivacyDialog> createState() => _TermsAndPrivacyDialogState();
}

class _TermsAndPrivacyDialogState extends State<TermsAndPrivacyDialog> {
  bool _isEnglish = true;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            // Header with language toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.policy, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isEnglish ? 'Privacy Policy & Terms of Service' : 'นโยบายความเป็นส่วนตัวและข้อตกลงการใช้งาน',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // Language toggle
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildLangButton('EN', _isEnglish, () => setState(() => _isEnglish = true)),
                        _buildLangButton('TH', !_isEnglish, () => setState(() => _isEnglish = false)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _isEnglish ? _buildEnglishContent() : _buildThaiContent(),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(_isEnglish ? 'Close' : 'ปิด'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLangButton(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFF6366F1) : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildEnglishContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAppInfo(isEnglish: true),
        const Divider(height: 32),
        _buildSectionTitle('1. Privacy Policy'),
        _buildParagraph(
          'POS ME respects your privacy and is committed to protecting your personal data. '
          'This policy explains how we collect, use, disclose, and protect your information '
          'in compliance with applicable data protection laws including GDPR and PDPA.',
        ),
        const SizedBox(height: 16),
        _buildSubsectionTitle('1.1 Information We Collect'),
        _buildBulletList([
          'User name and account credentials',
          'Email address',
          'Phone number (for OTP verification)',
          'Purchase history and transaction records',
          'Loyalty points, membership rank, and benefits',
          'Application usage data and preferences',
          'Device information (for security purposes)',
        ]),
        const SizedBox(height: 16),
        _buildSubsectionTitle('1.2 Purpose of Data Collection'),
        _buildParagraph('We use your information to:'),
        _buildBulletList([
          'Verify your identity via OTP authentication',
          'Provide POS and membership management services',
          'Calculate and display loyalty points and ranks',
          'Process orders and manage inventory',
          'Send service-related notifications',
          'Improve system security and service quality',
        ]),
        const SizedBox(height: 16),
        _buildSubsectionTitle('1.3 Use of Phone Number'),
        _buildParagraph(
          'Your phone number is used solely for identity verification, account identification, '
          'and transaction-related notifications. We do not use phone numbers for marketing calls '
          'or messages without your explicit consent.',
        ),
        const SizedBox(height: 16),
        _buildSubsectionTitle('1.4 Data Sharing'),
        _buildBulletList([
          'Your data is shared only with the merchants you are a member of',
          'Each merchant can access only their own customers\' data',
          'We do not sell, trade, or rent personal data to third parties',
          'Data may be disclosed if required by law or legal process',
        ]),
        const SizedBox(height: 16),
        _buildSubsectionTitle('1.5 Data Security'),
        _buildParagraph(
          'We implement appropriate technical and organizational security measures to protect '
          'your personal data against unauthorized access, alteration, disclosure, or destruction. '
          'Access to personal data is restricted to authorized personnel only.',
        ),
        const SizedBox(height: 16),
        _buildSubsectionTitle('1.6 User Rights & Data Deletion'),
        _buildParagraph('You have the right to:'),
        _buildBulletList([
          'Access, view, and download your personal data',
          'Request correction or update of inaccurate data',
          'Withdraw consent for data processing',
          'Request deletion of your account and personal data',
        ]),
        _buildParagraph(
          'To delete your account, please use the "Delete Account" option in the app settings '
          'or contact our support team. Account deletion requests will be processed within 30 days. '
          'Please note that this action is irreversible and all associated data including points '
          'and purchase history will be permanently deleted.',
        ),
        const Divider(height: 32),
        _buildSectionTitle('2. Terms of Service'),
        _buildSubsectionTitle('2.1 Service Scope'),
        _buildParagraph(
          'POS ME is a platform providing point-of-sale (POS), membership management, and '
          'loyalty program services. We act solely as a technology service provider and are '
          'not a party to any transactions between merchants and customers.',
        ),
        const SizedBox(height: 16),
        _buildSubsectionTitle('2.2 User Accounts'),
        _buildBulletList([
          'Users must provide accurate and current information',
          'One account per user/device is permitted',
          'Users are responsible for maintaining account security',
          'Sharing account credentials is prohibited',
        ]),
        const SizedBox(height: 16),
        _buildSubsectionTitle('2.3 Transactions'),
        _buildParagraph(
          'Sales transactions are considered complete when successfully recorded in the system. '
          'Refunds, cancellations, and returns are subject to individual merchant policies.',
        ),
        const SizedBox(height: 16),
        _buildSubsectionTitle('2.4 Loyalty Points & Ranks'),
        _buildBulletList([
          'Points have no cash value and cannot be exchanged for money',
          'Points are non-transferable between accounts',
          'Points may expire based on merchant-specific policies',
          'Merchants reserve the right to modify point rules and rank conditions',
        ]),
        const SizedBox(height: 16),
        _buildSubsectionTitle('2.5 Account Suspension'),
        _buildParagraph(
          'We reserve the right to suspend or terminate accounts that violate these terms, '
          'engage in fraudulent activities, or use the service for unlawful purposes.',
        ),
        const SizedBox(height: 16),
        _buildSubsectionTitle('2.6 Limitation of Liability'),
        _buildParagraph(
          'We are not liable for disputes, damages, or losses arising from transactions '
          'between merchants and customers. Our liability is limited to the extent permitted by law.',
        ),
        const SizedBox(height: 16),
        _buildSubsectionTitle('2.7 Changes to Terms'),
        _buildParagraph(
          'We may update these terms periodically. Continued use of the service after changes '
          'constitutes acceptance of the updated terms. Significant changes will be communicated '
          'through the application.',
        ),
        const Divider(height: 32),
        _buildContactInfo(isEnglish: true),
      ],
    );
  }

  Widget _buildThaiContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAppInfo(isEnglish: false),
        const Divider(height: 32),
        _buildSectionTitle('1. นโยบายความเป็นส่วนตัว (Privacy Policy)'),
        _buildParagraph(
          'แอปพลิเคชัน POS ME ให้ความสำคัญกับการคุ้มครองข้อมูลส่วนบุคคลของผู้ใช้งาน '
          'นโยบายฉบับนี้อธิบายถึงการเก็บ ใช้ เปิดเผย และคุ้มครองข้อมูลส่วนบุคคล '
          'ตามกฎหมาย PDPA และมาตรฐานสากล',
        ),
        const SizedBox(height: 16),
        _buildSubsectionTitle('1.1 ข้อมูลที่เก็บรวบรวม'),
        _buildBulletList([
          'ชื่อผู้ใช้งานและข้อมูลบัญชี',
          'อีเมล',
          'เบอร์โทรศัพท์ (สำหรับยืนยันตัวตนด้วย OTP)',
          'ประวัติการซื้อสินค้าและธุรกรรม',
          'คะแนนสะสม แรงค์ และสิทธิประโยชน์',
          'ข้อมูลการใช้งานแอปและการตั้งค่า',
          'ข้อมูลอุปกรณ์ (เพื่อความปลอดภัยของระบบ)',
        ]),
        const SizedBox(height: 16),
        _buildSubsectionTitle('1.2 วัตถุประสงค์ในการใช้ข้อมูล'),
        _buildParagraph('ข้อมูลของผู้ใช้งานถูกใช้เพื่อ:'),
        _buildBulletList([
          'ยืนยันตัวตนผ่านระบบ OTP',
          'ให้บริการระบบ POS และระบบสมาชิก',
          'คำนวณและแสดงคะแนนสะสมและแรงค์',
          'จัดการคำสั่งซื้อและสต๊อกสินค้า',
          'ส่งการแจ้งเตือนที่เกี่ยวข้องกับบริการ',
          'ปรับปรุงความปลอดภัยและคุณภาพของระบบ',
        ]),
        const SizedBox(height: 16),
        _buildSubsectionTitle('1.3 การใช้เบอร์โทรศัพท์'),
        _buildParagraph(
          'เบอร์โทรศัพท์ถูกใช้เพื่อยืนยันตัวตนของผู้ใช้งาน ระบุบัญชีผู้ใช้งาน '
          'และแจ้งเตือนเกี่ยวกับธุรกรรมเท่านั้น ระบบจะไ ',
        ),
        const SizedBox(height: 16),
        _buildSubsectionTitle('1.4 การเปิดเผยข้อมูล'),
        _buildBulletList([
          'ข้อมูลจะถูกเปิดเผยเฉพาะกับร้านค้าที่ผู้ใช้งานเป็นสมาชิก',
          'ร้านค้าแต่ละแห่งสามารถเข้าถึงข้อมูลเฉพาะลูกค้าของตนเอง',
          'ผู้ให้บริการจะไม่ขาย แลกเปลี่ยน หรือให้เช่าข้อมูลให้บุคคลภายนอก',
          'ข้อมูลอาจถูกเปิดเผยหากกฎหมายกำหนด',
        ]),
        const SizedBox(height: 16),
        _buildSubsectionTitle('1.5 การจัดเก็บและความปลอดภัย'),
        _buildParagraph(
          'เราใช้มาตรการรักษาความปลอดภัยทางเทคนิคและองค์กรที่เหมาะสม '
          'เพื่อปกป้องข้อมูลส่วนบุคคลจากการเข้าถึง แก้ไข เปิดเผย หรือทำลายโดยไม่ได้รับอนุญาต '
          'การเข้าถึงข้อมูลจำกัดเฉพาะผู้ที่ได้รับอนุญาตเท่านั้น',
        ),
        const SizedBox(height: 16),
        _buildSubsectionTitle('1.6 สิทธิของเจ้าของข้อมูลและการลบข้อมูล'),
        _buildParagraph('ผู้ใช้งานมีสิทธิ์:'),
        _buildBulletList([
          'เข้าถึง ดู และดาวน์โหลดข้อมูลส่วนบุคคลของตน',
          'ขอแก้ไขหรือปรับปรุงข้อมูลที่ไม่ถูกต้อง',
          'ถอนความยินยอมในการประมวลผลข้อมูล',
          'ขอให้ลบบัญชีและข้อมูลส่วนบุคคล',
        ]),
        _buildParagraph(
          'หากต้องการลบบัญชี กรุณาใช้ตัวเลือก "ลบบัญชี" ในการตั้งค่าแอป '
          'หรือติดต่อฝ่ายสนับสนุน การดำเนินการลบบัญชีจะใช้เวลาไม่เกิน 30 วัน '
          'โปรดทราบว่าการดำเนินการนี้ไม่สามารถย้อนกลับได้ และข้อมูลทั้งหมด '
          'รวมถึงคะแนนและประวัติการซื้อจะถูกลบอย่างถาวร',
        ),
        const Divider(height: 32),
        _buildSectionTitle('2. ข้อตกลงและเงื่อนไขการใช้งาน (Terms of Service)'),
        _buildSubsectionTitle('2.1 ขอบเขตการให้บริการ'),
        _buildParagraph(
          'POS ME เป็นแพลตฟอร์มที่ให้บริการระบบขายสินค้า (POS) ระบบสมาชิก '
          'และระบบสะสมคะแนน ผู้ให้บริการเป็นเพียงผู้ให้บริการระบบเทคโนโลยี '
          'ไม่ใช่คู่สัญญาในธุรกรรมระหว่างร้านค้าและลูกค้า',
        ),
        const SizedBox(height: 16),
        _buildSubsectionTitle('2.2 บัญชีผู้ใช้งาน'),
        _buildBulletList([
          'ผู้ใช้งานต้องให้ข้อมูลที่ถูกต้องและเป็นปัจจุบัน',
          'อนุญาตให้ใช้ 1 บัญชีต่อ 1 ผู้ใช้งาน/อุปกรณ์',
          'ผู้ใช้งานต้องรับผิดชอบในการรักษาความปลอดภัยของบัญชี',
          'ห้ามแชร์ข้อมูลเข้าสู่ระบบกับผู้อื่น',
        ]),
        const SizedBox(height: 16),
        _buildSubsectionTitle('2.3 ธุรกรรม'),
        _buildParagraph(
          'รายการขายถือว่าสมบูรณ์เมื่อระบบบันทึกสำเร็จ '
          'การคืนเงิน ยกเลิก และคืนสินค้าเป็นไปตามนโยบายของร้านค้าแต่ละแห่ง',
        ),
        const SizedBox(height: 16),
        _buildSubsectionTitle('2.4 คะแนนสะสมและแรงค์'),
        _buildBulletList([
          'คะแนนไม่มีมูลค่าเป็นเงินสดและไม่สามารถแลกเป็นเงินได้',
          'คะแนนไม่สามารถโอนระหว่างบัญชีได้',
          'คะแนนอาจหมดอายุตามนโยบายของร้านค้าแต่ละแห่ง',
          'ร้านค้ามีสิทธิ์เปลี่ยนแปลงกฎการให้คะแนนและเงื่อนไขแรงค์',
        ]),
        const SizedBox(height: 16),
        _buildSubsectionTitle('2.5 การระงับบัญชี'),
        _buildParagraph(
          'ผู้ให้บริการขอสงวนสิทธิ์ในการระงับหรือยกเลิกบัญชีที่ละเมิดข้อตกลงนี้ '
          'มีส่วนเกี่ยวข้องกับการฉ้อโกง หรือใช้บริการเพื่อวัตถุประสงค์ที่ผิดกฎหมาย',
        ),
        const SizedBox(height: 16),
        _buildSubsectionTitle('2.6 ข้อจำกัดความรับผิด'),
        _buildParagraph(
          'ผู้ให้บริการไม่รับผิดชอบต่อข้อพิพาท ความเสียหาย หรือการสูญเสีย '
          'ที่เกิดขึ้นจากธุรกรรมระหว่างร้านค้าและลูกค้า '
          'ความรับผิดของเราจำกัดตามขอบเขตที่กฎหมายอนุญาต',
        ),
        const SizedBox(height: 16),
        _buildSubsectionTitle('2.7 การเปลี่ยนแปลงข้อตกลง'),
        _buildParagraph(
          'ผู้ให้บริการอาจปรับปรุงข้อตกลงนี้เป็นระยะ การใช้บริการต่อหลังจากมีการเปลี่ยนแปลง '
          'ถือว่าผู้ใช้งานยอมรับข้อตกลงที่ปรับปรุงแล้ว การเปลี่ยนแปลงที่สำคัญ '
          'จะแจ้งให้ทราบผ่านแอปพลิเคชัน',
        ),
        const Divider(height: 32),
        _buildContactInfo(isEnglish: false),
      ],
    );
  }

  Widget _buildAppInfo({required bool isEnglish}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEnglish ? 'Application Name: POS ME' : 'ชื่อแอปพลิเคชัน: POS ME',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            isEnglish ? 'Effective Date: January 1, 2026' : 'วันที่มีผลบังคับใช้: 1 มกราคม 2569',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 4),
          Text(
            isEnglish ? 'Service Provider: POS ME Team' : 'ผู้ให้บริการ: ทีมงาน POS ME',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF6366F1),
        ),
      ),
    );
  }

  Widget _buildSubsectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          height: 1.6,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }

  Widget _buildBulletList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) => Padding(
        padding: const EdgeInsets.only(left: 16, bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildContactInfo({required bool isEnglish}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mail_outline, size: 20, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                isEnglish ? 'Contact Information' : 'ข้อมูลติดต่อ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isEnglish ? 'Email: support@posme.app' : 'อีเมล: support@posme.app',
            style: TextStyle(color: Colors.blue.shade900),
          ),
          const SizedBox(height: 4),
          Text(
            isEnglish ? 'Website: https://posme.app' : 'เว็บไซต์: https://posme.app',
            style: TextStyle(color: Colors.blue.shade900),
          ),
        ],
      ),
    );
  }
}
