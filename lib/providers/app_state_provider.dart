import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:tutorku/models/service_model.dart';
import 'package:tutorku/models/order_model.dart';
import 'package:tutorku/models/revision_model.dart';
import 'package:tutorku/services/database_helper.dart';
import 'package:tutorku/services/printer_service.dart';

class AppStateProvider extends ChangeNotifier {
  List<ServiceModel> _services = [];
  List<OrderModel> _orders = [];
  List<BluetoothInfo> _printerDevices = [];
  
  bool _isLoading = false;
  bool _isPrinterConnected = false;
  String? _connectedPrinterMac;
  String? _connectedPrinterName;

  // Shop Profile & Printer Configurations
  String _shopName = 'TutorKu';
  String _shopAddress = 'Jl. Pendidikan No. 123';
  String _shopPhone = '08123456789';
  String _qrisText = 'TUTORKU-MOCK-QRIS-PAYMENT';
  String _paperSize = '58mm'; // '58mm' or '80mm'
  String? _shopLogoPath;
  String _bcaNo = '';
  String _bcaName = '';
  String? _customQrisPath;

  List<ServiceModel> get services => _services;
  List<OrderModel> get orders => _orders;
  List<BluetoothInfo> get printerDevices => _printerDevices;
  
  bool get isLoading => _isLoading;
  bool get isPrinterConnected => _isPrinterConnected;
  String? get connectedPrinterMac => _connectedPrinterMac;
  String? get connectedPrinterName => _connectedPrinterName;

  String get shopName => _shopName;
  String get shopAddress => _shopAddress;
  String get shopPhone => _shopPhone;
  String get qrisText => _qrisText;
  String get paperSize => _paperSize;
  String? get shopLogoPath => _shopLogoPath;
  String get bcaNo => _bcaNo;
  String get bcaName => _bcaName;
  String? get customQrisPath => _customQrisPath;

  int _currentTabIndex = 0;
  int get currentTabIndex => _currentTabIndex;

  void setTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  AppStateProvider() {
    _init();
  }

  Future<void> _init() async {
    await loadServices();
    await loadOrders();
    await _loadSavedSettings();
  }

  // --- LOADING DATA ---

  Future<void> loadServices() async {
    _isLoading = true;
    notifyListeners();
    try {
      _services = await DatabaseHelper.instance.getServices();
    } catch (e) {
      debugPrint('Error loading services: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadOrders() async {
    _isLoading = true;
    notifyListeners();
    try {
      _orders = await DatabaseHelper.instance.getOrders();
    } catch (e) {
      debugPrint('Error loading orders: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- SERVICE CRUD ---

  Future<void> addService(ServiceModel service) async {
    await DatabaseHelper.instance.insertService(service);
    await loadServices();
  }

  Future<void> updateService(ServiceModel service) async {
    await DatabaseHelper.instance.updateService(service);
    await loadServices();
    await loadOrders(); 
  }

  Future<void> deleteService(int id) async {
    await DatabaseHelper.instance.deleteService(id);
    await loadServices();
  }

  // --- ORDER CRUD & REVISION ---

  Future<int> createOrder(OrderModel order) async {
    _isLoading = true;
    notifyListeners();
    try {
      final orderId = await DatabaseHelper.instance.insertOrder(order);
      await loadOrders();
      return orderId;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reviseOrder(OrderModel updatedOrder, String reason) async {
    if (updatedOrder.id == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final currentOrder = await DatabaseHelper.instance.getOrderById(updatedOrder.id!);
      if (currentOrder == null) {
        throw Exception('Order tidak ditemukan untuk direvisi.');
      }

      final snapshot = currentOrder.toMap();
      snapshot['service_name'] = currentOrder.serviceName;
      snapshot['service_category'] = currentOrder.serviceCategory;

      final oldDetailsJson = jsonEncode(snapshot);

      final revision = RevisionModel(
        orderId: updatedOrder.id!,
        revisionReason: reason,
        revisionDate: DateTime.now(),
        oldDetails: oldDetailsJson,
      );
      await DatabaseHelper.instance.insertRevision(revision);

      final revisedOrder = updatedOrder.copyWith(isRevised: 1);
      await DatabaseHelper.instance.updateOrder(revisedOrder);

      await loadOrders();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<RevisionModel>> getOrderRevisions(int orderId) async {
    return await DatabaseHelper.instance.getRevisionsForOrder(orderId);
  }

  Future<void> updateOrderStatus(int orderId, String status) async {
    final order = _orders.firstWhere((o) => o.id == orderId);
    final updated = order.copyWith(status: status);
    await DatabaseHelper.instance.updateOrder(updated);
    await loadOrders();
  }

  // --- SETTINGS (SHOP PROFILE & PAPER SIZE & PRINTER) ---

  Future<void> _loadSavedSettings() async {
    try {
      final dbDir = await DatabaseHelper.instance.getDatabaseFileAbsolutePath();
      final configFile = File(p.join(p.dirname(dbDir), 'app_settings.json'));
      if (await configFile.exists()) {
        final content = await configFile.readAsString();
        final config = jsonDecode(content) as Map<String, dynamic>;
        
        _connectedPrinterMac = config['mac'] as String?;
        _connectedPrinterName = config['name'] as String?;
        _paperSize = config['paperSize'] as String? ?? '58mm';
        _shopName = config['shopName'] as String? ?? 'TutorKu';
        _shopAddress = config['shopAddress'] as String? ?? 'Jl. Pendidikan No. 123';
        _shopPhone = config['shopPhone'] as String? ?? '08123456789';
        _qrisText = config['qrisText'] as String? ?? 'TUTORKU-MOCK-QRIS-PAYMENT';
        _shopLogoPath = config['shopLogoPath'] as String?;
        _bcaNo = config['bcaNo'] as String? ?? '';
        _bcaName = config['bcaName'] as String? ?? '';
        _customQrisPath = config['customQrisPath'] as String?;
        
        if (_connectedPrinterMac != null) {
          final success = await PrinterService.instance.connect(_connectedPrinterMac!);
          _isPrinterConnected = success;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final dbDir = await DatabaseHelper.instance.getDatabaseFileAbsolutePath();
      final configFile = File(p.join(p.dirname(dbDir), 'app_settings.json'));
      
      final config = {
        'mac': _connectedPrinterMac,
        'name': _connectedPrinterName,
        'paperSize': _paperSize,
        'shopName': _shopName,
        'shopAddress': _shopAddress,
        'shopPhone': _shopPhone,
        'qrisText': _qrisText,
        'shopLogoPath': _shopLogoPath,
        'bcaNo': _bcaNo,
        'bcaName': _bcaName,
        'customQrisPath': _customQrisPath,
      };
      
      await configFile.writeAsString(jsonEncode(config));
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  Future<void> updateShopProfile({
    required String name,
    required String address,
    required String phone,
    required String qris,
    String? logoPath,
    required String bcaNo,
    required String bcaName,
    String? customQrisPath,
  }) async {
    _shopName = name;
    _shopAddress = address;
    _shopPhone = phone;
    _qrisText = qris;
    _shopLogoPath = logoPath;
    _bcaNo = bcaNo;
    _bcaName = bcaName;
    _customQrisPath = customQrisPath;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> updatePaperSize(String size) async {
    _paperSize = size;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> scanPrinters() async {
    _isLoading = true;
    notifyListeners();
    try {
      _printerDevices = await PrinterService.instance.getPairedDevices();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> connectPrinter(BluetoothInfo device) async {
    _isLoading = true;
    notifyListeners();
    try {
      final success = await PrinterService.instance.connect(device.macAdress);
      if (success) {
        _isPrinterConnected = true;
        _connectedPrinterMac = device.macAdress;
        _connectedPrinterName = device.name;
        await _saveSettings();
      } else {
        _isPrinterConnected = false;
      }
      return success;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> disconnectPrinter() async {
    await PrinterService.instance.disconnect();
    _isPrinterConnected = false;
    _connectedPrinterMac = null;
    _connectedPrinterName = null;
    await _saveSettings();
    notifyListeners();
  }

  Future<bool> printReceipt(OrderModel order) async {
    return await PrinterService.instance.printReceipt(
      order,
      shopName: _shopName,
      shopAddress: _shopAddress,
      shopPhone: _shopPhone,
      paperSize: _paperSize,
      shopLogoPath: _shopLogoPath,
    );
  }

  // --- BACKUP & RESTORE ---

  Future<bool> backupData({bool share = false}) async {
    try {
      // Flush WAL cache to disk first
      try {
        final db = await DatabaseHelper.instance.database;
        await db.rawQuery('PRAGMA wal_checkpoint(FULL)');
      } catch (_) {
        // Ignore WAL checkpoint errors
      }

      final dbFilePath = await DatabaseHelper.instance.getDatabaseFileAbsolutePath();
      final dbFile = File(dbFilePath);
      
      if (!await dbFile.exists()) {
        debugPrint('Backup failed: Database file not found at $dbFilePath');
        return false;
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

      if (share && Platform.isAndroid) {
        // Android share: copy to temp then share via Share Sheet
        final tempDir = Directory.systemTemp;
        final tempBackupPath = p.join(tempDir.path, 'tutorku_backup_$timestamp.db');
        await dbFile.copy(tempBackupPath);
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(tempBackupPath)],
            subject: 'Backup Data TutorKu',
            text: 'File backup basis data TutorKu.',
          ),
        );
        return true;
      } else {
        // Windows & Android Simpan Lokal: open folder picker
        final String? outputFolder = await FilePicker.platform.getDirectoryPath(
          dialogTitle: 'Pilih Folder Penyimpanan Backup',
        );
        if (outputFolder != null) {
          final String outputFile = p.join(outputFolder, 'tutorku_backup_$timestamp.db');
          await dbFile.copy(outputFile);
          return true;
        }
        return false;
      }
    } catch (e) {
      debugPrint('Backup failed: $e');
      return false;
    }
  }

  Future<bool> restoreData() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        final sourcePath = result.files.single.path!;
        
        if (!sourcePath.endsWith('.db')) {
          throw Exception('File backup harus bertipe database (.db).');
        }

        await DatabaseHelper.instance.importBackup(sourcePath);
        await loadServices();
        await loadOrders();
        
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Restore failed: $e');
      return false;
    }
  }

  Future<bool> exportOrdersToCsv() async {
    try {
      final formatter = DateFormat('dd-MM-yyyy HH:mm');
      final buffer = StringBuffer();
      
      // Headers
      buffer.writeln('ID Transaksi,Nama Murid,Kelas,Jasa Les,Kategori,Tahun,Bulan,Tanggal,Nominal,Uang Diterima,Kembalian,Metode Pembayaran,Status,Tanggal Order,Catatan');
      
      for (final order in _orders) {
        final dateStr = formatter.format(order.orderDate);
        final cleanNotes = order.notes.replaceAll('\n', ' ').replaceAll(',', ';');
        final cashRec = order.cashReceived != null ? order.cashReceived!.toInt() : order.nominal.toInt();
        final change = (order.cashReceived != null && order.cashReceived! > order.nominal)
            ? (order.cashReceived! - order.nominal).toInt()
            : 0;
        buffer.writeln('${order.id},"${order.studentName}","${order.studentClass}","${order.serviceName}",${order.serviceCategory},${order.targetYear},${order.targetMonth},${order.targetDay},${order.nominal.toInt()},$cashRec,$change,${order.paymentMethod},${order.status},$dateStr,"$cleanNotes"');
      }
      
      String? outputFile;

      if (Platform.isWindows) {
        outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Simpan Laporan CSV (Excel)',
          fileName: 'laporan_transaksi_tutorku.csv',
          allowedExtensions: ['csv'],
          type: FileType.custom,
        );
      } else {
        // Android: saveFile not supported, use directory picker
        final selectedDir = await FilePicker.platform.getDirectoryPath(
          dialogTitle: 'Pilih Folder Penyimpanan Laporan',
        );
        if (selectedDir != null) {
          outputFile = p.join(selectedDir, 'laporan_transaksi_tutorku.csv');
        }
      }

      if (outputFile != null) {
        final savedFile = File(outputFile);
        await savedFile.writeAsString(buffer.toString());
        return true;
      }
      return false; // User cancelled save dialog
    } catch (e) {
      debugPrint('Export CSV failed: $e');
      return false;
    }
  }

  Future<void> resetAllData() async {
    _isLoading = true;
    notifyListeners();
    try {
      // 1. Close database
      await DatabaseHelper.instance.closeDatabase();

      // 2. Delete database file
      final dbFilePath = await DatabaseHelper.instance.getDatabaseFileAbsolutePath();
      final dbFile = File(dbFilePath);
      if (await dbFile.exists()) {
        await dbFile.delete();
      }

      // 3. Delete config app_settings.json file
      final appDir = p.dirname(dbFilePath);
      final configFile = File(p.join(appDir, 'app_settings.json'));
      if (await configFile.exists()) {
        await configFile.delete();
      }

      // 4. Delete shop logo file if exists
      if (_shopLogoPath != null) {
        final logoFile = File(_shopLogoPath!);
        if (await logoFile.exists()) {
          await logoFile.delete();
        }
      }

      // Delete custom QRIS image if exists
      if (_customQrisPath != null) {
        final qrisFile = File(_customQrisPath!);
        if (await qrisFile.exists()) {
          await qrisFile.delete();
        }
      }

      // 5. Reset internal memory state to defaults
      _shopName = 'TutorKu';
      _shopAddress = 'Jl. Pendidikan No. 123';
      _shopPhone = '08123456789';
      _qrisText = 'TUTORKU-MOCK-QRIS-PAYMENT';
      _shopLogoPath = null;
      _bcaNo = '';
      _bcaName = '';
      _customQrisPath = null;
      _paperSize = '58mm';
      _isPrinterConnected = false;
      _connectedPrinterMac = null;
      _connectedPrinterName = null;

      // 6. Reload empty database (this will re-create tables)
      await _init();
    } catch (e) {
      debugPrint('Reset all data failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
