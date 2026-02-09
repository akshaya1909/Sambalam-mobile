// lib/ui/leaves/request_leave_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../api/leave_api_service.dart';

class RequestLeaveScreen extends StatefulWidget {
  final List<dynamic> leaveBalances;
  const RequestLeaveScreen({
    Key? key,
    required this.leaveBalances,
  }) : super(key: key);

  @override
  State<RequestLeaveScreen> createState() => _RequestLeaveScreenState();
}

class _RequestLeaveScreenState extends State<RequestLeaveScreen> {
  final LeaveApiService _leaveApi = LeaveApiService();
  final Color _primaryStart = const Color(0xFF206C5E);
  final Color _primaryEnd = const Color(0xFF2BA98A);

  late DateTime _fromDate;
  late DateTime _toDate;

  bool _isHalfDay = false;
  dynamic _selectedBalance;
  late List<String> _leaveTypes;
  late String _selectedLeaveType;
  final TextEditingController _reasonController = TextEditingController();
  ImagePicker get _mobilePicker => ImagePicker();
  XFile? _pickedImage;
  PlatformFile? _pickedFile; // for web / docs
  bool _submitting = false;
  String? _employeeId;
  String? _companyId;

  @override
  void initState() {
    super.initState();

    final today = DateTime.now();
    _fromDate = DateTime(today.year, today.month, today.day);
    _toDate = DateTime(today.year, today.month, today.day);

    if (widget.leaveBalances.isNotEmpty) {
      _selectedBalance = widget.leaveBalances.first;
    }
    _loadEmployeeData();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployeeData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _employeeId = prefs.getString('employeeId');
        _companyId = prefs.getString('companyId'); // ← get companyId too
      });
    }
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? _fromDate : _toDate;
    final result = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: _primaryStart),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (result != null) {
      setState(() {
        if (isFrom) {
          _fromDate = result;
          if (_isHalfDay || _toDate.isBefore(_fromDate)) _toDate = _fromDate;
        } else {
          _toDate = result;
        }
      });
    }
  }

  void _showUploadDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Upload Document'),
              onTap: () {
                Navigator.pop(ctx);
                _pickDocument();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    if (kIsWeb) {
      // web -> file explorer
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.image,
      );
      if (result != null) {
        setState(() {
          _pickedFile = result.files.single;
          _pickedImage = null;
        });
      }
    } else {
      final xfile = await _mobilePicker.pickImage(source: ImageSource.gallery);
      if (xfile != null) {
        setState(() {
          _pickedImage = xfile;
          _pickedFile = null;
        });
      }
    }
  }

  Future<void> _pickFromCamera() async {
    if (kIsWeb) {
      // web has no native camera picker -> just open file explorer
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.image,
      );
      if (result != null) {
        setState(() {
          _pickedFile = result.files.single;
          _pickedImage = null;
        });
      }
    } else {
      final xfile = await _mobilePicker.pickImage(source: ImageSource.camera);
      if (xfile != null) {
        setState(() {
          _pickedImage = xfile;
          _pickedFile = null;
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final xfile = await _mobilePicker.pickImage(source: source);
    if (xfile != null)
      setState(() {
        _pickedImage = xfile;
        _pickedFile = null;
      });
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null)
      setState(() {
        _pickedFile = result.files.single;
        _pickedImage = null;
      });
  }

  void _ensureValidRange() {
    if (_isHalfDay) return; // half‑day always same date

    if (_fromDate.isAfter(_toDate)) {
      // show error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('From date should not be greater than To date'),
        ),
      );

      // set toDate = fromDate + 1 day
      _toDate = _fromDate.add(const Duration(days: 1));
    }
  }

  String _formatDate(DateTime date) {
    // 3 Dec 2025 style
    final day = date.day;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[date.month - 1];
    final year = date.year;
    return '$day $month $year';
  }

  String _mapLabelToType(String label) {
    if (label.startsWith('Casual')) return 'Casual';
    if (label.startsWith('Privileged')) return 'Privileged';
    if (label.startsWith('Sick')) return 'Sick';
    return 'Unpaid';
  }

  Future<void> _requestLeave() async {
    if (_submitting ||
        _employeeId == null ||
        _companyId == null ||
        _selectedBalance == null) return;

    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please provide a reason')));
      return;
    }

    setState(() => _submitting = true);

    try {
      // Extract the leaveTypeId (ObjectId string) from the selected balance object
      final String leaveTypeId =
          _selectedBalance['leaveTypeId']['_id'].toString();

      await _leaveApi.createLeaveRequest(
        employeeId: _employeeId!,
        companyId: _companyId!,
        fromDate: _fromDate,
        toDate: _toDate,
        isHalfDay: _isHalfDay,
        leaveTypeId: leaveTypeId, // Use the real ID from DB
        reason: _reasonController.text.trim(),
        file: kIsWeb ? _pickedFile : (_pickedImage ?? _pickedFile),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Leave request submitted'),
            backgroundColor: Colors.green),
      );
      Navigator.of(context)
          .pop(true); // Return true to refresh history on previous screen
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF232B2F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Request Leave',
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Selection Row
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'From date *',
                    value: _formatDate(_fromDate),
                    onTap: () => _pickDate(isFrom: true),
                    activeColor: _primaryStart,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateField(
                    label: 'To date *',
                    value: _formatDate(_toDate),
                    onTap: _isHalfDay ? null : () => _pickDate(isFrom: false),
                    activeColor: _primaryStart,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Half Day Checkbox with Primary Color
            Theme(
              data: ThemeData(unselectedWidgetColor: Colors.grey[400]),
              child: CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Request leave for half day',
                    style: TextStyle(fontSize: 14)),
                value: _isHalfDay,
                activeColor: _primaryStart,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (v) {
                  setState(() {
                    _isHalfDay = v ?? false;
                    if (_isHalfDay) _toDate = _fromDate;
                  });
                },
              ),
            ),

            const SizedBox(height: 16),
            _fieldLabel('Leave Type *'),
            const SizedBox(height: 8),
            _buildDynamicDropdown(),

            const SizedBox(height: 20),
            _fieldLabel('Reason of leave'),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Why are you taking leave?",
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _primaryStart, width: 2),
                ),
              ),
            ),

            const SizedBox(height: 24),
            _fieldLabel('Supporting Document (Optional)'),
            const SizedBox(height: 12),
            _buildUploadPlaceholder(),
            const SizedBox(height: 40),
          ],
        ),
      ),
      // --- THE GRADIENT BUTTON SECTION ---
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
    );
  }

  Widget _buildDynamicDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<dynamic>(
          isExpanded: true,
          value: _selectedBalance,
          items: widget.leaveBalances.map((bal) {
            String name = bal['leaveTypeId']?['name'] ?? 'Leave';
            double balance = (bal['current'] as num? ?? 0).toDouble();
            String displayBal = balance % 1 == 0
                ? balance.toInt().toString()
                : balance.toString();

            return DropdownMenuItem<dynamic>(
              value: bal,
              child: Text("$name (Balance: $displayBal days)",
                  style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedBalance = val),
        ),
      ),
    );
  }

  Widget _buildUploadPlaceholder() {
    return GestureDetector(
      onTap: _showUploadDialog,
      child: Container(
        width: double.infinity,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_upload_outlined, color: _primaryStart, size: 32),
            const SizedBox(height: 8),
            Text(
                _pickedFile != null || _pickedImage != null
                    ? "File selected"
                    : "Tap to upload image or document",
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // GRADIENT BUTTON IMPLEMENTATION
  Widget _buildBottomButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [_primaryStart, _primaryEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _primaryStart.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed:
                _submitting || _employeeId == null ? null : _requestLeave,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text(
                    'Submit Request',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;
  final Color activeColor;

  const _DateField({
    Key? key,
    required this.label,
    required this.value,
    required this.onTap,
    required this.activeColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: enabled ? onTap! : null,
          child: Container(
            height: 52,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: enabled ? Colors.white : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    enabled ? activeColor.withOpacity(0.5) : Colors.grey[200]!,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 16, color: enabled ? activeColor : Colors.grey),
                const SizedBox(width: 10),
                Text(value,
                    style: TextStyle(
                        fontSize: 14,
                        color: enabled ? Colors.black87 : Colors.grey)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
