import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:tutorku/providers/app_state_provider.dart';
import 'package:tutorku/models/order_model.dart';
import 'package:tutorku/views/theme.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  String _selectedPeriod = 'Hari Ini'; // 'Hari Ini', 'Kemarin', '7 Hari', '30 Hari'
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  List<OrderModel> _getFilteredOrders(List<OrderModel> allOrders) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    if (_selectedPeriod.startsWith('Tahun ') && _selectedPeriod != 'Tahun Ini') {
      final yearStr = _selectedPeriod.replaceAll('Tahun ', '');
      final yearInt = int.tryParse(yearStr);
      if (yearInt != null) {
        return allOrders.where((o) => o.orderDate.year == yearInt).toList();
      }
    }

    switch (_selectedPeriod) {
      case 'Hari Ini':
        final todayEnd = todayStart.add(const Duration(days: 1));
        return allOrders.where((o) => !o.orderDate.isBefore(todayStart) && o.orderDate.isBefore(todayEnd)).toList();
      case 'Kemarin':
        final yesterdayStart = todayStart.subtract(const Duration(days: 1));
        final yesterdayEnd = todayStart;
        return allOrders.where((o) => !o.orderDate.isBefore(yesterdayStart) && o.orderDate.isBefore(yesterdayEnd)).toList();
      case '7 Hari':
        final start = todayStart.subtract(const Duration(days: 7));
        return allOrders.where((o) => !o.orderDate.isBefore(start)).toList();
      case '30 Hari':
        final start = todayStart.subtract(const Duration(days: 30));
        return allOrders.where((o) => !o.orderDate.isBefore(start)).toList();
      case 'Bulan Ini':
        final monthStart = DateTime(now.year, now.month, 1);
        return allOrders.where((o) => !o.orderDate.isBefore(monthStart)).toList();
      case 'Tahun Ini':
        return allOrders.where((o) => o.orderDate.year == now.year).toList();
      case 'Semua Transaksi':
      default:
        return allOrders;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Penjualan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, provider, child) {
          final filteredOrders = _getFilteredOrders(provider.orders);
          
          // Stats calculation
          final activeOrCompleted = filteredOrders.where((o) => o.status != 'Dibatalkan').toList();
          final double totalOmzet = activeOrCompleted.fold(0.0, (sum, o) => sum + o.nominal);
          final int totalTransactions = filteredOrders.length;
          final int totalTunai = filteredOrders.where((o) => o.paymentMethod == 'Tunai').length;
          final int totalQris = filteredOrders.where((o) => o.paymentMethod == 'Transfer').length;

          final defaultPeriods = ['Hari Ini', 'Kemarin', '7 Hari', '30 Hari', 'Bulan Ini', 'Tahun Ini', 'Semua Transaksi'];
          final currentYear = DateTime.now().year;
          final otherYears = provider.orders
              .map((o) => o.orderDate.year)
              .where((y) => y != currentYear)
              .toSet()
              .toList()
            ..sort((a, b) => b.compareTo(a));
          final periodOptions = [...defaultPeriods, ...otherYears.map((y) => 'Tahun $y')];

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Period Selector Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: periodOptions.map((period) {
                    final isSelected = _selectedPeriod == period;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedPeriod = period;
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryColor.withOpacity(0.08) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              if (isSelected) ...[
                                const Icon(Icons.check, size: 16, color: AppTheme.primaryColor),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                period,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Total Omzet Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F9F90), Color(0xFF0D9488)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  boxShadow: AppTheme.shadowMedium,
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Total Omzet',
                      style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currencyFormatter.format(totalOmzet),
                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildOmzetStatItem(Icons.receipt_long_outlined, '$totalTransactions Transaksi'),
                        _buildOmzetStatItem(Icons.payments_outlined, '$totalTunai Tunai'),
                        _buildOmzetStatItem(Icons.qr_code_2_outlined, '$totalQris QRIS'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Export Buttons Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final textReport = _generateTextReport(filteredOrders, totalOmzet);
                        String? outputFile;

                        if (Platform.isWindows) {
                          outputFile = await FilePicker.platform.saveFile(
                            dialogTitle: 'Simpan Laporan Ringkasan',
                            fileName: 'laporan_penjualan_tutorku.txt',
                            allowedExtensions: ['txt'],
                            type: FileType.custom,
                          );
                        } else {
                          // Android: saveFile not supported, use directory picker
                          final selectedDir = await FilePicker.platform.getDirectoryPath(
                            dialogTitle: 'Pilih Folder Penyimpanan Laporan',
                          );
                          if (selectedDir != null) {
                            outputFile = '$selectedDir/laporan_penjualan_tutorku.txt';
                          }
                        }

                        if (outputFile != null) {
                          final savedFile = File(outputFile);
                          await savedFile.writeAsString(textReport);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Laporan berhasil disimpan!'), backgroundColor: Colors.green),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 18, color: AppTheme.primaryColor),
                      label: const Text('Ekspor Laporan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppTheme.primaryColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final success = await provider.exportOrdersToCsv();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success ? 'Laporan berhasil diekspor!' : 'Proses ekspor dibatalkan atau gagal.'),
                              backgroundColor: success ? Colors.green : Colors.orange,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.table_view_outlined, size: 18, color: AppTheme.primaryColor),
                      label: const Text('Ekspor Excel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppTheme.primaryColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Transactions List Section
              if (filteredOrders.isEmpty)
                Container(
                  height: 180,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      const Text(
                        'Tidak ada transaksi pada periode ini',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                )
              else ...[
                const Text(
                  'Daftar Transaksi',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    final order = filteredOrders[index];
                    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(order.orderDate);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.receipt_long, color: Color(0xFF10B981), size: 20),
                        ),
                        title: Text(
                          order.studentName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Text(
                          '${order.serviceName} • $dateStr',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              currencyFormatter.format(order.nominal),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryColor),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              order.paymentMethod,
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildOmzetStatItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  String _generateTextReport(List<OrderModel> orders, double total) {
    final buffer = StringBuffer();
    buffer.writeln('===================================');
    buffer.writeln('    LAPORAN PENJUALAN TUTORKU     ');
    buffer.writeln('    Periode: $_selectedPeriod      ');
    buffer.writeln('===================================');
    buffer.writeln('Total Omzet: ${currencyFormatter.format(total)}');
    buffer.writeln('Total Transaksi: ${orders.length}');
    buffer.writeln('-----------------------------------');
    
    for (final o in orders) {
      final dateStr = DateFormat('dd-MM-yyyy').format(o.orderDate);
      buffer.writeln('$dateStr | ${o.studentName} | ${o.serviceName} | ${currencyFormatter.format(o.nominal)}');
    }
    buffer.writeln('===================================');
    return buffer.toString();
  }
}
