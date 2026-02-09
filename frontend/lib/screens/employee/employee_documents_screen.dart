import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data'; // Required for Uint8List
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart'; // Use for 'View'
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import '../../api/employee_document_api_service.dart';
import '../../models/employee_document.dart';

class EmployeeDocumentsScreen extends StatefulWidget {
  final String employeeId;

  const EmployeeDocumentsScreen({Key? key, required this.employeeId})
      : super(key: key);

  @override
  State<EmployeeDocumentsScreen> createState() =>
      _EmployeeDocumentsScreenState();
}

class _EmployeeDocumentsScreenState extends State<EmployeeDocumentsScreen> {
  final EmployeeDocumentApiService _apiService = EmployeeDocumentApiService();

  bool _isLoading = true;
  List<EmployeeDocument> _documents = [];

  // Stats
  int get _verifiedCount => _documents.where((d) => d.verified).length;
  int get _pendingCount => _documents.where((d) => !d.verified).length;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    try {
      final docs = await _apiService.getDocuments(widget.employeeId);
      if (mounted) {
        setState(() {
          _documents = docs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteDocument(String docId) async {
    // Confirm Dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document?'),
        content: const Text('Are you sure you want to delete this document?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _apiService.deleteDocument(widget.employeeId, docId);
      _loadDocuments(); // Refresh
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document deleted successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  void _showImagePreview(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(child: InteractiveViewer(child: Image.network(url))),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const CircleAvatar(
                    backgroundColor: Colors.white54,
                    child: Icon(Icons.close, color: Colors.black)),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadAndOpen(String partialPath, String name,
      {bool isView = false}) async {
    try {
      // 1. Prepare the URL
      final cleanBaseUrl = EmployeeDocumentApiService.baseUrl.endsWith('/')
          ? EmployeeDocumentApiService.baseUrl
              .substring(0, EmployeeDocumentApiService.baseUrl.length - 1)
          : EmployeeDocumentApiService.baseUrl;

      final String urlString = '$cleanBaseUrl$partialPath';
      final Uri url = Uri.parse(urlString);

      // 2. Handle Native Image Preview (Works for both Web and Mobile)
      if (isView &&
          (name.toLowerCase().endsWith('.jpg') ||
              name.toLowerCase().endsWith('.png') ||
              name.toLowerCase().endsWith('.jpeg'))) {
        _showImagePreview(urlString);
        return;
      }

      // 3. PLATFORM SPECIFIC LOGIC
      if (kIsWeb) {
        // --- WEB FLOW ---
        if (isView) {
          html.window.open(urlString, '_blank');
        } else {
          final anchor = html.AnchorElement(href: urlString)
            ..setAttribute("download", name)
            ..click();
        }
      } else {
        // --- MOBILE FLOW ---
        // We use url_launcher to open the file in the system browser/viewer.
        // This avoids path_provider errors and permission issues.
        if (await canLaunchUrl(url)) {
          await launchUrl(
            url,
            mode: LaunchMode.externalApplication, // Opens in Chrome/Safari
          );
        } else {
          throw 'Could not launch browser for $urlString';
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action failed: $e')),
        );
      }
    }
  }

  void _showUploadSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _UploadDocumentSheet(
        employeeId: widget.employeeId,
        onSuccess: _loadDocuments,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Light grey
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Documents',
          style: TextStyle(
              color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF6366F1)), // Indigo
            onPressed: _showUploadSheet,
          )
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- SUMMARY STATS ---
                  Row(
                    children: [
                      _buildStatCard(
                        icon: Icons.description_outlined,
                        color: Colors.blue,
                        count: _documents.length,
                        label: 'Total',
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        icon: Icons.verified_outlined,
                        color: Colors.green,
                        count: _verifiedCount,
                        label: 'Verified',
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        icon: Icons.pending_outlined,
                        color: Colors.orange,
                        count: _pendingCount,
                        label: 'Pending',
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // --- DOCUMENTS LIST ---
                  const Text(
                    "Employee Documents",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 12),

                  if (_documents.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(Icons.upload_file,
                                size: 48, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text("No documents uploaded",
                                style: TextStyle(color: Colors.grey[500])),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _showUploadSheet,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text("Upload First"),
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF6366F1)),
                            )
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _documents.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildDocumentCard(_documents[index]);
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(
      {required IconData icon,
      required Color color,
      required int count,
      required String label}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(count.toString(),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard(EmployeeDocument doc) {
    // Icon based on type
    IconData fileIcon = Icons.insert_drive_file;
    Color iconColor = Colors.grey;
    if (doc.type.contains('pdf')) {
      fileIcon = Icons.picture_as_pdf;
      iconColor = Colors.red;
    } else if (doc.type.contains('image')) {
      fileIcon = Icons.image;
      iconColor = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(fileIcon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(doc.category,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(doc.size,
                            style: const TextStyle(
                                fontSize: 10, color: Colors.grey)),
                        const SizedBox(width: 4),
                        const Text("•",
                            style: TextStyle(fontSize: 10, color: Colors.grey)),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd MMM yyyy').format(doc.uploadedOn),
                          style:
                              const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: doc.verified
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  doc.verified ? 'Verified' : 'Pending',
                  style: TextStyle(
                      color: doc.verified ? Colors.green : Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _downloadAndOpen(doc.filePath, doc.name,
                      isView: true), // View mode
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.visibility_outlined,
                            size: 16, color: Colors.grey),
                        SizedBox(width: 6),
                        Text("View",
                            style:
                                TextStyle(fontSize: 13, color: Colors.black87)),
                      ],
                    ),
                  ),
                ),
              ),
              Container(width: 1, height: 24, color: Colors.grey[200]),
              Expanded(
                child: InkWell(
                  onTap: () => _downloadAndOpen(doc.filePath, doc.name,
                      isView: false), // Download mode
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.download_outlined,
                            size: 16, color: Colors.grey),
                        SizedBox(width: 6),
                        Text("Download",
                            style:
                                TextStyle(fontSize: 13, color: Colors.black87)),
                      ],
                    ),
                  ),
                ),
              ),
              Container(width: 1, height: 24, color: Colors.grey[200]),
              Expanded(
                child: InkWell(
                  onTap: () => _deleteDocument(doc.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.delete_outline, size: 16, color: Colors.red),
                        SizedBox(width: 6),
                        Text("Delete",
                            style: TextStyle(fontSize: 13, color: Colors.red)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

// --- UPLOAD SHEET ---

class _UploadDocumentSheet extends StatefulWidget {
  final String employeeId;
  final VoidCallback onSuccess;

  const _UploadDocumentSheet(
      {Key? key, required this.employeeId, required this.onSuccess})
      : super(key: key);

  @override
  State<_UploadDocumentSheet> createState() => _UploadDocumentSheetState();
}

class _UploadDocumentSheetState extends State<_UploadDocumentSheet> {
  final EmployeeDocumentApiService _apiService = EmployeeDocumentApiService();
  final _nameController = TextEditingController();

  bool _isUploading = false;
  File? _selectedFile;
  PlatformFile? _pickedFile;
  String _selectedCategory = 'Other';

  final List<String> _categories = [
    "Identity Proof",
    "Address Proof",
    "Education",
    "Experience",
    "Photo",
    "Bank Details",
    "Other"
  ];

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      withData: true, // REQUIRED for Web to get bytes
      allowedExtensions: ['jpg', 'pdf', 'png', 'jpeg'],
    );

    if (result != null) {
      setState(() {
        _pickedFile = result.files.first; // Store the PlatformFile object

        if (_nameController.text.isEmpty) {
          _nameController.text = _pickedFile!.name;
        }
      });
    }
  }

  Future<void> _upload() async {
    if (_pickedFile == null) return;
    if (_nameController.text.isEmpty) return;

    setState(() => _isUploading = true);

    try {
      // Use kIsWeb to decide what to send to the service
      await _apiService.uploadDocument(
        employeeId: widget.employeeId,
        fileBytes: kIsWeb ? _pickedFile!.bytes : null,
        filePath: kIsWeb ? null : _pickedFile!.path,
        name: _nameController.text,
        category: _selectedCategory,
      );

      widget.onSuccess();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Upload Document",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Document Name',
              hintText: 'e.g. Aadhar Card',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            items: _categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (val) => setState(() => _selectedCategory = val!),
          ),
          const SizedBox(height: 16),

          InkWell(
            onTap: _pickFile,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                border: Border.all(
                    color: Colors.grey.shade300,
                    style: BorderStyle
                        .solid), // Dashed border needs custom painter, using solid for now
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload_outlined,
                      size: 32, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    _pickedFile != null
                        ? _pickedFile!
                            .name // Changed from _selectedFile!.path...
                        : "Click to select file",
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  if (_pickedFile == null)
                    const Text("PDF, JPG, PNG up to 10MB",
                        style: TextStyle(color: Colors.grey, fontSize: 10)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: (_isUploading || _pickedFile == null)
                  ? null
                  : _upload, // Use _pickedFile
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: _isUploading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text("Upload",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20), // Bottom padding
        ],
      ),
    );
  }
}
