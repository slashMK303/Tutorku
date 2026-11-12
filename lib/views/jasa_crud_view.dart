import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:tutorku/models/service_model.dart';
import 'package:tutorku/providers/app_state_provider.dart';
import 'package:tutorku/utils/rupiah_formatter.dart';
import 'package:tutorku/views/theme.dart';

class JasaCrudView extends StatefulWidget {
  const JasaCrudView({super.key});

  @override
  State<JasaCrudView> createState() => _JasaCrudViewState();
}

class _JasaCrudViewState extends State<JasaCrudView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Jasa Les'),
        bottom: TabBar(
          controller: _tabController,
          dividerColor: Colors.transparent,
          indicatorColor: const Color(0xFF0F9F90),
          labelColor: const Color(0xFF0F9F90),
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Kategori SMP'),
            Tab(text: 'Kategori SMA/SMK'),
          ],
        ),
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final smpServices = provider.services.where((s) => s.category == 'SMP').toList();
          final smaServices = provider.services.where((s) => s.category == 'SMA/SMK').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildServiceGrid(context, smpServices, provider, currencyFormatter, 'SMP'),
              _buildServiceGrid(context, smaServices, provider, currencyFormatter, 'SMA/SMK'),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showServiceFormDialog(context),
        backgroundColor: const Color(0xFF0F9F90),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildServiceGrid(
    BuildContext context,
    List<ServiceModel> list,
    AppStateProvider provider,
    NumberFormat currencyFormatter,
    String category,
  ) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text(
              'Belum ada jasa les kategori $category.',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tekan tombol + di kanan bawah untuk menambah.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final double width = MediaQuery.of(context).size.width;
    // Responsive grid column count (Image 2 style)
    int crossAxisCount = 2;
    if (width > 900) {
      crossAxisCount = 4;
    } else if (width > 600) {
      crossAxisCount = 3;
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.68, // Taller cards to prevent overflow on mobile
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final service = list[index];
        final bool isSmp = service.category == 'SMP';
        
        // Solid flat light background for mock product image (no gradients)
        final Color headerBgColor = isSmp
            ? const Color(0xFFE0F2FE) // Very light blue
            : const Color(0xFFF3E8FF); // Very light purple
        final Color headerIconColor = isSmp
            ? const Color(0xFF0284C7)
            : const Color(0xFF7C3AED);

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: AppTheme.borderColor),
            boxShadow: AppTheme.shadowSmall,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mock Image Header (No gradients)
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppTheme.radiusMedium - 1),
                  ),
                  child: Container(
                    width: double.infinity,
                    color: isSmp ? const Color(0xFFE0F2FE) : const Color(0xFFF3E8FF),
                    child: Center(
                      child: Icon(
                        Icons.school_outlined,
                        color: isSmp ? const Color(0xFF0284C7) : const Color(0xFF7C3AED),
                        size: 36,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Service Info
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: Text(
                          service.category,
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        service.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Text(
                        currencyFormatter.format(service.defaultPrice),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      
                      const SizedBox(height: 4),
                      const Divider(height: 1, thickness: 0.5),
                      const SizedBox(height: 2),
                      
                      // Compact Action Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: () => _showServiceFormDialog(context, service: service),
                            icon: const Icon(Icons.edit_outlined, size: 12, color: AppTheme.primaryColor),
                            label: Text('Edit', style: TextStyle(fontSize: 10, color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _confirmDeleteService(context, service, provider),
                            icon: const Icon(Icons.delete_outline, size: 14, color: AppTheme.errorColor),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showServiceFormDialog(BuildContext context, {ServiceModel? service}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: service?.name ?? '');
    final priceController = TextEditingController(
      text: service?.defaultPrice != null
          ? NumberFormat.decimalPattern('id_ID').format(service!.defaultPrice)
          : '',
    );
    final descController = TextEditingController(text: service?.description ?? '');
    String selectedCategory = service?.category ?? 'SMP';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(service == null ? 'Tambah Jasa Les' : 'Edit Jasa Les'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Kategori Tingkatan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        items: const [
                          DropdownMenuItem(value: 'SMP', child: Text('SMP')),
                          DropdownMenuItem(value: 'SMA/SMK', child: Text('SMA / SMK')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedCategory = val;
                            });
                          }
                        },
                        decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                      ),
                      const SizedBox(height: 14),
                      const Text('Nama Jasa Les', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          hintText: 'Contoh: Matematika Kelas 9',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama jasa les wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      const Text('Harga Bawaan (Rp)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [RupiahInputFormatter()],
                        decoration: const InputDecoration(
                          hintText: 'Contoh: 150.000',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Harga wajib diisi';
                          }
                          final cleanValue = value.replaceAll('.', '');
                          if (double.tryParse(cleanValue) == null) {
                            return 'Harga harus berupa angka';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      const Text('Deskripsi Singkat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: descController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Keterangan materi / durasi...',
                          contentPadding: EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final name = nameController.text.trim();
                      final price = double.parse(priceController.text.replaceAll('.', ''));
                      final desc = descController.text.trim();

                      final provider = Provider.of<AppStateProvider>(context, listen: false);

                      if (service == null) {
                        // Create
                        final newService = ServiceModel(
                          name: name,
                          category: selectedCategory,
                          defaultPrice: price,
                          description: desc,
                          createdAt: DateTime.now(),
                        );
                        await provider.addService(newService);
                      } else {
                        // Update
                        final updated = service.copyWith(
                          name: name,
                          category: selectedCategory,
                          defaultPrice: price,
                          description: desc,
                        );
                        await provider.updateService(updated);
                      }

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(service == null ? 'Jasa berhasil ditambahkan' : 'Jasa berhasil diubah'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F9F90),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteService(BuildContext context, ServiceModel service, AppStateProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Hapus Jasa Les',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Apakah Anda yakin ingin menghapus jasa "${service.name}"? Tindakan ini tidak dapat dibatalkan.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          try {
                            await provider.deleteService(service.id!);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Jasa berhasil dihapus'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Gagal Menghapus'),
                                  content: Text(e.toString().replaceAll('Exception:', '')),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Hapus'),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
