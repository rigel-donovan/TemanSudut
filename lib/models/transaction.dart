import 'product.dart';

class TransactionItem {
  final int id;
  final int productId;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final String? notes;
  final Product? product;

  TransactionItem({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.notes,
    this.product,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      id: json['id'],
      productId: json['product_id'],
      quantity: json['quantity'],
      unitPrice: double.parse(json['unit_price'].toString()),
      subtotal: double.parse(json['subtotal'].toString()),
      notes: json['notes'],
      product: json['product'] != null ? Product.fromJson(json['product']) : null,
    );
  }
}

class Transaction {
  final int id;
  final int? tableId;
  final String orderType;
  final String? customerName;
  final double subtotal;
  final double tax;
  final double total;
  final String paymentMethod;
  final String paymentStatus;
  final String kitchenStatus;
  final String? notes;
  final List<TransactionItem> items;

  Transaction({
    required this.id,
    this.tableId,
    required this.orderType,
    this.customerName,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.kitchenStatus,
    this.notes,
    required this.items,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List? ?? [];
    List<TransactionItem> items = itemsList.map((i) => TransactionItem.fromJson(i)).toList();

    return Transaction(
      id: json['id'],
      tableId: json['table_id'],
      orderType: json['order_type'],
      customerName: json['customer_name'],
      subtotal: double.parse(json['subtotal'].toString()),
      tax: double.parse(json['tax'].toString()),
      total: double.parse(json['total'].toString()),
      paymentMethod: json['payment_method'],
      paymentStatus: json['payment_status'],
      kitchenStatus: json['kitchen_status'],
      notes: json['notes'],
      items: items,
    );
  }
}
