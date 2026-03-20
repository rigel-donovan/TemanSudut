import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/popup_notification.dart';
import '../utils/app_format.dart';
import '../widgets/slide_to_finish.dart';
import '../services/api_service.dart';
import 'dart:io';
import 'dart:typed_data';
import '../widgets/camera_dialog.dart';
import 'package:camera/camera.dart';

class OrdersTab extends StatelessWidget {
  final VoidCallback? onOrderFinished;

  const OrdersTab({Key? key, this.onOrderFinished}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isWideScreen = MediaQuery.of(context).size.width > 800;

    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: isWideScreen ? null : AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text('Orders', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            centerTitle: true,
            automaticallyImplyLeading: false,
          ),
          body: cart.items.isEmpty 
          ? Center(child: Text('Tidak ada pesanan.', style: TextStyle(color: Colors.grey)))
          : LayoutBuilder(
              builder: (context, constraints) {
                final bool isNarrow = constraints.maxWidth < 220;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                      child: Text('| Order Detail', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Divider(height: 1, thickness: 1, color: Colors.grey[200]),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Items List
                            ...cart.items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 50, height: 50,
                                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                                clipBehavior: Clip.antiAlias,
                                child: item.product.image != null && item.product.image!.isNotEmpty
                                  ? Image.network(
                                      ApiService().getImageUrl(item.product.image),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Icon(Icons.fastfood, color: Colors.black12),
                                    )
                                  : Icon(Icons.fastfood, color: Colors.black12),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(child: Text(item.product.name, style: TextStyle(fontWeight: FontWeight.bold))),
                                        Row(
                                          children: [
                                            Text('X${item.quantity}', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                            SizedBox(width: 8),
                                            InkWell(
                                              onTap: () {
                                                cart.removeFromCart(item);
                                              },
                                              child: Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: InkWell(
                                        onTap: () => _showNoteDialog(context, cart, item),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[50],
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey[200]!),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.edit_note, size: 18, color: Colors.blue[700]),
                                              SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  item.notes != null && item.notes!.isNotEmpty ? item.notes! : 'Tambah Catatan',
                                                  style: TextStyle(
                                                    color: item.notes != null && item.notes!.isNotEmpty ? Colors.black87 : Colors.grey[600],
                                                    fontSize: 12,
                                                    fontWeight: item.notes != null && item.notes!.isNotEmpty ? FontWeight.w500 : FontWeight.normal,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(child: Text('Harga Satuan', style: TextStyle(color: Colors.grey, fontSize: 12))),
                                        Text(AppFormat.currency(item.product.price), style: TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(child: Text('Subtotal', style: TextStyle(color: Colors.grey, fontSize: 12))),
                                        Text(AppFormat.currency(item.subtotal), style: TextStyle(color: Colors.green[600], fontSize: 12, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      
                      Divider(height: 32, thickness: 1, color: Colors.grey[200]),
                      
                      Text('| Payment Detail', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold)),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(child: Text('Subtotal', style: TextStyle(color: Colors.grey))),
                          Text(AppFormat.currency(cart.subtotal)),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(child: Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                          Text(AppFormat.currency(cart.total), style: TextStyle(color: Colors.green[600], fontWeight: FontWeight.bold)),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      SlideToFinish(
                        onSlideSuccess: () {
                          if (cart.items.isEmpty) return;
                          final nameController = TextEditingController(text: cart.customerName);
                          final outerContext = context;
                          String selectedPayment = 'cash'; // default
                          double amountReceived = 0;
                          double changeAmount = 0;

                          showModalBottomSheet(
                            context: outerContext,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (sheetCtx) {
                              return StatefulBuilder(
                                builder: (ctx, setSheetState) {
                                  return Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                    ),
                                    padding: EdgeInsets.only(
                                      left: 24, right: 24, top: 24,
                                      bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Handle bar
                                        Center(
                                          child: Container(
                                            width: 40, height: 4,
                                            margin: const EdgeInsets.only(bottom: 20),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          ),
                                        ),

                                        const Text('Konfirmasi Pesanan',
                                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 20),

                                        // Customer Name
                                        const Text('Nama Pelanggan',
                                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                                        const SizedBox(height: 8),
                                        TextField(
                                          controller: nameController,
                                          decoration: InputDecoration(
                                            hintText: 'Opsional (Default: Tamu)',
                                            prefixIcon: const Icon(Icons.person_outline, size: 18),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: BorderSide(color: Colors.grey[300]!)),
                                            enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: BorderSide(color: Colors.grey[300]!)),
                                          ),
                                        ),
                                        const SizedBox(height: 20),

                                        // Payment Method
                                        const Text('Metode Pembayaran',
                                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            // Tunai
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () => setSheetState(() => selectedPayment = 'cash'),
                                                child: AnimatedContainer(
                                                  duration: const Duration(milliseconds: 180),
                                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                                  decoration: BoxDecoration(
                                                    color: selectedPayment == 'cash' ? Colors.black : Colors.grey[50],
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(
                                                      color: selectedPayment == 'cash' ? Colors.black : Colors.grey[300]!,
                                                      width: selectedPayment == 'cash' ? 2 : 1,
                                                    ),
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      Icon(Icons.payments_outlined, 
                                                          size: 24, 
                                                          color: selectedPayment == 'cash' ? Colors.white : Colors.black54),
                                                      const SizedBox(height: 6),
                                                      Text('Tunai',
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 13,
                                                            color: selectedPayment == 'cash' ? Colors.white : Colors.black87,
                                                          )),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            // QRIS
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () => setSheetState(() => selectedPayment = 'qris'),
                                                child: AnimatedContainer(
                                                  duration: const Duration(milliseconds: 180),
                                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                                  decoration: BoxDecoration(
                                                    color: selectedPayment == 'qris' ? Colors.black : Colors.grey[50],
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(
                                                      color: selectedPayment == 'qris' ? Colors.black : Colors.grey[300]!,
                                                      width: selectedPayment == 'qris' ? 2 : 1,
                                                    ),
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      Icon(Icons.qr_code_scanner_outlined,
                                                          size: 24,
                                                          color: selectedPayment == 'qris' ? Colors.white : Colors.black54),
                                                      const SizedBox(height: 6),
                                                      Text('QRIS',
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 13,
                                                            color: selectedPayment == 'qris' ? Colors.white : Colors.black87,
                                                          )),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 24),

                                        // Summary Row
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[50],
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.grey[200]!),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text('Total Pembayaran',
                                                  style: TextStyle(fontWeight: FontWeight.bold)),
                                              Consumer<CartProvider>(
                                                builder: (_, c, __) => Text(
                                                  AppFormat.currency(c.total),
                                                  style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.green[700],
                                                      fontSize: 16),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Cash Input Section
                                        if (selectedPayment == 'cash') ...[
                                          const SizedBox(height: 20),
                                          Row(
                                            children: [
                                              const Icon(Icons.payments_outlined, size: 16, color: Colors.black87),
                                              const SizedBox(width: 6),
                                              const Text('Pembayaran Tunai', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.grey[200]!),
                                            ),
                                            child: Column(
                                              children: [
                                                TextField(
                                                  keyboardType: TextInputType.number,
                                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                                  decoration: InputDecoration(
                                                    labelText: 'Input Uang',
                                                    prefixText: 'Rp ',
                                                    filled: true,
                                                    fillColor: Colors.grey[50],
                                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                                  ),
                                                  onChanged: (val) {
                                                    setSheetState(() {
                                                      final raw = val.replaceAll(RegExp(r'[^0-9]'), '');
                                                      amountReceived = double.tryParse(raw) ?? 0;
                                                      changeAmount = amountReceived - cart.total;
                                                      if (changeAmount < 0) changeAmount = 0;
                                                    });
                                                  },
                                                ),
                                                const SizedBox(height: 12),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    const Text('Kembalian', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                                    Text(
                                                      AppFormat.currency(changeAmount),
                                                      style: TextStyle(
                                                        fontSize: 18, 
                                                        fontWeight: FontWeight.bold, 
                                                        color: changeAmount > 0 ? Colors.green[700] : Colors.grey
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (cart.currentShift != null) ...[
                                                  const Divider(height: 20),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text('Sisa Uang Kembalian', style: TextStyle(fontSize: 11, color: amountReceived > 0 ? Colors.blue[700] : Colors.black54)),
                                                      Text(
                                                        AppFormat.currency(
                                                          (double.tryParse(cart.currentShift!['current_cash']?.toString() ?? '0') ?? 0) + amountReceived - changeAmount
                                                        ),
                                                        style: TextStyle(
                                                          fontSize: 11, 
                                                          fontWeight: FontWeight.bold, 
                                                          color: amountReceived > 0 ? Colors.blue[700] : Colors.black54
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 4.0),
                                                    child: Text(
                                                      'Saldo saat ini: ${AppFormat.currency(double.tryParse(cart.currentShift!['current_cash']?.toString() ?? '0') ?? 0)}',
                                                      style: TextStyle(fontSize: 10, color: Colors.grey[500], fontStyle: FontStyle.italic),
                                                    ),
                                                  ),
                                                ]
                                              ],
                                            ),
                                          ),
                                        ],

                                        // Confirm Button
                                        SizedBox(
                                          width: double.infinity,
                                          height: 50,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.black,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12)),
                                            ),
                                            onPressed: (selectedPayment == 'cash' && amountReceived < cart.total)
                                                ? null
                                                : () async {
                                                    cart.setCustomerName(
                                                        nameController.text.isNotEmpty ? nameController.text : 'Tamu');
                                                    Navigator.pop(sheetCtx);

                                                    bool success = await cart.checkout(
                                                      selectedPayment,
                                                      amountReceived: selectedPayment == 'cash' ? amountReceived : null,
                                                      changeAmount: selectedPayment == 'cash' ? changeAmount : null,
                                                    );
                                              if (success) {
                                                PopupNotification.show(
                                                  outerContext,
                                                  title: 'Order Berhasil! 🎉',
                                                  message: 'Pesanan sedang diproses. Pantau di tab Orders.',
                                                  type: PopupType.success,
                                                );
                                                if (onOrderFinished != null) {
                                                  onOrderFinished!();
                                                }
                                              } else {
                                                PopupNotification.show(
                                                  outerContext,
                                                  title: 'Gagal Membuat Pesanan',
                                                  message: 'Terjadi kesalahan. Coba lagi.',
                                                  type: PopupType.error,
                                                );
                                              }
                                            },
                                            child: const Text('Konfirmasi Pesanan',
                                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                        text: 'Slide to Finish Order',
                        isEnabled: cart.items.isNotEmpty,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  },
);
}

  void _showNoteDialog(BuildContext context, CartProvider cart, CartItem item) {
    final TextEditingController _noteCtrl = TextEditingController(text: item.notes);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Edit Note'),
          content: TextField(
            controller: _noteCtrl,
            decoration: InputDecoration(
              hintText: 'e.g. Less sugar, extra ice',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            maxLines: 2,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                cart.updateItemNote(item, _noteCtrl.text);
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      }
    );
  }
}
