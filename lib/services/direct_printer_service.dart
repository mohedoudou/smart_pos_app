import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart' as bc;

class DirectThermalPrinterService {
  static Future<List<BluetoothInfo>> getPairedDevices() async {
    final bool isEnabled = await PrintBluetoothThermal.bluetoothEnabled;
    if (!isEnabled) return [];
    return await PrintBluetoothThermal.pairedBluetooths;
  }

  static Future<bool> connect(String macAddress) async {
    return await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
  }

  static Future<bool> printTicketBytes(List<int> bytes) async {
    final bool isConnected = await PrintBluetoothThermal.connectionStatus;
    if (!isConnected) return false;
    return await PrintBluetoothThermal.writeBytes(bytes);
  }

  static Future<List<int>> generateArabicReceiptBytes({
    required String storeName,
    required String phone,
    required String invoiceNumber,
    required String qrData,
    required List<Map<String, dynamic>> items,
    required double total,
    PaperSize paperSize = PaperSize.mm58,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(paperSize, profile);
    List<int> bytes = [];

    final int width = paperSize == PaperSize.mm58 ? 384 : 576;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    double currentY = 10.0;

    void drawText(String text, {double fontSize = 20, bool isBold = false, TextAlign align = TextAlign.center}) {
      final textSpan = TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.black,
          fontSize: fontSize,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.rtl,
        textAlign: align,
      );
      textPainter.layout(maxWidth: width.toDouble() - 20);
      textPainter.paint(canvas, Offset(10, currentY));
      currentY += textPainter.height + 6;
    }

    void drawDivider() {
      final linePaint = Paint()..color = Colors.black..strokeWidth = 1;
      canvas.drawLine(Offset(10, currentY), Offset(width.toDouble() - 10, currentY), linePaint);
      currentY += 8;
    }

    drawText(storeName, fontSize: 24, isBold: true);
    drawText('هاتف: $phone', fontSize: 16);
    drawText('رقم الفاتورة: $invoiceNumber', fontSize: 16);
    drawDivider();

    for (var item in items) {
      final name = item['name'];
      final qty = item['qty'];
      final price = (item['price'] * qty).toStringAsFixed(2);
      drawText('$name  ($qty)  :  $price دج', fontSize: 16, align: TextAlign.right);
    }

    drawDivider();
    drawText('المجموع: ${total.toStringAsFixed(2)} دج', fontSize: 22, isBold: true);
    drawDivider();

    if (qrData.isNotEmpty) {
      drawText('امسح للتحقق', fontSize: 14);
      final qrPainter = QrPainter(
        data: qrData,
        version: QrVersions.auto,
        gapless: true,
        color: Colors.black,
        emptyColor: Colors.white,
      );
      const double qrSize = 130.0;
      final double qrOffsetLeft = (width - qrSize) / 2;
      canvas.save();
      canvas.translate(qrOffsetLeft, currentY);
      qrPainter.paint(canvas, const Size(qrSize, qrSize));
      canvas.restore();
      currentY += qrSize + 15;
    }

    if (invoiceNumber.isNotEmpty) {
      const double barcodeWidth = 220.0;
      const double barcodeHeight = 45.0;
      final double barcodeOffsetLeft = (width - barcodeWidth) / 2;
      final barcode = bc.Barcode.code128();
      final customBarcodePainter = bc.BarcodePainter(
        barcode,
        invoiceNumber,
        textStyle: const TextStyle(color: Colors.black, fontSize: 12),
      );
      canvas.save();
      canvas.translate(barcodeOffsetLeft, currentY);
      customBarcodePainter.paint(canvas, const Size(barcodeWidth, barcodeHeight));
      canvas.restore();
      currentY += barcodeHeight + 15;
    }

    drawText('شكراً لزيارتكم!', fontSize: 16);
    currentY += 20;

    final picture = recorder.endRecording();
    final imgUi = await picture.toImage(width, currentY.toInt());
    final byteData = await imgUi.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List pngBytes = byteData!.buffer.asUint8List();
    final decodedImg = img.decodeImage(pngBytes)!;

    bytes += generator.reset();
    bytes += generator.imageRaster(decodedImg);
    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }
}
