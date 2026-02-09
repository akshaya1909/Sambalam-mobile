import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/reports_api_service.dart';
import '../../api/company_api_service.dart';
import '../../models/branch_model.dart';
import '../../models/department_model.dart';

class ReportFilterScreen extends StatefulWidget {
  final String companyId;
  final String category;
  final String reportType;

  const ReportFilterScreen(
      {Key? key,
      required this.companyId,
      required this.category,
      required this.reportType})
      : super(key: key);

  @override
  State<ReportFilterScreen> createState() => _ReportFilterScreenState();
}

class _ReportFilterScreenState extends State<ReportFilterScreen> {
  final ReportsApiService _reportsApi = ReportsApiService();
  final CompanyApiService _companyApi = CompanyApiService();

  static const Color primaryGreen = Color(0xFF206C5E);
  static const Color accentGreen = Color(0xFF2BA98A);

  bool _isLoading = true;
  bool _isGenerating = false;
  String? _selectedBranch;
  String? _selectedDepartment;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadFilterData();
  }

  Future<void> _loadFilterData() async {
    try {
      final results = await Future.wait([
        _companyApi.getCompanyBranches(companyId: widget.companyId),
        _companyApi.getCompanyDepartments(companyId: widget.companyId),
      ]);
      if (mounted) {
        setState(() {
          _branches = results[0] as List<Branch>;
          _departments = results[1] as List<Department>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Branch> _branches = [];
  List<Department> _departments = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black87),
            onPressed: () => Navigator.pop(context)),
        title: Text("Configure Report",
            style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryGreen))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoBanner(),
                        const SizedBox(height: 32),
                        _sectionLabel("WORK LOCATION"),
                        _customDropdown(
                          hint: "All Branches",
                          value: _selectedBranch,
                          items: _branches
                              .map((b) => DropdownMenuItem(
                                  value: b.id, child: Text(b.name)))
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedBranch = val),
                        ),
                        const SizedBox(height: 24),
                        _sectionLabel("DEPARTMENT"),
                        _customDropdown(
                          hint: "All Departments",
                          value: _selectedDepartment,
                          items: _departments
                              .map((d) => DropdownMenuItem(
                                  value: d.id, child: Text(d.name)))
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedDepartment = val),
                        ),
                        const SizedBox(height: 24),
                        _sectionLabel("DATE RANGE"),
                        _datePickerContainer(),
                        const SizedBox(height: 32),
                        _formatSelector(),
                      ],
                    ),
                  ),
                ),
                _bottomActionButton(),
              ],
            ),
    );
  }

  Widget _infoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: primaryGreen.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryGreen.withOpacity(0.1))),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: primaryGreen, size: 20),
          const SizedBox(width: 12),
          Expanded(
              child: Text(widget.reportType,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                      fontSize: 14))),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.grey,
              letterSpacing: 1.2)),
    );
  }

  Widget _customDropdown(
      {required String hint,
      required String? value,
      required List<DropdownMenuItem<String>> items,
      required ValueChanged<String?> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(hint,
              style: const TextStyle(color: Colors.grey, fontSize: 14)),
          items: [DropdownMenuItem(value: null, child: Text(hint)), ...items],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _datePickerContainer() {
    return InkWell(
      onTap: _selectDateRange,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!)),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_outlined,
                color: primaryGreen, size: 20),
            const SizedBox(width: 12),
            Text(
                "${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}",
                style: const TextStyle(fontWeight: FontWeight.w500)),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _formatSelector() {
    return Row(
      children: [
        _formatChip("XLS (Excel)", true),
        const SizedBox(width: 12),
        _formatChip("PDF", false),
      ],
    );
  }

  Widget _formatChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? primaryGreen : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: isSelected ? primaryGreen : Colors.grey[300]!),
      ),
      child: Text(label,
          style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[600],
              fontWeight: FontWeight.bold,
              fontSize: 12)),
    );
  }

  Widget _bottomActionButton() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5))
      ]),
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(colors: [primaryGreen, accentGreen]),
        ),
        child: ElevatedButton(
          onPressed: _isGenerating ? null : _generateReport,
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16))),
          child: _isGenerating
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Text("Generate Report",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
        ),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        initialDateRange: DateTimeRange(start: _startDate, end: _endDate));
    if (picked != null)
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
  }

  Future<void> _generateReport() async {
    setState(() => _isGenerating = true);
    try {
      await _reportsApi.generateReport(
          companyId: widget.companyId,
          reportType: widget.reportType,
          month: _startDate.month.toString(),
          year: _startDate.year.toString(),
          branch: _selectedBranch,
          department: _selectedDepartment);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _isGenerating = false);
    }
  }
}
