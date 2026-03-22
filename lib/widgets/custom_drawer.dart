import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../utils/app_format.dart';

class CustomDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, CartProvider>(
      builder: (context, auth, cart, _) {
        final userName = auth.user?['name'] ?? 'Guest';
        return Drawer(
          backgroundColor: Colors.white,
          child: SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24),
                  color: Colors.black,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hi, $userName', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      if (auth.isOwner) ...[
                        SizedBox(height: 24),
                        Text('Revenue', style: TextStyle(color: Colors.grey, fontSize: 14)),
                        SizedBox(height: 8),
                        Text('\$35.85', style: TextStyle(color: Colors.greenAccent, fontSize: 24, fontWeight: FontWeight.bold)), // Placeholder for actual revenue
                      ]
                    ],
                  ),
                ),
                if (auth.can('manage_stock') || auth.can('manage_employees'))
                  ListTile(
                    leading: Icon(Icons.grid_view),
                    title: Text('Management'),
                    trailing: Icon(Icons.keyboard_arrow_down, size: 20),
                    onTap: () {},
                  ),
                if (auth.can('view_history'))
                  ListTile(
                    leading: Icon(Icons.receipt_long),
                    title: Text('History'),
                    onTap: () {},
                  ),
                if (auth.isOwner)
                  ListTile(
                    leading: Icon(Icons.bar_chart),
                    title: Text('Report Sale'),
                    onTap: () {},
                  ),
                ListTile(
                  leading: Icon(Icons.language),
                  title: Text('Language'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('English', style: TextStyle(color: Colors.grey)),
                      SizedBox(width: 8),
                      Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.grey),
                    ]
                  ),
                  onTap: () {},
                ),
                ListTile(
                  leading: Icon(Icons.light_mode_outlined),
                  title: Text('Light Mode'),
                  trailing: Switch(
                    value: false, 
                    onChanged: (val) {},
                    activeColor: Colors.black,
                  ),
                ),
                Spacer(),
                if (cart.isShiftOpen)
                  ListTile(
                    leading: Icon(Icons.point_of_sale_rounded, color: Colors.orange[700]),
                    title: Text('Tutup Kasir', style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.of(context).pop();
                      _showCloseShiftDialog(context, cart);
                    },
                  ),
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.redAccent),
                  title: Text('Logout', style: TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext dialogContext) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: Row(
                            children: [
                              Icon(Icons.logout, color: Colors.redAccent),
                              SizedBox(width: 8),
                              Text('Konfirmasi Logout', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          content: Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(dialogContext).pop(),
                              child: Text('Batal', style: TextStyle(color: Colors.grey[700])),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[700],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                auth.logout();
                              },
                              child: Text('Keluar', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        );
      }
    );
  }
}

void _showCloseShiftDialog(BuildContext context, CartProvider cart) {
  final shift = cart.currentShift;
  if (shift == null) return;

  double startingCash = double.tryParse(shift['starting_cash']?.toString() ?? '0') ?? 0;
  double expectedCash = double.tryParse(shift['current_cash']?.toString() ?? '0') ?? 0;
  
  final TextEditingController endCashController = TextEditingController(
    text: expectedCash.toInt().toString()
  );

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      double enteredCash = expectedCash;
      double difference = 0;

      return StatefulBuilder(
        builder: (ctx, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.point_of_sale_rounded, color: Colors.red[700]),
                SizedBox(width: 8),
                Text('Tutup Kasir', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        _drawerSummaryRow('Modal Awal', AppFormat.currency(startingCash)),
                        SizedBox(height: 8),
                        _drawerSummaryRow('Uang di Laci (Estimasi)', AppFormat.currency(expectedCash), highlight: true),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Text('Uang Fisik di Laci', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  SizedBox(height: 8),
                  TextField(
                    controller: endCashController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      prefixStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      hintText: '0',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black, width: 2)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    onChanged: (val) {
                      setStateDialog(() {
                        enteredCash = double.tryParse(val.replaceAll(',', '')) ?? 0;
                        difference = enteredCash - expectedCash;
                      });
                    },
                  ),
                  if (endCashController.text.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: difference >= 0 ? Colors.green[50] : Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: difference >= 0 ? Colors.green[200]! : Colors.red[200]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            difference >= 0 ? 'Selisih Lebih' : 'Selisih Kurang',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: difference >= 0 ? Colors.green[700] : Colors.red[700],
                            ),
                          ),
                          Text(
                            AppFormat.currency(difference.abs()),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: difference >= 0 ? Colors.green[700] : Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text('Batal', style: TextStyle(color: Colors.grey[700])),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  double endingCash = double.tryParse(endCashController.text.replaceAll(',', '')) ?? 0;
                  Navigator.of(dialogContext).pop();
                  bool success = await cart.closeShift(endingCash);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(success ? 'Kasir berhasil ditutup.' : 'Gagal menutup kasir. Coba lagi.'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ));
                  }
                },
                child: Text('Tutup Kasir', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );
    },
  );
}

Widget _drawerSummaryRow(String label, String value, {bool highlight = false}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
      Text(value, style: TextStyle(fontWeight: highlight ? FontWeight.bold : FontWeight.w500, fontSize: 13)),
    ],
  );
}
