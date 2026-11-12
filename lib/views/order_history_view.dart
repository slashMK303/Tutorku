import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:tutorku/models/order_model.dart';
import 'package:tutorku/providers/app_state_provider.dart';
import 'package:tutorku/views/transaction_detail_view.dart';

class OrderHistoryView extends StatefulWidget {
  final int? highlightOrderId;

  const OrderHistoryView({super.key, this.highlightOrderId});

  @override
  State<OrderHistoryView> createState() => _OrderHistoryViewState();
}

class _OrderHistoryViewState extends State<OrderHistoryView> {
  String _searchQuery = '';
  String _categoryFilter = 'Semua'; // 'Semua', 'SMP', 'SMA/SMK'
  String _statusFilter = 'Semua'; // 'Semua', 'Aktif', 'Selesai', 'Dibatalkan'

  @override
  void initState() {
    super.initState();
    if (widget.highlightOrderId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionDetailView(orderId: widget.highlightOrderId!),
          ),
        );
      });
    }
  }

  String _formatInvoiceId(OrderModel order) {
    final datePattern = DateFormat('yyyyMMdd').format(order.orderDate);
    final idPattern = (order.id ?? 0).toString().padLeft(4, '0');
    return 'INV/$datePattern/$idPattern';
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormatter = DateFormat('dd MMM yyyy • HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredList = provider.orders.where((order) {
            final invoiceId = _formatInvoiceId(order);
            final matchesSearch = order.studentName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                invoiceId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (order.serviceName != null && order.serviceName!.toLowerCase().contains(_searchQuery.toLowerCase()));
            
            final matchesCategory = _categoryFilter == 'Semua' || order.serviceCategory == _categoryFilter;
            final matchesStatus = _statusFilter == 'Semua' || order.status == _statusFilter;

            return matchesSearch && matchesCategory && matchesStatus;
          }).toList();

          return Column(
            children: [
              _buildFilterPanel(),
              Expanded(
                child: filteredList.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredList.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final order = filteredList[index];
                            final invoiceId = _formatInvoiceId(order);
                            final isCash = order.paymentMethod == 'Tunai';

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TransactionDetailView(orderId: order.id!),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Ikon metode
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isCash
                                            ? const Color(0xFF0F9F90).withOpacity(0.1)
                                            : const Color(0xFF6366F1).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        isCash ? Icons.payments_outlined : Icons.qr_code_2_outlined,
                                        color: isCash ? const Color(0xFF0F9F90) : const Color(0xFF6366F1),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Info Transaksi
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            order.studentName,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '$invoiceId • ${dateFormatter.format(order.orderDate)}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Total Nominal & Chevron
                                    Text(
                                      currencyFormatter.format(order.nominal),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F9F90),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      color: Theme.of(context).cardTheme.color,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          TextField(
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
            decoration: InputDecoration(
              hintText: 'Cari invoice, siswa atau jasa les...',
              prefixIcon: const Icon(Icons.search),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('Tingkat: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(width: 8),
                _buildFilterChip('Semua', _categoryFilter, (val) => setState(() => _categoryFilter = val)),
                const SizedBox(width: 6),
                _buildFilterChip('SMP', _categoryFilter, (val) => setState(() => _categoryFilter = val)),
                const SizedBox(width: 6),
                _buildFilterChip('SMA/SMK', _categoryFilter, (val) => setState(() => _categoryFilter = val)),
              ],
            ),
          ),
          const SizedBox(height: 6),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('Status : ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(width: 8),
                _buildFilterChip('Semua', _statusFilter, (val) => setState(() => _statusFilter = val)),
                const SizedBox(width: 6),
                _buildFilterChip('Aktif', _statusFilter, (val) => setState(() => _statusFilter = val)),
                const SizedBox(width: 6),
                _buildFilterChip('Selesai', _statusFilter, (val) => setState(() => _statusFilter = val)),
                const SizedBox(width: 6),
                _buildFilterChip('Dibatalkan', _statusFilter, (val) => setState(() => _statusFilter = val)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String activeValue, ValueChanged<String> onSelected) {
    final isSelected = activeValue == label;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      selectedColor: const Color(0xFF0F9F90).withOpacity(0.15),
      onSelected: (selected) {
        if (selected) {
          onSelected(label);
        }
      },
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 56, color: Colors.grey.withOpacity(0.4)),
          const SizedBox(height: 12),
          const Text(
            'Tidak ada order les ditemukan.',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          const Text(
            'Sesuaikan filter pencarian atau buat order baru.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
