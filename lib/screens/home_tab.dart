import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

class _HomeTabState extends State<HomeTab> with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        return Scaffold(
          backgroundColor: Colors.grey[50], 
          body: RefreshIndicator(
           color: const Color(0xFF5D4037),
            onRefresh: () => cart.refreshProducts(),
            child: CustomScrollView(
            slivers: [
              // Header Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 48, bottom: 16),
                  child: MediaQuery.of(context).size.width > 800
                      ? _buildTabletHeader(context, cart)
                      : _buildMobileHeader(context, cart),
                ),
              ),
              
              // Categories Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 48,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          children: [
                                _buildCategoryItem(
                                  'All', cart.selectedCategory == null, 
                                  () => cart.filterByCategory(null),
                                ),
                                ...cart.categories.map((cat) {
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 10.0),
                                    child: _buildCategoryItem(
                                      cat.name,
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
                          crossAxisCount: MediaQuery.of(context).size.width > 800 ? 4 : (MediaQuery.of(context).size.width > 600 ? 3 : 2),
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 24, 
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
          ),
        );
      },
    );
  }

  Widget _buildCategoryItem(String title, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: isSelected 
              ? Border.all(color: Colors.orange, width: 1.5)
              : Border.all(color: Colors.transparent),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.orange : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, CartProvider cart, Product product) {
    return GestureDetector(
      onTap: () {
        cart.addToCart(product);
        // Remove snackbar here or clear immediately to avoid delay queues
        ScaffoldMessenger.of(context).clearSnackBars();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main Card Container
          Positioned.fill(
            top: 30, // Space for circular image to protrude
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: Offset(0, 4))
                ],
                border: Border.all(color: Colors.grey[200]!)
              ),
              padding: EdgeInsets.fromLTRB(12, 55, 12, 12), // Top padding gives room for image 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    product.name, 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87), 
                    maxLines: 2, 
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    AppFormat.currency(product.price), 
                    style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.w800, fontSize: 13)
                  ),
                ],
              ),
            ),
          ),
          
          // Protruding Circular Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: Offset(0, 4))
                  ],
                ),
                child: ClipOval(
                  child: product.image != null && product.image!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: ApiService().getImageUrl(product.image),
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(child: CircularProgressIndicator(color: Colors.orange, strokeWidth: 2)),
                        errorWidget: (context, url, error) => Icon(Icons.broken_image_outlined, size: 30, color: Colors.black12),
                      )
                    : Icon(Icons.fastfood, size: 30, color: Colors.black26),
                ),
              ),
            ),
          ),

          // Stock Badge if low/empty
          if (product.stock <= 5)
            Positioned(
              top: 40, right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: product.stock == 0 ? Colors.red : Colors.orange,
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(4)),
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

  Widget _buildTabletHeader(BuildContext context, CartProvider cart) {
    return Row(
      children: [
        // Search Bar fills space
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!)
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products.....',
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
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) {
                setState(() {});
                cart.setSearchQuery(value);
              },
            ),
          ),
        ),
        SizedBox(width: 16),
        // Sync icon
        IconButton(
          icon: Icon(Icons.sync, color: Colors.grey[600]),
          onPressed: () => cart.refreshProducts(),
        ),
        SizedBox(width: 8),
        // Webkul close shift / Select table simulation
        if (cart.isShiftOpen && Provider.of<AuthProvider>(context, listen: false).can('open_shift'))
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              elevation: 0,
            ),
            onPressed: () => _showCloseShiftDialog(context, cart),
            child: Text('Close Shift', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }

  Widget _buildMobileHeader(BuildContext context, CartProvider cart) {
    return Column(
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
                    backgroundColor: const Color(0xFF5D4037),
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
