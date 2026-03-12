import 'category.dart';

class Product {
  final int id;
  final int categoryId;
  final String name;
  final String description;
  final double price;
  final int stock;
  final String? image;
  final Category? category;

  Product({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    this.image,
    this.category,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      categoryId: json['category_id'],
      name: json['name'],
      description: json['description'] ?? '',
      price: double.parse(json['price'].toString()),
      stock: json['stock'],
      image: json['image'],
      category: json['category'] != null ? Category.fromJson(json['category']) : null,
    );
  }
}
