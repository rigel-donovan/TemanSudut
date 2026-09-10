class Branch {
  final int id;
  final String name;
  final String? address;
  final String? phone;
  final bool isActive;

  Branch({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.isActive = true,
  });

  static final Branch defaultBranch = Branch(
    id: 1,
    name: 'Cabang Ring Road',
    address: 'Pusat',
    isActive: true,
  );

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      address: json['address'],
      phone: json['phone'],
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'is_active': isActive,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Branch && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
