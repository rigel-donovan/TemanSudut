class ProductIngredient {
  final int rawMaterialId;
  final String rawMaterialName;
  final double quantityUsed;
  final String unit;

  ProductIngredient({
    required this.rawMaterialId,
    required this.rawMaterialName,
    required this.quantityUsed,
    required this.unit,
  });

  factory ProductIngredient.fromJson(Map<String, dynamic> json) {
    return ProductIngredient(
      rawMaterialId: json['raw_material_id'],
      rawMaterialName: json['raw_material_name'] ?? '',
      quantityUsed: double.tryParse(json['quantity_used'].toString()) ?? 0.0,
      unit: json['unit'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'raw_material_id': rawMaterialId,
    'raw_material_name': rawMaterialName,
    'quantity_used': quantityUsed,
    'unit': unit,
  };
}
