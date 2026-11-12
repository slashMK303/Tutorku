import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:tutorku/providers/app_state_provider.dart';
import 'package:tutorku/views/order_form_view.dart';
import 'package:tutorku/views/order_history_view.dart';
import 'package:tutorku/views/theme.dart';
import 'package:tutorku/models/order_model.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      body: Consumer<AppStateProvider>(
        builder: (context, provider, child) {
          // Calculations
          final DateTime today = DateTime.now();
          final String todayStr = DateFormat('yyyy-MM-dd').format(today);

          final todayOrders = provider.orders.where((o) {
            final String oDateStr = DateFormat('yyyy-MM-dd').format(o.orderDate);
            return oDateStr == todayStr && o.status != 'Dibatalkan';
          }).toList();

          final todayOmzet = todayOrders.fold<double>(0, (sum, order) => sum + order.nominal);
          final serviceCount = provider.services.length;
          final recentOrders = provider.orders.take(5).toList();

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // POS style Header (Image 1 reference)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selamat Datang! 👋',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            provider.shopName,
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                          ),
                        ],
                      ),
                      // Quick connection status icon
                      IconButton(
                        icon: Icon(
                          Icons.print_outlined,
                          color: provider.isPrinterConnected ? Colors.green : Colors.grey,
                        ),
                        onPressed: () {
                          // Jump to Settings
                          provider.setTabIndex(3);
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),

                  // Stats Grid Layout (Image 1 reference: colored small left icon box, bold value)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 600;
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildPOSStatCard(
                                  context,
                                  'Total Jasa',
                                  '$serviceCount',
                                  Icons.inventory_2_outlined,
                                  const Color(0xFF14B8A6), // Teal
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildPOSStatCard(
                                  context,
                                  'Transaksi Hari Ini',
                                  '${todayOrders.length}',
                                  Icons.receipt_long_outlined,
                                  const Color(0xFF6366F1), // Indigo/Purple
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildPOSStatCardWidth(
                            context,
                            'Omzet Hari Ini',
                            currencyFormatter.format(todayOmzet),
                            Icons.account_balance_wallet_outlined,
                            const Color(0xFF10B981), // Emerald/Green
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // Teal Action Button (Image 1 reference "Mulai Menjual")
                  Container(
                    height: 56,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFF0F9F90), // POS teal color
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const OrderFormView()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.storefront_outlined, color: Colors.white, size: 22),
                      label: const Text(
                        'Mulai Pemesanan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Menu Shortcuts
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pintasan Menu',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildQuickAction(context, 'Kelola Jasa', Icons.category_outlined, const Color(0xFF0F9F90), () {
                        provider.setTabIndex(1);
                      }),
                      const SizedBox(width: 12),
                      _buildQuickAction(context, 'Riwayat', Icons.assignment_outlined, const Color(0xFF6366F1), () {
                        provider.setTabIndex(2);
                      }),
                      const SizedBox(width: 12),
                      _buildQuickAction(context, 'Pengaturan', Icons.settings_outlined, Colors.orange, () {
                        provider.setTabIndex(3);
                      }),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Recent Transactions Header (Image 1 reference "Transaksi Terakhir")
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Transaksi Terakhir',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      TextButton(
                        onPressed: () {
                          provider.setTabIndex(2);
                        },
                        child: const Text(
                          'Lihat Semua',
                          style: TextStyle(color: Color(0xFF0F9F90), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Transaction List
                  recentOrders.isEmpty
                      ? _buildEmptyState(context)
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: recentOrders.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final order = recentOrders[index];
                            return _buildPOSOrderTile(context, order, currencyFormatter);
                          },
                        ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPOSStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color themeColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: themeColor, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPOSStatCardWidth(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color themeColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: themeColor, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.12)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPOSOrderTile(
    BuildContext context,
    OrderModel order,
    NumberFormat currencyFormatter,
  ) {
    final bool isSmp = order.serviceCategory == 'SMP';
    final Color categoryColor = isSmp ? Colors.blue : Colors.purple;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(
                Icons.school_outlined,
                color: categoryColor,
                size: 20,
              ),
            ),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.studentName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                currencyFormatter.format(order.nominal),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF0F9F90),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${order.serviceName} • Kl. ${order.studentClass}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  '${order.targetDay}/${order.targetMonth.substring(0, 3)}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          onTap: () {
            // Open details by switching tab to Riwayat and highlighting
            final provider = Provider.of<AppStateProvider>(context, listen: false);
            provider.setTabIndex(2);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderHistoryView(highlightOrderId: order.id),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 42, color: Colors.grey.withOpacity(0.4)),
          const SizedBox(height: 10),
          const Text(
            'Belum ada transaksi hari ini.',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 2),
          const Text(
            'Silakan buat pesanan baru untuk memulai.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
