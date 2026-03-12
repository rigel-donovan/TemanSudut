import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/table_model.dart';
import '../models/category.dart';
import '../services/api_service.dart';

class CartItem {
  final Product product;
  int quantity;
  String? notes;

  CartItem({required this.product, this.quantity = 1, this.notes});

  double get subtotal => product.price * quantity;
}

class CartProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Product> _availableProducts = [];
  List<Product> get availableProducts => _availableProducts;

  List<Category> _categories = [];
  List<Category> get categories => _categories;
  
  Category? _selectedCategory;
  Category? get selectedCategory => _selectedCategory;

  List<CartItem> _items = [];
  String _orderType = 'dine_in'; 
  TableModel? _selectedTable;
  String? _customerName;
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  bool _isShiftOpen = false;
  bool _isLoadingShift = true;
  Map<String, dynamic>? _currentShift;

  CartProvider() {
    _fetchProducts();
    checkShiftStatus();
  }

  Future<void> checkShiftStatus() async {
    _isLoadingShift = true;
    notifyListeners();
    _currentShift = await _apiService.getCurrentShift();
    _isShiftOpen = _currentShift != null;
    _isLoadingShift = false;
    notifyListeners();
  }

  Future<bool> openShift(double amount) async {
    bool success = await _apiService.openShift(amount);
    if (success) {
      await checkShiftStatus();
    }
    return success;
  }

  Future<bool> closeShift(double amount) async {
    bool success = await _apiService.closeShift(endingCash: amount);
    if (success) {
      _isShiftOpen = false;
      _currentShift = null;
      _items.clear();
      notifyListeners();
    }
    return success;
  }

  bool get isShiftOpen => _isShiftOpen;
  bool get isLoadingShift => _isLoadingShift;
  Map<String, dynamic>? get currentShift => _currentShift;

  Future<void> filterByCategory(Category? category) async {
    _selectedCategory = category;
    _fetchProducts();
  }

  Future<void> setSearchQuery(String query) async {
    _searchQuery = query;
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    if (_categories.isEmpty) {
      _categories = await _apiService.getCategories();
    }
    _availableProducts = await _apiService.getProducts(
      categoryId: _selectedCategory?.id,
      search: _searchQuery,
    );
    notifyListeners();
  }

  List<CartItem> get items => _items;
  String get orderType => _orderType;
  TableModel? get selectedTable => _selectedTable;
  String? get customerName => _customerName;

  double get subtotal => _items.fold(0, (sum, item) => sum + item.subtotal);
  double get tax => 0; 
  double get total => subtotal;

  void setOrderType(String type) {
    _orderType = type;
    if (type == 'take_away') {
      _selectedTable = null;
    }
    notifyListeners();
  }

  void setSelectedTable(TableModel? table) {
    _selectedTable = table;
    notifyListeners();
  }

  void setCustomerName(String? name) {
    _customerName = name;
    notifyListeners();
  }

  void addToCart(Product product, {String? notes}) {
    int index = _items.indexWhere((item) => item.product.id == product.id && item.notes == notes);
    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(CartItem(product: product, notes: notes));
    }
    notifyListeners();
  }

  void removeFromCart(CartItem cartItem) {
    _items.remove(cartItem);
    notifyListeners();
  }

  void updateQuantity(CartItem cartItem, int quantity) {
    if (quantity <= 0) {
      removeFromCart(cartItem);
    } else {
      cartItem.quantity = quantity;
      notifyListeners();
    }
  }

  void updateItemNote(CartItem cartItem, String newNote) {
    cartItem.notes = newNote;
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _selectedTable = null;
    _customerName = null;
    _orderType = 'dine_in';
    notifyListeners();
  }

  Future<bool> checkout(String paymentMethod) async {
    if (_items.isEmpty) return false;

    // Build the request payload. Fallback to take_away if dine_in but no table is selected to avoid 422.
    String finalOrderType = _orderType;
    if (_orderType == 'dine_in' && _selectedTable == null) {
        finalOrderType = 'take_away';
    }

    Map<String, dynamic> payload = {
      'payment_method': paymentMethod,
      'order_type': finalOrderType,
      'table_id': _selectedTable?.id,
      'customer_name': _customerName,
      'items': _items.map((item) {
        return {
          'product_id': item.product.id,
          'quantity': item.quantity,
          'notes': item.notes,
        };
      }).toList(),
    };

    try {
      bool success = await _apiService.createTransaction(payload);
      if (success) {
        clearCart();
      }
      return success;
    } catch (e) {
      print('Checkout Error: $e');
      return false;
    }
  }
}
