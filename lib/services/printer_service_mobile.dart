import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/services.dart';
import '../utils/app_format.dart';
import 'printer_service.dart';

PrinterService getPrinterService() => PrinterServiceMobile();

class PrinterServiceMobile implements PrinterService {
  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  @override
  Future<bool> get isConnected async {
    return (await bluetooth.isConnected) ?? false;
  }

  @override
  Future<List<dynamic>> getBondedDevices() async {
    return await bluetooth.getBondedDevices();
  }

  @override
  Future<void> connect(dynamic device) async {
    await bluetooth.connect(device);
  }

  @override
  Future<void> disconnect() async {
    await bluetooth.disconnect();
  }

  @override
  Stream<int> onStateChanged() {
    return bluetooth.onStateChanged().map((state) => state as int);
  }

  @override
  Future<void> printTest() async {
    if (await isConnected) {
      bluetooth.printNewLine();
      bluetooth.printCustom("===== TES PRINTER =====", 1, 1);
      bluetooth.printNewLine();
      bluetooth.printCustom("Printer Berhasil Tersambung!", 1, 1);
      bluetooth.printNewLine();
      bluetooth.printNewLine();
      bluetooth.paperCut();
    }
  }

  @override
  Future<void> printReceipt({
    required Map<String, dynamic> transaction,
    required List<dynamic> items,
    required bool isHistory,
  }) async {
    if (!(await isConnected)) {
      print('Printer not connected');
      throw Exception('Printer not connected');
    }

    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    // Header
    bytes += generator.text(
      'KASIR ANDROID POS',
      styles: PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2),
    );
    bytes += generator.text(
      'Jl. Contoh Alamat Resto No.123',
      styles: PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(1);

    // Meta Info
    bytes += generator.text('No. Order: INV-${transaction['id']}');
    bytes += generator.text('Tanggal: ${transaction['created_at']}');
    bytes += generator.text('Kasir: ${transaction['user']?['name'] ?? 'Unknown'}');
    bytes += generator.text('Pelanggan: ${transaction['customer_name'] ?? 'Guest'}');
    bytes += generator.text('Tipe: ${transaction['order_type'] == 'dine_in' ? 'Makan di Tempat' : 'Bawa Pulang'}');
    if (transaction['table'] != null) {
      bytes += generator.text('Meja: ${transaction['table']['table_number']}');
    }
    
    bytes += generator.hr();

    // Items List
    for (var item in items) {
      String name = item['product']['name'];
      int qty = int.tryParse(item['quantity'].toString()) ?? 1;
      double price = double.tryParse(item['unit_price'].toString()) ?? 0;
      double subtotal = double.tryParse(item['subtotal'].toString()) ?? (price * qty);

      bytes += generator.row([
        PosColumn(text: '$qty x', width: 2),
        PosColumn(text: name, width: 5),
        PosColumn(text: AppFormat.currency(subtotal), width: 5, styles: PosStyles(align: PosAlign.right)),
      ]);
    }

    bytes += generator.hr();

    // Footer Totals
    double txSubtotal = double.tryParse(transaction['subtotal'].toString()) ?? 0;
    double txTax = double.tryParse(transaction['tax'].toString()) ?? 0;
    double txTotal = double.tryParse(transaction['total'].toString()) ?? 0;

    bytes += generator.row([
      PosColumn(text: 'Subtotal:', width: 6),
      PosColumn(text: AppFormat.currency(txSubtotal), width: 6, styles: PosStyles(align: PosAlign.right)),
    ]);
    if (txTax > 0) {
      bytes += generator.row([
        PosColumn(text: 'Pajak:', width: 6),
        PosColumn(text: AppFormat.currency(txTax), width: 6, styles: PosStyles(align: PosAlign.right)),
      ]);
    }
    bytes += generator.row([
      PosColumn(text: 'TOTAL:', width: 6, styles: PosStyles(bold: true)),
      PosColumn(text: AppFormat.currency(txTotal), width: 6, styles: PosStyles(align: PosAlign.right, bold: true)),
    ]);
    bytes += generator.text('Pembayaran: ${transaction['payment_method'].toString().toUpperCase()}', styles: PosStyles(align: PosAlign.right));

    bytes += generator.feed(2);
    bytes += generator.text(
      isHistory ? '*** SALINAN (COPY) ***' : 'Terima Kasih Atas Kunjungan Anda!',
      styles: PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.feed(2);
    bytes += generator.cut();

    bluetooth.writeBytes(Uint8List.fromList(bytes));
  }
}
