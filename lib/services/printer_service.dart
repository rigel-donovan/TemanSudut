import 'printer_service_stub.dart'
  if (dart.library.io) 'printer_service_mobile.dart';

abstract class PrinterService {
  factory PrinterService() => getPrinterService();

  Future<bool> get isConnected;
  Future<List<dynamic>> getBondedDevices();
  Future<void> connect(dynamic device);
  Future<void> disconnect();
  Stream<int> onStateChanged();

  Future<void> printReceipt({
    required Map<String, dynamic> transaction,
    required List<dynamic> items,
    required bool isHistory,
  });

  Future<void> printTest();
  Future<void> downloadReceiptPdf(int transactionId);
}
