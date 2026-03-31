import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../models/product.dart';
import '../utils/app_format.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/stock_alert_dialog.dart';

class HomeTab extends StatefulWidget {
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        return Scaffold(
          backgroundColor: Colors.grey[50], 
          body: CustomScrollView(
            slivers: [
              // Header Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 48, bottom: 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey[300]!, width: 1),
                                ),
                                child: ClipOval(
                                  child: Image.asset('res/logo.png', width: 36, height: 36, fit: BoxFit.cover),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('TemanSudut', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                            ],
                          ),
                          if (cart.isShiftOpen && Provider.of<AuthProvider>(context, listen: false).can('open_shift'))
                            InkWell(
                              onTap: () => _showCloseShiftDialog(context, cart),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.red[100]!),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.lock_outline, size: 14, color: Colors.red[700]),
                                    SizedBox(width: 4),
                                    Text('Tutup Kasir', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red[700])),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 20),
                      // Persistent Search Bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: Offset(0, 4))],
                          border: Border.all(color: Colors.grey[200]!)
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Cari produk favoritmu...',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.close, size: 20, color: Colors.grey[600]),
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        cart.setSearchQuery('');
                                      });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          ),
                          onChanged: (value) {
                            setState(() {});
                            cart.setSearchQuery(value);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Categories Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kategori', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 12),
                      SizedBox(
                        height: 44, // Slightly slimmer pills
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          children: [
                            _buildCategoryItem(
                              'Semua', Icons.apps, cart.selectedCategory == null, 
                              () => cart.filterByCategory(null),
                            ),
                            ...cart.categories.map((cat) {
                              return Padding(
                                padding: const EdgeInsets.only(left: 10.0),
                                child: _buildCategoryItem(
                                  cat.name, 
                                  Icons.fastfood,
                                  cart.selectedCategory?.id == cat.id,
                                  () => cart.filterByCategory(cat),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              
              // Products Section
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                sliver: cart.availableProducts.isEmpty
                    ? SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 40.0),
                            child: Column(
                              children: [
                                _searchController.text.isNotEmpty 
                                    ? Icon(Icons.search_off, size: 48, color: Colors.grey[300])
                                    : CircularProgressIndicator(color: Colors.black),
                                SizedBox(height: 16),
                                Text(
                                  _searchController.text.isNotEmpty ? 'Produk tidak ditemukan' : 'Memuat produk...',
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MediaQuery.of(context).size.width > 800 ? 5 : (MediaQuery.of(context).size.width > 600 ? 4 : 2),
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final product = cart.availableProducts[index];
                            return _buildProductCard(context, cart, product);
                          },
                          childCount: cart.availableProducts.length,
                        ),
                      ),
              ),
              
              SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryItem(String title, IconData icon, bool isSelected, VoidCallback onTap) {
    return FilterChip(
      label: Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 13)),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.white,
      selectedColor: Colors.black,
      showCheckmark: false,
      elevation: isSelected ? 4 : 0,
      shadowColor: Colors.black26,
      side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey[300]!),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildProductCard(BuildContext context, CartProvider cart, Product product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: Offset(0, 6))
        ],
        border: Border.all(color: Colors.grey[100]!)
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Edge-to-edge image
              Expanded(
                flex: 3,
                child: Container(
                  color: Colors.grey[100],
                  child: product.image != null && product.image!.isNotEmpty
                    ? Image.network(
                        ApiService().getImageUrl(product.image),
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(child: CircularProgressIndicator(color: Colors.black12, strokeWidth: 2));
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.broken_image_outlined, size: 40, color: Colors.black12);
                        },
                      )
                    : Icon(Icons.fastfood, size: 50, color: Colors.black26),
                ),
              ),
              // Content
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(product.name, 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87), 
                        maxLines: 2, 
                        overflow: TextOverflow.ellipsis
                      ),
                      Text(AppFormat.currency(product.price), 
                        style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w800, fontSize: 13)
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Add Button positioned bottom right
          Positioned(
            bottom: 8,
            right: 8,
            child: Material(
              color: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  cart.addToCart(product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${product.name} tertambah', style: TextStyle(fontWeight: FontWeight.bold)), 
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    )
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(Icons.add, color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
          
          // Stock Badge if low/empty
          if (product.stock <= 5)
            Positioned(
              top: 8, left: 8,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: product.stock == 0 ? Colors.red : Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  product.stock == 0 ? 'Habis' : 'Sisa ${product.stock}',
                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            )
        ],
      ),
    );
  }

  void _showCloseShiftDialog(BuildContext context, CartProvider cart) {
    final shift = cart.currentShift;
    double expectedCash = double.tryParse(shift?['current_cash']?.toString() ?? '0') ?? 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final _cashController = TextEditingController(
          text: expectedCash > 0 ? expectedCash.toInt().toString() : '',
        );
        bool _isClosing = false;
        
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.lock_outline, color: Colors.black),
                  SizedBox(width: 8),
                  Text('Tutup Sesi Kasir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Masukkan nominal uang akhir di laci kasir (setelah shift selesai).', style: TextStyle(color: Colors.grey[700], height: 1.5)),
                  SizedBox(height: 16),
                  TextField(
                    controller: _cashController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Uang Akhir (Opsional)',
                      prefixText: 'Rp ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.black)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _isClosing ? null : () => Navigator.pop(context),
                  child: Text('Batal', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  onPressed: _isClosing ? null : () async {
                    setState(() => _isClosing = true);
                    double amount = double.tryParse(_cashController.text.replaceAll(',', '')) ?? 0;
                    bool success = await cart.closeShift(amount);
                    if (context.mounted) {
                      setState(() => _isClosing = false);
                      if (success) {
                        Navigator.pop(context);
                        // Show stock alert after closing shift
                        showDialog(
                          context: context,
                          builder: (context) => const StockAlertDialog(
                            title: 'Kasir Ditutup',
                            message: 'Shift telah berakhir. Silakan cek ringkasan stok terakhir:',
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menutup sesi kasir'), backgroundColor: Colors.red));
                      }
                    }
                  },
                  child: _isClosing 
                    ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Tutup Kasir', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      }
    );
  }
}
