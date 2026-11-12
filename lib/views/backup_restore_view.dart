import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutorku/providers/app_state_provider.dart';
import 'package:tutorku/views/theme.dart';

class BackupRestoreView extends StatefulWidget {
  const BackupRestoreView({super.key});

  @override
  State<BackupRestoreView> createState() => _BackupRestoreViewState();
}

class _BackupRestoreViewState extends State<BackupRestoreView> {
  bool _includeImages = true;
  bool _shareBackup = true; // true = Bagikan, false = Simpan Lokal

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, provider, child) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // SECTION 1: BACKUP DATA
              const Text(
                'Backup Data',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 4),
              const Text(
                'Simpan cadangan database dan gambar produk ke file ZIP',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),

              // Sertakan Gambar Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.image_outlined, color: Color(0xFF10B981), size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sertakan Gambar Produk',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Ukuran file akan lebih besar',
                            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _includeImages,
                      activeColor: AppTheme.primaryColor,
                      onChanged: (val) {
                        setState(() {
                          _includeImages = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Simpan Ke
              const Text(
                'Simpan ke',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 10),

              // Two buttons side-by-side
              Row(
                children: [
                  // Option 1: Bagikan
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _shareBackup = true;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _shareBackup ? AppTheme.primaryColor.withOpacity(0.08) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _shareBackup ? AppTheme.primaryColor : AppTheme.borderColor,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.share_outlined,
                              color: _shareBackup ? AppTheme.primaryColor : AppTheme.textSecondary,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Bagikan',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: _shareBackup ? AppTheme.primaryColor : AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'WhatsApp, Drive, dll',
                              style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Option 2: Simpan Lokal
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _shareBackup = false;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: !_shareBackup ? AppTheme.primaryColor.withOpacity(0.08) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: !_shareBackup ? AppTheme.primaryColor : AppTheme.borderColor,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.folder_open_outlined,
                              color: !_shareBackup ? AppTheme.primaryColor : AppTheme.textSecondary,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Simpan Lokal',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: !_shareBackup ? AppTheme.primaryColor : AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Pilih folder di HP',
                              style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Solid Teal Button: Mulai Backup
              ElevatedButton.icon(
                onPressed: () => _executeBackup(context, provider),
                icon: const Icon(Icons.cloud_upload_outlined, color: Colors.white),
                label: const Text('Mulai Backup', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 36),
              const Divider(),
              const SizedBox(height: 24),

              // SECTION 2: RESTORE DATA
              const Text(
                'Restore Data',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 4),
              const Text(
                'Pulihkan data dari file backup ZIP',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),

              // Alert/Warning box
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB), // Amber 50
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)), // Amber 200
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 24),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Restore akan menggantikan semua data yang ada saat ini. Pastikan Anda sudah membuat backup sebelum melakukan restore.',
                        style: TextStyle(color: Color(0xFF92400E), fontSize: 12, height: 1.5, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Restore Button
              OutlinedButton.icon(
                onPressed: () => _confirmRestore(context, provider),
                icon: const Icon(Icons.restore_page_outlined, color: AppTheme.primaryColor),
                label: const Text('Pilih & Pulihkan Data', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  void _executeBackup(BuildContext context, AppStateProvider provider) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final success = await provider.backupData(share: _shareBackup);

      if (mounted) {
        Navigator.pop(context); // close loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Backup data berhasil disimpan!' : 'Proses backup dibatalkan atau gagal.'),
            backgroundColor: success ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup gagal: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _confirmRestore(BuildContext context, AppStateProvider provider) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Pulihkan Data dari Backup'),
          content: const Text(
            'Apakah Anda yakin ingin melanjutkan? Seluruh database les aktif Anda akan digantikan dengan data backup tersebut.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _executeRestore(provider);
              },
              child: const Text('Lanjutkan Restore', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
            ),
          ],
        );
      },
    );
  }

  void _executeRestore(AppStateProvider provider) async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final success = await provider.restoreData();

      if (mounted) {
        Navigator.pop(context); // close loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Database berhasil dipulihkan!' : 'Proses restore dibatalkan atau gagal.'),
            backgroundColor: success ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore gagal: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
