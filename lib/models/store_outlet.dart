class StoreOutlet {
  final String id;
  final String name;
  final String code;
  final String city;
  final String address;
  final String manager;
  final String phone;
  final String operatingHours;
  final bool isOpen;
  final int terminalsCount;
  final double dailySales;
  final double monthlySales;
  final int staffCount;

  const StoreOutlet({
    required this.id,
    required this.name,
    required this.code,
    required this.city,
    required this.address,
    required this.manager,
    required this.phone,
    required this.operatingHours,
    required this.isOpen,
    required this.terminalsCount,
    required this.dailySales,
    required this.monthlySales,
    required this.staffCount,
  });

  StoreOutlet copyWith({
    String? id,
    String? name,
    String? code,
    String? city,
    String? address,
    String? manager,
    String? phone,
    String? operatingHours,
    bool? isOpen,
    int? terminalsCount,
    double? dailySales,
    double? monthlySales,
    int? staffCount,
  }) {
    return StoreOutlet(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      city: city ?? this.city,
      address: address ?? this.address,
      manager: manager ?? this.manager,
      phone: phone ?? this.phone,
      operatingHours: operatingHours ?? this.operatingHours,
      isOpen: isOpen ?? this.isOpen,
      terminalsCount: terminalsCount ?? this.terminalsCount,
      dailySales: dailySales ?? this.dailySales,
      monthlySales: monthlySales ?? this.monthlySales,
      staffCount: staffCount ?? this.staffCount,
    );
  }
}
