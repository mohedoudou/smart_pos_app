import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/saved_invoice.dart';
import '../services/database_helper.dart';

class ScanInvoiceScreen extends StatefulWidget {
  const ScanInvoiceScreen({super.key});

  @override
  State<ScanInvoiceScreen> createState() => _ScanInvoiceScreenState();
}

class _ScanInvoiceScreenState extends State<ScanInvoiceScreen> {
  bool _isProcessing = false;
  final MobileScannerController _cameraController = MobileScannerController();

  void _onBarcodeDetected(String code) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final invoice = await DatabaseHelper.instance.getInvoiceByBarcode(code);

    if (!mounted) return;

    if (invoice != null) {
      await _showInvoiceDetailsSheet(invoice);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('لم يتم العثور على فاتورة برقم: $code'),
          backgroundColor: Colors.red,
        ),
      );
    }

    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) setState(() => _isProcessing = false);
  }

  Future<void> _showInvoiceDetailsSheet(SavedInvoice invoice) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('فاتورة: ${invoice.invoiceNumber}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Icon(Icons.receipt, color: Colors.blue),
                ],
              ),
              Text('التاريخ: ${invoice.date}', style: const TextStyle(color: Colors.grey)),
              const Divider(height: 20),
              const Text('المنتجات:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              ...invoice.items.map((it) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${it.productName} × ${it.quantity}'),
                      Text('${(it.price * it.quantity).toStringAsFixed(2)} دج'),
                    ],
                  )),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('المجموع الإجمالي:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('${invoice.totalAmount.toStringAsFixed(2)} دج',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('استرجاع الفاتورة بمسح الكود')),
      body: Stack(
        children: [
          MobileScanner(
            controller: _cameraController,
            onDetect: (capture) {
              final barcode = capture.barcodes.firstOrNull?.rawValue;
              if (barcode != null) {
                _onBarcodeDetected(barcode);
              }
            },
          ),
          Center(
            child: Container(
              width: 260,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.redAccent, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.all(6.0),
                  child: Text(
                    'وجّه الكاميرا نحو باركود الفاتورة',
                    style: TextStyle(color: Colors.white, backgroundColor: Colors.black54, fontSize: 12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
