import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/popup_notification.dart';
import '../utils/app_format.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/printer_service.dart';

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
    if (_transactions.isEmpty) {
      setState(() => _isLoading = true);
    }
    final data = await _apiService.getHistory(_selectedFilter);
    if (!mounted) return;
    setState(() {
      _transactions = data;
      _isLoading = false;
    });
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
      backgroundColor: Colors.grey[50], 
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Riwayat Transaksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(_filterTitle, style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.normal)),
          ],
        ),
        centerTitle: false,
        actions: [
          if (auth.isOwner)
            Container(
              margin: EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: Icon(Icons.file_download_outlined, color: Colors.green[700]), 
                onPressed: () => _showDownloadOptions(context),
                tooltip: 'Export Laporan',
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Hari Ini', 'daily'),
                  SizedBox(width: 8),
                  _buildFilterChip('Minggu Ini', 'weekly'),
                  SizedBox(width: 8),
                  _buildFilterChip('Bulan Ini', 'monthly'),
                  SizedBox(width: 8),
                  _buildDateFilterChip(),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: Colors.black))
              : _transactions.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = _transactions[index];
                      return _buildHistoryCard(transaction);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedFilter = value);
          _fetchHistory();
        }
      },
      selectedColor: Colors.black,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      backgroundColor: Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide(color: isSelected ? Colors.black : Colors.grey[300]!, width: 1),
    );
  }

  Widget _buildDateFilterChip() {
    final isDateFilter = _selectedFilter.startsWith('date:');
    final label = isDateFilter ? _selectedFilter.substring(5) : 'Pilih Tanggal';
    
    return ChoiceChip(
      avatar: Icon(Icons.calendar_month, size: 16, color: isDateFilter ? Colors.white : Colors.grey[700]),
      label: Text(label),
      selected: isDateFilter,
      onSelected: (selected) async {
        final DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: Colors.black, 
                  onPrimary: Colors.white, 
                  onSurface: Colors.black, 
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
      selectedColor: Colors.black,
      labelStyle: TextStyle(
        color: isDateFilter ? Colors.white : Colors.grey[700],
        fontWeight: isDateFilter ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      backgroundColor: Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide(color: isDateFilter ? Colors.black : Colors.grey[300]!, width: 1),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text(
            'Tidak Ada Transaksi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
          ),
          SizedBox(height: 8),
          Text(
            'Belum ada riwayat pesanan pada periode ini.',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
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
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04), 
            blurRadius: 15, 
            offset: Offset(0, 8)
          )
        ],
        border: Border.all(color: Colors.grey[100]!)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Section
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: Colors.grey[100]!))
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(invoice, style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.bold)),
                    SizedBox(height: 2),
                    Text(date, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                  ],
                ),
                Row(
                  children: [
                    if (transaction['order_type'] != null) ...[
                      Builder(builder: (_) {
                        final type = transaction['order_type'].toString();
                        String label = type;
                        MaterialColor color = Colors.grey;
                        IconData iconData = Icons.receipt;

                        if (type == 'dine_in') {
                          label = 'Dine In';
                          color = Colors.blue;
                          iconData = Icons.restaurant;
                        } else if (type == 'take_away') {
                          label = 'Take Away';
                          color = Colors.orange;
                          iconData = Icons.takeout_dining;
                        } else if (type == 'online') {
                          label = 'Online';
                          color = Colors.green;
                          iconData = Icons.moped;
                        }

                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: color.withOpacity(0.2), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(iconData, size: 12, color: color[700]),
                              SizedBox(width: 4),
                              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color[700])),
                            ],
                          ),
                        );
                      }),
                      SizedBox(width: 8),
                    ],
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        if (auth.can('print_receipt')) {
                          return GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                                builder: (context) {
                                  return SafeArea(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(top: 24.0, bottom: 16, left: 24, right: 24),
                                          child: Row(
                                            children: [
                                              Icon(Icons.print, color: Colors.black87),
                                              SizedBox(width: 12),
                                              Text('Cetak Struk Transaksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                            ],
                                          ),
                                        ),
                                        ListTile(
                                          contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                                          leading: Container(
                                            padding: EdgeInsets.all(8),
                                            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                                            child: Icon(Icons.bluetooth, color: Colors.blue[700])
                                          ),
                                          title: Text('Printer Thermal (Bluetooth)', style: TextStyle(fontWeight: FontWeight.w600)),
                                          subtitle: Text('Cetak langsung via bluetooth'),
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
                                                messenger.showSnackBar(SnackBar(content: Text('Mencetak struk...')));
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
                                          contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                                          leading: Container(
                                            padding: EdgeInsets.all(8),
                                            decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                                            child: Icon(Icons.picture_as_pdf, color: Colors.red[700])
                                          ),
                                          title: Text('Simpan PDF (80mm)', style: TextStyle(fontWeight: FontWeight.w600)),
                                          subtitle: Text('Download format PDF'),
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
                                        SizedBox(height: 16),
                                      ],
                                    ),
                                  );
                                }
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                              child: Icon(Icons.print, size: 16, color: Colors.grey[700]),
                            ),
                          );
                        }
                        return SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Info Grid
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pelanggan', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                          SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.person, size: 12, color: Colors.black54),
                              SizedBox(width: 4),
                              Flexible(child: Text(customer, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Kasir', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                          SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.badge, size: 12, color: Colors.indigo[400]),
                              SizedBox(width: 4),
                              Flexible(child: Text(cashier, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.indigo[700]), overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Jumlah Item', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                          SizedBox(height: 2),
                          Text('$itemsCount item', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pembayaran', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                          SizedBox(height: 2),
                          Text(paymentMethod, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green[700])),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 16),
                Divider(color: Colors.grey[200], thickness: 1, height: 1),
                SizedBox(height: 16),
                
                // Item List inside History
                ...(transaction['items'] as List).map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42, height: 42, 
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
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
                                  Flexible(child: Text(item['product'] != null ? item['product']['name'] : 'Item', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                                  Text('x${item['quantity']}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                              if (item['notes'] != null && item['notes'].toString().isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber[50],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.edit_note, size: 12, color: Colors.amber[800]),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          item['notes'],
                                          style: TextStyle(fontSize: 10, color: Colors.amber[900], fontStyle: FontStyle.italic),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              SizedBox(height: 2),
                              Text(AppFormat.currency(item['subtotal']), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),

                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!)
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Pembayaran', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                      Text(AppFormat.currency(total), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green[700])),
                    ],
                  ),
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
                                child: CachedNetworkImage(
                                  imageUrl: photoUrl,
                                  fit: BoxFit.contain,
                                  placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.white)),
                                  errorWidget: (context, url, error) => Column(
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
                      child: CachedNetworkImage(
                        imageUrl: photoUrl,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 120,
                          color: Colors.grey[200],
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
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
