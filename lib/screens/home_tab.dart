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
        return CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (!_isSearching)
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey[200]!, width: 1),
                            ),
                            child: ClipOval(
                              child: Image.asset('res/logo.png', width: 32, height: 32, fit: BoxFit.cover),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('TemanSudut', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    _isSearching 
                      ? Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: TextField(
                              
                              controller: _searchController,
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: 'Cari produk...',
                                prefixIcon: Icon(Icons.search, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(Icons.close, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _isSearching = false;
                                      _searchController.clear();
                                      cart.setSearchQuery('');
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                              ),
                              onChanged: (value) {
                                cart.setSearchQuery(value);
                              },
                            ),
                          ),
                        )
                      : Row(
                          children: [
                            if (cart.isShiftOpen && Provider.of<AuthProvider>(context, listen: false).can('open_shift'))
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[50],
                                  foregroundColor: Colors.red[700],
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: Icon(Icons.lock_outline, size: 18),
                                label: Text('Tutup Kasir', style: TextStyle(fontWeight: FontWeight.bold)),
                                onPressed: () => _showCloseShiftDialog(context, cart),
                              ),
                            SizedBox(width: 16),
                            IconButton(
                              icon: Icon(Icons.search, size: 28),
                              onPressed: () {
                                setState(() {
                                  _isSearching = true;
                                });
                              },
                            ),
                          ]
                        ),
                  ],
                ),
              ),
            ),
            
            // Categories
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('| Category', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    SizedBox(
                      height: 50,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildCategoryItem(
                            'All', '', Icons.apps, cart.selectedCategory == null, 
                            () => cart.filterByCategory(null),
                          ),
                          ...cart.categories.map((cat) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 12.0),
                              child: _buildCategoryItem(
                                cat.name, 
                                '', 
                                Icons.fastfood_outlined,
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
            
            // Products List Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
                child: Text('| Products List', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold)),
              ),
            ),
            
            // Products Grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              sliver: cart.availableProducts.isEmpty
                  ? SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: Colors.black)))
                  : SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context).size.width > 800 ? 5 : (MediaQuery.of(context).size.width > 600 ? 4 : 2),
                        childAspectRatio: 0.75,
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
            
            SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
    );
  }

  Widget _buildCategoryItem(String title, String subtitle, IconData icon, bool isSelected, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.transparent,
        border: Border.all(color: isSelected ? Colors.grey[300]! : Colors.transparent),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isSelected ? [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0,2))] : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: isSelected ? Colors.black : Colors.grey, size: 20),
                SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // prevent overflow
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.black : Colors.grey)),
                    if (subtitle.isNotEmpty) Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, CartProvider cart, Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
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
        SizedBox(height: 8),
        Text(product.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
        SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(AppFormat.currency(product.price), style: TextStyle(color: Colors.green[600], fontWeight: FontWeight.bold)),
            InkWell(
              onTap: () {
                cart.addToCart(product);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${product.name} ditambahkan'), duration: Duration(seconds: 1)));
              },
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                child: Icon(Icons.add, color: Colors.white, size: 16),
              ),
            ),
          ],
        )
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
