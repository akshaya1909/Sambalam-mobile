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
import '../../../api/notes_api_service.dart';

class MyNotesScreen extends StatefulWidget {
  const MyNotesScreen({Key? key}) : super(key: key);

  @override
  State<MyNotesScreen> createState() => _MyNotesScreenState();
}

class _MyNotesScreenState extends State<MyNotesScreen> {
  String? _companyId;
  String? _userId;
  String? _userName;
  final NotesApiService _notesApi = NotesApiService();
  final TextEditingController _noteController = TextEditingController();
  List<dynamic> _dynamicNotes = [];
  bool _isNotesLoading = true;

  // Exact same Theme Colors as StaffDetailScreen
  final Color primaryDeepTeal = const Color(0xFF206C5E);
  final Color secondaryTeal = const Color(0xFF2BA98A);
  final Color scaffoldBg = const Color(0xFFF4F6FB);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _companyId = prefs.getString('companyId');
      _userId = prefs.getString('userId'); // Your stored User/Employee ID
      _userName = prefs.getString('userName') ?? "User";
    });
    if (_userId != null) {
      _fetchMyNotes();
    }
  }

  Future<void> _fetchMyNotes() async {
    try {
      final notes = await _notesApi.fetchNotes(_userId!);
      if (!mounted) return;
      setState(() {
        _dynamicNotes = notes;
        _isNotesLoading = false;
      });
    } catch (e) {
      debugPrint("Notes Error: $e");
      if (mounted) setState(() => _isNotesLoading = false);
    }
  }

  void _handleSend() async {
    final text = _noteController.text.trim();
    if (text.isEmpty || _companyId == null || _userId == null) return;

    try {
      await _notesApi.sendNote(
        employeeId: _userId!,
        companyId: _companyId!,
        senderId: _userId!,
        senderName: _userName!,
        senderType: "user", // Changed to user as the employee is sending it
        text: text,
      );

      if (!mounted) return;
      _noteController.clear();
      _fetchMyNotes();
    } catch (e) {
      debugPrint("Send Error: $e");
    }
  }

  // --- Same File Logic as StaffDetail ---

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc'],
      );
      if (result != null) {
        PlatformFile file = result.files.first;
        const int maxBytes = 5 * 1024 * 1024;
        if (file.size > maxBytes) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Max size is 5MB")));
          return;
        }
        _showUploadConfirmDialog(file);
      }
    } catch (e) {
      debugPrint("Pick Error: $e");
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
              onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
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
    try {
      await _notesApi.sendNote(
        employeeId: _userId!,
        companyId: _companyId!,
        senderId: _userId!,
        senderName: _userName!,
        senderType: "user",
        text: "Sent an attachment",
        file: file,
      );
      _fetchMyNotes();
    } catch (e) {
      debugPrint("Upload Error: $e");
    }
  }

  Future<void> _downloadFile(String url, String fileName, bool isImage) async {
    if (kIsWeb) {
      html.AnchorElement(href: url)
        ..setAttribute("download", fileName)
        ..click();
      return;
    }
    try {
      if (Platform.isAndroid || Platform.isIOS)
        await Permission.storage.request();
      final dio = Dio();
      final tempDir = await getTemporaryDirectory();
      final savePath = "${tempDir.path}/$fileName";
      await dio.download(url, savePath);
      if (isImage) {
        await Gal.putImage(savePath);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Saved to Gallery")));
      } else {
        await OpenFile.open(savePath);
      }
    } catch (e) {
      debugPrint("Download Error: $e");
    }
  }

  // --- Same Widget Helpers as StaffDetail ---

  Widget _buildChatBubble(Map<String, dynamic> note) {
    final bool isMe = note['senderId'] == _userId; // If sender is this user
    final String? fileUrl = note['fileUrl'];
    final bool hasFile = fileUrl != null && fileUrl.toString().isNotEmpty;
    final bool isImage = hasFile &&
        (fileUrl!.toLowerCase().endsWith('.jpg') ||
            fileUrl.toLowerCase().endsWith('.jpeg') ||
            fileUrl.toLowerCase().endsWith('.png'));
    final String fullUrl = 'http://10.80.210.30:5000$fileUrl';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
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
            if (hasFile) ...[
              Stack(
                children: [
                  GestureDetector(
                    onTap: () => _downloadFile(
                        fullUrl, fileUrl!.split('/').last, isImage),
                    child: isImage
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(fullUrl,
                                width: 200, fit: BoxFit.cover))
                        : Container(
                            padding: const EdgeInsets.all(12),
                            width: 200,
                            decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8)),
                            child: Row(children: [
                              Icon(Icons.insert_drive_file,
                                  color: primaryDeepTeal, size: 30),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Text(fileUrl!.split('-').last,
                                      style: const TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis))
                            ]),
                          ),
                  ),
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
                              onPressed: () => _downloadFile(fullUrl,
                                  fileUrl!.split('/').last, isImage)))),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (note['text'] != null && note['text'].isNotEmpty)
              Text(note['text'] ?? "",
                  style: const TextStyle(fontSize: 15, color: Colors.black87)),
            const SizedBox(height: 4),
            Text(
                DateFormat('hh:mm a')
                    .format(DateTime.parse(note['createdAt']).toLocal()),
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text("My Notes",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [primaryDeepTeal, secondaryTeal],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight)),
        ),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isNotesLoading
                ? const Center(child: CircularProgressIndicator())
                : _dynamicNotes.isEmpty
                    ? Center(
                        child: Text("No history for this month",
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 13)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _dynamicNotes.length,
                        itemBuilder: (context, index) =>
                            _buildChatBubble(_dynamicNotes[index]),
                      ),
          ),
          // Input Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2))
            ]),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                      icon:
                          Icon(Icons.camera_alt_outlined, color: secondaryTeal),
                      onPressed: _pickFile),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                          color: scaffoldBg,
                          borderRadius: BorderRadius.circular(24)),
                      child: TextField(
                        controller: _noteController,
                        decoration: const InputDecoration(
                            hintText: "Save a note...",
                            hintStyle:
                                TextStyle(fontSize: 14, color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: primaryDeepTeal,
                    child: IconButton(
                        icon: const Icon(Icons.send,
                            color: Colors.white, size: 18),
                        onPressed: _handleSend),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
