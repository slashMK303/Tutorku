import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutorku/providers/app_state_provider.dart';
import 'package:tutorku/views/printer_setup_view.dart';
import 'package:tutorku/views/shop_setup_view.dart';
import 'package:tutorku/views/reports_view.dart';
import 'package:tutorku/views/backup_restore_view.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, provider, child) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // SECTION 1: TOKO (Image 4 reference)
              _buildCategoryHeader('Toko'),
              const SizedBox(height: 8),
              _buildMenuCard(
                context,
                title: 'Atur Toko',
                subtitle: 'Nama, alamat, telepon, QRIS',
                icon: Icons.storefront_outlined,
                iconColor: const Color(0xFF0F9F90),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ShopSetupView()),
                ),
              ),
              const SizedBox(height: 10),
              _buildMenuCard(
                context,
                title: 'Atur Printer',
                subtitle: 'Hubungkan printer bluetooth',
                icon: Icons.print_outlined,
                iconColor: const Color(0xFF6366F1),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PrinterSetupView()),
                ),
              ),

              const SizedBox(height: 20),

              // SECTION 2: DATA (Image 4 reference)
              _buildCategoryHeader('Data'),
              const SizedBox(height: 8),
              _buildMenuCard(
                context,
                title: 'Laporan',
                subtitle: 'Rekap penjualan & ekspor',
                icon: Icons.bar_chart_outlined,
                iconColor: const Color(0xFF10B981),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReportsView()),
                ),
              ),
              const SizedBox(height: 10),
              _buildMenuCard(
                context,
                title: 'Backup & Restore',
                subtitle: 'Cadangkan atau pulihkan data',
                icon: Icons.cloud_done_outlined,
                iconColor: Colors.orange,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BackupRestoreView()),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 2.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF1E293B),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: Colors.grey,
            size: 18,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
