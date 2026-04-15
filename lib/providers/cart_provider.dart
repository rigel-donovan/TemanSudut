import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/table_model.dart';
import '../models/category.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';

class CartItem {
  final Product product;
  int quantity;
  String? notes;
  double extraCharge;
  String? extraChargeLabel;
  bool isFree;

  CartItem({
    required this.product, 
    this.quantity = 1, 
    this.notes, 
    this.extraCharge = 0, 
    this.extraChargeLabel,
    this.isFree = false,
  });

  double get subtotal => isFree ? 0 : (product.price + extraCharge) * quantity;
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

  // All products
  List<Product> _allProducts = [];

  Future<void> filterByCategory(Category? category) async {
    _selectedCategory = category;
    _applyFilter();
  }

  Future<void> setSearchQuery(String query) async {
    _searchQuery = query;
    _applyFilter();
  }

  // Apply category + search filter locally (no network call)
  void _applyFilter() {
    List<Product> result = _allProducts;
    if (_selectedCategory != null) {
      result = result.where((p) => p.categoryId == _selectedCategory!.id).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((p) => p.name.toLowerCase().contains(q)).toList();
    }
    _availableProducts = result;
    notifyListeners();
  }

  /// Initial load: use cache if valid, otherwise fetch and store in cache.
  Future<void> _fetchProducts() async {
    // â”€â”€ Categories â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if (_categories.isEmpty) {
      final cachedCats = await CacheService.getCategories();
      if (cachedCats != null) {
        _categories = cachedCats.map((j) => Category.fromJson(j)).toList();
      } else {
        _categories = await _apiService.getCategories();
        await CacheService.saveCategories(_categories.map((c) => c.toJson()).toList());
      }
    }

    // â”€â”€ Products (all, unfiltered) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if (_allProducts.isEmpty) {
      final cachedProds = await CacheService.getProducts();
      if (cachedProds != null) {
        _allProducts = cachedProds.map((j) => Product.fromJson(j)).toList();
      } else {
        _allProducts = await _apiService.getProducts();
        await CacheService.saveProducts(_allProducts.map((p) => p.toJson()).toList());
      }
    }

    _applyFilter();
  }

  /// Force refresh from network (e.g. after admin edits a product).
  Future<void> refreshProducts() async {
    await CacheService.invalidateAll();
    _allProducts = [];
    _categories = [];
    await _fetchProducts();
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

  void toggleFreeCup(CartItem cartItem) {
    cartItem.isFree = !cartItem.isFree;
    notifyListeners();
  }

  void updateExtraCharge(CartItem cartItem, double charge, {String? label}) {
    cartItem.extraCharge = charge;
    cartItem.extraChargeLabel = label;
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _selectedTable = null;
    _customerName = null;
    _orderType = 'dine_in';
    notifyListeners();
  }

  String? _lastCheckoutError;
  String? get lastCheckoutError => _lastCheckoutError;

  Future<bool> checkout(String paymentMethod, {double? amountReceived, double? changeAmount, dynamic photo}) async {
    if (_items.isEmpty) return false;
    _lastCheckoutError = null;
    String finalOrderType = _orderType;
    if (_orderType == 'dine_in' && _selectedTable == null) {
        finalOrderType = 'take_away';
    }

    Map<String, dynamic> payload = {
      'payment_method': paymentMethod,
      'order_type': finalOrderType,
      'table_id': _selectedTable?.id,
      'customer_name': _customerName,
      'amount_received': amountReceived,
      'change_amount': changeAmount,
      'items': _items.map((item) {
        String? finalNotes = item.notes;
        if (item.extraCharge > 0) {
          String extraInfo = '[Extra: ${item.extraChargeLabel ?? "Tambahan"} +Rp${item.extraCharge.toInt()}]';
          finalNotes = finalNotes != null && finalNotes.isNotEmpty ? '$finalNotes | $extraInfo' : extraInfo;
        }
        if (item.isFree) {
          String freeInfo = '[FREE CUP / GRATIS]';
          finalNotes = finalNotes != null && finalNotes.isNotEmpty ? '$finalNotes | $freeInfo' : freeInfo;
        }

        double finalExtraCharge = item.extraCharge;
        if (item.isFree) {
          finalExtraCharge = -(item.product.price);
        }

        return {
          'product_id': item.product.id,
          'quantity': item.quantity,
          'notes': finalNotes,
          'extra_charge': finalExtraCharge,
        };
      }).toList(),
    };

    try {
      final result = await _apiService.createTransaction(payload, photo: photo);
      if (result['success'] == true) {
        clearCart();
        await checkShiftStatus();
        return true;
      } else {
        // Stock shortage or other error
        final details = result['details'];
        if (details != null && details is List && details.isNotEmpty) {
          _lastCheckoutError = details.join('\n');
        } else {
          _lastCheckoutError = result['error'] ?? 'Gagal membuat transaksi';
        }
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Checkout Error: $e');
      _lastCheckoutError = 'Terjadi kesalahan saat checkout';
      notifyListeners();
      return false;
    }
  }
}
