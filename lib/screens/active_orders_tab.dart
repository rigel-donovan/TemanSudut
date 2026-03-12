import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'dart:typed_data';
import 'dart:async';
import '../services/api_service.dart';
import '../widgets/popup_notification.dart';
import '../utils/app_format.dart';
import '../providers/auth_provider.dart';
import '../services/printer_service.dart';
import 'package:provider/provider.dart';

class ActiveOrdersTab extends StatefulWidget {
  final VoidCallback? onNavigateToHistory;

  const ActiveOrdersTab({Key? key, this.onNavigateToHistory}) : super(key: key);

  @override
  ActiveOrdersTabState createState() => ActiveOrdersTabState();
}

class ActiveOrdersTabState extends State<ActiveOrdersTab> {
  final ApiService _apiService = ApiService();
  final PrinterService _printerService = PrinterService();
  final ImagePicker _picker = ImagePicker();
  List<dynamic> _activeOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchActiveOrders();
  }

  void refreshOrders() {
    _fetchActiveOrders();
  }

  Future<void> _fetchActiveOrders() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final orders = await _apiService.getActiveOrders();
    if (!mounted) return;
    setState(() {
      _activeOrders = orders;
      _isLoading = false;
    });
  }

  Future<void> _markAsCompleted(dynamic order, {XFile? photo, String? orderType}) async {
    final success = await _apiService.updateTransactionStatus(
      order['id'],
      'completed',
      photo: photo,
      orderType: orderType,
    );
    if (!mounted) return;
    if (success) {
      PopupNotification.show(
        context,
        title: 'Order Selesai! ✅',
        message: 'Order #${order['id']} telah dipindahkan ke History.',
        type: PopupType.success,
      );
      if (widget.onNavigateToHistory != null) {
        widget.onNavigateToHistory!();
      } else {
        _fetchActiveOrders();
      }
    } else {
      PopupNotification.show(
        context,
        title: 'Gagal Update Status',
        message: 'Tidak bisa menyelesaikan order. Coba lagi.',
        type: PopupType.error,
      );
    }
  }

  Future<XFile?> _captureWithCamera(BuildContext context) async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return null;

    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await controller.initialize();
    } catch (e) {
      debugPrint('Camera init error: $e');
      controller.dispose();
      return null;
    }

    final XFile? result = await showDialog<XFile?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _CameraDialog(controller: controller),
    );

    // Wait for dialog pop animation to finish before disposing
    await Future.delayed(const Duration(milliseconds: 500));
    await controller.dispose();
    return result;
  }

  void _showCompletionDialog(dynamic order) {
    XFile? selectedPhoto;
    Uint8List? photoBytes;
    bool isPickingImage = false;
    String? selectedOrderType = order['order_type'] as String?; 

    const orderTypes = [
      {'value': 'dine_in',  'label': 'Dine In',  'icon': Icons.restaurant},
      {'value': 'take_away','label': 'Take Away', 'icon': Icons.shopping_bag_outlined},
      {'value': 'online',   'label': 'Online',    'icon': Icons.delivery_dining},
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            Future<void> pickImage(ImageSource source) async {
              if (isPickingImage) return;
              setDialogState(() => isPickingImage = true);
              try {
                XFile? img;
                if (source == ImageSource.camera) {
                  // Use robust camera logic for live preview
                  img = await _captureWithCamera(dialogCtx);
                } else {
                  img = await _picker.pickImage(
                    source: source,
                    imageQuality: 70,
                  );
                }

                if (img != null) {
                  final bytes = await img.readAsBytes();
                  setDialogState(() {
                    selectedPhoto = img;
                    photoBytes = bytes;
                  });
                }
              } catch (e) {
                debugPrint('Image pick error: $e');
              } finally {
                setDialogState(() => isPickingImage = false);
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: Colors.green[600], size: 22),
                          const SizedBox(width: 8),
                          const Text('Selesaikan Orderan',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Order #${order['id']} – ${order['customer_name'] ?? 'Tamu'}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 20),

                      // Order Type Selector
                      Row(
                        children: [
                          const Icon(Icons.storefront_outlined, size: 16, color: Colors.black87),
                          const SizedBox(width: 6),
                          const Text('Tipe Order (Wajib)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: orderTypes.map((type) {
                          final isSelected = selectedOrderType == type['value'];
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setDialogState(() => selectedOrderType = type['value'] as String),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.black : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? Colors.black : Colors.grey[300]!,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      type['icon'] as IconData,
                                      size: 20,
                                      color: isSelected ? Colors.white : Colors.black54,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      type['label'] as String,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Photo section label
                      Row(
                        children: [
                          const Icon(Icons.camera_alt, size: 16, color: Colors.black87),
                          const SizedBox(width: 6),
                          const Text('Foto Bukti (Wajib)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Photo preview OR picker buttons
                      if (photoBytes != null)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                photoBytes!,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: GestureDetector(
                                onTap: () => setDialogState(() {
                                  selectedPhoto = null;
                                  photoBytes = null;
                                }),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xAA000000),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                          ],
                        )
                      else if (isPickingImage)
                        Container(
                          height: 100,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: Colors.black54),
                                SizedBox(height: 8),
                                Text('Mengambil foto...', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: Material(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  onTap: () => pickImage(ImageSource.camera),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    height: 100,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey[300]!),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.camera_alt_outlined, size: 32, color: Colors.black87),
                                        SizedBox(height: 8),
                                        Text('Ambil Foto Kamera', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogCtx),
                            child: Text('Batal', style: TextStyle(color: Colors.grey[600])),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: (photoBytes == null || selectedOrderType == null)
                                ? null
                                : () {
                                    Navigator.pop(dialogCtx);
                                    _markAsCompleted(order, photo: selectedPhoto, orderType: selectedOrderType);
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey[300],
                              disabledForegroundColor: Colors.grey[500],
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Ya, Selesai'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Active Orders', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _fetchActiveOrders,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _activeOrders.isEmpty
              ? const Center(child: Text('Tidak ada orderan aktif.', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _activeOrders.length,
                  itemBuilder: (context, index) {
                    final order = _activeOrders[index];
                    final customerName = order['customer_name'] ?? 'Guest';
                    final items = order['items'] as List;
                    final status = order['kitchen_status'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Order #${order['id']} - $customerName',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: status == 'pending' ? Colors.orange[100] : Colors.blue[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    status.toString().toUpperCase(),
                                    style: TextStyle(
                                      color: status == 'pending' ? Colors.orange[800] : Colors.blue[800],
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text('${items.length} Items:', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                            const SizedBox(height: 8),
                            ...items.map((item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${item['quantity']}x ${item['product'] != null ? item['product']['name'] : 'Unknown'}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (item['notes'] != null)
                                        Flexible(
                                          child: Text(
                                            'Note: ${item['notes']}',
                                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                    ],
                                  ),
                                )),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    AppFormat.currency(order['total']),
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700]),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Row(
                                  children: [
                                    // Print Receipt Button for Owners (if not pending)
                                    Consumer<AuthProvider>(
                                      builder: (context, auth, _) {
                                        if (auth.can('print_receipt') && status != 'pending') {
                                          return Padding(
                                            padding: const EdgeInsets.only(right: 8.0),
                                            child: IconButton(
                                              icon: Icon(Icons.print, size: 20, color: Colors.blue[600]),
                                              tooltip: 'Cetak Struk',
                                              padding: EdgeInsets.zero,
                                              constraints: BoxConstraints(),
                                              onPressed: () async {
                                                if (await _printerService.isConnected) {
                                                  try {
                                                    await _printerService.printReceipt(transaction: order, items: items, isHistory: false);
                                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mencetak struk pesanan...')));
                                                  } catch (e) {
                                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mencetak: $e')));
                                                  }
                                                } else {
                                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Printer belum terhubung!'), backgroundColor: Colors.red));
                                                }
                                              },
                                            ),
                                          );
                                        }
                                        return SizedBox.shrink();
                                      },
                                    ),
                                    
                                    ElevatedButton.icon(
                                      onPressed: () => _showCompletionDialog(order),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.black,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      icon: const Icon(Icons.camera_alt_outlined, size: 14),
                                      label: const Text(
                                        'Mark as Completed',
                                        style: TextStyle(fontSize: 11),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _CameraDialog extends StatelessWidget {
  final CameraController controller;

  const _CameraDialog({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(0),
      child: Stack(
        children: [
          Center(child: CameraPreview(controller)),
          
          // Controls
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context, null),
                  icon: const Icon(Icons.close, color: Colors.white, size: 32),
                ),
                GestureDetector(
                  onTap: () async {
                    try {
                      final image = await controller.takePicture();
                      if (context.mounted) {
                        Navigator.pop(context, image);
                      }
                    } catch (e) {
                      debugPrint('Error taking picture: $e');
                    }
                  },
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Center(
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48), // Spacer for centering
              ],
            ),
          ),
        ],
      ),
    );
  }
}
