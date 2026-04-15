import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'home_tab.dart';
import 'orders_tab.dart';
import 'history_tab.dart';
import 'profile_tab.dart';
import 'management_tab.dart';
import 'active_orders_tab.dart';
import '../widgets/custom_drawer.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/stock_alert_dialog.dart';

class MainNavScreen extends StatefulWidget {
  @override
  _MainNavScreenState createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _selectedIndex = 0;

  final _historyKey = GlobalKey<HistoryTabState>();
  final _activeOrdersKey = GlobalKey<ActiveOrdersTabState>();

  List<Widget> _pages = [];
  List<BottomNavigationBarItem> _navItems = [];

  bool _isSidebarMinimized = false;
  final TextEditingController _cashController = TextEditingController();
  bool _isOpeningShift = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _buildPagesForRole();
  }

  void _buildPagesForRole() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    final bool canHistory = auth.can('view_history');
    final bool canManagement = auth.can('manage_stock') || auth.can('manage_employees') || auth.can('manage_printer');

    _pages = [
      HomeTab(),
      if (canHistory) HistoryTab(key: _historyKey),
      ActiveOrdersTab(
        key: _activeOrdersKey, 
        onNavigateToHistory: canHistory ? () {
          int idx = _pages.indexWhere((p) => p is HistoryTab);
          if (idx != -1) _onItemTapped(idx);
        } : null
      ),
      if (canManagement) ManagementTab(),
      ProfileTab(),
    ];

    _navItems = [
      BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), activeIcon: Icon(Icons.storefront), label: 'Home'),
      if (canHistory) 
        BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'History'),
      BottomNavigationBarItem(icon: Icon(Icons.list_alt), activeIcon: Icon(Icons.list), label: 'Orders'),
      if (canManagement) 
        BottomNavigationBarItem(icon: Icon(Icons.grid_view_outlined), activeIcon: Icon(Icons.grid_view), label: 'Management'),
      BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
    ];

    if (_selectedIndex >= _pages.length) {
      _selectedIndex = 0;
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    return (await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Batal', style: TextStyle(color: Colors.grey[700])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Keluar'),
          ),
        ],
      ),
    )) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Consumer<CartProvider>(
        builder: (context, cart, child) {
          Widget mainContent = LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 800) {
                return _buildTabletLayout(context);
              } else {
                return _buildMobileLayout(context);
              }
            },
          );

          if (cart.isLoadingShift) {
            return Scaffold(
              backgroundColor: Colors.white,
              body: Center(child: CircularProgressIndicator(color: const Color(0xFF5D4037))),
            );
          }

          if (!cart.isShiftOpen) {
            return Scaffold(
              body: Stack(
                children: [
                  mainContent,
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                      child: Container(
                        color: Colors.white.withOpacity(0.5),
                        child: Center(
                          child: _buildOpenShiftCard(context, cart),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return mainContent;
        },
      ),
    );
  }


  Widget _buildOpenShiftCard(BuildContext context, CartProvider cart) {
    return Card(
      elevation: 20,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 380,
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.point_of_sale_rounded, size: 48, color: Colors.blue[700]),
            ),
            SizedBox(height: 24),
            Text('Buka Kasir', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
            SizedBox(height: 12),
            Text('Silakan masukkan modal awal (uang kembalian) untuk memulai shift.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], height: 1.5, fontSize: 15)),
            SizedBox(height: 32),
            TextField(
              controller: _cashController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Modal Awal',
                prefixText: 'Rp ',
                prefixStyle: TextStyle(color: const Color(0xFF5D4037), fontWeight: FontWeight.bold, fontSize: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFF5D4037), width: 2)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D4037),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isOpeningShift ? null : () async {
                  if (_cashController.text.isEmpty) return;
                  setState(() => _isOpeningShift = true);
                  double amount = double.tryParse(_cashController.text.replaceAll(',', '')) ?? 0;
                  bool success = await cart.openShift(amount);
                  if (mounted) {
                    setState(() => _isOpeningShift = false);
                    if (!success) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membuka kasir. Coba lagi.'), backgroundColor: Colors.red));
                    } else {
                      _cashController.clear();
                      showDialog(
                        context: context,
                        builder: (context) => const StockAlertDialog(
                          title: 'Kasir Dibuka',
                          message: 'Shift telah dimulai. Berikut adalah ringkasan stok saat ini:',
                        ),
                      );
                    }
                  }
                },
                child: _isOpeningShift 
                  ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Buka Kasir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletSidebar(BuildContext context) {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: const Color(0xFF5D4037),
        border: Border(right: BorderSide(color: const Color(0xFF4E342E)!)),
      ),
      child: Column(
        children: [
          SizedBox(height: 24),
          // Logo
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: ClipOval(
              child: Image.asset('res/logo.png', width: 36, height: 36, fit: BoxFit.cover),
            ),
          ),
          SizedBox(height: 8),
          Text('TemanSudut', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: -0.5, color: Colors.white70)),
          SizedBox(height: 32),
          // Nav Items
          Expanded(
            child: ListView.builder(
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedIndex == index;
                final item = _navItems[index]; 
                return InkWell(
                  onTap: () => _onItemTapped(index),
                  hoverColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    decoration: isSelected
                        ? BoxDecoration(
                            border: Border.all(color: Colors.white38, width: 1.5),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white.withOpacity(0.15),
                          )
                        : null,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected ? (item.activeIcon as Icon).icon : (item.icon as Icon).icon,
                          color: isSelected ? Colors.white : Colors.white54,
                        ),
                        SizedBox(height: 8),
                        Text(
                          item.label ?? '',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white54,
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Settings / Logout at bottom
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [

                IconButton(
                  icon: Icon(Icons.logout, color: Colors.red[400]),
                  onPressed: () async {
                    bool confirm = await _onWillPop();
                    if (confirm) {
                      Provider.of<AuthProvider>(context, listen: false).logout();
                    }
                  },
                ),
                SizedBox(height: 8),
                Text('Logout', style: TextStyle(color: Colors.white60, fontSize: 10)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Row(
        children: [
          // 1. Sidebar Navigation 
          _buildTabletSidebar(context),

          // 2. Main Content
          Expanded(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: SafeArea(
                child: Stack(
                  children: [
                    IndexedStack(
                      index: _selectedIndex,
                      children: _pages,
                    ),
                    if (_isSidebarMinimized)
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: FloatingActionButton.extended(
                          backgroundColor: const Color(0xFF5D4037),
                          foregroundColor: Colors.white,
                          onPressed: () => setState(() => _isSidebarMinimized = false),
                          icon: Stack(
                             alignment: Alignment.center,
                             children: [
                               const Icon(Icons.shopping_cart),
                               if (cart.items.isNotEmpty)
                                 Positioned(
                                   right: 0,
                                   top: 0,
                                   child: Container(
                                     padding: const EdgeInsets.all(4),
                                     decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                   )
                                 )
                             ]
                          ),
                          label: Text(
                            'Cart (${cart.items.length})', 
                            style: const TextStyle(fontWeight: FontWeight.bold)
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Cart / Orders Right Sidebar
          if (!_isSidebarMinimized)
            Container(
              width: MediaQuery.of(context).size.width * 0.35,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(left: BorderSide(color: Colors.grey[200]!)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(-5, 0))
                ]
              ),
              child: Column(
                children: [
                  // Minimize Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Keranjang (${cart.items.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        IconButton(
                          icon: const Icon(Icons.close_fullscreen),
                          tooltip: 'Minimize Cart',
                          onPressed: () => setState(() => _isSidebarMinimized = true),
                        )
                      ]
                    )
                  ),
                  Expanded(
                    child: OrdersTab(onOrderFinished: () => _onItemTapped(2)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: CustomDrawer(),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -5),
          )
        ]
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF5D4037),
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        currentIndex: _selectedIndex >= _navItems.length ? 0 : _selectedIndex,
        onTap: _onItemTapped,
        items: _navItems,
      ),
    );
  }
}
