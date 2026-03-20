import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/popup_notification.dart';
import '../utils/app_format.dart';
import '../widgets/dio_network_image.dart';
import '../services/printer_service.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({Key? key}) : super(key: key);

  @override
  HistoryTabState createState() => HistoryTabState();
}

class HistoryTabState extends State<HistoryTab> {
  final ApiService _apiService = ApiService();
  final PrinterService _printerService = PrinterService();
  String _selectedFilter = 'daily';
  List<dynamic> _transactions = [];
  bool _isLoading = true;

  String get _filterTitle {
    if (_selectedFilter == 'daily') return 'Hari Ini';
    if (_selectedFilter == 'weekly') return 'Minggu Ini';
    if (_selectedFilter == 'monthly') return 'Bulan Ini';
    if (_selectedFilter.startsWith('date:')) return 'Tanggal ${_selectedFilter.substring(5)}';
    return '';
  }

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  void refreshHistory() {
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    _transactions = await _apiService.getHistory(_selectedFilter);
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _downloadFile(String format) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final url = Uri.parse('${ApiService.baseUrl}/transactions/export/$format?filter=$_selectedFilter&token=$token');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      PopupNotification.show(context, title: 'Gagal Export', message: 'Tidak bisa membuka link export.', type: PopupType.error);
    }
  }

  void _showDownloadOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text('Export to PDF'),
                onTap: () {
                  Navigator.pop(context);
                  _downloadFile('pdf');
                },
              ),
              ListTile(
                leading: Icon(Icons.table_chart, color: Colors.green),
                title: Text('Export to Excel'),
                onTap: () {
                  Navigator.pop(context);
                  _downloadFile('excel');
                },
              ),
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            Text(_filterTitle, style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.normal)),
          ],
        ),
        centerTitle: false,
        actions: [
          // Only show export for owners
          if (auth.isOwner)
            IconButton(icon: Icon(Icons.download, color: Colors.white), onPressed: () => _showDownloadOptions(context)),
          IconButton(
            icon: Icon(Icons.calendar_today, color: Colors.white), 
            onPressed: () => _showFilterOptions(context)
          ),
          SizedBox(width: 8),
        ],
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : _transactions.isEmpty
          ? Center(child: Text('Tidak ada riwayat pada periode ini'))
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _transactions.length,
              itemBuilder: (context, index) {
                final transaction = _transactions[index];
                return _buildHistoryCard(transaction);
              },
            ),
    );
  }

  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Harian (Daily)'),
                trailing: _selectedFilter == 'daily' ? Icon(Icons.check) : null,
                onTap: () {
                  setState(() => _selectedFilter = 'daily');
                  Navigator.pop(context);
                  _fetchHistory();
                },
              ),
              ListTile(
                title: Text('Mingguan (Weekly)'),
                trailing: _selectedFilter == 'weekly' ? Icon(Icons.check) : null,
                onTap: () {
                  setState(() => _selectedFilter = 'weekly');
                  Navigator.pop(context);
                  _fetchHistory();
                },
              ),
              ListTile(
                title: Text('Bulanan (Monthly)'),
                trailing: _selectedFilter == 'monthly' ? Icon(Icons.check) : null,
                onTap: () {
                  setState(() => _selectedFilter = 'monthly');
                  Navigator.pop(context);
                  _fetchHistory();
                },
              ),
              ListTile(
                title: Text('Pilih Tanggal (Specific Date)'),
                trailing: _selectedFilter.startsWith('date:') ? Icon(Icons.check) : null,
                onTap: () async {
                  Navigator.pop(context); // Close bottom sheet
                  
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: Colors.black, // header background color
                            onPrimary: Colors.white, // header text color
                            onSurface: Colors.black, // body text color
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  
                  if (pickedDate != null) {
                    final String formattedDate = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                    setState(() => _selectedFilter = 'date:$formattedDate');
                    _fetchHistory();
                  }
                },
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildHistoryCard(dynamic transaction) {
    final date = transaction['created_at'].toString().substring(0, 10);
    final invoice = 'INV-${transaction['id']}';
    final customer = transaction['customer_name'] ?? 'Guest';
    final cashier = transaction['user'] != null ? transaction['user']['name'] : 'Unknown';
    final itemsCount = (transaction['items'] as List).length;
    final total = double.tryParse(transaction['total'].toString()) ?? 0;
    final paymentMethod = (transaction['payment_method'] ?? 'cash').toString().toUpperCase();
    
    final String photoUrl = ApiService().getImageUrl(transaction['completion_photo']);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 5))],
        border: Border.all(color: Colors.grey[200]!)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(date, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    SizedBox(width: 8),
                    Text(invoice, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    if (transaction['order_type'] != null) ...[
                      Builder(builder: (_) {
                        final type = transaction['order_type'].toString();
                        final label = type == 'dine_in' ? 'Dine In' : type == 'take_away' ? 'Take Away' : type == 'online' ? 'Online' : type;
                        final color = type == 'dine_in' ? Colors.blue : type == 'take_away' ? Colors.orange : Colors.green;
                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: color.withOpacity(0.4), width: 1),
                          ),
                          child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color[700])),
                        );
                      }),
                    ],
                  ],
                ),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    if (auth.can('print_receipt')) {
                      return IconButton(
                        icon: Icon(Icons.print, size: 18, color: Colors.blue[600]),
                        tooltip: 'Cetak Struk',
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                            builder: (context) {
                              return SafeArea(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text('Opsi Cetak Struk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    ),
                                    ListTile(
                                      leading: Icon(Icons.bluetooth, color: Colors.blue),
                                      title: Text('Cetak Struk (Bluetooth)'),
                                      subtitle: Text('Direct ke printer thermal bluetooth'),
                                      onTap: () async {
                                        final messenger = ScaffoldMessenger.of(context);
                                        Navigator.pop(context);
                                        if (await _printerService.isConnected) {
                                          if (!mounted) return;
                                          try {
                                            await _printerService.printReceipt(
                                              transaction: transaction, 
                                              items: transaction['items'] ?? [], 
                                              isHistory: true
                                            );
                                            messenger.showSnackBar(SnackBar(content: Text('Mencetak struk (Bluetooth)...')));
                                          } catch (e) {
                                            messenger.showSnackBar(SnackBar(content: Text('Gagal mencetak: $e')));
                                          }
                                        } else {
                                          messenger.showSnackBar(SnackBar(
                                            content: Text('Printer belum terhubung!'), 
                                            backgroundColor: Colors.red,
                                            action: SnackBarAction(label: 'Settings', textColor: Colors.white, onPressed: () {
                                              Navigator.pushNamed(context, '/printer_settings');
                                            }),
                                          ));
                                        }
                                      },
                                    ),
                                    ListTile(
                                      leading: Icon(Icons.picture_as_pdf, color: Colors.red),
                                      title: Text('Cetak Struk (PDF 80mm)'),
                                      subtitle: Text('Format PDF untuk printer kasir meja'),
                                      onTap: () async {
                                        final messenger = ScaffoldMessenger.of(context);
                                        Navigator.pop(context);
                                        try {
                                          await _printerService.downloadReceiptPdf(transaction['id']);
                                          messenger.showSnackBar(SnackBar(content: Text('Membuka struk PDF...')));
                                        } catch (e) {
                                          messenger.showSnackBar(SnackBar(content: Text('Gagal membuat PDF: $e'), backgroundColor: Colors.red));
                                        }
                                      },
                                    ),
                                    SizedBox(height: 8),
                                  ],
                                ),
                              );
                            }
                          );
                        },
                      );
                    }
                    return SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
                      child: Text('1', style: TextStyle(fontWeight: FontWeight.bold)), 
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(child: Text('Customer', style: TextStyle(color: Colors.grey, fontSize: 12))),
                              Flexible(child: Text(customer, style: TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(child: Text('Kasir', style: TextStyle(color: Colors.grey, fontSize: 12))),
                              Flexible(child: Text(cashier, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo), overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Items', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              Text('$itemsCount item', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Pembayaran', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.green[200]!),
                                ),
                                child: Text(paymentMethod, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green[700])),
                              ),
                            ],
                          ),
                        ]
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                
                // Item List inside History
                ...(transaction['items'] as List).map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40, height: 40, 
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                          clipBehavior: Clip.antiAlias,
                          child: item['product'] != null && item['product']['image'] != null
                            ? Image.network(
                                ApiService().getImageUrl(item['product']['image']),
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Icon(Icons.fastfood, size: 20, color: Colors.black12),
                              )
                            : Icon(Icons.fastfood, size: 20, color: Colors.black12),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(child: Text(item['product'] != null ? item['product']['name'] : 'Item', style: TextStyle(fontWeight: FontWeight.bold))),
                                  Text('X${item['quantity']}', style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              if (item['notes'] != null && item['notes'].toString().isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.amber[50],
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.amber[100]!),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.edit_note, size: 14, color: Colors.amber[800]),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          item['notes'],
                                          style: TextStyle(fontSize: 11, color: Colors.amber[900], fontWeight: FontWeight.w500),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(AppFormat.currency(item['subtotal']), style: TextStyle(color: Colors.green[600], fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),

                Divider(height: 32),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(AppFormat.currency(total), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[600])),
                  ],
                ),

                // Completion Photo (if exists)
                if (photoUrl.isNotEmpty) ...
                [
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.camera_alt, size: 14, color: Colors.grey),
                      SizedBox(width: 4),
                      Text('Foto Bukti', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          backgroundColor: Colors.black,
                          insetPadding: EdgeInsets.all(12),
                          child: Stack(
                            children: [
                              Center(
                                child: DioNetworkImage(
                                  url: photoUrl,
                                  fit: BoxFit.contain,
                                  loadingWidget: const Center(child: CircularProgressIndicator(color: Colors.white)),
                                  errorWidget: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.broken_image, color: Colors.white, size: 60),
                                      SizedBox(height: 8),
                                      Text('Gagal memuat gambar', style: TextStyle(color: Colors.white, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8, right: 8,
                                child: IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: Icon(Icons.close, color: Colors.white),
                                  style: IconButton.styleFrom(backgroundColor: Colors.black45),
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: DioNetworkImage(
                        url: photoUrl,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingWidget: Container(
                          height: 120,
                          color: Colors.grey[200],
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: Container(
                          height: 80,
                          color: Colors.grey[200],
                          child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                        ),
                      ),
                    ),
                  ),
                ],

                SizedBox(height: 16),
              ],
            ),
          ),
        ],
      )
    );
  }
}
