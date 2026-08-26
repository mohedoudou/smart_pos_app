import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/cart_item.dart';
import '../models/saved_invoice.dart';
import '../services/database_helper.dart';
import '../services/direct_printer_service.dart';

class POSScreen extends StatefulWidget {
  const POSScreen({super.key});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  final List<CartItem> _cart = [];
  bool _isScanning = true;

  double get _grandTotal => _cart.fold(0.0, (sum, item) => sum + item.totalPrice);

  void _onBarcodeDetected(String barcode) async {
    if (!_isScanning) return;

    final product = await DatabaseHelper.instance.getProductByBarcode(barcode);

    if (product != null) {
      setState(() {
        final existingIndex = _cart.indexWhere((item) => item.product.barcode == barcode);
        if (existingIndex >= 0) {
          _cart[existingIndex].quantity += 1;
        } else {
          _cart.add(CartItem(product: product));
        }
      });
      _pauseScannerTemporarily();
    } else {
      _showUnregisteredDialog(barcode);
    }
  }

  void _pauseScannerTemporarily() {
    setState(() => _isScanning = false);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isScanning = true);
    });
  }

  void _showUnregisteredDialog(String barcode) {
    setState(() => _isScanning = false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('منتج غير مسجل'),
        content: Text('الباركود $barcode غير موجود في المخزون. انتقل لتبويب المخزون لإضافته.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isScanning = true);
            },
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _checkout() async {
    final invoiceNumber = 'INV${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
    final dateNow = DateTime.now().toString().substring(0, 16);

    final invoice = SavedInvoice(
      invoiceNumber: invoiceNumber,
      date: dateNow,
      totalAmount: _grandTotal,
      items: _cart
          .map((item) => SavedInvoiceItem(
                invoiceNumber: invoiceNumber,
                productName: item.product.name,
                quantity: item.quantity,
                price: item.product.price,
              ))
          .toList(),
    );

    await DatabaseHelper.instance.saveInvoice(invoice);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('تم حفظ الفاتورة بنجاح', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Text('رقم الفاتورة: $invoiceNumber'),
            Text('المجموع: ${_grandTotal.toStringAsFixed(2)} دج'),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              icon: const Icon(Icons.print),
              label: const Text('طباعة فورية عبر البلوتوث'),
              onPressed: () async {
                Navigator.pop(ctx);
                _showPrinterSelection(invoiceNumber);
              },
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _cart.clear());
              },
              child: const Text('إغلاق وبدء عملية جديدة'),
            )
          ],
        ),
      ),
    );
  }

  void _showPrinterSelection(String invoiceNumber) async {
    final devices = await DirectThermalPrinterService.getPairedDevices();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('اختر طابعة البلوتوث'),
        content: SizedBox(
          width: double.maxFinite,
          height: 250,
          child: devices.isEmpty
              ? const Center(child: Text('لا توجد طابعات مقترنة بالهاتف'))
              : ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (c, i) => ListTile(
                    leading: const Icon(Icons.print),
                    title: Text(devices[i].name),
                    subtitle: Text(devices[i].macAdress),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await DirectThermalPrinterService.connect(devices[i].macAdress);
                      final bytes = await DirectThermalPrinterService.generateArabicReceiptBytes(
                        storeName: 'سوبرماركت النور',
                        phone: '0555 12 34 56',
                        invoiceNumber: invoiceNumber,
                        qrData: 'INV:$invoiceNumber:TOTAL:$_grandTotal',
                        items: _cart
                            .map((e) => {
                                  'name': e.product.name,
                                  'qty': e.quantity,
                                  'price': e.product.price,
                                })
                            .toList(),
                        total: _grandTotal,
                      );
                      await DirectThermalPrinterService.printTicketBytes(bytes);
                      setState(() => _cart.clear());
                    },
                  ),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نقطة البيع - POS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => setState(() => _cart.clear()),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 200,
            child: MobileScanner(
              onDetect: (capture) {
                final barcode = capture.barcodes.firstOrNull?.rawValue;
                if (barcode != null) {
                  _onBarcodeDetected(barcode);
                }
              },
            ),
          ),
          Expanded(
            child: _cart.isEmpty
                ? const Center(child: Text('امسح باركود المنتج لإضافته إلى الفاتورة'))
                : ListView.builder(
                    itemCount: _cart.length,
                    itemBuilder: (context, index) {
                      final item = _cart[index];
                      return ListTile(
                        title: Text(item.product.name),
                        subtitle: Text('${item.product.price} × ${item.quantity}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${item.totalPrice.toStringAsFixed(2)} دج',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () {
                                setState(() {
                                  if (item.quantity > 1) {
                                    item.quantity--;
                                  } else {
                                    _cart.removeAt(index);
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('المجموع الإجمالي:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('${_grandTotal.toStringAsFixed(2)} دج',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: Colors.blueAccent,
                  ),
                  onPressed: _cart.isEmpty ? null : _checkout,
                  icon: const Icon(Icons.receipt_long, color: Colors.white),
                  label: const Text('إصدار وحفظ الفاتورة', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
