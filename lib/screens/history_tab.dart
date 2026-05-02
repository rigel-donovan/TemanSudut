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

class HistoryTabState extends State<HistoryTab> with AutomaticKeepAliveClientMixin {
  final ApiService _apiService = ApiService();
  final PrinterService _printerService = PrinterService();
  String _selectedFilter = 'daily';
  List<dynamic> _transactions = [];
  bool _isLoading = true;
  bool _showAdvancedFilter = false;
  DateTimeRange? _dateRange;
  int? _weekYear;
  int? _weekNum;
  final Set<int> _selectedMonths = {};

  @override
  bool get wantKeepAlive => true;

  static const List<String> _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];

  String get _filterTitle {
    if (_selectedFilter == 'daily') return 'Hari Ini';
    if (_selectedFilter == 'weekly') return 'Minggu Ini';
    if (_selectedFilter == 'monthly') return 'Bulan Ini';
    if (_selectedFilter.startsWith('date:')) return 'Tanggal ${_selectedFilter.substring(5)}';
    if (_selectedFilter.startsWith('date_range:')) {
      final parts = _selectedFilter.substring(11).split(',');
      return '${parts[0]} s/d ${parts[1]}';
    }
    if (_selectedFilter.startsWith('week:')) {
      final parts = _selectedFilter.substring(5).split(',');
      return 'Minggu ${parts[1]} / ${parts[0]}';
    }
    if (_selectedFilter.startsWith('month:')) {
      final parts = _selectedFilter.split(';');
      return '${parts.length} Bulan Dipilih';
    }
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
    super.build(context);
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
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () => refreshHistory(),
            tooltip: 'Refresh',
          ),
          if (auth.can('export_history'))
            IconButton(
              icon: const Icon(Icons.file_download_outlined, color: Colors.black), 
              onPressed: () => _showDownloadOptions(context),
              tooltip: 'Export Laporan',
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          if (_showAdvancedFilter) _buildAdvancedFilterPanel(),
          
          Expanded(
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: Colors.black))
              : _transactions.isEmpty
                ? _buildEmptyState()
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final cardWidth = (constraints.maxWidth - 34) / 2; 
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.start,
                          children: _transactions.map((transaction) {
                            return SizedBox(
                              width: cardWidth,
                              child: _buildHistoryCard(transaction),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ── Filter bar (quick chips + toggle advanced) ────────────────────────────
  Widget _buildFilterBar() {
    final quickFilters = [
      {'val': 'daily',   'label': 'Hari Ini'},
      {'val': 'weekly',  'label': 'Minggu Ini'},
      {'val': 'monthly', 'label': 'Bulan Ini'},
    ];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: quickFilters.map((f) {
                  final sel = _selectedFilter == f['val'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() { _selectedFilter = f['val']!; _showAdvancedFilter = false; });
                        _fetchHistory();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: sel ? Colors.black : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: sel ? Colors.black : Colors.grey[300]!),
                        ),
                        child: Text(f['label']!, style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : Colors.grey[700],
                        )),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Advanced filter toggle button
          GestureDetector(
            onTap: () => setState(() => _showAdvancedFilter = !_showAdvancedFilter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: _showAdvancedFilter ? const Color(0xFF5D4037) : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _showAdvancedFilter ? const Color(0xFF5D4037) : Colors.grey[300]!),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.tune, size: 14, color: _showAdvancedFilter ? Colors.white : Colors.grey[700]),
                const SizedBox(width: 4),
                Text('Filter', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: _showAdvancedFilter ? Colors.white : Colors.grey[700])),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Advanced filter panel ─────────────────────────────────────────────────
  Widget _buildAdvancedFilterPanel() {
    final now = DateTime.now();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section 1: Date Range ─────────────────────
          _sectionLabel('Rentang Tanggal', Icons.date_range),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: _filterOptionBtn(
                label: _dateRange == null
                    ? 'Pilih Rentang'
                    : '${_fmt(_dateRange!.start)} – ${_fmt(_dateRange!.end)}',
                icon: Icons.calendar_month,
                active: _selectedFilter.startsWith('date_range:'),
                onTap: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: now,
                    initialDateRange: _dateRange,
                    builder: (ctx, child) => Theme(data: _pickerTheme(ctx), child: child!),
                  );
                  if (range != null) {
                    setState(() {
                      _dateRange = range;
                      _selectedFilter = 'date_range:${_fmtIso(range.start)},${_fmtIso(range.end)}';
                      _showAdvancedFilter = false;
                    });
                    _fetchHistory();
                  }
                },
              ),
            ),
          ]),
          const SizedBox(height: 14),

          // ── Section 2: Week picker ────────────────────
          _sectionLabel('Pilih Minggu Spesifik', Icons.view_week_outlined),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 12,
              itemBuilder: (ctx, i) {
                // Last 12 weeks, newest first
                final weekDate = now.subtract(Duration(days: 7 * (11 - i)));
                final isoWeek = _isoWeekNumber(weekDate);
                final isoYear = _isoWeekYear(weekDate);
                final key = '$isoYear,$isoWeek';
                final sel = _selectedFilter == 'week:$key';
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = 'week:$key';
                        _weekYear = isoYear;
                        _weekNum = isoWeek;
                        _showAdvancedFilter = false;
                      });
                      _fetchHistory();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel ? const Color(0xFF5D4037) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: sel ? const Color(0xFF5D4037) : Colors.grey[300]!),
                      ),
                      child: Text('Mg $isoWeek', style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : Colors.grey[700],
                      )),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // ── Section 3: Month picker (multi-select) ────
          _sectionLabel('Pilih Bulan (bisa lebih dari satu)', Icons.calendar_month_outlined),
          const SizedBox(height: 8),
          // Year selector
          Row(children: [
            ...[now.year - 1, now.year].map((yr) {
              final ysel = _selectedMonths.any((m) => m ~/ 100 == yr);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(yr.toString(), style: TextStyle(
                  fontWeight: ysel ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12, color: ysel ? const Color(0xFF5D4037) : Colors.grey[500],
                )),
              );
            }),
          ]),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(24, (i) {
              // Last 24 months
              final date = DateTime(now.year, now.month - (23 - i));
              final key = date.year * 100 + date.month;
              final sel = _selectedMonths.contains(key);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (sel) {
                      _selectedMonths.remove(key);
                    } else {
                      _selectedMonths.add(key);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFF5D4037) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: sel ? const Color(0xFF5D4037) : Colors.grey[300]!),
                  ),
                  child: Text(
                    '${_monthNames[date.month - 1]} ${date.year}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : Colors.grey[700]),
                  ),
                ),
              );
            }),
          ),
          if (_selectedMonths.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D4037),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: () {
                  // Build multi-month filter — we'll send multiple requests and merge
                  final sortedMonths = _selectedMonths.toList()..sort();
                  // For simplicity, pick earliest & latest and use date_range
                  final first = DateTime(sortedMonths.first ~/ 100, sortedMonths.first % 100);
                  final last = DateTime(sortedMonths.last ~/ 100, sortedMonths.last % 100,
                    DateUtils.getDaysInMonth(sortedMonths.last ~/ 100, sortedMonths.last % 100));
                  setState(() {
                    _selectedFilter = 'date_range:${_fmtIso(first)},${_fmtIso(last)}';
                    _showAdvancedFilter = false;
                  });
                  _fetchHistory();
                },
                child: Text('Terapkan ${_selectedMonths.length} Bulan', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionLabel(String label, IconData icon) {
    return Row(children: [
      Icon(icon, size: 14, color: Colors.grey[600]),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700])),
    ]);
  }

  Widget _filterOptionBtn({required String label, required IconData icon, required bool active, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF5D4037).withOpacity(0.08) : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? const Color(0xFF5D4037) : Colors.grey[300]!),
        ),
        child: Row(children: [
          Icon(icon, size: 14, color: active ? const Color(0xFF5D4037) : Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: TextStyle(
            fontSize: 12, color: active ? const Color(0xFF5D4037) : Colors.grey[700],
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ))),
          Icon(Icons.chevron_right, size: 16, color: Colors.grey[400]),
        ]),
      ),
    );
  }

  ThemeData _pickerTheme(BuildContext ctx) => Theme.of(ctx).copyWith(
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF5D4037),
      onPrimary: Colors.white,
      onSurface: Colors.black87,
    ),
  );

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
  String _fmtIso(DateTime d) => '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  int _isoWeekNumber(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final dayOfYear = date.difference(startOfYear).inDays + 1;
    final weekday = startOfYear.weekday;
    return ((dayOfYear + weekday - 2) / 7).ceil();
  }

  int _isoWeekYear(DateTime date) {
    final week = _isoWeekNumber(date);
    if (week >= 52 && date.month == 1) return date.year - 1;
    if (week == 1 && date.month == 12) return date.year + 1;
    return date.year;
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
    final itemsCount = (transaction['items'] as List).length;
    final total = double.tryParse(transaction['total'].toString()) ?? 0;
    final paymentMethod = (transaction['payment_method'] ?? 'cash').toString().toUpperCase();

    // Order type badge
    String? orderTypeLabel;
    Color? orderTypeColor;
    IconData? orderTypeIcon;
    if (transaction['order_type'] != null) {
      final type = transaction['order_type'].toString();
      if (type == 'dine_in') { orderTypeLabel = 'Dine In'; orderTypeColor = Colors.blue; orderTypeIcon = Icons.restaurant; }
      else if (type == 'take_away') { orderTypeLabel = 'Take Away'; orderTypeColor = Colors.orange; orderTypeIcon = Icons.takeout_dining; }
      else if (type == 'online') { orderTypeLabel = 'Online'; orderTypeColor = Colors.green; orderTypeIcon = Icons.moped; }
    }

    return GestureDetector(
      onTap: () => _showDetailSheet(transaction),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF5D4037).withOpacity(0.06),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      invoice,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF5D4037)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (orderTypeLabel != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: orderTypeColor!.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(orderTypeIcon, size: 11, color: orderTypeColor),
                    ),
                ],
              ),
            ),
            // Body
            // Body
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Total (prominent)
                  Text(
                    AppFormat.currency(total),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green[700]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  
                  // Item Pesanan Summary
                  if (transaction['items'] != null && (transaction['items'] as List).isNotEmpty) ...[
                    ...((transaction['items'] as List).take(3).map((item) {
                      final name = item['product'] != null ? item['product']['name'] : 'Item';
                      final qty = item['quantity'];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${qty}x ', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
                            Expanded(child: Text(name, style: const TextStyle(fontSize: 10, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      );
                    }).toList()),
                    if ((transaction['items'] as List).length > 3)
                      Text('+ ${(transaction['items'] as List).length - 3} item lainnya', style: TextStyle(fontSize: 9, color: Colors.grey[500], fontStyle: FontStyle.italic)),
                    const SizedBox(height: 6),
                  ],

                  // Customer
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 10, color: Colors.grey[500]),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          customer,
                          style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Date
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 10, color: Colors.grey[500]),
                      const SizedBox(width: 3),
                      Text(date, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Footer row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          paymentMethod,
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green[700]),
                        ),
                      ),
                      Text(
                        '$itemsCount item',
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailSheet(dynamic transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, scrollCtrl) {
          final date = transaction['created_at'].toString().substring(0, 10);
          final invoice = 'INV-${transaction['id']}';
          final customer = transaction['customer_name'] ?? 'Guest';
          final cashier = transaction['user'] != null ? transaction['user']['name'] : 'Unknown';
          final total = double.tryParse(transaction['total'].toString()) ?? 0;
          final paymentMethod = (transaction['payment_method'] ?? 'cash').toString().toUpperCase();
          final String photoUrl = ApiService().getImageUrl(transaction['completion_photo']);

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(invoice, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(date, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        ],
                      ),
                      Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          if (auth.can('print_receipt')) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.pop(ctx);
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
                                            child: Row(children: [ Icon(Icons.print, color: Colors.black87), SizedBox(width: 12), Text('Cetak Struk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)) ]),
                                          ),
                                          ListTile(
                                            contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                                            leading: Container(padding: EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)), child: Icon(Icons.bluetooth, color: Colors.blue[700])),
                                            title: Text('Printer Thermal', style: TextStyle(fontWeight: FontWeight.w600)),
                                            subtitle: Text('Cetak via bluetooth'),
                                            onTap: () async {
                                              final messenger = ScaffoldMessenger.of(context);
                                              Navigator.pop(context);
                                              if (await _printerService.isConnected) {
                                                if (!mounted) return;
                                                try {
                                                  await _printerService.printReceipt(transaction: transaction, items: transaction['items'] ?? [], isHistory: true);
                                                  messenger.showSnackBar(SnackBar(content: Text('Mencetak struk...')));
                                                } catch (e) {
                                                  messenger.showSnackBar(SnackBar(content: Text('Gagal: $e')));
                                                }
                                              } else {
                                                messenger.showSnackBar(SnackBar(content: Text('Printer belum terhubung!'), backgroundColor: Colors.red));
                                              }
                                            },
                                          ),
                                          ListTile(
                                            contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                                            leading: Container(padding: EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)), child: Icon(Icons.picture_as_pdf, color: Colors.red[700])),
                                            title: Text('Simpan PDF', style: TextStyle(fontWeight: FontWeight.w600)),
                                            subtitle: Text('Download format PDF'),
                                            onTap: () async {
                                              final messenger = ScaffoldMessenger.of(context);
                                              Navigator.pop(context);
                                              try {
                                                await _printerService.downloadReceiptPdf(transaction['id']);
                                                messenger.showSnackBar(SnackBar(content: Text('Membuka PDF...')));
                                              } catch (e) {
                                                messenger.showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
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
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                                child: Icon(Icons.print, size: 18, color: Colors.grey[700]),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: Colors.grey[200]),
                // Scrollable content
                Expanded(
                  child: ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Info Grid
                      Row(
                        children: [
                          Expanded(child: _infoCell('Pelanggan', customer, Icons.person_outline)),
                          const SizedBox(width: 12),
                          Expanded(child: _infoCell('Kasir', cashier, Icons.badge_outlined, color: Colors.indigo[400]!)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _infoCell('Pembayaran', paymentMethod, Icons.payments_outlined, color: Colors.green[600]!)),
                          const SizedBox(width: 12),
                          Expanded(child: _infoCell('Total', AppFormat.currency(total), Icons.attach_money, color: Colors.green[700]!)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Divider(color: Colors.grey[200]),
                      const SizedBox(height: 12),
                      Text('Item Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 10),
                      // Items
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
                                  ? Image.network(ApiService().getImageUrl(item['product']['image']), fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => Icon(Icons.fastfood, size: 20, color: Colors.black12))
                                  : Icon(Icons.fastfood, size: 20, color: Colors.black12),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(child: Text(item['product'] != null ? item['product']['name'] : 'Item', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis)),
                                        Text('x${item['quantity']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      ],
                                    ),
                                    if (item['notes'] != null && item['notes'].toString().isNotEmpty &&
                                        item['notes'].toString().replaceAll('[FREE CUP / GRATIS]', '').replaceAll('|', '').trim().isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          item['notes'].toString().replaceAll(RegExp(r'\s*\|\s*\[FREE CUP / GRATIS\]|\[FREE CUP / GRATIS\]\s*\|\s*|\[FREE CUP / GRATIS\]'), '').trim(),
                                          style: TextStyle(fontSize: 11, color: Colors.amber[800], fontStyle: FontStyle.italic),
                                        ),
                                      ),
                                    const SizedBox(height: 2),
                                    if (item['notes'] != null && item['notes'].toString().contains('[FREE CUP / GRATIS]'))
                                      Text('Gratis', style: TextStyle(color: Colors.green[700], fontSize: 12, fontWeight: FontWeight.bold))
                                    else
                                      Text(AppFormat.currency(item['subtotal']), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      // Total
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Pembayaran', style: TextStyle(fontWeight: FontWeight.w500)),
                            Text(AppFormat.currency(total), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green[700])),
                          ],
                        ),
                      ),
                      // Photo
                      if (photoUrl.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Row(children: [
                          Icon(Icons.camera_alt, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('Foto Bukti', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                        ]),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => Dialog(
                                backgroundColor: const Color(0xFF5D4037),
                                insetPadding: const EdgeInsets.all(12),
                                child: Stack(children: [
                                  Center(child: CachedNetworkImage(
                                    imageUrl: photoUrl, fit: BoxFit.contain,
                                    placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: Colors.white)),
                                    errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white, size: 60),
                                  )),
                                  Positioned(top: 8, right: 8, child: IconButton(
                                    onPressed: () => Navigator.pop(context),
                                    icon: const Icon(Icons.close, color: Colors.white),
                                    style: IconButton.styleFrom(backgroundColor: Colors.black45),
                                  )),
                                ]),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CachedNetworkImage(
                              imageUrl: photoUrl, height: 120, width: double.infinity, fit: BoxFit.cover,
                              placeholder: (_, __) => Container(height: 120, color: Colors.grey[200], child: const Center(child: CircularProgressIndicator())),
                              errorWidget: (_, __, ___) => Container(height: 80, color: Colors.grey[200], child: const Center(child: Icon(Icons.broken_image, color: Colors.grey))),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoCell(String label, String value, IconData icon, {Color color = Colors.black54}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ]),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color == Colors.black54 ? Colors.black87 : color), overflow: TextOverflow.ellipsis, maxLines: 1),
        ],
      ),
    );
  }
}
