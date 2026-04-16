import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/popup_notification.dart';
import '../utils/app_format.dart';
import '../widgets/slide_to_finish.dart';
import '../services/api_service.dart';
import '../widgets/camera_dialog.dart';
import '../utils/app_animations.dart';
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
            title: Text('Orders', style: TextStyle(color: const Color(0xFF5D4037), fontWeight: FontWeight.bold)),
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

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Items List
                            ...cart.items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 48, height: 48,
                                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                                        clipBehavior: Clip.antiAlias,
                                        child: item.product.image != null && item.product.image!.isNotEmpty
                                          ? Image.network(
                                              ApiService().getImageUrl(item.product.image),
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Icon(Icons.fastfood, color: Colors.black12),
                                            )
                                          : Icon(Icons.fastfood, color: Colors.black12),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item.product.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                                            SizedBox(height: 2),
                                            Text(AppFormat.currency(item.product.price), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  // Notes
                                  InkWell(
                                    onTap: () => _showNoteDialog(context, cart, item),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey[200]!),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.edit_note, size: 16, color: Colors.blue[700]),
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
                                  SizedBox(height: 8),
                                  // Action Buttons Row
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      // Extra Charge Button
                                      if (!item.isFree)
                                        InkWell(
                                          onTap: () => _showExtraChargeDialog(context, cart, item),
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: item.extraCharge > 0 ? Colors.orange[50] : Colors.white,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: item.extraCharge > 0 ? Colors.orange[300]! : Colors.grey[200]!),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.add_circle_outline, size: 16, color: Colors.orange[700]),
                                                SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    item.extraCharge > 0
                                                        ? '${item.extraChargeLabel ?? "Extra"}: +${AppFormat.currency(item.extraCharge)}'
                                                        : 'Tambah Ekstra Biaya',
                                                    style: TextStyle(
                                                      color: item.extraCharge > 0 ? Colors.orange[800] : Colors.grey[600],
                                                      fontSize: 12,
                                                      fontWeight: item.extraCharge > 0 ? FontWeight.w600 : FontWeight.normal,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (item.extraCharge > 0) ...[
                                                  SizedBox(width: 4),
                                                  GestureDetector(
                                                    onTap: () {
                                                      cart.updateExtraCharge(item, 0, label: null);
                                                    },
                                                    child: Icon(Icons.close, size: 14, color: Colors.orange[700]),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                      // Free Cup Button
                                      InkWell(
                                        onTap: () {
                                          cart.toggleFreeCup(item);
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: item.isFree ? Colors.green[50] : Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: item.isFree ? Colors.green[300]! : Colors.grey[200]!),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.card_giftcard, size: 16, color: item.isFree ? Colors.green[700] : Colors.grey[600]),
                                              SizedBox(width: 4),
                                              Text(
                                                item.isFree ? 'Free Cup' : 'Jadikan Free/Gratis',
                                                style: TextStyle(
                                                  color: item.isFree ? Colors.green[800] : Colors.grey[600],
                                                  fontSize: 12,
                                                  fontWeight: item.isFree ? FontWeight.w600 : FontWeight.normal,
                                                ),
                                              ),
                                              if (item.isFree) ...[
                                                SizedBox(width: 4),
                                                Icon(Icons.close, size: 14, color: Colors.green[700]),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  // Bottom row: qty stepper + subtotal + delete
                                  Row(
                                    children: [
                                      // Quantity Stepper
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey[300]!),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            AnimatedBounceButton(
                                              scaleTo: 0.80,
                                              onTap: () => cart.updateQuantity(item, item.quantity - 1),
                                              child: Container(
                                                width: 30, height: 30,
                                                alignment: Alignment.center,
                                                child: Icon(Icons.remove, size: 16, color: Colors.black87),
                                              ),
                                            ),
                                            Container(
                                              width: 1, height: 30,
                                              color: Colors.grey[200],
                                            ),
                                            Container(
                                              width: 36, height: 30,
                                              alignment: Alignment.center,
                                              child: Text('${item.quantity}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                            ),
                                            Container(
                                              width: 1, height: 30,
                                              color: Colors.grey[200],
                                            ),
                                            AnimatedBounceButton(
                                              scaleTo: 0.80,
                                              onTap: () => cart.updateQuantity(item, item.quantity + 1),
                                              child: Container(
                                                width: 30, height: 30,
                                                alignment: Alignment.center,
                                                child: Icon(Icons.add, size: 16, color: Colors.black87),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      // Subtotal
                                      Expanded(
                                        child: Text(
                                          AppFormat.currency(item.subtotal),
                                          style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 13),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      // Delete Button
                                      InkWell(
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                              title: Text('Hapus Item?', style: TextStyle(fontWeight: FontWeight.bold)),
                                              content: Text('Hapus "${item.product.name}" dari pesanan?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(ctx),
                                                  child: Text('Batal', style: TextStyle(color: Colors.grey)),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    cart.removeFromCart(item);
                                                    Navigator.pop(ctx);
                                                  },
                                                  child: Text('Hapus', style: TextStyle(color: Colors.red)),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.red[50],
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.red[200]!),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.delete_outline, color: Colors.red, size: 16),
                                              SizedBox(width: 4),
                                              Text('Hapus', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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
                      
                      const SizedBox(height: 24),
                      SlideToFinish(
                        text: 'Slide to Proceed',
                        isEnabled: cart.items.isNotEmpty,
                        onSlideSuccess: () {
                          if (cart.items.isEmpty) return;
                          final nameController = TextEditingController(text: cart.customerName);
                          final tableController = TextEditingController();
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
                                    child: SingleChildScrollView(
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

                                        // Customer Name & Table Number in a Row
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Customer Name
                                            Expanded(
                                              flex: 3,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text('Nama Pelanggan',
                                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                                                  const SizedBox(height: 8),
                                                  TextField(
                                                    controller: nameController,
                                                    decoration: InputDecoration(
                                                      hintText: 'Default: Tamu',
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
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            // Table Number
                                            Expanded(
                                              flex: 2,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text('No. Meja',
                                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                                                  const SizedBox(height: 8),
                                                  TextField(
                                                    controller: tableController,
                                                    keyboardType: TextInputType.number,
                                                    decoration: InputDecoration(
                                                      hintText: 'Opsional',
                                                      prefixIcon: const Icon(Icons.table_bar_outlined, size: 18),
                                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                                      border: OutlineInputBorder(
                                                          borderRadius: BorderRadius.circular(12),
                                                          borderSide: BorderSide(color: Colors.grey[300]!)),
                                                      enabledBorder: OutlineInputBorder(
                                                          borderRadius: BorderRadius.circular(12),
                                                          borderSide: BorderSide(color: Colors.grey[300]!)),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
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
                                                    color: selectedPayment == 'cash' ? const Color(0xFF5D4037) : Colors.grey[50],
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(
                                                      color: selectedPayment == 'cash' ? const Color(0xFF5D4037) : Colors.grey[300]!,
                                                      width: selectedPayment == 'cash' ? 2 : 1,
                                                    ),
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      Icon(Icons.payments_outlined, 
                                                          size: 24, 
                                                          color: selectedPayment == 'cash' ? Colors.white : Colors.grey[600]!),
                                                      const SizedBox(height: 6),
                                                      Text('Tunai',
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 13,
                                                            color: selectedPayment == 'cash' ? Colors.white : Colors.grey[700]!,
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
                                                    color: selectedPayment == 'qris' ? const Color(0xFF5D4037) : Colors.grey[50],
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(
                                                      color: selectedPayment == 'qris' ? const Color(0xFF5D4037) : Colors.grey[300]!,
                                                      width: selectedPayment == 'qris' ? 2 : 1,
                                                    ),
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      Icon(Icons.qr_code_scanner_outlined,
                                                          size: 24,
                                                          color: selectedPayment == 'qris' ? Colors.white : Colors.grey[600]!),
                                                      const SizedBox(height: 6),
                                                      Text('QRIS',
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 13,
                                                            color: selectedPayment == 'qris' ? Colors.white : Colors.grey[700]!,
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
                                                if (amountReceived > 0 && amountReceived < cart.total)
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 8.0),
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          'Uang kurang ${AppFormat.currency(cart.total - amountReceived)}', 
                                                          style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                if (cart.currentShift != null) ...[
                                                  const Divider(height: 20),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text('Total Saldo Kasir', style: TextStyle(fontSize: 11, color: amountReceived > 0 ? Colors.blue[700] : Colors.black54)),
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
                                              backgroundColor: const Color(0xFF5D4037),
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12)),
                                            ),
                                            onPressed: (selectedPayment == 'cash' && amountReceived < cart.total)
                                                ? null
                                                : () async {
                                                    String customerName = nameController.text.isNotEmpty ? nameController.text : 'Tamu';
                                                    String tableNum = tableController.text.trim();
                                                    if (tableNum.isNotEmpty) {
                                                      customerName = '$customerName - Meja $tableNum';
                                                    }
                                                    cart.setCustomerName(customerName);
                                                    Navigator.pop(sheetCtx);

                                                    bool success = await cart.checkout(
                                                      selectedPayment,
                                                      amountReceived: selectedPayment == 'cash' ? amountReceived : null,
                                                      changeAmount: selectedPayment == 'cash' ? changeAmount : null,
                                                    );
                                              if (success) {
                                                PopupNotification.show(
                                                  outerContext,
                                                  title: 'Order Berhasil! ðŸŽ‰',
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
                                  ),
                                );
                              },
                              );
                            },
                          );
                        },
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
                backgroundColor: const Color(0xFF5D4037),
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

  void _showExtraChargeDialog(BuildContext context, CartProvider cart, CartItem item) {
    final labelCtrl = TextEditingController(text: item.extraChargeLabel ?? '');
    final amountCtrl = TextEditingController(
      text: item.extraCharge > 0 ? item.extraCharge.toInt().toString() : '',
    );

    // Preset options for quick selection
    final presets = [
      {'label': 'Double Shot', 'amount': 5000},
      {'label': 'Extra Cheese', 'amount': 5000},
      {'label': 'Extra Topping', 'amount': 3000},
      {'label': 'Upsize', 'amount': 5000},
    ];

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(Icons.add_circle_outline, color: Colors.orange[700], size: 22),
                  SizedBox(width: 8),
                  Text('Ekstra Biaya', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pilih cepat:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: presets.map((preset) {
                        final isSelected = labelCtrl.text == preset['label'] && amountCtrl.text == (preset['amount'] as int).toString();
                        return InkWell(
                          onTap: () {
                            setDialogState(() {
                              labelCtrl.text = preset['label'] as String;
                              amountCtrl.text = (preset['amount'] as int).toString();
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.orange[50] : Colors.grey[50],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? Colors.orange[400]! : Colors.grey[300]!,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(preset['label'] as String, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                Text('+${AppFormat.currency(preset['amount'])}', style: TextStyle(fontSize: 11, color: Colors.orange[700])),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 20),
                    Divider(height: 1),
                    SizedBox(height: 16),
                    Text('Atau input manual:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                    SizedBox(height: 10),
                    TextField(
                      controller: labelCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nama Ekstra',
                        hintText: 'e.g. Double Shot',
                        prefixIcon: Icon(Icons.label_outline, size: 18),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Nominal Biaya',
                        hintText: '5000',
                        prefixText: 'Rp ',
                        prefixStyle: TextStyle(fontWeight: FontWeight.bold),
                        prefixIcon: Icon(Icons.attach_money, size: 18),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text('Batal', style: TextStyle(color: Colors.grey[600])),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  onPressed: () {
                    double charge = double.tryParse(amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                    cart.updateExtraCharge(item, charge, label: labelCtrl.text.isNotEmpty ? labelCtrl.text : null);
                    Navigator.pop(dialogCtx);
                  },
                  child: Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
