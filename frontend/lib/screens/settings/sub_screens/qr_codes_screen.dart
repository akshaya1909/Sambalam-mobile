import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui; // Needed for QR painting
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../api/branch_api_service.dart';
import '../../../../models/branch_model.dart';

class QrCodesScreen extends StatefulWidget {
  const QrCodesScreen({Key? key}) : super(key: key);

  @override
  State<QrCodesScreen> createState() => _QrCodesScreenState();
}

class _QrCodesScreenState extends State<QrCodesScreen> {
  final BranchApiService _api = BranchApiService();
  List<Branch> _allBranches = [];
  List<Branch> _filteredBranches = [];
  bool _isLoading = true;
  String? _companyId;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _companyId = prefs.getString('companyId');
    if (_companyId != null) {
      _fetchBranches();
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchBranches() async {
    setState(() => _isLoading = true);
    try {
      final list = await _api.getCompanyBranches(_companyId!);
      if (mounted) {
        setState(() {
          _allBranches = list;
          _filteredBranches = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack('Failed to load branches', isError: true);
      }
    }
  }

  void _filterBranches(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredBranches = _allBranches;
      } else {
        _filteredBranches = _allBranches
            .where((b) =>
                b.name.toLowerCase().contains(query.toLowerCase()) ||
                b.address.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : const Color(0xFF10B981),
      ),
    );
  }

  // --- QR GENERATION LOGIC ---
  String _generateQrData(Branch branch) {
    final Map<String, dynamic> payload = {
      'type': 'attendance',
      'companyId': _companyId,
      'branchId': branch.id,
      'branchName': branch.name,
      'address': branch.address,
      'lat': branch.latitude,
      'lng': branch.longitude,
      'ts': DateTime.now().millisecondsSinceEpoch,
    };
    return jsonEncode(payload);
  }

  void _showQrDialog(Branch branch) {
    final String qrData = _generateQrData(branch);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0), // Reduced padding slightly
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                branch.name,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Scan to mark attendance',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // --- RESPONSIVE BUTTONS (Fixes Overflow) ---
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12, // Horizontal gap
                runSpacing: 12, // Vertical gap if wrapped
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showQrDialog(branch); // Regenerate
                      _showSnack("QR Code Regenerated");
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Regenerate'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    onPressed: () => _shareQrCode(branch, qrData),
                    icon:
                        const Icon(Icons.share, size: 18, color: Colors.white),
                    label: const Text('Share',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareQrCode(Branch branch, String data) async {
    try {
      final qrValidationResult = QrValidator.validate(
        data: data,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );

      if (qrValidationResult.status == QrValidationStatus.valid) {
        final qrCode = qrValidationResult.qrCode!;
        final painter = QrPainter.withQr(
          qr: qrCode,
          color: const Color(0xFF000000),
          gapless: true,
          embeddedImageStyle: null,
          embeddedImage: null,
        );

        final picData = await painter.toImageData(875);
        final Uint8List pngBytes = picData!.buffer.asUint8List();

        final tempDir = await getTemporaryDirectory();
        final file =
            await File('${tempDir.path}/${branch.name}_QR.png').create();
        await file.writeAsBytes(pngBytes);

        await Share.shareXFiles([XFile(file.path)],
            text: 'Attendance QR for ${branch.name}');
      }
    } catch (e) {
      _showSnack('Failed to share QR code', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color bg = Color(0xFFF4F6FB);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        titleSpacing: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'QR Codes',
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          // Info Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFFECFDF5),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: Color(0xFF047857), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Each branch has a unique QR code for attendance scanning.',
                    style: TextStyle(
                        color: Color(0xFF065F46), fontSize: 13, height: 1.3),
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              onChanged: _filterBranches,
              decoration: InputDecoration(
                hintText: 'Search branches...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
            ),
          ),

          // Grid Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredBranches.isEmpty
                    ? _buildEmptyState()
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio:
                              0.85, // Adjusted to prevent vertical overflow in card
                        ),
                        itemCount: _filteredBranches.length,
                        itemBuilder: (context, index) {
                          return _BranchQrCard(
                            branch: _filteredBranches[index],
                            onViewQr: () =>
                                _showQrDialog(_filteredBranches[index]),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.qr_code_2, size: 60, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No branches found',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
          ),
          SizedBox(height: 4),
          Text(
            'Add branches in "My Branches" settings',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET: Branch QR Card ---

class _BranchQrCard extends StatelessWidget {
  final Branch branch;
  final VoidCallback onViewQr;

  const _BranchQrCard({
    Key? key,
    required this.branch,
    required this.onViewQr,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onViewQr,
        child: Padding(
          padding: const EdgeInsets.all(12), // Reduced padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFFE5E7EB), style: BorderStyle.solid),
                ),
                child: const Icon(Icons.qr_code_2,
                    size: 28, color: Color(0xFF9CA3AF)),
              ),
              const SizedBox(height: 12),

              // Flexible widgets prevent text overflow inside Column
              Text(
                branch.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                branch.address,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onViewQr,
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                        vertical: 8), // Tighter padding
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'View QR',
                    style: TextStyle(fontSize: 12, color: Color(0xFF111827)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
