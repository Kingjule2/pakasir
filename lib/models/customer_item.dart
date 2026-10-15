class CustomerItem {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String tier; // 'VIP', 'Regular', 'Wholesale', 'Baru'
  final int totalOrders;
  final double totalSpent;
  final String lastActive;
  final String status; // 'Aktif', 'Nonaktif'
  final String city;
  final String notes;

  const CustomerItem({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.tier,
    required this.totalOrders,
    required this.totalSpent,
    required this.lastActive,
    required this.status,
    required this.city,
    this.notes = '',
  });

  CustomerItem copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? tier,
    int? totalOrders,
    double? totalSpent,
    String? lastActive,
    String? status,
    String? city,
    String? notes,
  }) {
    return CustomerItem(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      tier: tier ?? this.tier,
      totalOrders: totalOrders ?? this.totalOrders,
      totalSpent: totalSpent ?? this.totalSpent,
      lastActive: lastActive ?? this.lastActive,
      status: status ?? this.status,
      city: city ?? this.city,
      notes: notes ?? this.notes,
    );
  }
}
