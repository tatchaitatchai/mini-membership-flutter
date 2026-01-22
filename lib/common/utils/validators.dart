class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'กรุณากรอกอีเมล';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'กรุณากรอกอีเมลที่ถูกต้อง';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'กรุณากรอกรหัสผ่าน';
    }
    if (value.length < 6) {
      return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'กรุณากรอก$fieldName';
    }
    return null;
  }

  static String? validatePin(String? value) {
    if (value == null || value.isEmpty) {
      return 'กรุณากรอกรหัส PIN';
    }
    if (value.length != 4) {
      return 'รหัส PIN ต้องเป็นตัวเลข 4 หลัก';
    }
    return null;
  }

  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'กรุณากรอกจำนวนเงิน';
    }
    final amount = double.tryParse(value);
    if (amount == null || amount <= 0) {
      return 'กรุณากรอกจำนวนเงินที่ถูกต้อง';
    }
    return null;
  }
}
