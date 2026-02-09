import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sambalam/api/attendance_api_service.dart';
import '../../api/attendance_admin_api_service.dart';
import '../../api/shift_api_service.dart';
import '../../api/leave_type_api_service.dart';
import '../../models/leave_type_model.dart';
import '../../models/shift_model.dart';

class EditAttendanceScreen extends StatefulWidget {
  final String employeeName;
  final DateTime date;
  final Map<String, dynamic> record;

  final String employeeId;
  final String companyId;
  final bool isAdmin;

  const EditAttendanceScreen({
    Key? key,
    required this.employeeName,
    required this.date,
    required this.record,
    required this.employeeId,
    required this.companyId,
    required this.isAdmin,
  }) : super(key: key);

  @override
  State<EditAttendanceScreen> createState() => _EditAttendanceScreenState();
}

class _EditAttendanceScreenState extends State<EditAttendanceScreen> {
  static const String _baseUrl = 'https://sambalam.ifoxclicks.com';

  final AttendanceAdminApiService _adminApi = AttendanceAdminApiService();
  final AttendanceApiService _apiAttendance = AttendanceApiService();
  final ShiftApiService _shiftApi = ShiftApiService();
  final LeaveTypeApiService _leaveApi = LeaveTypeApiService();
  late TextEditingController _notesController;
  bool _hasText = false;
  bool _didChange = false;

  String? _statusOverride;
  bool _saving = false;
  List<Shift> _dynamicShifts = []; // Add this to store fetched shifts
  bool _isLoadingShifts = false;
  List<LeaveType> _companyLeaveTypes = [];
  bool _isLoadingLeaves = false;
  String? _leaveIdOverride;

  // final _shifts = <String>[
  //   '09:30 AM - 06:30 PM',
  //   '10:00 AM - 07:00 PM',
  //   '10:00 AM - 06:30 PM',
  //   'Tele Calling | 10:00 AM - 06:00 PM',
  //   'No Shift',
  // ];

  DateTime? _parseServerTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final s = value as String;

    if (RegExp(r'^\d{1,2}:\d{2} ').hasMatch(s)) {
      final t = DateFormat('hh:mm a').parse(s);
      final d = widget.date;
      return DateTime(d.year, d.month, d.day, t.hour, t.minute);
    }

    return DateTime.parse(s).toLocal();
  }

  String _employeeInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  String get _dateLabel =>
      DateFormat("d'${_daySuffix(widget.date.day)}' MMMM yyyy")
          .format(widget.date);

  static String _daySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDynamicShifts();
    _loadCompanyLeaves();
    _notesController = TextEditingController(
      text: (widget.record['remarks'] as String?) ?? '',
    );
    _hasText = _notesController.text.trim().isNotEmpty;
    _notesController.addListener(() {
      final hasTextNow = _notesController.text.trim().isNotEmpty;
      if (hasTextNow != _hasText) {
        setState(() => _hasText = hasTextNow);
      }
    });
  }

  Future<void> _loadDynamicShifts() async {
    setState(() => _isLoadingShifts = true);
    try {
      final shifts = await _shiftApi.getCompanyShifts(widget.companyId);
      setState(() {
        _dynamicShifts = shifts;
        _isLoadingShifts = false;
      });
    } catch (e) {
      debugPrint("Error loading shifts: $e");
      setState(() => _isLoadingShifts = false);
    }
  }

  Future<void> _loadCompanyLeaves() async {
    setState(() => _isLoadingLeaves = true);
    try {
      final leaves = await _leaveApi.getLeaveTypes(widget.companyId);
      setState(() {
        _companyLeaveTypes = leaves;
        _isLoadingLeaves = false;
      });
    } catch (e) {
      debugPrint("Error loading leaves: $e");
      setState(() => _isLoadingLeaves = false);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveNotes() async {
    if (!_hasText) return;
    setState(() => _saving = true);
    try {
      await _apiAttendance.updateRemarks(
        employeeId: widget.employeeId,
        companyId: widget.companyId,
        date: widget.date,
        remarks: _notesController.text.trim(),
      );
      _didChange = true;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Remarks updated')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ---------------- Punch-in / punch-out bottom sheets ----------------

  void _openAddPunchInSheet(BuildContext context) {
    final timeController = TextEditingController(
      text: DateFormat('hh:mm a').format(DateTime.now()),
    );
    Shift? selectedShiftObject;
    TimeOfDay? pickedTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Add in time',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Shift',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final Shift? chosen =
                          await _openSelectShiftSheet(ctx, selectedShiftObject);
                      if (chosen != null) {
                        setModalState(() {
                          selectedShiftObject = chosen;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        selectedShiftObject?.name ?? 'Select shift',
                        style: TextStyle(
                          fontSize: 15,
                          color: selectedShiftObject == null
                              ? Colors.grey
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'In time',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: timeController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    onTap: () async {
                      final now = DateTime.now();
                      final initial = pickedTime ?? TimeOfDay.fromDateTime(now);
                      final picked = await showTimePicker(
                        context: ctx,
                        initialTime: initial,
                      );
                      if (picked != null) {
                        pickedTime = picked;
                        final dt = DateTime(
                          now.year,
                          now.month,
                          now.day,
                          picked.hour,
                          picked.minute,
                        );
                        timeController.text = DateFormat('hh:mm a').format(dt);
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (pickedTime == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Please select time')),
                              );
                              return;
                            }
                            try {
                              await _adminApi.adminPunchIn(
                                employeeId: widget.employeeId,
                                companyId: widget.companyId,
                                date: widget.date,
                                time: pickedTime!,
                              );
                              if (!mounted) return;
                              Navigator.of(ctx).pop();
                              Navigator.of(context).pop(true);
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to punch in: $e'),
                                ),
                              );
                            }
                          },
                          child: const Text('Save in time'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openAddPunchOutSheet(BuildContext context) {
    final timeController = TextEditingController(
      text: DateFormat('hh:mm a').format(DateTime.now()),
    );
    TimeOfDay? pickedTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Add out time',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Out time',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: timeController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    onTap: () async {
                      final now = DateTime.now();
                      final initial = pickedTime ?? TimeOfDay.fromDateTime(now);
                      final picked = await showTimePicker(
                        context: ctx,
                        initialTime: initial,
                      );
                      if (picked != null) {
                        pickedTime = picked;
                        final dt = DateTime(
                          now.year,
                          now.month,
                          now.day,
                          picked.hour,
                          picked.minute,
                        );
                        timeController.text = DateFormat('hh:mm a').format(dt);
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (pickedTime == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Please select time')),
                              );
                              return;
                            }
                            try {
                              await _adminApi.adminPunchOut(
                                employeeId: widget.employeeId,
                                companyId: widget.companyId,
                                date: widget.date,
                                time: pickedTime!,
                              );
                              if (!mounted) return;
                              Navigator.of(ctx).pop();
                              Navigator.of(context).pop(true);
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to punch out: $e'),
                                ),
                              );
                            }
                          },
                          child: const Text('Save out time'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<Shift?> _openSelectShiftSheet(
      BuildContext context, Shift? current) async {
    return showModalBottomSheet<Shift>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        Shift? selected = current;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text('Select shift',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  if (_isLoadingShifts)
                    const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    )
                  else if (_dynamicShifts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text("No shifts found for this company"),
                    )
                  else
                    ..._dynamicShifts.map((s) {
                      final isSelected = selected?.id == s.id;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(s.name,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            )),
                        subtitle: Text("${s.startTime} - ${s.endTime}"),
                        trailing: isSelected
                            ? const Icon(Icons.check, color: Colors.green)
                            : null,
                        onTap: () => setModalState(() => selected = s),
                      );
                    }).toList(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(selected),
                      child: const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ---------------- Status helpers ----------------

  String _currentStatusLabel() {
    final String? fromRecord = widget.record['status'] as String?;
    final punchIn = widget.record['punchIn'] as Map<String, dynamic>?;

    final String? leaveId = widget.record['leaveType'] as String?;
    final value = (_statusOverride ?? fromRecord ?? 'Absent')
        .toLowerCase()
        .replaceAll('_', ' ')
        .trim();

    if (punchIn == null || punchIn['time'] == null) {
      if (value == 'absent') return 'Absent';
      if (value == 'week off' || value == 'sunday') return 'Week off';
      if (value == 'holiday') return 'Holiday';
      if (value == 'unpaid leave') return 'Unpaid Leave';

      // If the live status "no punch in" is passed, force it to show "Absent"
      // because that is the actual DB state you want to display here.
      if (value == 'no punch in') return 'Absent';
    }

    String label = "";
    switch (value) {
      case 'paid_leave':
      case 'paid leave':
        label = 'Paid Leave';
        break;
      case 'half_day_leave':
      case 'half day leave':
        label = 'Half Day Leave';
        break;
      case 'unpaid_leave':
      case 'unpaid leave':
        return 'Unpaid Leave'; // Unpaid usually doesn't have a sub-type ID
      case 'absent':
        return 'Absent';
      case 'half_day':
        return 'Half day';
      case 'week_off':
        return 'Week off';
      case 'holiday':
        return 'Holiday';
      case 'double_present':
      case 'double present':
        return 'Double Present';
      default:
        label = value.isNotEmpty
            ? value[0].toUpperCase() + value.substring(1)
            : 'Absent';
    }

    // If it's a leave type and we have an ID, try to find the specific name
    if ((value.contains('leave')) &&
        leaveId != null &&
        _companyLeaveTypes.isNotEmpty) {
      try {
        final specificLeave =
            _companyLeaveTypes.firstWhere((l) => l.id == leaveId);
        return "$label (${specificLeave.name})";
      } catch (_) {
        return label;
      }
    }

    return label;
  }

  Color _statusColor() {
    final label = _currentStatusLabel();

    // Present & Double Present
    if (label.contains('Present')) {
      return const Color(0xFF2BBE74); // Vibrant Green
    }

    // Absent
    if (label == 'Absent') {
      return const Color(0xFFE53935); // Alert Red
    }

    // Half Day or Half Day Leave
    if (label.contains('Half Day') || label.contains('Half day')) {
      return const Color(0xFFF39C12); // Warning Orange
    }

    // Paid Leave
    if (label.contains('Paid Leave')) {
      return const Color(0xFF9B59B6); // Purple
    }

    // Unpaid Leave
    if (label.contains('Unpaid Leave')) {
      return Colors.blue; // Blue
    }

    // Week off
    if (label.contains('Week off') || label.contains('Week Off')) {
      return const Color(0xFF64748B); // Slate Grey
    }

    // Holiday
    if (label.contains('Holiday')) {
      return const Color(0xFF3F51B5); // Indigo
    }

    // Default color if no match found
    return const Color(0xFF206C5E);
  }

  void _changeStatus(String newStatus, {String? leaveId}) async {
    setState(() {
      _statusOverride = newStatus;
      _leaveIdOverride = leaveId; // Store locally for immediate UI update
    });
    try {
      await _adminApi.updateStatus(
        employeeId: widget.employeeId,
        companyId: widget.companyId,
        date: widget.date,
        status: newStatus,
        leaveId: leaveId,
      );
      _didChange = true;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status updated successfully')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }

  // ---------------- Build ----------------

  @override
  Widget build(BuildContext context) {
    final Color primary = const Color(0xFF206C5E);
    final Color bg = const Color(0xFFF4F6FB);

    final punchIn = widget.record['punchIn'] as Map<String, dynamic>?;
    final punchOut = widget.record['punchOut'] as Map<String, dynamic>?;

    final inTime = _parseServerTime(punchIn?['time']);
    final outTime = _parseServerTime(punchOut?['time']);

    final inAddress = punchIn?['location']?['address'] as String? ?? '';
    final outAddress = punchOut?['location']?['address'] as String? ?? '';

    final inPhoto = punchIn?['punchInPhoto'] as String?;
    final outPhoto = punchOut?['punchOutPhoto'] as String?;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        titleSpacing: 0,
        leading: IconButton(
          // Added explicit black color to the icon for consistency
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(_didChange),
        ),
        title: const Text(
          'Edit attendance',
          style: TextStyle(
            color: Colors.black, // Set font color to black
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          if (widget.isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Chip(
                labelPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                backgroundColor: primary.withOpacity(0.06),
                avatar: const Icon(Icons.shield_outlined,
                    size: 18, color: Color(0xFF206C5E)),
                label: const Text(
                  'Admin',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF206C5E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Employee header
              // Employee header section
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment
                      .start, // Align to top for multi-line support
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: primary.withOpacity(0.12),
                      child: Text(
                        _employeeInitials(widget.employeeName),
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.employeeName,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _dateLabel,
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[600]),
                          ),

                          // ADDED: Logic to show status below name on very long strings or mobile
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusColor().withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _currentStatusLabel(),
                              // ALLOW MULTI-LINE
                              softWrap: true,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _statusColor(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Status selector
              // Status selector
              if (widget.isAdmin)
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Attendance status',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.start,
                          children: [
                            _presentDropdownChip(),
                            _statusChip('Absent', 'absent'),
                            _statusChip('Half day', 'half_day'),
                            _statusChip('Week off', 'week_off'),
                            _statusChip('Holiday', 'holiday'),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Divider(height: 1, thickness: 0.5),
                        ),
                        const Text(
                          'Leaves',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            // 1. PAID LEAVE WITH DROPDOWN
                            _leaveDropdownChip(
                              label: 'PAID LEAVE',
                              value: 'Paid Leave',
                              onSelected: (id) => _changeStatus('paid_leave',
                                  leaveId: id), // or specific leave logic
                              color: const Color(0xFF9B59B6),
                            ),
                            // 2. HALF DAY LEAVE WITH DROPDOWN
                            _leaveDropdownChip(
                              label: 'HALF DAY LEAVE',
                              value: 'Half Day Leave',
                              onSelected: (id) =>
                                  _changeStatus('half_day_leave', leaveId: id),
                              color: const Color(0xFFF39C12),
                            ),
                            // 3. UNPAID LEAVE (NO DROPDOWN)
                            (() {
                              const unpaidColor = Colors.blue;
                              final rawStatus = (_statusOverride ??
                                      (widget.record['status'] as String? ??
                                          ''))
                                  .toLowerCase();
                              final isUnpaidSelected =
                                  rawStatus == 'unpaid_leave' ||
                                      rawStatus == 'unpaid leave';

                              return GestureDetector(
                                onTap: () => _changeStatus(
                                    'unpaid_leave'), // Usually unpaid is marked as absent or specific status
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isUnpaidSelected
                                        ? unpaidColor.withOpacity(0.12)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isUnpaidSelected
                                          ? unpaidColor
                                          : unpaidColor.withOpacity(0.3),
                                      width: isUnpaidSelected ? 1.5 : 1.0,
                                    ),
                                  ),
                                  child: Text(
                                    'UNPAID LEAVE',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isUnpaidSelected
                                            ? unpaidColor
                                            : unpaidColor.withOpacity(0.6)),
                                  ),
                                ),
                              );
                            })(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              if (widget.isAdmin) const SizedBox(height: 16),

              // In / Out cards
              LayoutBuilder(
                builder: (context, constraints) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _punchCard(
                          title: 'In time',
                          time: inTime,
                          address: inAddress,
                          photoPath: inPhoto,
                          icon: Icons.login,
                          color: const Color(0xFF21C48D),
                          emptyLabel: 'Add in', // Shortened label to save space
                          onAdd: widget.isAdmin
                              ? () => _openAddPunchInSheet(context)
                              : null,
                        ),
                      ),
                      const SizedBox(
                          width: 8), // Reduced gap for smaller screens
                      Expanded(
                        child: _punchCard(
                          title: 'Out time',
                          time: outTime,
                          address: outAddress,
                          photoPath: outPhoto,
                          icon: Icons.logout,
                          color: const Color(0xFFE55039),
                          emptyLabel: 'Add out', // Shortened label
                          onAdd: widget.isAdmin
                              ? () => _openAddPunchOutSheet(context)
                              : null,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              // Remarks
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Remarks',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      maxLines: 4,
                      minLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Add a note about this entry',
                        filled: true,
                        fillColor: const Color(0xFFF7F8FC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${_notesController.text.length}/250',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),

      // bottom save bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Discard'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                  ),
                  onPressed: _saving ? null : _saveNotes,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- UI helpers ----------

  Widget _statusChip(String label, String value) {
    // 1. Get the current status from state or record
    final rawStatus =
        (_statusOverride ?? (widget.record['status'] as String? ?? 'Absent'))
            .toString()
            .toLowerCase()
            .trim()
            .replaceAll('_', ' ');
    final normalizedValue = value.toLowerCase().trim().replaceAll('_', ' ');

    // 2. Multi-case selection logic for Week Off
    bool isSelected;

    if (normalizedValue == 'absent') {
      // Highlight if DB says absent OR if it's a "no punch in" state
      isSelected = (rawStatus == 'absent' || rawStatus == 'no punch in');
    } else if (normalizedValue == 'week_off') {
      // Check for all possible "Off" variations in your enum
      isSelected = (rawStatus == 'Week Off' ||
          rawStatus == 'Sunday' ||
          rawStatus == 'week_off');
    } else {
      // For others, do a case-insensitive comparison
      isSelected = rawStatus == normalizedValue;
    }

    Map<String, dynamic> theme;
    switch (normalizedValue) {
      case 'present':
        theme = {
          'bg': const Color(0xFFE8F5E9),
          'border': const Color(0xFF2BBE74),
          'text': const Color(0xFF2BBE74)
        };
        break;
      case 'absent':
        theme = {
          'bg': const Color(0xFFFFEBEE),
          'border': const Color(0xFFE53935),
          'text': const Color(0xFFE53935)
        };
        break;
      case 'half_day':
        theme = {
          'bg': const Color(0xFFFFF8E1),
          'border': const Color(0xFFF39C12),
          'text': const Color(0xFFF39C12)
        };
        break;
      case 'week_off':
        theme = {
          'bg': const Color(0xFFF1F5F9),
          'border': const Color(0xFF64748B),
          'text': const Color(0xFF64748B)
        };
        break;
      case 'holiday':
        theme = {
          'bg': const Color(0xFFE8EAF6),
          'border': const Color(0xFF3F51B5),
          'text': const Color(0xFF3F51B5)
        };
        break;
      default:
        theme = {
          'bg': Colors.white,
          'border': Colors.grey,
          'text': Colors.black
        };
    }

    return GestureDetector(
      onTap: () => _changeStatus(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme['bg'] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected ? theme['border'] : theme['border'].withOpacity(0.3),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? theme['text'] : theme['text'].withOpacity(0.6),
          ),
        ),
      ),
    );
  }

  Widget _punchCard({
    required String title,
    required DateTime? time,
    required String address,
    required String? photoPath,
    required IconData icon,
    required Color color,
    required String emptyLabel,
    VoidCallback? onAdd,
  }) {
    final hasData = time != null || (address.isNotEmpty || photoPath != null);
    final timeStr =
        time != null ? DateFormat('hh:mm a').format(time) : '-- : --';

    return Container(
      // Reduced padding to 10 for more internal space on small screens
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // Subtle border helps define the card on white backgrounds
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: hasData
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER ROW
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14, // Slightly smaller
                      backgroundColor: color.withOpacity(0.1),
                      child: Icon(icon, size: 14, color: color),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onAdd != null)
                      GestureDetector(
                        onTap: onAdd,
                        child: Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                // TIME SECTION - Using FittedBox to prevent overflow
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    timeStr,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                // ADDRESS SECTION
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                // PHOTO SECTION
                if (photoPath != null && photoPath.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _showImagePreview(
                        context, '$_baseUrl$photoPath'), // Trigger Preview
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Hero(
                        // Hero added for smooth transition effect
                        tag: '$_baseUrl$photoPath',
                        child: Image.network(
                          '$_baseUrl$photoPath',
                          height: 70,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 70,
                            color: Colors.grey[100],
                            child: const Icon(Icons.broken_image_outlined,
                                size: 20, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: color.withOpacity(0.1),
                      child: Icon(icon, size: 14, color: color),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'No record',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
                if (onAdd != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 32, // Controlled height
                    child: OutlinedButton(
                      onPressed: onAdd,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        side: BorderSide(color: color.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        emptyLabel,
                        style: TextStyle(fontSize: 11, color: color),
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _presentDropdownChip() {
    final rawStatus =
        (_statusOverride ?? (widget.record['status'] as String? ?? 'Absent'))
            .toLowerCase();

    // Logic to keep the chip highlighted if either state is active
    final bool isSelected =
        (rawStatus == 'present' || rawStatus == 'double present');

    const Color presentColor = Color(0xFF2BBE74);
    const Color presentBg = Color(0xFFE8F5E9);

    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (String value) {
        // SUCCESS: Passes "Present" or "Double Present" exactly as written below
        _changeStatus(value);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'present', // Exact match for backend enum
          child: Text('Present'),
        ),
        const PopupMenuItem(
          value: 'double_present', // Exact match for backend enum
          child: Text('Double Present'),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? presentBg : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? presentColor : presentColor.withOpacity(0.3),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              // Show "DOUBLE PRESENT" on the chip if that's the current state
              rawStatus == 'double present' ? 'DOUBLE PRESENT' : 'PRESENT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color:
                    isSelected ? presentColor : presentColor.withOpacity(0.6),
              ),
            ),
            Icon(Icons.arrow_drop_down,
                size: 16,
                color:
                    isSelected ? presentColor : presentColor.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }

  Widget _leaveDropdownChip({
    required String label,
    required String value,
    required Function(String) onSelected,
    required Color color,
  }) {
    final rawStatus =
        (_statusOverride ?? (widget.record['status'] as String? ?? ''))
            .toLowerCase();
    // Highlight if the current status matches the value assigned to this chip
    final bool isSelected = rawStatus == value.toLowerCase();
    final String? currentLeaveId = _statusOverride != null
        ? null // If we just changed status, the ID might be pending or passed via callback
        : (widget.record['leaveType'] as String?);
    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: onSelected,
      itemBuilder: (context) {
        if (_isLoadingLeaves) {
          return [
            const PopupMenuItem(enabled: false, child: Text("Loading..."))
          ];
        }
        if (_companyLeaveTypes.isEmpty) {
          return [
            const PopupMenuItem(
                enabled: false, child: Text("No leave types defined"))
          ];
        }
        return _companyLeaveTypes.map((leave) {
          final bool isThisTypeSelected =
              isSelected && (currentLeaveId == leave.id);
          return PopupMenuItem<String>(
            value: leave.id,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    leave.name,
                    style: TextStyle(
                      fontWeight: isThisTypeSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isThisTypeSelected ? color : Colors.black87,
                    ),
                  ),
                ),
                if (isThisTypeSelected)
                  Icon(Icons.check, color: color, size: 18),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : color.withOpacity(0.6),
              ),
            ),
            Icon(Icons.arrow_drop_down,
                size: 18, color: isSelected ? color : color.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }

  void _showImagePreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // The Big Image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: InteractiveViewer(
                // Allows user to pinch and zoom
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.error, color: Colors.white),
                ),
              ),
            ),
            // Close Button at top right
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.close, color: Colors.white),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
