import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:tutorku/models/order_model.dart';
import 'package:tutorku/models/revision_model.dart';
import 'package:tutorku/providers/app_state_provider.dart';
import 'package:tutorku/views/order_form_view.dart';
import 'package:tutorku/views/theme.dart';
import 'package:tutorku/services/database_helper.dart';

class TransactionDetailView extends StatefulWidget {
  final int orderId;

  const TransactionDetailView({super.key, required this.orderId});

  @override
  State<TransactionDetailView> createState() => _TransactionDetailViewState();
}

class _TransactionDetailViewState extends State<TransactionDetailView> {
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final dateFormatter = DateFormat('dd MMM yyyy • HH:mm');

  String _formatInvoiceId(OrderModel order) {
    final datePattern = DateFormat('yyyyMMdd').format(order.orderDate);
    final idPattern = (order.id ?? 0).toString().padLeft(4, '0');
    return 'INV/$datePattern/$idPattern';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Consumer<AppStateProvider>(
            builder: (context, provider, child) {
              final order = provider.orders.where((o) => o.id == widget.orderId).firstOrNull;
              if (order == null) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.print_outlined),
                tooltip: 'Cetak Struk',
                onPressed: () => _printStruk(context, order, provider),
              );
            },
          ),
        ],
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, provider, child) {
          final order = provider.orders.where((o) => o.id == widget.orderId).firstOrNull;

          if (order == null) {
            return const Center(
              child: Text(
                'Transaksi tidak ditemukan.',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            );
          }

          final invoiceId = _formatInvoiceId(order);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── STRUK DIGITAL CARD ───
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderColor),
                    boxShadow: AppTheme.shadowMedium,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Header Toko dengan Logo di Pojok Kiri Atas
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (provider.shopLogoPath != null && File(provider.shopLogoPath!).existsSync()) ...[
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.borderColor),
                                image: DecorationImage(
                                  image: FileImage(File(provider.shopLogoPath!)),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  provider.shopName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  provider.shopAddress,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Telp: ${provider.shopPhone}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, thickness: 1),
                      const SizedBox(height: 12),

                      // Info Invoice
                      _buildReceiptRow('No. Invoice', invoiceId),
                      _buildReceiptRow('Waktu Order', dateFormatter.format(order.orderDate)),
                      const SizedBox(height: 10),
                      const Divider(height: 1, thickness: 1),
                      const SizedBox(height: 12),

                      // Info Siswa & Jasa Les
                      _buildReceiptRow('Nama Murid', order.studentName, isBold: true),
                      _buildReceiptRow('Kelas', 'Kl. ${order.studentClass}'),
                      _buildReceiptRow('Jasa Les', order.serviceName ?? 'Les Custom', isBold: true),
                      _buildReceiptRow('Kategori', order.serviceCategory ?? 'SMP'),
                      _buildReceiptRow('Periode Belajar', '${order.targetDay} ${order.targetMonth} ${order.targetYear}'),
                      const SizedBox(height: 10),
                      const Divider(height: 1, thickness: 1),
                      const SizedBox(height: 12),

                      // Detail Pembayaran
                      _buildReceiptRow(
                        'TOTAL NOMINAL',
                        currencyFormatter.format(order.nominal),
                        isBold: true,
                        valueColor: AppTheme.primaryColor,
                        valueSize: 16,
                      ),
                      _buildReceiptRow(
                        'Metode Bayar',
                        order.paymentMethod == 'Transfer'
                            ? 'Transfer (${order.transferChannel})'
                            : 'Tunai',
                      ),
                      if (order.paymentMethod == 'Tunai' && order.cashReceived != null) ...[
                        _buildReceiptRow(
                          'Uang Diterima',
                          currencyFormatter.format(order.cashReceived),
                        ),
                        _buildReceiptRow(
                          'Kembalian',
                          currencyFormatter.format(
                            (order.cashReceived! - order.nominal) >= 0
                                ? (order.cashReceived! - order.nominal)
                                : 0,
                          ),
                          valueColor: Colors.green.shade700,
                        ),
                      ],
                      _buildReceiptRow(
                        'Status Kelas',
                        '',
                        trailingWidget: _buildStatusBadge(order.status),
                      ),
                      if (order.notes.trim().isNotEmpty)
                        _buildReceiptRow('Catatan', order.notes.trim()),

                      // Riwayat Revisi (Tampil langsung jika ada)
                      if (order.isRevised == 1) ...[
                        const SizedBox(height: 12),
                        const Divider(height: 1, thickness: 1),
                        const SizedBox(height: 12),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              Icon(Icons.history, size: 14, color: Colors.orange),
                              SizedBox(width: 6),
                              Text(
                                'Riwayat Perubahan (Revisi)',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildRevisionHistoryWidget(order.id!, provider),
                      ],

                      const SizedBox(height: 16),
                      const Divider(height: 1, thickness: 1),
                      const SizedBox(height: 12),
                      
                      // Receipt Footer Note
                      const Text(
                        'Terima kasih atas kepercayaannya belajar bersama kami!',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ─── TOMBOL AKSI ───
                Row(
                  children: [
                    // Edit Status Dropdown
                    Expanded(
                      flex: 4,
                      child: PopupMenuButton<String>(
                        onSelected: (status) => provider.updateOrderStatus(order.id!, status),
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'Aktif', child: Text('Set Aktif')),
                          const PopupMenuItem(value: 'Selesai', child: Text('Set Selesai')),
                          const PopupMenuItem(value: 'Dibatalkan', child: Text('Set Dibatalkan')),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.borderColor),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.edit_road_outlined, size: 18, color: AppTheme.textPrimary),
                              SizedBox(width: 8),
                              Text(
                                'Ubah Status',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Revisi Button
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderFormView(revisingOrder: order),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.white),
                        label: const Text('Revisi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Delete Button
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red.shade200),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.red.shade50,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        onPressed: () => _confirmDeleteOrder(context, order, provider),
                        tooltip: 'Hapus Transaksi',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Cetak Struk Big Button
                ElevatedButton.icon(
                  onPressed: () => _printStruk(context, order, provider),
                  icon: const Icon(Icons.print, color: Colors.white),
                  label: const Text('Cetak Struk Pembayaran', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReceiptRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
    double valueSize = 12,
    Widget? trailingWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: trailingWidget ??
                Text(
                  value,
                  style: TextStyle(
                    fontSize: valueSize,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                    color: valueColor ?? AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.right,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'Aktif':
        color = Colors.green;
        break;
      case 'Selesai':
        color = Colors.blue;
        break;
      default:
        color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRevisionHistoryWidget(int orderId, AppStateProvider provider) {
    return FutureBuilder<List<RevisionModel>>(
      future: provider.getOrderRevisions(orderId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5)));
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('Gagal memuat riwayat revisi.', style: TextStyle(fontSize: 10, color: Colors.grey));
        }

        final revisions = snapshot.data!;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: revisions.length,
          itemBuilder: (context, idx) {
            final rev = revisions[idx];
            final Map<String, dynamic> oldData = jsonDecode(rev.oldDetails);

            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Revisi #${revisions.length - idx}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 10),
                      ),
                      Text(
                        dateFormatter.format(rev.revisionDate),
                        style: const TextStyle(fontSize: 8, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Alasan: ${rev.revisionReason}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sebelumnya:\n'
                    '• Siswa: ${oldData['student_name']} (${oldData['student_class']})\n'
                    '• Jasa: ${oldData['service_name'] ?? 'Les'}\n'
                    '• Nominal: ${currencyFormatter.format(oldData['nominal'] ?? 0)} (${oldData['payment_method']})',
                    style: const TextStyle(fontSize: 9, color: Colors.black54),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _printStruk(BuildContext context, OrderModel order, AppStateProvider provider) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final success = await provider.printReceipt(order);

    if (context.mounted) {
      Navigator.pop(context); // close loader
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Struk berhasil dicetak!' : 'Gagal mencetak struk. Pastikan printer bluetooth terhubung.'),
          backgroundColor: success ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  void _confirmDeleteOrder(BuildContext context, OrderModel order, AppStateProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Transaksi'),
          content: Text('Apakah Anda yakin ingin menghapus transaksi atas nama "${order.studentName}" secara permanen?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close detail view back to history
                await DatabaseHelper.instance.deleteOrder(order.id!);
                await provider.loadOrders();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Transaksi berhasil dihapus'), backgroundColor: Colors.green),
                  );
                }
              },
              child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
            ),
          ],
        );
      },
    );
  }
}
