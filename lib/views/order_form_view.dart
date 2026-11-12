import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tutorku/models/order_model.dart';
import 'package:tutorku/models/service_model.dart';
import 'package:tutorku/providers/app_state_provider.dart';
import 'package:tutorku/views/theme.dart';
import 'package:intl/intl.dart';
import 'package:tutorku/utils/rupiah_formatter.dart';

class OrderFormView extends StatefulWidget {
  final OrderModel? revisingOrder;

  const OrderFormView({super.key, this.revisingOrder});

  @override
  State<OrderFormView> createState() => _OrderFormViewState();
}

class _OrderFormViewState extends State<OrderFormView> {
  final _formKey = GlobalKey<FormState>();

  // Form Fields
  String _selectedCategory = 'SMP';
  ServiceModel? _selectedService;
  int _selectedYear = DateTime.now().year;
  String _selectedMonth = '';
  int _selectedDay = DateTime.now().day;
  
  final _studentNameController = TextEditingController();
  final _studentClassController = TextEditingController();
  final _nominalController = TextEditingController();
  final _notesController = TextEditingController();
  final _revisionReasonController = TextEditingController();
  final _cashReceivedController = TextEditingController();

  String _paymentMethod = 'Tunai'; // 'Tunai' or 'Transfer'
  String _transferChannel = 'QRIS'; // 'QRIS' or 'BCA'

  final List<String> _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  final List<int> _years = [
    DateTime.now().year - 1,
    DateTime.now().year,
    DateTime.now().year + 1,
    DateTime.now().year + 2,
  ];

  @override
  void initState() {
    super.initState();
    
    // Set default month to current month
    final currentMonthIdx = DateTime.now().month - 1;
    _selectedMonth = _months[currentMonthIdx];

    // Prepopulate if revising
    if (widget.revisingOrder != null) {
      final order = widget.revisingOrder!;
      _selectedCategory = order.serviceCategory ?? 'SMP';
      _selectedYear = order.targetYear;
      _selectedMonth = order.targetMonth;
      _selectedDay = order.targetDay;
      
      _studentNameController.text = order.studentName;
      _studentClassController.text = order.studentClass;
      _nominalController.text = NumberFormat.decimalPattern('id_ID').format(order.nominal);
      _notesController.text = order.notes;
      _paymentMethod = order.paymentMethod;
      _transferChannel = order.transferChannel;
      if (order.cashReceived != null) {
        _cashReceivedController.text = NumberFormat.decimalPattern('id_ID').format(order.cashReceived!.toInt());
      }
    }

    // Trigger load of service default selection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppStateProvider>(context, listen: false);
      final filteredServices = provider.services.where((s) => s.category == _selectedCategory).toList();
      
      setState(() {
        if (widget.revisingOrder != null) {
          _selectedService = provider.services.firstWhere(
            (s) => s.id == widget.revisingOrder!.serviceId,
            orElse: () => filteredServices.isNotEmpty ? filteredServices.first : provider.services.first,
          );
        } else {
          if (filteredServices.isNotEmpty) {
            _selectedService = filteredServices.first;
            _nominalController.text = NumberFormat.decimalPattern('id_ID').format(_selectedService!.defaultPrice);
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _studentNameController.dispose();
    _studentClassController.dispose();
    _nominalController.dispose();
    _notesController.dispose();
    _revisionReasonController.dispose();
    _cashReceivedController.dispose();
    super.dispose();
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
      final provider = Provider.of<AppStateProvider>(context, listen: false);
      final filtered = provider.services.where((s) => s.category == category).toList();
      if (filtered.isNotEmpty) {
        _selectedService = filtered.first;
        _nominalController.text = NumberFormat.decimalPattern('id_ID').format(_selectedService!.defaultPrice);
      } else {
        _selectedService = null;
        _nominalController.clear();
      }
      
      // Update day validity if month days limit changes
      _validateDayLimit();
    });
  }

  void _onServiceChanged(ServiceModel? service) {
    if (service != null) {
      setState(() {
        _selectedService = service;
        _nominalController.text = NumberFormat.decimalPattern('id_ID').format(service.defaultPrice);
      });
    }
  }

  // Get total days in selected month and year
  int _getDaysInMonth(String monthName, int year) {
    final monthIndex = _months.indexOf(monthName) + 1;
    if (monthIndex <= 0) return 31;
    if (monthIndex == 2) {
      final isLeap = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
      return isLeap ? 29 : 28;
    }
    const thirtyDays = [4, 6, 9, 11];
    return thirtyDays.contains(monthIndex) ? 30 : 31;
  }

  void _validateDayLimit() {
    final maxDays = _getDaysInMonth(_selectedMonth, _selectedYear);
    if (_selectedDay > maxDays) {
      _selectedDay = maxDays;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppStateProvider>(context);
    final isRevising = widget.revisingOrder != null;
    final filteredServices = provider.services.where((s) => s.category == _selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(isRevising ? 'Revisi Transaksi Les' : 'Pesan Jasa Les Baru'),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SECTION 1: INFORMASI JASA LES & PERIODE
                    _buildSectionTitle('Informasi Jasa & Periode'),
                    const SizedBox(height: 12),

                    // Kategori Jasa (Dropdown) - Image 3 style input
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Pilih Kategori Jasa *',
                        prefixIcon: Icon(Icons.school_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'SMP', child: Text('SMP')),
                        DropdownMenuItem(value: 'SMA/SMK', child: Text('SMA / SMK')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          _onCategoryChanged(val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Jasa Les (Dropdown)
                    filteredServices.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange.withOpacity(0.2)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Belum ada jasa les terdaftar di kategori ini. Silakan tambah jasa di menu "Produk" terlebih dahulu.',
                                    style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : DropdownButtonFormField<ServiceModel>(
                            value: _selectedService,
                            decoration: const InputDecoration(
                              // labelText: 'Pilih Jasa Les *',
                              prefixIcon: Icon(Icons.assignment_outlined),
                            ),
                            items: filteredServices.map((service) {
                              return DropdownMenuItem<ServiceModel>(
                                value: service,
                                child: Text(service.name),
                              );
                            }).toList(),
                            onChanged: _onServiceChanged,
                          ),
                    const SizedBox(height: 16),

                    // Grouped Date Dropdowns: Year, Month, Day - Vertical Layout for mobile
                    Column(
                      children: [
                        // Baris 1: Bulan + Tahun
                        Row(
                          children: [
                            // Bulan
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                value: _selectedMonth,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Bulan *',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                                  prefixIcon: Icon(Icons.calendar_month_outlined, size: 16),
                                ),
                                items: _months.map((m) {
                                  return DropdownMenuItem<String>(
                                    value: m,
                                    child: Text(m, style: const TextStyle(fontSize: 12)),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedMonth = val;
                                      _validateDayLimit();
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Tahun
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<int>(
                                value: _selectedYear,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Tahun *',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                                  prefixIcon: Icon(Icons.timeline_outlined, size: 16),
                                ),
                                items: _years.map((y) {
                                  return DropdownMenuItem<int>(
                                    value: y,
                                    child: Text('$y', style: const TextStyle(fontSize: 12)),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedYear = val;
                                      _validateDayLimit();
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Baris 2: Tanggal (full width)
                        DropdownButtonFormField<int>(
                          value: _selectedDay,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Tanggal *',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            prefixIcon: Icon(Icons.calendar_today_outlined, size: 16),
                          ),
                          items: List.generate(
                            _getDaysInMonth(_selectedMonth, _selectedYear),
                            (i) => i + 1,
                          ).map((d) {
                            return DropdownMenuItem<int>(
                              value: d,
                              child: Text('$d'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedDay = val;
                              });
                            }
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // SECTION 2: DETAIL MURID & PEMBAYARAN
                    _buildSectionTitle('Detail Siswa & Pembayaran'),
                    const SizedBox(height: 12),

                    // Student Name
                    TextFormField(
                      controller: _studentNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Anak / Murid *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama murid wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Student Class
                    TextFormField(
                      controller: _studentClassController,
                      decoration: const InputDecoration(
                        labelText: 'Kelas (Misal: 9 SMP, 12 IPA) *',
                        prefixIcon: Icon(Icons.class_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Kelas wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Nominal
                    TextFormField(
                      controller: _nominalController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [RupiahInputFormatter()],
                      decoration: const InputDecoration(
                        labelText: 'Nominal Pembayaran (Rp) *',
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nominal pembayaran wajib diisi';
                        }
                        final cleanValue = value.replaceAll('.', '');
                        if (double.tryParse(cleanValue) == null) {
                          return 'Nominal harus berupa angka';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Catatan Tambahan (Opsional)',
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // SECTION 3: METODE PEMBAYARAN
                    _buildSectionTitle('Metode Pembayaran'),
                    const SizedBox(height: 12),

                    // Payment Method (Dropdown)
                    DropdownButtonFormField<String>(
                      value: _paymentMethod,
                      decoration: const InputDecoration(
                        labelText: 'Pilih Metode Pembayaran *',
                        prefixIcon: Icon(Icons.payment_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Tunai', child: Text('Tunai (Cash)')),
                        DropdownMenuItem(value: 'Transfer', child: Text('Transfer (BCA / QRIS)')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _paymentMethod = val;
                          });
                        }
                      },
                    ),

                    if (_paymentMethod == 'Transfer') ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _transferChannel,
                        decoration: const InputDecoration(
                          labelText: 'Pilih Kanal Transfer *',
                          prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'QRIS', child: Text('QRIS (Scan Barcode)')),
                          DropdownMenuItem(value: 'BCA', child: Text('BCA (Transfer Bank)')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _transferChannel = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      _transferChannel == 'QRIS'
                          ? _buildQRISMockup(provider)
                          : _buildBCAMockup(provider),
                    ],

                    // REVISION REASON (Mandatory when revising)
                    if (isRevising) ...[
                      const SizedBox(height: 24),
                      _buildSectionTitle('Alasan Revisi (Wajib)', color: Colors.orange),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _revisionReasonController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Tuliskan alasan mengapa data transaksi ini diubah...',
                          prefixIcon: Icon(Icons.edit_note_outlined, color: Colors.orange),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Alasan revisi wajib diisi';
                          }
                          return null;
                        },
                      ),
                    ],

                    const SizedBox(height: 36),

                    // SUBMIT BUTTON (Image 2/3 style full-width teal button)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _selectedService == null
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  final nominal = double.parse(_nominalController.text.replaceAll('.', ''));
                                  _showCheckoutBottomSheet(context, nominal);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                        ),
                        child: Text(
                          isRevising ? 'Simpan Perubahan (Revisi)' : 'Simpan & Checkout',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(left: 2.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: color ?? AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildQRISMockup(AppStateProvider provider) {
    final bool hasCustomQris = provider.customQrisPath != null && File(provider.customQrisPath!).existsSync();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.qr_code_2_rounded, size: 28, color: Color(0xFF0F9F90)),
                const SizedBox(width: 6),
                const Text(
                  'QRIS INTERAKTIF',
                  style: TextStyle(
                    color: Color(0xFF0F9F90),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF0F9F90).withOpacity(0.2), width: 1.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: hasCustomQris
                  ? Image.file(
                      File(provider.customQrisPath!),
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                    )
                  : Image.network(
                      'https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=${Uri.encodeComponent(provider.qrisText)}',
                      width: 150,
                      height: 150,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 150,
                          height: 150,
                          color: Colors.grey.shade100,
                          child: const Icon(Icons.qr_code, size: 96, color: Colors.black45),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Silakan scan QRIS di atas untuk melakukan transfer.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            Text(
              hasCustomQris ? '(QRIS Kustom Toko)' : '(Simulasi Pembayaran Terintegrasi)',
              style: const TextStyle(color: Colors.black54, fontSize: 10, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBCAMockup(AppStateProvider provider) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_balance_rounded, size: 24, color: Color(0xFF0F9F90)),
                const SizedBox(width: 8),
                const Text(
                  'INFORMASI BANK TRANSFER',
                  style: TextStyle(
                    color: Color(0xFF0F9F90),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bank Tujuan:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const Text('Bank BCA', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const SizedBox(height: 12),
                  const Text('Nomor Rekening:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text(
                    provider.bcaNo.isNotEmpty ? provider.bcaNo : 'Belum diatur (Atur di Pengaturan Toko)',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  const Text('Nama Pemilik Rekening:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text(
                    provider.bcaName.isNotEmpty ? provider.bcaName : 'Belum diatur',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Silakan lakukan transfer ke rekening di atas sebelum menyelesaikan transaksi.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  void _showCheckoutBottomSheet(BuildContext context, double totalAmount) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    
    if (_paymentMethod == 'Tunai') {
      _cashReceivedController.text = NumberFormat.decimalPattern('id_ID').format(totalAmount);
      
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                final double cashReceived = double.tryParse(_cashReceivedController.text.replaceAll('.', '')) ?? 0;
                final double change = cashReceived - totalAmount;
                final bool isSufficient = cashReceived >= totalAmount;
                
                Widget quickAmountButton(double amount, String label) {
                  final isSelected = cashReceived == amount;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: InkWell(
                        onTap: () {
                          setSheetState(() {
                            _cashReceivedController.text = NumberFormat.decimalPattern('id_ID').format(amount);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryColor : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }

                final quickAmounts = <double>[];
                quickAmounts.add(totalAmount);
                if (totalAmount < 50000) {
                  if (totalAmount < 20000) quickAmounts.add(20000);
                  quickAmounts.add(50000);
                  quickAmounts.add(100000);
                } else if (totalAmount < 100000) {
                  quickAmounts.add(100000);
                  quickAmounts.add(150000);
                  quickAmounts.add(200000);
                } else {
                  final nextRound = ((totalAmount / 50000).ceil() * 50000).toDouble();
                  if (nextRound > totalAmount) {
                    quickAmounts.add(nextRound);
                  }
                  quickAmounts.add(nextRound + 50000);
                  quickAmounts.add(nextRound + 100000);
                  quickAmounts.add(nextRound + 150000);
                }
                final uniqueAmounts = quickAmounts.toSet().toList().take(4).toList();

                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Checkout Pembayaran',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 10),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Tagihan', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                          Text(
                            currencyFormatter.format(totalAmount),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      const Text('Uang Diterima (Rp)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _cashReceivedController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [RupiahInputFormatter()],
                        decoration: const InputDecoration(
                          hintText: 'Masukkan jumlah uang...',
                          prefixIcon: Icon(Icons.payments_outlined),
                        ),
                        onChanged: (val) {
                          setSheetState(() {});
                        },
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: uniqueAmounts.map((amt) {
                          final label = amt == totalAmount ? 'Uang Pas' : currencyFormatter.format(amt).replaceAll('Rp ', '');
                          return quickAmountButton(amt, label);
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSufficient ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isSufficient ? 'Kembalian' : 'Kekurangan Uang',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isSufficient ? Colors.green.shade700 : Colors.red.shade700,
                              ),
                            ),
                            Text(
                              currencyFormatter.format(change.abs()),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isSufficient ? Colors.green.shade700 : Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: isSufficient
                            ? () {
                                Navigator.pop(context);
                                _submitForm();
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: AppTheme.primaryColor,
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Selesaikan Transaksi (Cetak Struk)',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      );
    } else {
      final provider = Provider.of<AppStateProvider>(context, listen: false);
      final bool hasCustomQris = provider.customQrisPath != null && File(provider.customQrisPath!).existsSync();
      final qrisUrl = provider.qrisText.isNotEmpty
          ? 'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${Uri.encodeComponent(provider.qrisText)}'
          : 'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=TUTORKU-MOCK-QRIS-PAYMENT';

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: _transferChannel == 'QRIS'
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Checkout QRIS',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 10),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Tagihan', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                          Text(
                            currencyFormatter.format(totalAmount),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.borderColor),
                            boxShadow: AppTheme.shadowSmall,
                          ),
                          child: hasCustomQris
                              ? Image.file(
                                  File(provider.customQrisPath!),
                                  width: 180,
                                  height: 180,
                                  fit: BoxFit.contain,
                                )
                              : Image.network(
                                  qrisUrl,
                                  width: 180,
                                  height: 180,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 180,
                                      height: 180,
                                      color: Colors.grey.shade100,
                                      child: const Icon(Icons.qr_code, size: 96, color: Colors.black45),
                                    );
                                  },
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Silakan scan QRIS di atas untuk melakukan transfer.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        hasCustomQris ? '(QRIS Kustom Toko)' : '(Simulasi Pembayaran Terintegrasi)',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _submitForm();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Konfirmasi Pembayaran (Cetak Struk)',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Checkout Transfer BCA',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 10),

                      // Total Tagihan Row with Copy Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Tagihan', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                          Row(
                            children: [
                              Text(
                                currencyFormatter.format(totalAmount),
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.copy_rounded, size: 18, color: AppTheme.primaryColor),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Salin nominal',
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: totalAmount.toInt().toString()));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Nominal transfer berhasil disalin!'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Bank info box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Bank Tujuan:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            const Text('Bank BCA', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                            const SizedBox(height: 12),
                            
                            // Account Number Row with Copy Button
                            const Text('Nomor Rekening:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  provider.bcaNo.isNotEmpty ? provider.bcaNo : 'Belum diatur (Atur di Pengaturan Toko)',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                ),
                                if (provider.bcaNo.isNotEmpty)
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: provider.bcaNo));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Nomor Rekening berhasil disalin!'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.copy_rounded, size: 14),
                                    label: const Text('Salin', style: TextStyle(fontSize: 11)),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                      foregroundColor: AppTheme.primaryColor,
                                      elevation: 0,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            const Text('Nama Pemilik Rekening:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text(
                              provider.bcaName.isNotEmpty ? provider.bcaName : 'Belum diatur',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Silakan transfer ke rekening di atas sebelum mengkonfirmasi pembayaran.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _submitForm();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Konfirmasi Transfer (Cetak Struk)',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
          );
        },
      );
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final name = _studentNameController.text.trim();
      final className = _studentClassController.text.trim();
      final nominal = double.parse(_nominalController.text.replaceAll('.', ''));
      final notes = _notesController.text.trim();
      final provider = Provider.of<AppStateProvider>(context, listen: false);
      final monthIdx = _months.indexOf(_selectedMonth) + 1;
      final now = DateTime.now();
      final baseTime = widget.revisingOrder?.orderDate ?? now;
      final calculatedOrderDate = DateTime(
        _selectedYear,
        monthIdx,
        _selectedDay,
        baseTime.hour,
        baseTime.minute,
        baseTime.second,
      );

      double? cashReceived;
      if (_paymentMethod == 'Tunai') {
        final cleanCash = _cashReceivedController.text.replaceAll('.', '');
        cashReceived = double.tryParse(cleanCash);
      }

      final newOrder = OrderModel(
        id: widget.revisingOrder?.id,
        studentName: name,
        studentClass: className,
        serviceId: _selectedService!.id!,
        serviceName: _selectedService!.name,
        serviceCategory: _selectedCategory,
        targetYear: _selectedYear,
        targetMonth: _selectedMonth,
        targetDay: _selectedDay,
        nominal: nominal,
        cashReceived: cashReceived,
        paymentMethod: _paymentMethod,
        transferChannel: _paymentMethod == 'Transfer' ? _transferChannel : 'None',
        orderDate: calculatedOrderDate,
        status: widget.revisingOrder?.status ?? 'Aktif',
        notes: notes,
        isRevised: widget.revisingOrder != null ? 1 : 0,
      );

      try {
        int orderId = 0;
        if (widget.revisingOrder == null) {
          // Create new order
          orderId = await provider.createOrder(newOrder);
        } else {
          // Revise order
          final reason = _revisionReasonController.text.trim();
          await provider.reviseOrder(newOrder, reason);
          orderId = widget.revisingOrder!.id!;
        }

        if (context.mounted) {
          final savedOrder = provider.orders.firstWhere((o) => o.id == orderId || (widget.revisingOrder != null && o.id == widget.revisingOrder!.id));
          _showPrintDialog(context, savedOrder, provider);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Terjadi kesalahan: $e'), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  void _showPrintDialog(BuildContext context, OrderModel order, AppStateProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pemesanan Disimpan'),
          content: Text(
            'Order atas nama ${order.studentName} berhasil disimpan.\n\n'
            'Apakah Anda ingin langsung mencetak struk pembayaran via bluetooth?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // return to dashboard
              },
              child: const Text('Tidak, Nanti Saja'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // close dialog
                _printAndNavigateBack(context, order, provider);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F9F90), foregroundColor: Colors.white),
              child: const Text('Ya, Cetak Struk'),
            ),
          ],
        );
      },
    );
  }

  void _printAndNavigateBack(BuildContext context, OrderModel order, AppStateProvider provider) async {
    // Show quick progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final success = await provider.printReceipt(order);
    
    if (context.mounted) {
      Navigator.pop(context); // close progress indicator
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Struk berhasil dicetak!'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mencetak. Hubungkan printer di menu Pengaturan terlebih dahulu.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
      Navigator.pop(context); // return to dashboard
    }
  }
}
