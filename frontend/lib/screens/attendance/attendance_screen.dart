import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../api/employee_api_service.dart';
import '../../../api/attendance_api_service.dart';
import 'edit_attendance_screen.dart';

class AttendanceScreen extends StatefulWidget {
  final String phoneNumber;
  final String companyId;
  final String? employeeId;

  const AttendanceScreen({
    Key? key,
    required this.phoneNumber,
    required this.companyId,
    this.employeeId,
  }) : super(key: key);

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final EmployeeApiService _employeeApi = EmployeeApiService();
  final AttendanceApiService _attendanceApi = AttendanceApiService();

  DateTime _selectedMonth = DateTime.now();

  int _presentCount = 0;
  int _absentCount = 0;
  int _halfDayCount = 0;
  double _paidLeaveCount = 0;
  int _weekOffCount = 0;

  String? _employeeFullName;
  bool _isLoadingEmployee = true;
  String? _employeeId;

  Map<DateTime, String> _dailyStatus = {};
  Map<DateTime, Map<String, dynamic>> _recordByDate = {};

  Map<String, dynamic>? _workSchedule;
  bool _isFlexible = false;
  bool _isAdmin = false;
  bool _isTriggering = false;
  DateTime? _dateOfJoining;

  String get _employeeInitial {
    final name = _employeeFullName ?? '';
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    _initEmployeeAndAttendance();
  }

  Future<void> _initEmployeeAndAttendance() async {
    try {
      await _resolveEmployeeId();

      if (_employeeId != null) {
        final prefs = await SharedPreferences.getInstance();
        // Ensure we have the companyId for the attendance API calls
        String effectiveCompanyId = widget.companyId.isNotEmpty
            ? widget.companyId
            : (prefs.getString('companyId') ?? '');
        final String? adminId = prefs.getString('adminId');
        final String? storedEmployeeId = prefs.getString('employeeId');

        // Fetch Schedule
        final schedule = await _attendanceApi.getWorkSchedule(_employeeId!);

        final data = await _employeeApi.getEmployeeBasicDetails(
          employeeId: _employeeId!,
          companyId: effectiveCompanyId,
        );

        debugPrint("--- EMPLOYEE BASIC DETAILS ---");
        debugPrint("Full Name: ${data['fullName']}");
        debugPrint("Date of Joining (Raw): ${data['dateOfJoining']}");

        if (mounted) {
          setState(() {
            _workSchedule = schedule;
            _isFlexible = schedule?['scheduleType'] == 'Flexible';
            _isAdmin = (adminId != null && adminId.isNotEmpty) &&
                (storedEmployeeId == null || storedEmployeeId.isEmpty);
            _employeeFullName = data['fullName'];
            if (data['dateOfJoining'] != null) {
              _dateOfJoining = DateTime.parse(data['dateOfJoining']);
              debugPrint("Date of Joining (Parsed): $_dateOfJoining");
            }
            _isLoadingEmployee = false;
          });
        }

        // Load Details and Attendance using the effective companyId
        await _loadEmployeeDetails(effectiveCompanyId);
        await _loadMonthAttendance(effectiveCompanyId);
      }
    } catch (e) {
      debugPrint("Initialization error: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoadingEmployee = false);
      }
    }
  }

  Future<void> _resolveEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. ADMIN FLOW: If employeeId is passed in constructor, use it.
    if (widget.employeeId != null && widget.employeeId!.isNotEmpty) {
      _employeeId = widget.employeeId;
      return;
    }

    // 2. REFRESH FLOW: Check local storage first (Persists on refresh)
    final String? storedId = prefs.getString('employeeId');
    if (storedId != null && storedId.isNotEmpty) {
      _employeeId = storedId;
      return;
    }

    // 3. FALLBACK: If storage is empty, use phone number to fetch ID
    // Ensure we have a valid companyId (re-fetch from storage if widget is empty)
    String effectiveCompanyId = widget.companyId;
    if (effectiveCompanyId.isEmpty) {
      effectiveCompanyId = prefs.getString('companyId') ?? '';
    }

    if (widget.phoneNumber.isNotEmpty && effectiveCompanyId.isNotEmpty) {
      try {
        final data = await _employeeApi.getEmployeeByPhone(
          phoneNumber: widget.phoneNumber,
          companyId: effectiveCompanyId,
        );
        _employeeId = data['id'] as String?;
        _employeeFullName = data['fullName'] as String?;
      } catch (e) {
        debugPrint("Error fetching employee by phone: $e");
      }
    }
  }

  Future<void> _loadMonthAttendance(String compId) async {
    if (_employeeId == null) return;
    try {
      // if (_employeeId == null) {
      //   setState(() {
      //     _dailyStatus = {};
      //     _recordByDate = {};
      //     _presentCount = 0;
      //     _absentCount = 0;
      //     _halfDayCount = 0;
      //     _paidLeaveCount = 0;
      //     _weekOffCount = 0;
      //   });
      //   return;
      // }

      final res = await _attendanceApi.getMonthlyAttendance(
        employeeId: _employeeId!,
        companyId: compId,
        year: _selectedMonth.year,
        month: _selectedMonth.month,
      );

      final List records = (res['records'] as List?) ?? [];

      final Map<DateTime, String> map = {};
      final Map<DateTime, Map<String, dynamic>> recordMap = {};
      int present = 0;
      int absent = 0;
      int halfDay = 0;
      double paidLeave = 0;
      int weekOff = 0;

      for (final r in records) {
        final dateStr = r['date'] as String;
        final d = DateTime.parse(dateStr);
        final local = d.toLocal();
        final dateOnly = DateTime(local.year, local.month, local.day);

        final status = r['status'] as String?;
        final punchIn = r['punchIn'];

        String cellStatus;

        switch (status) {
  case 'Present':
    cellStatus = (punchIn != null && punchIn['status'] == 'Late') ? 'present_late' : 'present';
    present += 1;
    break;
  case 'Double Present':
    cellStatus = 'double_present';
    present += 1;
    break;
  case 'Absent':
    cellStatus = 'absent';
    absent += 1;
    break;
  case 'Half Day':
    cellStatus = 'half_day';
    halfDay += 1;
    break;
  case 'Half Day Leave':
    cellStatus = 'half_day_leave';
    halfDay += 1;
    break;
  case 'Paid Leave':
    cellStatus = 'paid_leave';
    paidLeave += 1.0;
    break;
  case 'Unpaid Leave':
    cellStatus = 'unpaid_leave';
    absent += 1; // Unpaid leave usually counts towards absent total
    break;
  case 'Sunday':
  case 'Week Off':
    cellStatus = 'weekoff';
    weekOff += 1;
    break;
  case 'Holiday':
    cellStatus = 'holiday';
    weekOff += 1;
    break;
  default:
    cellStatus = 'disabled';
}

        map[dateOnly] = cellStatus;
        recordMap[dateOnly] = r as Map<String, dynamic>;
      }

      setState(() {
        _dailyStatus = map;
        _recordByDate = recordMap;
        _presentCount = present;
        _absentCount = absent;
        _halfDayCount = halfDay;
        _paidLeaveCount = paidLeave;
        _weekOffCount = weekOff;
      });
    } catch (_) {
      setState(() {
        _dailyStatus = {};
        _recordByDate = {};
        _presentCount = 0;
        _absentCount = 0;
        _halfDayCount = 0;
        _paidLeaveCount = 0;
        _weekOffCount = 0;
      });
    }
  }

  Future<void> _runAutoMarkAbsent() async {
    setState(() => _isTriggering = true);
    try {
      await _attendanceApi.triggerAutoMarkAbsent();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Auto-mark logic processed successfully"),
            backgroundColor: Colors.green),
      );
      // Refresh the attendance view
      await _loadMonthAttendance(widget.companyId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isTriggering = false);
    }
  }

  Future<void> _loadEmployeeDetails(String compId) async {
    if (_employeeId == null) return;
    try {
      // if (_employeeId == null) {
      //   setState(() => _isLoadingEmployee = false);
      //   return;
      // }

      final data = await _employeeApi.getEmployeeBasicDetails(
        employeeId: _employeeId!,
        companyId: compId,
      );

      if (!mounted) return;
      setState(() {
        _employeeFullName = data['fullName'] as String?;
        _isLoadingEmployee = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingEmployee = false);
    }
  }

  String get _monthLabel => DateFormat('MMMM yyyy').format(_selectedMonth);

  void _openMonthPicker() async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _MonthPickerSheet(
        initialMonth: _selectedMonth,
        isAdmin: _isAdmin, // Pass Admin Status
        doj: _dateOfJoining,
      ),
    );

    if (picked != null) {
      setState(() => _selectedMonth = picked);
      final prefs = await SharedPreferences.getInstance();
      String effectiveCompanyId = widget.companyId.isNotEmpty
          ? widget.companyId
          : (prefs.getString('companyId') ?? '');
      await _loadMonthAttendance(effectiveCompanyId);
    }
  }

  bool _isDayAWeekOff(DateTime date) {
    if (_workSchedule == null) return false;

    if (!_isFlexible) {
      // FIXED SCHEDULE LOGIC
      final String dayName =
          DateFormat('EEE').format(date); // "Mon", "Tue", etc.
      final List days = _workSchedule!['fixed']['days'] ?? [];
      final dayConfig = days.firstWhere(
        (d) => d['day'] == dayName,
        orElse: () => null,
      );
      return dayConfig != null && dayConfig['isWeekoff'] == true;
    } else {
      // FLEXIBLE SCHEDULE LOGIC
      final String dateStr = DateFormat('yyyy-MM-dd').format(date);
      final String currentMonth = DateFormat('yyyy-MM').format(date);
      final List flexibles = _workSchedule!['flexibles'] ?? [];

      // Find the flexible config for the current month
      final monthConfig = flexibles.firstWhere(
        (m) => m['month'] == currentMonth,
        orElse: () => null,
      );

      if (monthConfig != null) {
        final List days = monthConfig['days'] ?? [];
        final dayConfig = days.firstWhere(
          (d) => d['day'] == dateStr,
          orElse: () => null,
        );
        return dayConfig != null && dayConfig['isWeekoff'] == true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = const Color(0xFF206C5E);
    final Color bg = const Color(0xFFF4F6FB);

    return Scaffold(
      backgroundColor: bg,
      // appBar: AppBar(
      //   elevation: 0,
      //   backgroundColor: Colors.white,
      //   foregroundColor: Colors.black,
      //   titleSpacing: 0,
      //   leading: IconButton(
      //     icon: const Icon(Icons.arrow_back, color: Colors.black),
      //     onPressed: () => Navigator.of(context).pop(),
      //   ),
      //   title: const Text(
      //     'Attendance',
      //     style: TextStyle(
      //       color: Colors.black, // Set font color to black here
      //       fontWeight: FontWeight.w600,
      //       fontSize: 18,
      //     ),
      //   ),
      // ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildHeaderCard(primary),
            const SizedBox(height: 12),
            _buildSummaryRow(),
            const SizedBox(height: 12),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 0),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    child: _buildCalendarGrid(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(Color primary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: 14, horizontal: 8), // Reduced horizontal padding
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // BACK BUTTON: Removed IconButton to eliminate default internal padding
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(8), // Controlled hit area
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    size: 16, color: Colors.grey[800]),
              ),
            ),
            const SizedBox(width: 4),
            CircleAvatar(
              radius: 22, // Slightly smaller to save horizontal space
              backgroundColor: primary.withOpacity(0.1),
              child: Text(
                _employeeInitial,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: primary,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // TEXT SECTION: Wrapped in Expanded to prevent pixel breaking
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isLoadingEmployee
                        ? 'Loading...'
                        : (_employeeFullName?.isNotEmpty == true
                            ? _employeeFullName!
                            : 'Your name'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow
                        .ellipsis, // Prevents name from breaking into lines
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Attendance overview',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow
                        .ellipsis, // Ensures "overview" stays on one line
                  ),
                ],
              ),
            ),
            // if (_isAdmin)
            //   IconButton(
            //     icon: _isTriggering
            //         ? const SizedBox(
            //             width: 18,
            //             height: 18,
            //             child: CircularProgressIndicator(strokeWidth: 2))
            //         : const Icon(Icons.bolt, color: Colors.orange, size: 20),
            //     tooltip: "Run Auto-Absent Check",
            //     onPressed: _isTriggering ? null : _runAutoMarkAbsent,
            //   ),
            const SizedBox(width: 8),

            // MONTH PICKER: Wrapped in a Flexible if needed, but standard is fine here
            InkWell(
              onTap: _openMonthPicker,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F7),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 12, color: Colors.black87),
                    const SizedBox(width: 4),
                    Text(
                      _monthLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Icon(Icons.expand_more,
                        size: 16, color: Colors.black54),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _summaryChip(
              label: 'Present',
              value: _presentCount.toString(),
              color: const Color(0xFF2BBE74),
            ),
            _summaryChip(
              label: 'Absent',
              value: _absentCount.toString(),
              color: const Color(0xFFE53935),
            ),
            _summaryChip(
              label: 'Half day',
              value: _halfDayCount.toString(),
              color: const Color(0xFFF6C94C),
            ),
            _summaryChip(
              label: 'Paid leave',
              value: _paidLeaveCount.toStringAsFixed(1),
              color: const Color(0xFF9B59B6),
            ),
            _summaryChip(
              label: 'Week off',
              value: _weekOffCount.toString(),
              color: const Color(0xFF7F8C8D),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 11,
              backgroundColor: color.withOpacity(0.12),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final year = _selectedMonth.year;
    final month = _selectedMonth.month;

    final firstDayOfMonth = DateTime(year, month, 1);
    final weekdayOfFirst = firstDayOfMonth.weekday;
    final daysInMonth = DateTime(year, month + 1, 0).day;

    final int leadingEmpty = (weekdayOfFirst % 7);
    final totalCells = leadingEmpty + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _WeekdayLabel('Sun'),
              _WeekdayLabel('Mon'),
              _WeekdayLabel('Tue'),
              _WeekdayLabel('Wed'),
              _WeekdayLabel('Thu'),
              _WeekdayLabel('Fri'),
              _WeekdayLabel('Sat'),
            ],
          ),
        ),
        const Divider(height: 1),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.builder(
            // Use clamping physics to avoid conflict with outer scrolling if any
            physics: const ClampingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              // Adjust childAspectRatio to be dynamic based on row count
              // to ensure cells don't get too tall and overflow the bottom
              childAspectRatio: 0.85,
            ),
            itemCount: rows * 7,
            itemBuilder: (context, index) {
              final dayNumber = index - leadingEmpty + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox.shrink();
              }

              final date = DateTime(year, month, dayNumber);
              String? status = _dailyStatus[date];
              final record = _recordByDate[date];

              if (status == null || status == 'disabled') {
                if (_isDayAWeekOff(date)) {
                  status = 'weekoff';
                }
              }

              return _DayCell(
                date: date,
                status: status,
                record: record,
                onTap: record == null
                    ? null
                    : () async {
                        // 1. Initialize SharedPreferences
                        final prefs = await SharedPreferences.getInstance();

                        // 2. Retrieve the IDs
                        final String? adminId = prefs.getString('adminId');
                        final String? storedEmployeeId =
                            prefs.getString('employeeId');

                        // 3. Apply your logic: isAdmin is true ONLY IF adminId exists AND employeeId is null
                        // Note: We check if employeeId is null OR empty to be safe
                        bool calculatedIsAdmin =
                            (adminId != null && adminId.isNotEmpty) &&
                                (storedEmployeeId == null ||
                                    storedEmployeeId.isEmpty);

                        if (!mounted) return;

                        // 4. Navigate with the calculated isAdmin value
                        final changed = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => EditAttendanceScreen(
                              employeeName: _employeeFullName ?? 'Your Name',
                              date: date,
                              record: record,
                              employeeId:
                                  _employeeId!, // This is the ID of the staff being edited
                              companyId: widget.companyId,
                              isAdmin: calculatedIsAdmin, // Passed dynamically
                            ),
                          ),
                        );

                        if (changed == true) {
                          // Re-load attendance if a change was made
                          final String effectiveCompanyId =
                              widget.companyId.isNotEmpty
                                  ? widget.companyId
                                  : (prefs.getString('companyId') ?? '');
                          _loadMonthAttendance(effectiveCompanyId);
                        }
                      },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String label;
  const _WeekdayLabel(this.label, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime date;
  final String? status;
  final Map<String, dynamic>? record;
  final VoidCallback? onTap;

  const _DayCell({
    Key? key,
    required this.date,
    this.status,
    this.record,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final int day = date.day;
    Color? bg = const Color(0xFFE5E7EB);
    Gradient? gradient;
    Color textColor = Colors.white;
    String bottomText = '';

    switch (status) {
      case 'present':
        bg = const Color(0xFF2BBE74);
        break;
      case 'present_late':
        bg = const Color(0xFF2BBE74);
        bottomText = 'LATE';
        break;
      case 'double_present':
        bg = const Color(0xFF2BBE74);
        bottomText = '2P'; // Indication for Double Present
        break;
      case 'absent':
        bg = const Color(0xFFE53935);
        break;
      case 'half_day':
        bg = const Color(0xFFF39C12);
        break;
      case 'half_day_leave':
      bg = null; // Important: Clear color when using gradient
      gradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFF39C12), // Half Day Yellow/Orange
          Color(0xFF9B59B6), // Paid Leave Purple
        ],
      );
      break;
      case 'paid_leave':
        bg = const Color(0xFF9B59B6);
        bottomText = 'PAID';
        break;
      case 'unpaid_leave':
        bg = Colors.blue;
        break;
      case 'weekoff':
        bg = const Color(0xFF94A3B8);
        bottomText = 'OFF';
        break;
      case 'holiday':
        bg = const Color(0xFF3F51B5); 
        break;
      default:
        bg = const Color(0xFFE5E7EB);
        textColor = const Color(0xFF4B5563);
        break;
    }

    final bool hasRecord = record != null;

    return GestureDetector(
      onTap: hasRecord ? onTap : null,
      child: Opacity(
        opacity: hasRecord ? 1.0 : 0.45,
        child: Container(
          decoration: BoxDecoration(
          color: gradient == null ? bg : null, // Use color only if no gradient
          gradient: gradient, // Apply the gradient here
          borderRadius: BorderRadius.circular(8),
        ),
          child: LayoutBuilder(builder: (context, constraints) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Use FittedBox to scale the number if the cell is tiny
                FittedBox(
                  child: Text(
                    day.toString(),
                    style: TextStyle(
                      fontSize:
                          constraints.maxHeight * 0.35, // Dynamic font size
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ),
                if (bottomText.isNotEmpty)
                  FittedBox(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: Text(
                        bottomText,
                        style: TextStyle(
                          fontSize:
                              constraints.maxHeight * 0.18, // Dynamic font size
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _MonthPickerSheetState extends State<_MonthPickerSheet> {
  late int _selectedYear;
  late int _selectedMonth;

  late final DateTime _now;
  late final DateTime _minMonth; // now - 2 months

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    if (widget.isAdmin && widget.doj != null) {
      // For Admin: Start from 1 month before DOJ
      _minMonth = DateTime(widget.doj!.year, widget.doj!.month - 1, 1);
    } else {
      // For Employee: Current month and before 2 months
      _minMonth = DateTime(_now.year, _now.month - 2, 1);
    }
    _selectedYear = widget.initialMonth.year;
    _selectedMonth = widget.initialMonth.month;
  }

  List<int> _allowedYears() {
    final years = <int>{};
    for (DateTime d = _minMonth;
        !d.isAfter(_now);
        d = DateTime(d.year, d.month + 1, 1)) {
      years.add(d.year);
    }
    final list = years.toList()..sort();
    return list;
  }

  List<Map<String, dynamic>> _allowedMonthsForSelectedYear() {
    final List<Map<String, dynamic>> months = [];
    for (DateTime d = _minMonth;
        !d.isAfter(_now);
        d = DateTime(d.year, d.month + 1, 1)) {
      if (d.year == _selectedYear) {
        months.add({
          'value': d.month,
          'label': DateFormat.MMMM().format(d),
        });
      }
    }
    return months;
  }

  @override
  Widget build(BuildContext context) {
    final years = _allowedYears();
    if (!years.contains(_selectedYear)) _selectedYear = years.last;

    final allowedMonths = _allowedMonthsForSelectedYear();
    if (!allowedMonths.any((m) => m['value'] == _selectedMonth)) {
      _selectedMonth = allowedMonths.last['value'] as int;
    }

    return Container(
      // Ensure the bottom sheet doesn't take more than 70% of screen height
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Shrink to content
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar for better UX
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),

          const Text('Select year',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          DropdownButtonFormField<int>(
            value: _selectedYear,
            isExpanded: true,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: years
                .map((y) =>
                    DropdownMenuItem(value: y, child: Text(y.toString())))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedYear = val);
            },
          ),

          const SizedBox(height: 20),
          const Text('Select month',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // THIS FIXES THE PIXEL BREAKING: Wrap the list in Expanded + ScrollView
          Expanded(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: allowedMonths.length,
              separatorBuilder: (context, index) => Divider(
                  height: 1,
                  thickness: 0.5,
                  color: Colors.grey.shade200,
                  indent: 12,
                  endIndent: 12),
              itemBuilder: (context, index) {
                final m = allowedMonths[index];
                return _monthRadio(m['value'] as int, m['label'] as String);
              },
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(DateTime(_selectedYear, _selectedMonth, 1));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF206C5E),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Apply',
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthRadio(int value, String label) {
    final bool isSelected = _selectedMonth == value;
    return InkWell(
      onTap: () => setState(() => _selectedMonth = value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Radio<int>(
              value: value,
              groupValue: _selectedMonth,
              activeColor: const Color(0xFF206C5E),
              onChanged: (val) {
                if (val != null) setState(() => _selectedMonth = val);
              },
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF206C5E) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthPickerSheet extends StatefulWidget {
  final DateTime initialMonth;
  final bool isAdmin;
  final DateTime? doj;

  const _MonthPickerSheet({
    Key? key,
    required this.initialMonth,
    required this.isAdmin,
    this.doj,
  }) : super(key: key);

  @override
  State<_MonthPickerSheet> createState() => _MonthPickerSheetState();
}
