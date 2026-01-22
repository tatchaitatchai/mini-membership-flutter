class Customer {
  final String id;
  final String code;
  final String last4;
  final String fullName;
  final String? phone;
  final String? email;

  const Customer({
    required this.id,
    required this.code,
    required this.last4,
    required this.fullName,
    this.phone,
    this.email,
  });

  static Customer guest() {
    return const Customer(id: 'guest', code: 'GUEST', last4: '0000', fullName: 'Guest');
  }
}
