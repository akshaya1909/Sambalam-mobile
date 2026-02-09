import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:io';
import 'package:gal/gal.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/staff_model.dart';
import '../../../api/notes_api_service.dart';
import '../screens/attendance/attendance_screen.dart';
import '../screens/admin/edit_staff_screen.dart';
import '../screens/admin/salary_screen.dart';

class StaffDetailScreen extends StatefulWidget {
  final Staff staff;

  const StaffDetailScreen({Key? key, required this.staff}) : super(key: key);

  @override
  State<StaffDetailScreen> createState() => _StaffDetailScreenState();
}

class _StaffDetailScreenState extends State<StaffDetailScreen> {
  String? _companyId;
  final NotesApiService _notesApi = NotesApiService();
  final TextEditingController _noteController = TextEditingController();
  List<dynamic> _dynamicNotes = [];
  bool _isNotesLoading = true;

  // Theme Colors matching Admin Home Screen
  final Color primaryDeepTeal = const Color(0xFF206C5E);
  final Color secondaryTeal = const Color(0xFF2BA98A);
  final Color scaffoldBg = const Color(0xFFF4F6FB);

  @override
  void initState() {
    super.initState();
    _loadCompanyId();
    _fetchEmployeeNotes(); // Initial load
  }

  Future<void> _loadCompanyId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _companyId = prefs.getString('companyId');
    });
  }

  Future<void> _fetchEmployeeNotes() async {
    try {
      final notes = await _notesApi.fetchNotes(widget.staff.id);
      // 3. Prevent calling setState if user navigated away
      if (!mounted) return;
      setState(() {
        _dynamicNotes = notes;
        _isNotesLoading = false;
      });
    } catch (e) {
      debugPrint("Notes Error: $e");
      if (mounted) {
        setState(() => _isNotesLoading = false);
      }
    }
  }

  void _handleSend() async {
    final text = _noteController.text.trim();
    if (text.isEmpty || _companyId == null) return;

    try {
      await _notesApi.sendNote(
        employeeId: widget.staff.id,
        companyId: _companyId!, // From your loaded state
        senderId: _companyId!, // In a real app, use the logged-in Admin's ID
        senderName: "Admin",
        senderType: "admin", // Must match one of your enum values in Mongoose
        text: text,
      );

      if (!mounted) return;
      _noteController.clear();
      _fetchEmployeeNotes(); // Refresh list immediately
    } catch (e) {
      debugPrint("Send Error: $e");
    }
  }

  Future<void> _pickFile() async {
    try {
      // 1. Pick the file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc'],
      );

      if (result != null) {
        PlatformFile file = result.files.first;

        // 2. Validate Size (5MB limit)
        const int maxBytes = 5 * 1024 * 1024;
        if (file.size > maxBytes) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("File too large. Maximum size is 5MB")),
          );
          return;
        }

        // 3. Confirm Upload Dialog
        _showUploadConfirmDialog(file);
      }
    } catch (e) {
      debugPrint("File Picking Error: $e");
    }
  }

  void _showUploadConfirmDialog(PlatformFile file) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Upload Attachment?"),
        content: Text(
            "File: ${file.name}\nSize: ${(file.size / 1024).toStringAsFixed(1)} KB"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _uploadFile(file);
            },
            child: const Text("UPLOAD"),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadFile(PlatformFile file) async {
    if (_companyId == null) return;

    try {
      await _notesApi.sendNote(
        employeeId: widget.staff.id,
        companyId: _companyId!,
        senderId: _companyId!,
        senderName: "Admin",
        senderType: "admin",
        text: "Sent an attachment", // Optional caption
        file: file, // Passing the actual file object
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("File uploaded successfully")),
      );
      _fetchEmployeeNotes(); // Refresh to see the new bubble
    } catch (e) {
      debugPrint("Upload Error: $e");
    }
  }

  Future<void> _downloadFile(String url, String fileName, bool isImage) async {
    if (kIsWeb) {
      // ignore: undefined_prefixed_name
      html.AnchorElement(href: url)
        ..setAttribute("download", fileName)
        ..click();
      return;
    }
    try {
      // 1. Request Permissions
      if (Platform.isAndroid || Platform.isIOS) {
        var status = await Permission.storage.request();
        // For Android 13+, storage permission might return isDenied even if fine
        // gal handles its own internal permissions usually, but this is a good safety.
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Downloading...")),
      );

      // 2. Setup Dio and get paths
      final dio = Dio();
      final tempDir = await getTemporaryDirectory();
      final savePath = "${tempDir.path}/$fileName";

      // 3. Perform Download
      await dio.download(url, savePath);

      if (isImage) {
        // 4a. Save Image to Gallery
        // Gal.putImage returns Future<void>. If it fails, it throws an error.
        await Gal.putImage(savePath);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Image saved to Gallery")),
        );
      } else {
        // 4b. For PDFs/Docs, open it
        await OpenFile.open(savePath);
      }
    } catch (e) {
      debugPrint("Download Error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Error: ${e.toString().contains('Access denied') ? 'Permission denied' : e}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial =
        widget.staff.name.isNotEmpty ? widget.staff.name[0].toUpperCase() : 'A';

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          elevation: 0,
          titleSpacing: 0,
          // Gradient Background logic matching Admin Home Screen
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryDeepTeal, secondaryTeal],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white.withOpacity(0.3),
                child: Text(initial,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.staff.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            // Pill-shaped professional EDIT button
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 12), // Aligns vertically
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EditStaffScreen(staff: widget.staff),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.15),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Colors.white38),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text(
                  "EDIT",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            // Menu Button
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              padding: EdgeInsets.zero,
              itemBuilder: (context) => [
                const PopupMenuItem(
                    value: 'delete', child: Text("Delete Staff")),
                const PopupMenuItem(
                    value: 'branch', child: Text("Change Branch")),
              ],
            ),
            const SizedBox(width: 4), // Small end padding
          ],
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 4,
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.bold, letterSpacing: 0.5),
            tabs: const [
              Tab(text: "ATTENDANCE"),
              Tab(text: "SALARY"),
              Tab(text: "NOTES"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Attendance
            _companyId == null
                ? const Center(child: CircularProgressIndicator())
                : AttendanceScreen(
                    phoneNumber: widget.staff.phone,
                    companyId: _companyId!,
                  ),
            // Tab 2: Salary
            SalaryScreen(
              employeeId: widget.staff.id ?? "",
              phoneNumber: widget.staff.phone,
              companyId: _companyId!,
              staffName: widget.staff.name,
            ),
            // Tab 3: Notes
            _buildNotesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesTab() {
    return Column(
      children: [
        Expanded(
          child: _isNotesLoading
              ? const Center(child: CircularProgressIndicator())
              : _dynamicNotes.isEmpty
                  ? Center(
                      child: Text(
                        "No history for this month",
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _dynamicNotes.length,
                      itemBuilder: (context, index) {
                        final note = _dynamicNotes[index];
                        // Show your existing chat bubble style here
                        return _buildChatBubble(note);
                      },
                    ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.camera_alt_outlined, color: secondaryTeal),
                  onPressed: _pickFile,
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: scaffoldBg,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _noteController, // Controller attached
                      decoration: const InputDecoration(
                        hintText: "Save a note...",
                        hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: primaryDeepTeal,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: _handleSend, // Dynamic send function
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> note) {
    final bool isMe = note['senderName'] == "Admin";
    final String? fileUrl = note['fileUrl'];
    final bool hasFile = fileUrl != null && fileUrl.toString().isNotEmpty;

    // Determine if it's an image based on extension
    final bool isImage = hasFile &&
        (fileUrl!.toLowerCase().endsWith('.jpg') ||
            fileUrl.toLowerCase().endsWith('.jpeg') ||
            fileUrl.toLowerCase().endsWith('.png'));

    final String fullUrl = 'http://10.80.210.30:5000$fileUrl';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        // Constrain bubble width to 75% of the screen
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? primaryDeepTeal.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isMe ? 12 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 12),
          ),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- FILE / IMAGE SECTION ---
            if (hasFile) ...[
              Stack(
                children: [
                  GestureDetector(
                    onTap: () => _downloadFile(
                        fullUrl, fileUrl!.split('/').last, isImage),
                    child: isImage
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              fullUrl,
                              width: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                width: 200,
                                height: 100,
                                color: Colors.grey[200],
                                child: const Icon(Icons.broken_image,
                                    color: Colors.grey),
                              ),
                            ),
                          )
                        : Container(
                            // DESIGN FOR PDF / DOCS
                            padding: const EdgeInsets.all(12),
                            width: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.insert_drive_file,
                                    color: primaryDeepTeal, size: 30),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    fileUrl!
                                        .split('-')
                                        .last, // Show filename after the timestamp
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                  // DOWNLOAD BUTTON OVERLAY
                  Positioned(
                    right: 4,
                    top: 4,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.black45,
                      child: IconButton(
                        icon: const Icon(Icons.download,
                            size: 14, color: Colors.white),
                        padding: EdgeInsets.zero,
                        onPressed: () => _downloadFile(
                            fullUrl, fileUrl!.split('/').last, isImage),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // --- TEXT MESSAGE SECTION ---
            if (note['text'] != null && note['text'].toString().isNotEmpty)
              Text(
                note['text'] ?? "",
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),

            const SizedBox(height: 4),

            // --- TIMESTAMP SECTION ---
            Text(
              DateFormat('hh:mm a')
                  .format(DateTime.parse(note['createdAt']).toLocal()),
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
