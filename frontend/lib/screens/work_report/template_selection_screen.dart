import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/work_report_api_service.dart';
import 'report_form_screen.dart';

class TemplateSelectionScreen extends StatefulWidget {
  final String employeeId;
  final String companyId;
  final DateTime date;

  const TemplateSelectionScreen({
    Key? key,
    required this.employeeId,
    required this.companyId,
    required this.date,
  }) : super(key: key);

  @override
  State<TemplateSelectionScreen> createState() =>
      _TemplateSelectionScreenState();
}

class _TemplateSelectionScreenState extends State<TemplateSelectionScreen> {
  final WorkReportApiService _api = WorkReportApiService();
  bool _isLoading = true;
  List<dynamic> _templates = [];
  Map<String, dynamic>? _existingDayReport;

  // Theme Colors
  final Color primaryGreen = const Color(0xFF059669);
  final Color accentSlate = const Color(0xFF1E293B);
  final Color bgGrey = const Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkTemplates();
  }

  Future<void> _loadData() async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(widget.date);
      // Fetch both in parallel
      final results = await Future.wait([
        _api.getTemplatesForEmployee(widget.employeeId),
        _api.getDayReport(widget.employeeId, dateStr),
      ]);

      setState(() {
        _templates = results[0] as List<dynamic>;
        _existingDayReport = results[1] as Map<String, dynamic>?;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _checkTemplates() async {
    try {
      final templates = await _api.getTemplatesForEmployee(widget.employeeId);
      if (!mounted) return;

      if (templates.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("No report template assigned to your department.")),
        );
        Navigator.pop(context);
      } else if (templates.length == 1) {
        // Redirect immediately if only one template exists
        _navigateToForm(templates[0]);
      } else {
        setState(() {
          _templates = templates;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }
  }

  void _navigateToForm(dynamic template,
      {List<dynamic>? existingEntries}) async {
    // Use await here to wait for the Form to finish
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportFormScreen(
          template: template,
          employeeId: widget.employeeId,
          companyId: widget.companyId,
          date: widget.date,
          initialEntries: existingEntries,
        ),
      ),
    );

    // After the form is closed, go back to the calendar
    if (mounted) {
      Navigator.pop(context, true); // Send 'true' back to the calendar
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: accentSlate),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          "Report Configuration",
          style: TextStyle(
              color: accentSlate, fontWeight: FontWeight.w900, fontSize: 16),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                  color: primaryGreen, strokeWidth: 3))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeHeader(),
                const SizedBox(height: 10),
                Expanded(
                  child: Stack(
                    children: [
                      // Subtle Watermark
                      Positioned(
                        bottom: -20,
                        right: -20,
                        child: Icon(Icons.assignment_turned_in_rounded,
                            size: 200, color: primaryGreen.withOpacity(0.03)),
                      ),
                      ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: _templates.length,
                        itemBuilder: (context, index) {
                          final t = _templates[index];

                          // Check if this specific template was used today
                          bool isSubmitted = _existingDayReport != null &&
                              _existingDayReport!['templateId'] == t['_id'];

                          if (isSubmitted) {
                            return _buildSubmittedPreviewCard(
                                t, _existingDayReport!);
                          } else {
                            return _buildTemplateCard(t);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSubmittedPreviewCard(
      dynamic template, Map<String, dynamic> report) {
    int entryCount = (report['entries'] as List).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      // FIX 1: Add clipBehavior to ensure children don't bleed over rounded edges
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: primaryGreen.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: primaryGreen,
              child: const Icon(Icons.check, color: Colors.white, size: 20),
            ),
            title: Text(template['title'],
                style:
                    TextStyle(color: accentSlate, fontWeight: FontWeight.bold)),
            subtitle: Text("$entryCount entries submitted",
                style: TextStyle(
                    color: primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
            trailing: IconButton(
              icon: Icon(Icons.edit_note_rounded, color: accentSlate, size: 28),
              onPressed: () =>
                  _navigateToForm(template, existingEntries: report['entries']),
            ),
          ),
          // Mini Preview Section
          if (report['entries'].isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bgGrey,
                // FIX 2: Ensure the internal grey box also matches the parent's bottom radius
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(Icons.history,
                      size: 14, color: accentSlate.withOpacity(0.5)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Last entry: ${report['entries'].last['data'][0]['value']}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w700,
                          color: accentSlate.withOpacity(0.7)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Select Report Type",
            style: TextStyle(
                color: accentSlate, fontSize: 14, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            "Choose the most relevant template for your update.",
            style: TextStyle(
                color: accentSlate.withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(dynamic t) {
    // Determine if it's global or department specific
    final bool isGlobal = t['isForAllDepartments'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      // Ensures rounded corners are not cut/bleeding
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _navigateToForm(t),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon Box with dynamic color based on type
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isGlobal
                          ? [
                              Colors.blue.withOpacity(0.1),
                              Colors.blue.withOpacity(0.05)
                            ]
                          : [
                              primaryGreen.withOpacity(0.1),
                              primaryGreen.withOpacity(0.05)
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                      isGlobal
                          ? Icons.public_rounded
                          : Icons.business_center_rounded,
                      color: isGlobal ? Colors.blueAccent : primaryGreen,
                      size: 24),
                ),
                const SizedBox(width: 18),
                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t['title'] ?? "Standard Report",
                        style: TextStyle(
                            color: accentSlate,
                            fontWeight: FontWeight.w800,
                            fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      // DYNAMIC LABEL BASED ON SCHEMA
                      Text(
                        isGlobal ? "GLOBAL TEMPLATE" : "DEPARTMENT SPECIFIC",
                        style: TextStyle(
                            color: isGlobal ? Colors.blueAccent : primaryGreen,
                            fontWeight: FontWeight.w900,
                            fontSize: 9,
                            letterSpacing: 0.8),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: accentSlate.withOpacity(0.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
