import 'dart:async';
import 'printer_service.dart';

PrinterService getPrinterService() => PrinterServiceStub();

class MockBluetoothDevice {
  final String name;
  final String address;
  MockBluetoothDevice(this.name, this.address);
}

class PrinterServiceStub implements PrinterService {
  bool _connected = false;
  final StreamController<int> _stateController = StreamController<int>.broadcast();

  @override
  Future<bool> get isConnected async => _connected;

  @override
  Future<List<dynamic>> getBondedDevices() async {
    await Future.delayed(Duration(milliseconds: 500));
    return [
      MockBluetoothDevice('Web Mock Printer 1', '00:11:22:33:FF:EE'),
      MockBluetoothDevice('Web Mock Printer 2', 'AA:BB:CC:DD:EE:FF'),
    ];
  }

  @override
  Future<void> connect(dynamic device) async {
    await Future.delayed(Duration(seconds: 1));
    _connected = true;
    _stateController.add(1); 
    print('Mock: Connected to ${device.name}');
  }

  @override
  Future<void> disconnect() async {
    await Future.delayed(Duration(milliseconds: 500));
    _connected = false;
    _stateController.add(0);
    print('Mock: Disconnected');
  }

  @override
  Stream<int> onStateChanged() => _stateController.stream;

  @override
  Future<void> printTest() async {
    if (_connected) {
      print('Mock: ===== TES PRINTER =====');
      print('Mock: Printer Berhasil Tersambung!');
      print('Mock: Paper Cut');
    } else {
      throw Exception('Printer not connected');
    }
  }

  @override
  Future<void> printReceipt({
    required Map<String, dynamic> transaction,
    required List<dynamic> items,
    required bool isHistory,
  }) async {
    if (_connected) {
      print('Mock: Printing ${isHistory ? "History" : "New"} Receipt for Transaction ID: ${transaction['id']}');
      print('Mock: Items: ${items.length}');
      print('Mock: Total: ${transaction['total']}');
      print('Mock: Paper Cut');
    } else {
      throw Exception('Printer not connected');
    }
  }
}
