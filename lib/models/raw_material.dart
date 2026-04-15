class RawMaterial {
  final int id;
  final String name;
  final double stock;
  final String unit;
  final double minStock;
  final String? image;
  final bool isActive;

  RawMaterial({
    required this.id,
    required this.name,
    required this.stock,
    required this.unit,
    required this.minStock,
    this.image,
    this.isActive = true,
  });

  factory RawMaterial.fromJson(Map<String, dynamic> json) {
    return RawMaterial(
      id: json['id'],
      name: json['name'],
      stock: double.tryParse(json['stock'].toString()) ?? 0.0,
      unit: json['unit'] ?? 'unit',
      minStock: double.tryParse(json['min_stock'].toString()) ?? 0.0,
      image: json['image'],
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'stock': stock,
      'unit': unit,
      'min_stock': minStock,
      'image': image,
      'is_active': isActive,
    };
  }
}
