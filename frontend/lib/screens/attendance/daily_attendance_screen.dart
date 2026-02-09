import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:open_file/open_file.dart';
import '../../../models/staff_model.dart';
import '../../api/company_api_service.dart';
import 'edit_attendance_screen.dart';

const String kBaseUrl = 'http://10.80.210.30:5000';

enum AttendanceFilter {
  inStaff,
  outStaff,
  noPunchIn,
  all,
  breakStaff,
  lateStaff,
  earlyLeaving,
  halfDay,
  overtime,
}

enum AttendanceTab { live, daily }

class DailyAttendanceScreen extends StatefulWidget {
  final AttendanceFilter initialFilter;
  final String companyId;
  final String? branchId; // ADD THIS
  final String? branchName;

  const DailyAttendanceScreen({
    Key? key,
    required this.initialFilter,
    required this.companyId,
    this.branchId, // ADD THIS
    this.branchName,
  }) : super(key: key);

  @override
  State<DailyAttendanceScreen> createState() => _DailyAttendanceScreenState();
}

class _DailyAttendanceScreenState extends State<DailyAttendanceScreen> {
  late AttendanceFilter _activeFilter;
  AttendanceTab _activeTab = AttendanceTab.live;
  final TextEditingController _searchController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  final CompanyApiService _api = CompanyApiService();
  List<Staff> _staff = [];
  bool _loading = true;
  bool _isAdmin = false;
  bool _loadingDaily = false;

  @override
  void initState() {
    super.initState();
    _activeFilter = widget.initialFilter;
    _loadIsAdmin();
    _loadLiveAttendance();
  }

  Future<void> _loadLiveAttendance() async {
    try {
      final list = await _api.getCompanyLiveAttendanceList(
        widget.companyId,
        branchId: widget.branchId,
      );
      if (!mounted) return;
      setState(() {
        _staff = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _loadDailyAttendance() async {
    setState(() => _loadingDaily = true);
    try {
      final list = await _api.getCompanyDailyAttendanceList(
        companyId: widget.companyId,
        date: _selectedDate,
        branchId: widget.branchId,
      );
      if (!mounted) return;
      setState(() {
        _staff = list;
        _loadingDaily = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingDaily = false);
    }
  }

  Future<void> _loadIsAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    final isAdmin = prefs.getBool('isAdmin') ?? false;
    if (!mounted) return;
    setState(() => _isAdmin = isAdmin);
  }

  String get _readableDate {
    final day = _selectedDate.day;
    const monthNames = [
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
      'Dec'
    ];
    final suffix = day == 1 || day == 21 || day == 31
        ? 'st'
        : (day == 2 || day == 22)
            ? 'nd'
            : (day == 3 || day == 23)
                ? 'rd'
                : 'th';
    return '$day$suffix ${monthNames[_selectedDate.month - 1]} ${_selectedDate.year}';
  }

  void _changeDate(int delta) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: delta));
    });
    if (_activeTab == AttendanceTab.daily) {
      _loadDailyAttendance();
    }
  }

  List<Staff> get _filteredStaff {
    final q = _searchController.text.toLowerCase();

    if (_activeTab == AttendanceTab.live) {
      return _staff.where((s) {
        final byName = s.name.toLowerCase().contains(q);
        if (!byName) return false;

        final status = (s.status ?? '').toLowerCase();

        switch (_activeFilter) {
          case AttendanceFilter.inStaff:
            return status == 'in';
          case AttendanceFilter.outStaff:
            return status == 'out';
          case AttendanceFilter.noPunchIn:
            return status == 'no_punch_in';
          case AttendanceFilter.breakStaff:
            return status == 'break';
          case AttendanceFilter.lateStaff:
            return status == 'late';
          case AttendanceFilter.earlyLeaving:
            return status == 'early_leaving';
          case AttendanceFilter.halfDay:
            return s.isHalfDay;
          case AttendanceFilter.overtime:
            return s.isOvertime;
          case AttendanceFilter.all:
            return true;
        }
      }).toList();
    }

    // daily tab
    return _staff.where((s) {
      final byName = s.name.toLowerCase().contains(q);
      if (!byName) return false;

      final status = (s.status ?? '').toLowerCase();
      final bool hasIn = status == 'in' ||
          status == 'late' ||
          status == 'early_leaving' ||
          status == 'out';
      final bool explicitAbsent = status == 'absent';
      final bool noPunch = status == 'no_punch_in';

      switch (_activeFilter) {
        case AttendanceFilter.inStaff:
          return hasIn && !explicitAbsent;
        case AttendanceFilter.outStaff:
          return explicitAbsent || (!hasIn && noPunch);
        case AttendanceFilter.noPunchIn:
          return noPunch;
        case AttendanceFilter.breakStaff:
          return status == 'break';
        case AttendanceFilter.lateStaff:
          return status == 'late';
        case AttendanceFilter.earlyLeaving:
          return status == 'early_leaving';
        case AttendanceFilter.halfDay:
          return s.isHalfDay;
        case AttendanceFilter.overtime:
          return s.isOvertime;
        case AttendanceFilter.all:
          return true;
      }
    }).toList();
  }

  int get _inCount =>
      _staff.where((s) => (s.status ?? '').toLowerCase() == 'in').length;
  int get _outCount =>
      _staff.where((s) => (s.status ?? '').toLowerCase() == 'out').length;
  int get _noPunchInCount => _staff
      .where((s) => (s.status ?? '').toLowerCase() == 'no_punch_in')
      .length;
  int get _lateCount =>
      _staff.where((s) => (s.status ?? '').toLowerCase() == 'late').length;
  int get _earlyLeavingCount => _staff
      .where((s) => (s.status ?? '').toLowerCase() == 'early_leaving')
      .length;
  int get _breakCount => 0;

  int get _presentCount => _staff.where((s) {
        final st = (s.status ?? '').toLowerCase();
        return st == 'in' ||
            st == 'late' ||
            st == 'early_leaving' ||
            st == 'out';
      }).length;

  int get _absentCount => _staff.where((s) {
        final st = (s.status ?? '').toLowerCase();
        return st == 'absent' || st == 'no_punch_in';
      }).length;

  int get _halfDayCount => _staff.where((s) => s.isHalfDay).length;
  int get _overtimeCount => _staff.where((s) => s.isOvertime).length;

  Future<void> _openEditForStaff(Staff s) async {
    final date =
        _activeTab == AttendanceTab.daily ? _selectedDate : DateTime.now();

    final record = <String, dynamic>{
      'status': s.status ?? 'Present',
      'attendanceStatus': s.attendanceStatus ?? 'Absent',
      'punchIn': {
        'time': s.inTimeIst,
        'punchInPhoto': s.punchInPhoto,
        'location': {'address': s.punchInAddress},
      },
      'punchOut': {
        'time': s.punchOutTimeIst,
        'punchOutPhoto': s.punchOutPhoto,
        'location': {'address': s.punchOutAddress},
      },
      'remarks': '',
    };

    final shouldReload = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditAttendanceScreen(
          employeeName: s.name,
          date: date,
          record: record,
          employeeId: s.employeeId,
          companyId: widget.companyId,
          isAdmin: _isAdmin,
        ),
      ),
    );

    if (shouldReload == true) {
      if (_activeTab == AttendanceTab.daily) {
        await _loadDailyAttendance();
      } else {
        await _loadLiveAttendance();
      }
    }
  }

  // Future<void> _generateExcelReport() async {
  //   try {
  //     // 1. Create a new Excel document.
  //     final xlsio.Workbook workbook = xlsio.Workbook();

  //     // Accessing the first sheet (default)
  //     final xlsio.Worksheet liveSheet = workbook.worksheets[0];
  //     liveSheet.name = 'Live Attendance';

  //     // --- STYLING ---
  //     final xlsio.Style headerStyle = workbook.styles.add('headerStyle');
  //     headerStyle.backColor = '#206C5E';
  //     headerStyle.fontColor = '#FFFFFF';
  //     headerStyle.bold = true;
  //     headerStyle.hAlign = xlsio.HAlignType.center;
  //     headerStyle.vAlign = xlsio.VAlignType.center;

  //     // --- SHEET 1: LIVE ATTENDANCE ---
  //     // Title
  //     liveSheet.getRangeByName('A1').setText('Live Attendance Report');
  //     liveSheet.getRangeByName('A1').cellStyle.bold = true;
  //     liveSheet.getRangeByName('A1').cellStyle.fontSize = 14;

  //     // Headers
  //     List<String> liveHeaders = [
  //       'Staff Name',
  //       'Current Status',
  //       'Punch In Time',
  //       'Punch Out Time',
  //       'Address'
  //     ];
  //     for (int i = 0; i < liveHeaders.length; i++) {
  //       final cell = liveSheet.getRangeByIndex(3, i + 1);
  //       cell.setText(liveHeaders[i]);
  //       cell.cellStyle = headerStyle;
  //     }

  //     // Data Rows
  //     for (int i = 0; i < _staff.length; i++) {
  //       final s = _staff[i];
  //       final int row = i + 4;
  //       liveSheet.getRangeByIndex(row, 1).setText(s.name);
  //       liveSheet.getRangeByIndex(row, 2).setText(s.status ?? 'N/A');
  //       liveSheet.getRangeByIndex(row, 3).setText(s.inTimeIst ?? '-');
  //       liveSheet.getRangeByIndex(row, 4).setText(s.punchOutTimeIst ?? '-');
  //       liveSheet
  //           .getRangeByIndex(row, 5)
  //           .setText(s.punchInAddress ?? (s.punchOutAddress ?? '-'));
  //     }
  //     liveSheet.getRangeByName('A3:E${_staff.length + 3}').autoFitColumns();

  //     // --- SHEET 2: DAILY ATTENDANCE ---
  //     final xlsio.Worksheet dailySheet =
  //         workbook.worksheets.addWithName('Daily Detailed');

  //     // Header Info
  //     dailySheet.getRangeByName('A1').setText('Daily Attendance Report');
  //     dailySheet.getRangeByName('A1').cellStyle.bold = true;
  //     dailySheet
  //         .getRangeByName('A2')
  //         .setText('Attendance Date: $_readableDate');
  //     dailySheet.getRangeByName('A3').setText(
  //         'Exported On: ${DateFormat('dd-MMM-yyyy hh:mm a').format(DateTime.now())}');

  //     // Table Headers
  //     List<String> dailyHeaders = [
  //       'Staff Name',
  //       'Attendance Status',
  //       'Punch In',
  //       'Punch Out',
  //       'Duration',
  //       'Location'
  //     ];
  //     for (int j = 0; j < dailyHeaders.length; j++) {
  //       final cell = dailySheet.getRangeByIndex(5, j + 1);
  //       cell.setText(dailyHeaders[j]);
  //       cell.cellStyle = headerStyle;
  //     }

  //     // Fill Detailed Data
  //     for (int i = 0; i < _staff.length; i++) {
  //       final s = _staff[i];
  //       final int row = i + 6;
  //       dailySheet.getRangeByIndex(row, 1).setText(s.name);
  //       dailySheet
  //           .getRangeByIndex(row, 2)
  //           .setText(s.attendanceStatus ?? (s.status ?? 'Absent'));
  //       dailySheet.getRangeByIndex(row, 3).setText(s.inTimeIst ?? '-');
  //       dailySheet.getRangeByIndex(row, 4).setText(s.punchOutTimeIst ?? '-');
  //       dailySheet.getRangeByIndex(row, 5).setText(s.hoursWorked ?? '-');
  //       dailySheet.getRangeByIndex(row, 6).setText(s.punchInAddress ?? 'N/A');
  //     }

  //     // --- SUMMARY SECTION ---
  //     int summaryStartRow = _staff.length + 8;
  //     dailySheet.getRangeByIndex(summaryStartRow, 1).setText('SUMMARY');
  //     dailySheet.getRangeByIndex(summaryStartRow, 1).cellStyle.bold = true;

  //     dailySheet
  //         .getRangeByIndex(summaryStartRow + 1, 1)
  //         .setText('Total Staff:');
  //     dailySheet
  //         .getRangeByIndex(summaryStartRow + 1, 2)
  //         .setNumber(_staff.length.toDouble());

  //     dailySheet.getRangeByIndex(summaryStartRow + 2, 1).setText('Present:');
  //     dailySheet
  //         .getRangeByIndex(summaryStartRow + 2, 2)
  //         .setNumber(_presentCount.toDouble());

  //     dailySheet.getRangeByIndex(summaryStartRow + 3, 1).setText('Absent:');
  //     dailySheet
  //         .getRangeByIndex(summaryStartRow + 3, 2)
  //         .setNumber(_absentCount.toDouble());

  //     dailySheet.getRangeByName('A5:F${_staff.length + 5}').autoFitColumns();

  //     // --- SAVE AND OPEN ---
  //     final List<int> bytes = workbook.saveAsStream();
  //     // Dispose the workbook to free memory and avoid "unsupported operation" on lists
  //     workbook.dispose();

  //     final Directory directory = await getApplicationSupportDirectory();
  //     final String path = directory.path;
  //     final String fileName =
  //         '$path/Attendance_${DateTime.now().millisecondsSinceEpoch}.xlsx';
  //     final File file = File(fileName);

  //     await file.writeAsBytes(bytes, flush: true);

  //     // Open the file
  //     final openResult = await OpenFile.open(fileName);
  //     if (openResult.type != ResultType.done) {
  //       throw 'No app found to open Excel. Please install Microsoft Excel or Google Sheets.';
  //     }
  //   } catch (e) {
  //     debugPrint("Excel Export Error: $e");
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //           content: Text('Export Failed: $e'), backgroundColor: Colors.red),
  //     );
  //   }
  // }

  Future<void> _generateExcelReport() async {
    try {
      // 1. Create a new Excel document.
      final xlsio.Workbook workbook = xlsio.Workbook();
      // Start with 2 worksheets (Live and Daily)
      workbook.worksheets.add();

      // --- SHEET 1: LIVE ATTENDANCE ---
      final xlsio.Worksheet liveSheet = workbook.worksheets[0];
      liveSheet.name = 'Live Attendance';

      // Headers
      liveSheet.getRangeByIndex(1, 1).setText('Live Attendance Report');
      liveSheet.getRangeByIndex(1, 1).cellStyle.bold = true;

      List<String> liveHeaders = [
        'Staff Name',
        'Status',
        'In Time',
        'Out Time',
        'Address'
      ];
      for (int i = 0; i < liveHeaders.length; i++) {
        final cell = liveSheet.getRangeByIndex(3, i + 1);
        cell.setText(liveHeaders[i]);
        // Apply styles directly to the cell instead of using a named style
        cell.cellStyle.backColor = '#206C5E';
        cell.cellStyle.fontColor = '#FFFFFF';
        cell.cellStyle.bold = true;
      }

      // Data Rows
      for (int i = 0; i < _staff.length; i++) {
        final s = _staff[i];
        final int row = i + 4;
        liveSheet.getRangeByIndex(row, 1).setText(s.name);
        liveSheet.getRangeByIndex(row, 2).setText(s.status ?? 'N/A');
        liveSheet.getRangeByIndex(row, 3).setText(s.inTimeIst ?? '-');
        liveSheet.getRangeByIndex(row, 4).setText(s.punchOutTimeIst ?? '-');
        liveSheet
            .getRangeByIndex(row, 5)
            .setText(s.punchInAddress ?? (s.punchOutAddress ?? '-'));
      }
      liveSheet.getRangeByName('A3:E${_staff.length + 3}').autoFitColumns();

      // --- SHEET 2: DAILY ATTENDANCE ---
      final xlsio.Worksheet dailySheet = workbook.worksheets[1];
      dailySheet.name = 'Daily Report';

      dailySheet.getRangeByName('A1').setText('Daily Attendance Report');
      dailySheet
          .getRangeByName('A2')
          .setText('Attendance Date: $_readableDate');

      List<String> dailyHeaders = [
        'Staff Name',
        'Attendance',
        'Punch In',
        'Punch Out',
        'Work Hrs',
        'Location'
      ];
      for (int j = 0; j < dailyHeaders.length; j++) {
        final cell = dailySheet.getRangeByIndex(4, j + 1);
        cell.setText(dailyHeaders[j]);
        cell.cellStyle.backColor = '#206C5E';
        cell.cellStyle.fontColor = '#FFFFFF';
        cell.cellStyle.bold = true;
      }

      for (int i = 0; i < _staff.length; i++) {
        final s = _staff[i];
        final int row = i + 5;
        dailySheet.getRangeByIndex(row, 1).setText(s.name);
        dailySheet
            .getRangeByIndex(row, 2)
            .setText(s.attendanceStatus ?? (s.status ?? 'Absent'));
        dailySheet.getRangeByIndex(row, 3).setText(s.inTimeIst ?? '-');
        dailySheet.getRangeByIndex(row, 4).setText(s.punchOutTimeIst ?? '-');
        dailySheet.getRangeByIndex(row, 5).setText(s.hoursWorked ?? '-');
        dailySheet.getRangeByIndex(row, 6).setText(s.punchInAddress ?? 'N/A');
      }
      dailySheet.getRangeByName('A4:F${_staff.length + 5}').autoFitColumns();

      // --- SAVE AND OPEN ---
      // Save the document as a list of bytes
      final List<int> bytes = workbook.saveAsStream();

      // IMPORTANT: Do NOT call workbook.dispose() immediately if it causes the crash.
      // Flutter's Garbage Collector will handle it. If you must, call it after the file is saved.

      final Directory directory = await getApplicationSupportDirectory();
      final String path = directory.path;
      final String fileName =
          '$path/Attendance_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final File file = File(fileName);

      await file.writeAsBytes(bytes, flush: true);

      // Open the file
      final openResult = await OpenFile.open(fileName);
      if (openResult.type != ResultType.done) {
        throw 'Please install an Excel viewer app like Google Sheets to view the report.';
      }
    } catch (e) {
      debugPrint("Excel Export Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = const Color(0xFF206C5E);
    final Color bg = const Color(0xFFF4F6FB);

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        titleSpacing: 0,
        leading: IconButton(
          // Force the arrow icon to be black
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.branchName != null
              ? 'Attendance - ${widget.branchName}'
              : 'Attendance',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Colors.black, // Force the text to be black
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Generating Excel File...'),
                    duration: Duration(seconds: 2)),
              );
              await _generateExcelReport();
            },
            icon: const Icon(Icons.download_outlined, size: 16),
            label: const Text(
              'Daily report',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF206C5E),
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            margin:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _tabChip(
                  label: 'Live',
                  icon: Icons.wifi_tethering,
                  selected: _activeTab == AttendanceTab.live,
                  onTap: () {
                    setState(() => _activeTab = AttendanceTab.live);
                    _loadLiveAttendance();
                  },
                ),
                _tabChip(
                  label: 'Daily',
                  icon: Icons.calendar_today,
                  selected: _activeTab == AttendanceTab.daily,
                  onTap: () {
                    setState(() => _activeTab = AttendanceTab.daily);
                    _loadDailyAttendance();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: _activeTab == AttendanceTab.live
          ? _buildLiveAttendanceBody(primary)
          : _buildDailyAttendanceBody(primary),
    );
  }

  Widget _tabChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? const Color(0xFF206C5E) : Colors.grey[700],
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected ? const Color(0xFF206C5E) : Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _getStatusCount(List<String> targets) {
    return _staff.where((s) {
      final status = (s.status ?? '').toLowerCase();
      return targets.any((t) => status == t);
    }).length;
  }

  // ---------- LIVE TAB UI ----------

  Widget _buildLiveAttendanceBody(Color primary) {
    return Column(
      children: [
        const SizedBox(height: 12),
        _liveSummaryRow(primary),
        const SizedBox(height: 12),
        _searchRow(),
        const SizedBox(height: 10),
        _resultCount(),
        const SizedBox(height: 6),
        Expanded(
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: _filteredStaff.isEmpty
                ? _emptyState()
                : ListView.builder(
                    itemCount: _filteredStaff.length,
                    itemBuilder: (context, index) {
                      final s = _filteredStaff[index];
                      return _liveStaffRow(s);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _liveSummaryRow(Color primary) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _filterChipCard(
            label: 'In',
            value: _inCount,
            filter: AttendanceFilter.inStaff,
            color: const Color(0xFF21C48D),
          ),
          _filterChipCard(
            label: 'Out',
            value: _outCount,
            filter: AttendanceFilter.outStaff,
            color: const Color(0xFFE55039),
          ),
          _filterChipCard(
            label: 'No punch',
            value: _noPunchInCount,
            filter: AttendanceFilter.noPunchIn,
            color: const Color(0xFFF39C12),
          ),
          _filterChipCard(
            label: 'Late',
            value: _lateCount,
            filter: AttendanceFilter.lateStaff,
            color: primary,
          ),
          _filterChipCard(
            label: 'Early leaving',
            value: _earlyLeavingCount,
            filter: AttendanceFilter.earlyLeaving,
            color: const Color(0xFF9B59B6),
          ),
        ],
      ),
    );
  }

  Widget _filterChipCard({
    required String label,
    required int value,
    required AttendanceFilter filter,
    required Color color,
  }) {
    final selected = _activeFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: () => setState(() => _activeFilter = filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.12) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : const Color(0xFFE0E4EC),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: color.withOpacity(0.15),
                child: Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: selected ? color : const Color(0xFF4B5563),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search staff',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _showMoreFiltersBottomSheet,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E4EC)),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
              child: const Icon(Icons.tune, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultCount() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Showing ${_filteredStaff.length} staff',
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
      ),
    );
  }

  // ---------- DAILY TAB UI ----------

  Widget _buildDailyAttendanceBody(Color primary) {
    if (_loadingDaily) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        const SizedBox(height: 10),
        _dateSelector(),
        const SizedBox(height: 12),
        _dailyFilterRow(),
        const SizedBox(height: 10),
        _searchRow(),
        const SizedBox(height: 8),
        _resultCount(),
        const SizedBox(height: 4),
        Expanded(
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: _filteredStaff.isEmpty
                ? _emptyState()
                : ListView.builder(
                    itemCount: _filteredStaff.length,
                    itemBuilder: (context, index) {
                      final s = _filteredStaff[index];
                      return _dailyStaffRow(s);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _dateSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _changeDate(-1),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 18, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      _readableDate,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _changeDate(1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dailyFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _filterChipCard(
            label: 'Present',
            value: _presentCount,
            filter: AttendanceFilter.inStaff,
            color: const Color(0xFF21C48D),
          ),
          _filterChipCard(
            label: 'Absent',
            value: _absentCount,
            filter: AttendanceFilter.outStaff,
            color: const Color(0xFFE55039),
          ),
          _filterChipCard(
            label: 'Half day',
            value: _halfDayCount,
            filter: AttendanceFilter.halfDay,
            color: const Color(0xFF9B59B6),
          ),
          _moreFilterChip(),
        ],
      ),
    );
  }

  Widget _moreFilterChip() {
    final bool selected = _activeFilter == AttendanceFilter.all;
    final Color color = const Color(0xFF007AFF);

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: _showMoreFiltersBottomSheet,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : const Color(0xFFE0E4EC),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.tune, size: 16, color: Color(0xFF4B5563)),
              const SizedBox(width: 6),
              Text(
                'More',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: selected ? color : const Color(0xFF4B5563),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String text, AttendanceFilter filter) {
    final selected = _activeFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8F2FF) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? const Color(0xFF007AFF) : const Color(0xFFDFE4EA),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: selected ? const Color(0xFF007AFF) : const Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }

  Widget _moreButton() {
    return GestureDetector(
      onTap: _showMoreFiltersBottomSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFDFE4EA)),
        ),
        child: const Text(
          'More',
          style: TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
        ),
      ),
    );
  }

  void _showMoreFiltersBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        AttendanceFilter tempFilter = _activeFilter;

        return StatefulBuilder(
          builder: (context, setModalState) {
            // pill is inside StatefulBuilder so it can use setModalState
            Widget pill(String label, AttendanceFilter f) {
              final selected = tempFilter == f;
              return GestureDetector(
                onTap: () => setModalState(() => tempFilter = f),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFFE8F2FF) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF007AFF)
                          : const Color(0xFFDFE4EA),
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: selected
                          ? const Color(0xFF007AFF)
                          : const Color(0xFF4B5563),
                    ),
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'More filters',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      pill('Late ($_lateCount)', AttendanceFilter.lateStaff),
                      pill('Early leaving ($_earlyLeavingCount)',
                          AttendanceFilter.earlyLeaving),
                      pill('Overtime ($_overtimeCount)',
                          AttendanceFilter.overtime),
                      pill('Half day ($_halfDayCount)',
                          AttendanceFilter.halfDay),
                      pill('All staff', AttendanceFilter.all),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00C29A),
                          ),
                          onPressed: () {
                            setState(() => _activeFilter = tempFilter);
                            Navigator.pop(context);
                          },
                          child: const Text('Apply filters'),
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

  // row for Live Attendance list
  Widget _liveStaffRow(Staff s) {
    final status = (s.status ?? '').toLowerCase();
    String statusText;
    Color bg;
    Color fg;

    final bool isOut = status == 'out';

    if (status == 'present' || status == 'in') {
      statusText = 'In';
      bg = const Color(0xFFE5F9EA);
      fg = const Color(0xFF0BB44B);
    } else if (isOut) {
      statusText = 'Out';
      bg = const Color(0xFFFFE5E5);
      fg = const Color(0xFFE53935);
    } else {
      statusText = 'No Punch In';
      bg = const Color(0xFFFFF1E5);
      fg = const Color(0xFFE67E22);
    }

    final time = isOut ? (s.punchOutTimeIst ?? '-') : (s.inTimeIst ?? '-');
    final address =
        isOut ? (s.punchOutAddress ?? '') : (s.punchInAddress ?? '');
    final photo = isOut ? (s.punchOutPhoto ?? s.punchInPhoto) : s.punchInPhoto;

    return Column(
      children: [
        ListTile(
          onTap: () => _openEditForStaff(s),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: Colors.grey[300],
            child: photo != null && photo.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      '$kBaseUrl$photo',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Text(
                        s.name.isNotEmpty ? s.name[0].toUpperCase() : 'A',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  )
                : Text(
                    s.name.isNotEmpty ? s.name[0].toUpperCase() : 'A',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
          ),
          title: Text(
            s.name,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            address,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 0),
      ],
    );
  }

  // row for Daily Attendance list
  Widget _dailyStaffRow(Staff s) {
    final status = (s.status ?? '').toLowerCase();

    final bool hasIn = status == 'in' ||
        status == 'late' ||
        status == 'early_leaving' ||
        status == 'out';

    final bool explicitAbsent = status == 'absent';
    final bool noPunch = status == 'no_punch_in';

    String statusText;
    Color bg;
    Color fg;

    if (hasIn && !explicitAbsent) {
      statusText = 'Present';
      bg = const Color(0xFFE5F9EA);
      fg = const Color(0xFF0BB44B);
    } else if (explicitAbsent) {
      statusText = 'Absent';
      bg = const Color(0xFFFFE5E5);
      fg = const Color(0xFFE53935);
    } else if (noPunch) {
      statusText = 'No Punch In';
      bg = const Color(0xFFFFF1E5);
      fg = const Color(0xFFE67E22);
    } else {
      statusText = 'No Punch In';
      bg = const Color(0xFFFFF1E5);
      fg = const Color(0xFFE67E22);
    }

    final hoursWorked = s.hoursWorked ?? '-';

    return Column(
      children: [
        InkWell(
          onTap: () => _openEditForStaff(s),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.grey[300],
                        child: Text(
                          s.name.isNotEmpty ? s.name[0].toUpperCase() : 'A',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          s.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    hoursWorked,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: fg,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 0),
      ],
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          'No records available for this filter',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[500],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
