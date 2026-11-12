import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:tutorku/services/database_helper.dart';
import 'package:tutorku/providers/app_state_provider.dart';
import 'package:tutorku/views/theme.dart';

class ShopSetupView extends StatefulWidget {
  const ShopSetupView({super.key});

  @override
  State<ShopSetupView> createState() => _ShopSetupViewState();
}

class _ShopSetupViewState extends State<ShopSetupView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _qrisController = TextEditingController();
  final _bcaNoController = TextEditingController();
  final _bcaNameController = TextEditingController();

  String? _logoPath;
  String? _customQrisPath;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<AppStateProvider>(context, listen: false);
    _nameController.text = provider.shopName;
    _addressController.text = provider.shopAddress;
    _phoneController.text = provider.shopPhone;
    _qrisController.text = provider.qrisText;
    _logoPath = provider.shopLogoPath;
    _bcaNoController.text = provider.bcaNo;
    _bcaNameController.text = provider.bcaName;
    _customQrisPath = provider.customQrisPath;
  }

  Future<void> _pickLogo() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null && result.files.single.path != null) {
        final pickedPath = result.files.single.path!;
        final dbDir = await DatabaseHelper.instance.getDatabaseFileAbsolutePath();
        final appDir = p.dirname(dbDir);
        final ext = p.extension(pickedPath);
        final targetPath = p.join(appDir, 'shop_logo$ext');

        // Copy the file to local config directory
        final sourceFile = File(pickedPath);
        await sourceFile.copy(targetPath);

        setState(() {
          _logoPath = targetPath;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih logo: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _pickCustomQris() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null && result.files.single.path != null) {
        final pickedPath = result.files.single.path!;
        final dbDir = await DatabaseHelper.instance.getDatabaseFileAbsolutePath();
        final appDir = p.dirname(dbDir);
        final ext = p.extension(pickedPath);
        final targetPath = p.join(appDir, 'shop_qris$ext');

        // Copy the file to local config directory
        final sourceFile = File(pickedPath);
        await sourceFile.copy(targetPath);

        setState(() {
          _customQrisPath = targetPath;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih gambar QRIS: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _qrisController.dispose();
    _bcaNoController.dispose();
    _bcaNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atur Toko / Bimbingan'),
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, provider, child) {
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informasi Profil Bimbingan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Data di bawah ini akan ditampilkan di header dan footer struk pembayaran yang dicetak.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  // Logo Usaha / Bimbel
                  const Text('Logo Usaha / Bimbel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  _buildLogoPicker(context),
                  const SizedBox(height: 24),

                  // Name
                  const Text('Nama Bimbingan / Toko *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Contoh: TutorKu Bimbingan',
                      prefixIcon: Icon(Icons.storefront),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama bimbingan wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Address
                  const Text('Alamat *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Alamat lengkap bimbingan les...',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      contentPadding: EdgeInsets.all(12),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Alamat wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Phone
                  const Text('Nomor Kontak / WhatsApp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: 'Contoh: 08123456789',
                      prefixIcon: Icon(Icons.phone_outlined),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // BCA Account Number
                  const Text('Nomor Rekening BCA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _bcaNoController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Contoh: 1234567890',
                      prefixIcon: Icon(Icons.account_balance_outlined),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // BCA Account Name
                  const Text('Nama Pemilik Rekening BCA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _bcaNameController,
                    decoration: const InputDecoration(
                      hintText: 'Contoh: Budi Santoso',
                      prefixIcon: Icon(Icons.person_outline),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Custom QRIS Image Upload
                  const Text('Gambar QR Code QRIS / BCA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  _buildCustomQrisPicker(context),
                  const SizedBox(height: 36),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final name = _nameController.text.trim();
                          final address = _addressController.text.trim();
                          final phone = _phoneController.text.trim();
                          final qris = _qrisController.text.trim();

                          await provider.updateShopProfile(
                            name: name,
                            address: address,
                            phone: phone,
                            qris: qris,
                            logoPath: _logoPath,
                            bcaNo: _bcaNoController.text.trim(),
                            bcaName: _bcaNameController.text.trim(),
                            customQrisPath: _customQrisPath,
                          );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Profil Toko berhasil diperbarui!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.pop(context); // Go back
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F9F90), // Teal color
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        'Simpan Profil',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogoPicker(BuildContext context) {
    final bool hasLogo = _logoPath != null && File(_logoPath!).existsSync();

    return GestureDetector(
      onTap: () => _showLogoPickerSheet(context),
      child: Container(
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.borderColor,
            width: 1.5,
          ),
        ),
        child: hasLogo
            ? ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      File(_logoPath!),
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => _buildLogoPlaceholder(),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : _buildLogoPlaceholder(),
      ),
    );
  }

  Widget _buildLogoPlaceholder() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_a_photo_outlined,
          size: 38,
          color: AppTheme.textLight,
        ),
        SizedBox(height: 8),
        Text(
          'Tambah Logo Usaha/Bimbel',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Format PNG/JPG, disarankan rasio 1:1',
          style: TextStyle(
            color: AppTheme.textLight,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  void _showLogoPickerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pilih Logo Usaha',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.image_outlined, color: AppTheme.primaryColor),
                ),
                title: const Text('Pilih dari File/Galeri', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                subtitle: const Text('Cari berkas gambar logo', style: TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickLogo();
                },
              ),
              if (_logoPath != null) ...[
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  ),
                  title: const Text('Hapus Logo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _logoPath = null;
                    });
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomQrisPicker(BuildContext context) {
    final bool hasQris = _customQrisPath != null && File(_customQrisPath!).existsSync();

    return GestureDetector(
      onTap: () => _showCustomQrisPickerSheet(context),
      child: Container(
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.borderColor,
            width: 1.5,
          ),
        ),
        child: hasQris
            ? ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      File(_customQrisPath!),
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => _buildCustomQrisPlaceholder(),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : _buildCustomQrisPlaceholder(),
      ),
    );
  }

  Widget _buildCustomQrisPlaceholder() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.qr_code_scanner_outlined,
          size: 38,
          color: AppTheme.textLight,
        ),
        SizedBox(height: 8),
        Text(
          'Tambah QR Code Toko',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Format PNG/JPG, disarankan barcode QRIS/BCA',
          style: TextStyle(
            color: AppTheme.textLight,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  void _showCustomQrisPickerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pilih QR Code Toko',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.qr_code_2_outlined, color: AppTheme.primaryColor),
                ),
                title: const Text('Pilih dari File/Galeri', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                subtitle: const Text('Cari berkas gambar barcode QRIS/BCA', style: TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickCustomQris();
                },
              ),
              if (_customQrisPath != null) ...[
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  ),
                  title: const Text('Hapus QR Code', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _customQrisPath = null;
                    });
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
