import 'dart:io';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img;
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:tutorku/models/order_model.dart';
import 'package:intl/intl.dart';

class PrinterService {
  static final PrinterService instance = PrinterService._init();
  PrinterService._init();

  // Scan paired/available devices
  Future<List<BluetoothInfo>> getPairedDevices() async {
    try {
      final List<BluetoothInfo> result = await PrintBluetoothThermal.pairedBluetooths;
      return result;
    } catch (e) {
      return [];
    }
  }

  // Connect to a device
  Future<bool> connect(String macAddress) async {
    try {
      final bool result = await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
      return result;
    } catch (e) {
      return false;
    }
  }

  // Disconnect
  Future<bool> disconnect() async {
    try {
      final bool result = await PrintBluetoothThermal.disconnect;
      return result;
    } catch (e) {
      return false;
    }
  }

  // Check connection status
  Future<bool> get isConnected async {
    try {
      final bool result = await PrintBluetoothThermal.connectionStatus;
      return result;
    } catch (e) {
      return false;
    }
  }

  // Print receipt
  Future<bool> printReceipt(
    OrderModel order, {
    required String shopName,
    required String shopAddress,
    required String shopPhone,
    required String paperSize,
    String? shopLogoPath,
  }) async {
    final connected = await isConnected;
    if (!connected) {
      return false;
    }

    final bytes = await _generateReceiptBytes(
      order,
      shopName: shopName,
      shopAddress: shopAddress,
      shopPhone: shopPhone,
      paperSize: paperSize,
      shopLogoPath: shopLogoPath,
    );
    if (bytes.isEmpty) return false;

    try {
      final bool result = await PrintBluetoothThermal.writeBytes(bytes);
      return result;
    } catch (e) {
      return false;
    }
  }

  // Generate bytes using esc_pos_utils_plus
  Future<List<int>> _generateReceiptBytes(
    OrderModel order, {
    required String shopName,
    required String shopAddress,
    required String shopPhone,
    required String paperSize,
    String? shopLogoPath,
  }) async {
    List<int> bytes = [];
    final profile = await CapabilityProfile.load();
    final pSize = paperSize == '80mm' ? PaperSize.mm80 : PaperSize.mm58;
    final generator = Generator(pSize, profile);

    final String divider = paperSize == '80mm'
        ? '================================================'
        : '================================';
    final String subDivider = paperSize == '80mm'
        ? '------------------------------------------------'
        : '--------------------------------';

    // Global code table
    bytes += generator.setGlobalCodeTable('CP1252');

    // Print Shop Logo image if present (resized for fast thermal printing)
    if (shopLogoPath != null && File(shopLogoPath).existsSync()) {
      try {
        final logoBytes = File(shopLogoPath).readAsBytesSync();
        final decodedImage = img.decodeImage(logoBytes);
        if (decodedImage != null) {
          final maxWidth = paperSize == '80mm' ? 180 : 130;
          final resizedImage = img.copyResize(decodedImage, width: maxWidth);
          bytes += generator.image(resizedImage, align: PosAlign.center);
        }
      } catch (e) {
        // Fallback silently if image parsing fails
      }
    }

    // Header
    bytes += generator.text(
      shopName.toUpperCase(),
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );
    bytes += generator.text(
      shopAddress,
      styles: const PosStyles(align: PosAlign.center),
    );
    if (shopPhone.isNotEmpty) {
      bytes += generator.text(
        'Telp/WA: $shopPhone',
        styles: const PosStyles(align: PosAlign.center),
      );
    }
    bytes += generator.text(divider, styles: const PosStyles(align: PosAlign.center));

    // Order Info
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate);
    bytes += generator.text('Struk ID: TR-${order.id ?? 0}');
    bytes += generator.text('Tanggal : $dateStr');
    bytes += generator.text('Siswa   : ${order.studentName}');
    bytes += generator.text('Kelas   : ${order.studentClass}');
    bytes += generator.text(divider, styles: const PosStyles(align: PosAlign.center));

    // Tutoring details
    bytes += generator.text(
      'Detail Periode Les:',
      styles: const PosStyles(bold: true),
    );
    bytes += generator.text(
      '${order.targetDay} ${order.targetMonth} ${order.targetYear}',
      styles: const PosStyles(align: PosAlign.left),
    );
    bytes += generator.text(
      'Jasa: ${order.serviceName ?? 'Les Custom'}',
      styles: const PosStyles(align: PosAlign.left),
    );
    
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final nominalStr = currencyFormatter.format(order.nominal);
    bytes += generator.text('Nominal : $nominalStr');
    if (order.notes.trim().isNotEmpty) {
      bytes += generator.text('Catatan : ${order.notes.trim()}');
    }
    
    bytes += generator.text(subDivider, styles: const PosStyles(align: PosAlign.center));
    
    bytes += generator.text('Metode  : ${order.paymentMethod}');
    if (order.paymentMethod == 'Transfer') {
      bytes += generator.text('Saluran : ${order.transferChannel}');
    } else if (order.paymentMethod == 'Tunai' && order.cashReceived != null) {
      final cashStr = currencyFormatter.format(order.cashReceived);
      final changeVal = order.cashReceived! - order.nominal;
      final changeStr = currencyFormatter.format(changeVal >= 0 ? changeVal : 0);
      bytes += generator.text('Dibayar : $cashStr');
      bytes += generator.text('Kembali : $changeStr');
    }
    bytes += generator.text('Status  : LUNAS', styles: const PosStyles(bold: true));
    
    bytes += generator.text(divider, styles: const PosStyles(align: PosAlign.center));

    // Footer
    bytes += generator.text(
      'Terima Kasih',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      'Telah mempercayakan pendidikan',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      'putra/putri Anda pada kami.',
      styles: const PosStyles(align: PosAlign.center),
    );

    // Feed paper
    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }
}
