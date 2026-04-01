import 'category.dart';

class Product {
  final int id;
  final int categoryId;
  final String name;
  final String description;
  final double price;
  final int stock;
  final String? image;
  final bool isActive;
  final Category? category;

  Product({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    this.isActive = true,
    this.image,
    this.category,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      categoryId: json['category_id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      description: json['description'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      stock: int.tryParse(json['stock'].toString()) ?? 0,
      isActive: json['is_active'] == 1 || json['is_active'] == true || json['is_active'] == "1",
      image: json['image'],
      category: json['category'] != null ? Category.fromJson(json['category']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'category_id': categoryId,
    'name': name,
    'description': description,
    'price': price,
    'stock': stock,
    'is_active': isActive,
    'image': image,
    'category': category?.toJson(),
  };
}
