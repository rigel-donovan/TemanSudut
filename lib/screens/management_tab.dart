import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../widgets/popup_notification.dart';
import 'user_management_tab.dart';
import 'printer_settings_screen.dart';
import '../models/raw_material.dart';
import '../utils/app_format.dart';
import '../providers/auth_provider.dart';

class ManagementTab extends StatefulWidget {
  @override
  _ManagementTabState createState() => _ManagementTabState();
}

class _ManagementTabState extends State<ManagementTab> with SingleTickerProviderStateMixin {
  TabController? _tabCtrl;
  bool _isOwner = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthProvider>(context);
    
    // Check permissions
    final bool canStock = auth.can('manage_stock');
    final bool canEmployees = auth.can('manage_employees');
    final bool canPrinter = auth.can('manage_printer');
    final bool canRawItems = auth.can('manage_raw_materials');
    
    int tabCount = 0;
    if (canStock) tabCount++;
    if (canEmployees) tabCount++;
    if (canPrinter) tabCount++;
    if (canRawItems) tabCount++;

    if (_tabCtrl == null || _tabCtrl!.length != tabCount) {
      _tabCtrl?.dispose();
      _tabCtrl = TabController(length: tabCount, vsync: this);
    }
  }

  @override
  void dispose() {
    _tabCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_tabCtrl == null) return SizedBox.shrink();

    return Column(
      children: [
        // Tab bar header
        Container(
          color: Colors.black,
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Text('Management', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                TabBar(
                  controller: _tabCtrl,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey[400],
                  tabs: [
                    if (Provider.of<AuthProvider>(context, listen: false).can('manage_stock')) 
                      Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Stok Produk'),
                    if (Provider.of<AuthProvider>(context, listen: false).can('manage_employees')) 
                      Tab(icon: Icon(Icons.people_outline), text: 'Karyawan'),
                    if (Provider.of<AuthProvider>(context, listen: false).can('manage_printer')) 
                      Tab(icon: Icon(Icons.print_outlined), text: 'Printer'),
                    if (Provider.of<AuthProvider>(context, listen: false).can('manage_raw_materials')) 
                      Tab(icon: Icon(Icons.bakery_dining), text: 'Bahan Baku'),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              if (Provider.of<AuthProvider>(context, listen: false).can('manage_stock')) 
                _StockManagementView(),
              if (Provider.of<AuthProvider>(context, listen: false).can('manage_employees')) 
                UserManagementTab(),
              if (Provider.of<AuthProvider>(context, listen: false).can('manage_printer')) 
                PrinterSettingsScreen(),
              if (Provider.of<AuthProvider>(context, listen: false).can('manage_raw_materials')) 
                _RawMaterialsView(),
            ],
          ),
        ),
      ],
    );
  }
}

// ---- Stock Management (original ManagementTab content) ----

class _StockManagementView extends StatefulWidget {
  @override
  _StockManagementViewState createState() => _StockManagementViewState();
}

class _StockManagementViewState extends State<_StockManagementView> {
  final ApiService _apiService = ApiService();
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final products = await _apiService.getProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: Colors.black));
    }

    return RefreshIndicator(
      onRefresh: _fetchProducts,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return Container(
            margin: EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))
              ],
            ),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: product.image != null
                    ? Image.network(
                        _apiService.getImageUrl(product.image),
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                          child: Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      )
                    : Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.fastfood, color: Colors.grey),
                      ),
              ),
              title: Text(product.name, style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${AppFormat.currency(product.price)} · Stok: ${product.stock}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline, color: Colors.red),
                    onPressed: product.stock > 0
                        ? () async {
                            final success = await _apiService.updateProduct(product.id, {'stock': product.stock - 1});
                            if (success) _fetchProducts();
                          }
                        : null,
                  ),
                  Text('${product.stock}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline, color: Colors.green),
                    onPressed: () async {
                      final success = await _apiService.updateProduct(product.id, {'stock': product.stock + 1});
                      if (success) _fetchProducts();
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: Colors.black),
                    onPressed: () => _showEditDialog(product),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showEditDialog(Product product) {
    final stockCtrl = TextEditingController(text: product.stock.toString());
    final priceCtrl = TextEditingController(text: product.price.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Edit ${product.name}', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: stockCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Stok',
                  prefixIcon: Icon(Icons.inventory),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Harga (Rp)',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.pop(dialogCtx);
                final success = await _apiService.updateProduct(product.id, {
                  'stock': int.tryParse(stockCtrl.text) ?? product.stock,
                  'price': double.tryParse(priceCtrl.text) ?? product.price,
                });

                if (success) {
                  PopupNotification.show(
                    context,
                    title: 'Berhasil Diperbarui ✏️',
                    message: '${product.name} telah diupdate.',
                    type: PopupType.success,
                  );
                  _fetchProducts();
                } else {
                  PopupNotification.show(
                    context,
                    title: 'Gagal Memperbarui',
                    message: 'Tidak bisa mengupdate ${product.name}.',
                    type: PopupType.error,
                  );
                }
              },
              child: Text('Simpan'),
            ),
          ],
        );
      },
    );
  }
}

// ---- Raw Materials Management ----

class _RawMaterialsView extends StatefulWidget {
  @override
  _RawMaterialsViewState createState() => _RawMaterialsViewState();
}

class _RawMaterialsViewState extends State<_RawMaterialsView> {
  final ApiService _apiService = ApiService();
  List<RawMaterial> _materials = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMaterials();
  }

  Future<void> _fetchMaterials() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final materials = await _apiService.getRawMaterials();
      if (!mounted) return;
      setState(() {
        _materials = materials;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: Colors.black));
    }

    return RefreshIndicator(
      onRefresh: _fetchMaterials,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _materials.length,
        itemBuilder: (context, index) {
          final material = _materials[index];
          return Container(
            margin: EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))
              ],
            ),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: Colors.amber[50], 
                  borderRadius: BorderRadius.circular(12),
                  image: material.image != null && material.image!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(_apiService.getImageUrl(material.image)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: material.image == null || material.image!.isEmpty
                    ? Icon(Icons.bakery_dining, color: Colors.amber[700])
                    : null,
              ),
              title: Text(material.name, style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Stok: ${material.stock} ${material.unit}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: Colors.blue),
                    onPressed: () => _showEditDialog(material),
                  ),
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline, color: Colors.red),
                    onPressed: material.stock > 0
                        ? () async {
                            final success = await _apiService.updateRawMaterial(material.id, {'stock': material.stock - 1});
                            if (success) _fetchMaterials();
                          }
                        : null,
                  ),
                  Text('${material.stock.toStringAsFixed(1)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline, color: Colors.green),
                    onPressed: () async {
                      final success = await _apiService.updateRawMaterial(material.id, {'stock': material.stock + 1});
                      if (success) _fetchMaterials();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showEditDialog(RawMaterial material) {
    final nameCtrl = TextEditingController(text: material.name);
    final stockCtrl = TextEditingController(text: material.stock.toString());
    final unitCtrl = TextEditingController(text: material.unit);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit ${material.name}', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Nama Bahan',
                  prefixIcon: Icon(Icons.shopping_bag),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: stockCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Stok',
                  prefixIcon: Icon(Icons.inventory),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: unitCtrl,
                decoration: InputDecoration(
                  labelText: 'Satuan (kg, gr, dll)',
                  prefixIcon: Icon(Icons.straighten),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final success = await _apiService.updateRawMaterial(material.id, {
                'name': nameCtrl.text,
                'stock': double.tryParse(stockCtrl.text) ?? material.stock,
                'unit': unitCtrl.text,
              });

              if (success) {
                PopupNotification.show(
                  context,
                  title: 'Berhasil Diperbarui ✏️',
                  message: '${material.name} telah diupdate.',
                  type: PopupType.success,
                );
                _fetchMaterials();
              } else {
                PopupNotification.show(
                  context,
                  title: 'Gagal Memperbarui',
                  message: 'Tidak bisa mengupdate ${material.name}.',
                  type: PopupType.error,
                );
              }
            },
            child: Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
