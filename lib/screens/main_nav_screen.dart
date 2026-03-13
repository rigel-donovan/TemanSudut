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
          // Find index of HistoryTab
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
    // Auto-refresh data when switching to these tabs
    if (index == 1) {
      _historyKey.currentState?.refreshHistory();
    } else if (index == 2) {
      _activeOrdersKey.currentState?.refreshOrders();
    }
  }

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
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
            body: Center(child: CircularProgressIndicator(color: Colors.black)),
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
                prefixStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black, width: 2)),
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
                  backgroundColor: Colors.black,
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
                      // Show stock alert after opening shift
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

  Widget _buildTabletLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Row(
        children: [
          // Main Content
          Expanded(
            flex: _isSidebarMinimized ? 1 : 5,
            child: ClipRRect(
              borderRadius: BorderRadius.horizontal(left: Radius.circular(32)),
              child: Scaffold(
                backgroundColor: Colors.white,
                body: Stack(
                  children: [
                    SafeArea(
                      child: _pages[_selectedIndex],
                    ),
                    if (_isSidebarMinimized)
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: InkWell(
                            onTap: () => setState(() => _isSidebarMinimized = false),
                            child: Container(
                              width: 32,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
                                boxShadow: [
                                  BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(-2, 0))
                                ],
                              ),
                              child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                bottomNavigationBar: _buildBottomNav(),
              ),
            ),
          ),
          // Sidebar Toggle Handle
          if (!_isSidebarMinimized)
            Container(
              width: 1,
              height: double.infinity,
              color: Colors.grey[300],
            ),
          // Sidebar
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: _isSidebarMinimized ? 0 : MediaQuery.of(context).size.width * 0.35,
            child: _isSidebarMinimized 
              ? SizedBox.shrink()
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(left: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: Stack(
                    children: [
                      OrdersTab(onOrderFinished: () => _onItemTapped(2)),
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: InkWell(
                            onTap: () => setState(() => _isSidebarMinimized = true),
                            child: Container(
                              width: 24,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.horizontal(right: Radius.circular(12)),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: Offset(2, 0))
                                ],
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
        child: _pages[_selectedIndex],
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
        selectedItemColor: Colors.black,
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
