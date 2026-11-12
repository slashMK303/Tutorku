import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutorku/models/order_model.dart';
import 'package:tutorku/providers/app_state_provider.dart';

class PrinterSetupView extends StatefulWidget {
  const PrinterSetupView({super.key});

  @override
  State<PrinterSetupView> createState() => _PrinterSetupViewState();
}

class _PrinterSetupViewState extends State<PrinterSetupView> {
  @override
  void initState() {
    super.initState();
    // Scan automatically on page open to check for paired printers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppStateProvider>(context, listen: false).scanPrinters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atur Printer'),
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, provider, child) {
          final connected = provider.isPrinterConnected;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Connection Status Card (Image 5 reference)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withOpacity(0.12)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: connected ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          connected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                          color: connected ? Colors.green : Colors.grey,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              connected ? 'Terhubung' : 'Tidak Terhubung',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: connected ? Colors.green : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              connected
                                  ? '${provider.connectedPrinterName} (${provider.connectedPrinterMac})'
                                  : 'Belum ada printer yang terhubung',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      if (connected)
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.redAccent),
                          onPressed: () => provider.disconnectPrinter(),
                        )
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 2. Paper Size Selector (Image 5 reference: 58mm / 80mm buttons)
                const Text(
                  'Ukuran Kertas',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildPaperSizeButton(context, '58mm', provider),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildPaperSizeButton(context, '80mm', provider),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 3. Scan Button (Image 5 reference: solid teal)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: provider.isLoading ? null : () => provider.scanPrinters(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F9F90),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: provider.isLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.bluetooth_searching, size: 20),
                    label: const Text(
                      'Scan Printer Bluetooth',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 4. Test Print Button (Image 5 reference: outline teal/white)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: connected ? () => _sendTestPrint(context, provider) : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F9F90),
                      side: BorderSide(
                        color: connected ? const Color(0xFF0F9F90) : Colors.grey.withOpacity(0.3),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.print_outlined, size: 20),
                    label: const Text(
                      'Test Print',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Paired devices list
                if (provider.printerDevices.isNotEmpty) ...[
                  const Text(
                    'Perangkat Paired Terdeteksi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.printerDevices.length,
                    itemBuilder: (context, index) {
                      final dev = provider.printerDevices[index];
                      final isCurrent = provider.connectedPrinterMac == dev.macAdress;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            Icons.print,
                            color: isCurrent ? const Color(0xFF0F9F90) : Colors.grey,
                          ),
                          title: Text(dev.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text(dev.macAdress, style: const TextStyle(fontSize: 11)),
                          trailing: isCurrent
                              ? const Icon(Icons.check_circle, color: Color(0xFF0F9F90))
                              : const Icon(Icons.link),
                          onTap: () async {
                            if (isCurrent) return;
                            _showLoading(context);
                            final success = await provider.connectPrinter(dev);
                            if (context.mounted) {
                              Navigator.pop(context); // Close loader
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(success ? 'Printer terhubung!' : 'Koneksi gagal. Coba lagi.'),
                                  backgroundColor: success ? Colors.green : Colors.redAccent,
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // 5. Alert Info Box (Image 5 reference: Lavender background, blue text)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF), // Indigo/Lavender tint
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFC7D2FE)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFF4F46E5), size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Pastikan printer Bluetooth sudah dinyalakan dan mode pairing aktif. '
                          'Mendukung printer thermal 58mm dan 80mm dari berbagai merek (EPSON, Xprinter, Zjiang, MiniPrint, dll).',
                          style: TextStyle(
                            color: Color(0xFF4338CA), // Blue/indigo text
                            fontSize: 12,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaperSizeButton(BuildContext context, String size, AppStateProvider provider) {
    final bool isSelected = provider.paperSize == size;
    return InkWell(
      onTap: () => provider.updatePaperSize(size),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE6F4F1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? const Color(0xFF0F9F90) : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2.0 : 1.0,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            size,
            style: TextStyle(
              color: isSelected ? const Color(0xFF0F9F90) : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  void _showLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _sendTestPrint(BuildContext context, AppStateProvider provider) async {
    _showLoading(context);

    // Create a mock order for printing test
    final testOrder = OrderModel(
      studentName: 'Budi Santoso',
      studentClass: '9 SMP',
      serviceId: 0,
      serviceName: 'Test Print Cetak Struk',
      serviceCategory: 'SMP',
      targetYear: DateTime.now().year,
      targetMonth: 'Juli',
      targetDay: DateTime.now().day,
      nominal: 10000,
      cashReceived: 50000,
      paymentMethod: 'Tunai',
      transferChannel: 'None',
      orderDate: DateTime.now(),
      status: 'Aktif',
      notes: 'Testing printer thermal bluetooth',
      isRevised: 0,
    );

    final success = await provider.printReceipt(testOrder);

    if (context.mounted) {
      Navigator.pop(context); // Close loader
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Test print dikirim!' : 'Gagal mengirim test print. Hubungkan ulang printer.'),
          backgroundColor: success ? Colors.green : Colors.orange,
        ),
      );
    }
  }
}
