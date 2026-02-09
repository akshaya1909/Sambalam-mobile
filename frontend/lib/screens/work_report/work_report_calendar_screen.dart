import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/work_report_api_service.dart';
import '../../api/employee_api_service.dart';
import 'template_selection_screen.dart';

class WorkReportCalendarScreen extends StatefulWidget {
  final String employeeId;
  final String companyId;

  const WorkReportCalendarScreen({
    Key? key,
    required this.employeeId,
    required this.companyId,
  }) : super(key: key);

  @override
  State<WorkReportCalendarScreen> createState() =>
      _WorkReportCalendarScreenState();
}

class _WorkReportCalendarScreenState extends State<WorkReportCalendarScreen> {
  final WorkReportApiService _api = WorkReportApiService();
  final EmployeeApiService _employeeApi = EmployeeApiService();

  DateTime _selectedMonth = DateTime.now();
  Set<int> _reportedDays = {};
  bool _isLoading = true;
  String? _employeeFullName;

  final Color primaryEmerald = const Color(0xFF059669);
  final Color backgroundGrey = const Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _initialLoad();
  }

  Future<void> _initialLoad() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();

    // Resolve IDs: Check widget first, then fallback to SharedPreferences
    final String? effectiveEmployeeId = widget.employeeId.isNotEmpty
        ? widget.employeeId
        : prefs.getString('employeeId');

    final String? effectiveCompanyId = widget.companyId.isNotEmpty
        ? widget.companyId
        : prefs.getString('companyId');

    if (effectiveEmployeeId == null || effectiveCompanyId == null) {
      debugPrint("Critical Error: IDs missing from storage on refresh.");
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // Pass the resolved IDs to the loading methods
    await Future.wait([
      _loadEmployeeDetails(effectiveEmployeeId, effectiveCompanyId),
      _loadReports(effectiveEmployeeId),
    ]);

    if (mounted) setState(() => _isLoading = false);
  }

  DateTime _getISTNow() {
    // Always calculates IST based on UTC + 5:30 regardless of device settings
    return DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
  }

  Future<void> _loadEmployeeDetails(String empId, String compId) async {
    try {
      final data = await _employeeApi.getEmployeeBasicDetails(
        employeeId: empId,
        companyId: compId,
      );
      if (mounted) {
        setState(() {
          _employeeFullName = data['fullName'];
        });
      }
    } catch (e) {
      debugPrint("Details load error: $e");
    }
  }

// 3. Update Reports method to accept parameters
  Future<void> _loadReports(String empId) async {
    try {
      final reports = await _api.getMonthlyReports(
        empId,
        _selectedMonth.year,
        _selectedMonth.month,
      );
      if (mounted) {
        setState(() {
          _reportedDays = reports.map((r) {
            return DateTime.parse(r['date']).toUtc().day;
          }).toSet();
        });
      }
    } catch (e) {
      debugPrint("Reports load error: $e");
    }
  }

  String get _employeeInitial {
    if (_employeeFullName == null || _employeeFullName!.isEmpty) return 'E';
    return _employeeFullName!
        .trim()
        .split(' ')
        .map((l) => l[0])
        .take(2)
        .join()
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundGrey,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildSummaryBar(),
            const SizedBox(height: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(32)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(32)),
                    child: _isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                                color: primaryEmerald, strokeWidth: 2))
                        : _buildCalendarContent(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            CircleAvatar(
              radius: 22,
              backgroundColor: primaryEmerald.withOpacity(0.1),
              child: Text(_employeeInitial,
                  style: TextStyle(
                      color: primaryEmerald, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _employeeFullName ?? "Loading...",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text("Daily Work Reports",
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            _buildMonthSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return InkWell(
      onTap: () {/* Add Month Picker logic if needed */},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundGrey,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(DateFormat('MMM yyyy').format(_selectedMonth),
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBar() {
    final istNow = _getISTNow();
    final todayIST = DateTime(istNow.year, istNow.month, istNow.day);

    // 1. Total days in the selected month
    final totalDaysInMonth =
        DateUtils.getDaysInMonth(_selectedMonth.year, _selectedMonth.month);

    // 2. Identify the last day we should care about (either today or end of month)
    int lastRelevantDay;
    if (_selectedMonth.year == todayIST.year &&
        _selectedMonth.month == todayIST.month) {
      // If viewing current month, only look up to today
      lastRelevantDay = todayIST.day;
    } else if (_selectedMonth.isAfter(todayIST)) {
      // If viewing a future month, pending is 0
      lastRelevantDay = 0;
    } else {
      // If viewing a past month, look at all days in that month
      lastRelevantDay = totalDaysInMonth;
    }

    // 3. Filter reported days to only include those up to the 'lastRelevantDay'
    final reportsUpToToday =
        _reportedDays.where((day) => day <= lastRelevantDay).length;

    // 4. Calculate Pending: (Days passed so far) - (Reports submitted for those days)
    final pendingCount = lastRelevantDay - reportsUpToToday;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _summaryItem("${_reportedDays.length} Submitted", primaryEmerald),
          const SizedBox(width: 12),
          _summaryItem(
              "${pendingCount < 0 ? 0 : pendingCount} Pending", Colors.orange),
        ],
      ),
    );
  }

  Widget _summaryItem(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildCalendarContent() {
    final year = _selectedMonth.year;
    final month = _selectedMonth.month;
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final firstDayWeekday = DateTime(year, month, 1).weekday % 7;
    final istNow = _getISTNow();
    final todayIST = DateTime(istNow.year, istNow.month, istNow.day);

    return Column(
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((d) => Text(d,
                    style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)))
                .toList(),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(indent: 20, endIndent: 20, height: 1),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: daysInMonth + firstDayWeekday,
            itemBuilder: (context, index) {
              if (index < firstDayWeekday) return const SizedBox.shrink();

              final day = index - firstDayWeekday + 1;
              final date = DateTime(year, month, day);
              final cellDate = DateTime(date.year, date.month, date.day);
              bool isFuture = cellDate.isAfter(todayIST);
              bool hasReport = _reportedDays.contains(day);
              bool isToday = cellDate.isAtSameMomentAs(todayIST);

              return _buildDayCell(day, date, hasReport, isToday, isFuture);
            },
          ),
        ),
        _buildBottomLegend(),
      ],
    );
  }

  Widget _buildDayCell(
      int day, DateTime date, bool hasReport, bool isToday, bool isFuture) {
    final cellDate = DateTime(date.year, date.month, date.day);
    return GestureDetector(
      onTap: isFuture
          ? null
          : () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TemplateSelectionScreen(
                    employeeId: widget.employeeId,
                    companyId: widget.companyId,
                    date: date,
                  ),
                ),
              );

              // FIX: Resolve ID before calling the function
              final prefs = await SharedPreferences.getInstance();
              String effectiveEmployeeId = widget.employeeId.isNotEmpty
                  ? widget.employeeId
                  : (prefs.getString('employeeId') ?? '');

              // REFRESH: Always call this after returning to update the dots/colors
              _loadReports(effectiveEmployeeId);
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isFuture
              ? backgroundGrey // Disabled look
              : (hasReport ? primaryEmerald : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isToday
                ? primaryEmerald
                : (hasReport ? primaryEmerald : Colors.grey.shade200),
            width: isToday ? 2 : 1,
          ),
          boxShadow: hasReport && !isFuture
              ? [
                  BoxShadow(
                      color: primaryEmerald.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Center(
          child: Text(
            "$day",
            style: TextStyle(
              color: isFuture
                  ? Colors.grey.shade400 // Faded text for future
                  : (hasReport
                      ? Colors.white
                      : (isToday ? primaryEmerald : Colors.black87)),
              fontWeight: isFuture ? FontWeight.normal : FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendItem(primaryEmerald, "Submitted"),
          const SizedBox(width: 24),
          _legendItem(Colors.white, "Pending", border: Colors.grey.shade300),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label, {Color? border}) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: border != null ? Border.all(color: border) : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
