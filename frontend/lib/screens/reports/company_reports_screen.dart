import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:share_plus/share_plus.dart'; // Ensure this is imported
import '../../api/reports_api_service.dart';
import '../../models/report_history.dart';
import 'report_filter_screen.dart';

class CompanyReportsScreen extends StatefulWidget {
  const CompanyReportsScreen({Key? key}) : super(key: key);

  @override
  State<CompanyReportsScreen> createState() => _CompanyReportsScreenState();
}

class _CompanyReportsScreenState extends State<CompanyReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ReportsApiService _reportsApi = ReportsApiService();

  // Primary Theme Colors
  static const Color primaryGreen = Color(0xFF206C5E);
  static const Color accentGreen = Color(0xFF2BA98A);
  static const Color surfaceColor = Colors.white;

  String _companyId = '';
  bool _isLoadingHistory = true;
  List<ReportHistory> _history = [];

  final Map<String, List<Map<String, dynamic>>> _reportCategories = {
    'Attendance': [
      {"name": "Daily Attendance Report", "icon": Icons.event_available},
      {"name": "Attendance Summary Report", "icon": Icons.summarize_outlined},
      {"name": "Detailed Attendance Report", "icon": Icons.list_alt},
      {"name": "Late Arrival Report", "icon": Icons.timer_outlined},
      {"name": "Leave Report", "icon": Icons.beach_access},
      {"name": "Overtime Report", "icon": Icons.more_time},
    ],
    'Payroll': [
      {"name": "Pay Slips", "icon": Icons.receipt_long},
      {"name": "Salary Sheet", "icon": Icons.table_view_rounded},
      {"name": "CTC Breakdown Report", "icon": Icons.account_tree_outlined},
      {"name": "Reimbursement Report", "icon": Icons.money_outlined},
    ],
    'Employee': [
      {"name": "Employee List Report", "icon": Icons.badge_outlined},
      {"name": "Employee Exit Report", "icon": Icons.exit_to_app},
    ]
  };

  String? _expandedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    final cId = prefs.getString('companyId');
    if (cId == null) return;
    setState(() => _companyId = cId);
    await _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final history = await _reportsApi.getReportHistory(_companyId);
      if (mounted) {
        setState(() {
          _history = history;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  void _navigateToFilterScreen(String category, String reportType) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportFilterScreen(
          companyId: _companyId,
          category: category,
          reportType: reportType,
        ),
      ),
    );
    if (result == true) {
      await _loadHistory();
      _tabController.animateTo(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: surfaceColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: primaryGreen, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Reports Center',
          style: TextStyle(
              color: Color(0xFF1A1C1E),
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryGreen,
          unselectedLabelColor: Colors.grey,
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(width: 3, color: primaryGreen),
            insets: EdgeInsets.symmetric(horizontal: 40),
          ),
          tabs: const [
            Tab(text: 'AVAILABLE'),
            Tab(text: 'HISTORY'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReportsTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionHeader("Operational Reports"),
        _buildCategoryCard('Attendance', Icons.calendar_month, primaryGreen),
        const SizedBox(height: 16),
        _buildSectionHeader("Financial Reports"),
        _buildCategoryCard('Payroll', Icons.account_balance_wallet_outlined,
            Colors.orange[800]!),
        const SizedBox(height: 16),
        _buildSectionHeader("Staff Management"),
        _buildCategoryCard(
            'Employee', Icons.groups_3_outlined, Colors.blue[800]!),
        const SizedBox(height: 16),
        _buildSectionHeader("Performance Tracking"),
        _buildNavigationCard(
          title: "Work Reports",
          icon: Icons.assignment_turned_in_outlined,
          color: Colors.purple[700]!,
          onTap: () {
            // Navigate to your specific Work Report screen here
            // Example: _navigateToWorkReportSummary();
          },
        ),
      ],
    );
  }

  Widget _buildNavigationCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        // SIDE ARROW ICON
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(title,
          style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1)),
    );
  }

  Widget _buildCategoryCard(String title, IconData icon, Color color) {
    final isExpanded = _expandedCategory == title;
    final subItems = _reportCategories[title] ?? [];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () =>
                setState(() => _expandedCategory = isExpanded ? null : title),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 24),
            ),
            title: Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more,
                color: Colors.grey),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: subItems.map((item) {
                  return ListTile(
                    contentPadding: const EdgeInsets.only(left: 72, right: 20),
                    title: Text(item['name'],
                        style:
                            TextStyle(color: Colors.grey[800], fontSize: 14)),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        size: 12, color: Colors.grey),
                    onTap: () => _navigateToFilterScreen(title, item['name']),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoadingHistory)
      return const Center(
          child: CircularProgressIndicator(color: primaryGreen));
    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_download_outlined,
                size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text("Your generated reports will appear here",
                style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final item = _history[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                      color: const Color(0xFFE7F3F1),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.description_outlined,
                      color: primaryGreen),
                ),
                title: Text(item.reportType,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: Text("${item.duration} • ${item.branch}",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _historyAction("Open", Icons.open_in_new,
                        () => _downloadAndOpenReport(item)),
                    Container(height: 20, width: 1, color: Colors.grey[200]),
                    _historyAction("Share", Icons.share_outlined,
                        () => _downloadAndShareReport(item)),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _historyAction(String label, IconData icon, VoidCallback onTap) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: primaryGreen),
      label: Text(label,
          style: const TextStyle(
              color: primaryGreen, fontWeight: FontWeight.w600)),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchReportDataForDownload({
    required String companyId,
    required String reportType,
    required String month,
    required String year,
    String? branch,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('token');

    String query =
        'companyId=$companyId&reportType=$reportType&month=$month&year=$year';

    if (branch != null) query += '&branch=$branch';

    const String baseUrl = 'http://10.80.210.30:5000';

    final url = Uri.parse('$baseUrl/api/reports/generate?$query');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);

      final List<dynamic> list = jsonResponse['data'] ?? [];

      return list.map((e) => e as Map<String, dynamic>).toList();
    } else {
      throw Exception('Failed to fetch report data');
    }
  }

  // Implementation of download logic (keep existing logic but update UI indicators)
  Future<void> _downloadAndOpenReport(ReportHistory item) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      String month = '1';

      String year = DateTime.now().year.toString();

      if (item.duration.contains('-')) {
        final parts = item.duration.split('-');

        if (parts.length >= 2) {
          month = parts[0];

          year = parts[1];
        }
      }

      final data = await _fetchReportDataForDownload(
        companyId: _companyId,
        reportType: item.reportType,
        month: month,
        year: year,
        branch: item.branch == "All Branches" ? null : item.branch,
      );

      if (data.isEmpty) {
        if (mounted) {
          Navigator.pop(context);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No data available for this report.")),
          );
        }

        return;
      }

      // 2. Create Excel File (Use alias here)

      var excel = excel_pkg.Excel.createExcel(); // ✅ FIXED

      excel_pkg.Sheet sheetObject = excel['Sheet1']; // ✅ FIXED

      List<String> headers = data.first.keys.toList();

      sheetObject.appendRow(
          headers.map((e) => excel_pkg.TextCellValue(e)).toList()); // ✅ FIXED

      for (var row in data) {
        List<excel_pkg.CellValue> rowData = headers.map((header) {
          // ✅ FIXED

          return excel_pkg.TextCellValue(
              row[header]?.toString() ?? ""); // ✅ FIXED
        }).toList();

        sheetObject.appendRow(rowData);
      }

      // 3. Save File

      var fileBytes = excel.save();

      final directory = await getApplicationDocumentsDirectory();

      final fileName =
          "${item.reportType.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.xlsx";

      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(fileBytes!);

      if (mounted) {
        Navigator.pop(context);

        final result = await OpenFile.open(file.path);

        if (result.type != ResultType.done) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Could not open file: ${result.message}")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error opening report: $e")),
        );
      }
    }
  }

  Future<void> _downloadAndShareReport(ReportHistory item) async {
    // 1. Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) =>
          const Center(child: CircularProgressIndicator(color: primaryGreen)),
    );

    try {
      // 2. Parse month and year from duration string (e.g., "1-2026")
      String month = '1';
      String year = DateTime.now().year.toString();
      if (item.duration.contains('-')) {
        final parts = item.duration.split('-');
        if (parts.length >= 2) {
          month = parts[0];
          year = parts[1];
        }
      }

      // 3. Fetch report data from your API
      final data = await _fetchReportDataForDownload(
        companyId: _companyId,
        reportType: item.reportType,
        month: month,
        year: year,
        branch: item.branch == "All Branches" ? null : item.branch,
      );

      if (data.isEmpty) {
        if (mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No data available to share.")),
        );
        return;
      }

      // 4. Generate the Excel file locally
      var excel = excel_pkg.Excel.createExcel();
      excel_pkg.Sheet sheetObject = excel['Sheet1'];
      List<String> headers = data.first.keys.toList();

      sheetObject
          .appendRow(headers.map((e) => excel_pkg.TextCellValue(e)).toList());

      for (var row in data) {
        List<excel_pkg.CellValue> rowData = headers.map((header) {
          return excel_pkg.TextCellValue(row[header]?.toString() ?? "");
        }).toList();
        sheetObject.appendRow(rowData);
      }

      // 5. Save to a temporary file
      var fileBytes = excel.save();
      final tempDir = await getTemporaryDirectory();
      final fileName =
          "${item.reportType.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.xlsx";
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(fileBytes!);

      // 6. Close loader and trigger native share sheet
      if (mounted) {
        Navigator.pop(context); // Close the loading dialog

        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Attendance Report: ${item.reportType} (${item.duration})',
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint("Share Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Error preparing share: $e"),
            backgroundColor: Colors.red),
      );
    }
  }
}
