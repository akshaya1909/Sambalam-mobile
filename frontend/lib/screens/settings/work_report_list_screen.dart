import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/work_report_api_service.dart';
import 'work_report_settings_screen.dart';

class WorkReportListScreen extends StatefulWidget {
  const WorkReportListScreen({Key? key}) : super(key: key);

  @override
  State<WorkReportListScreen> createState() => _WorkReportListScreenState();
}

class _WorkReportListScreenState extends State<WorkReportListScreen> {
  final WorkReportApiService _api = WorkReportApiService();
  List<dynamic> _templates = [];
  bool _isLoading = true;

  // Professional Theme Colors
  final Color primaryGreen = const Color(0xFF206C5E);
  final Color accentGreen = const Color(0xFF2BA98A);
  final Color surfaceColor = const Color(0xFFF8FAFC);
  final Color textDark = const Color(0xFF1E293B);
  final Color textLight = const Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _fetchTemplates();
  }

  Future<void> _fetchTemplates() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final companyId = prefs.getString('companyId') ?? '';

    try {
      final data = await _api.getTemplates(companyId);
      if (mounted) {
        setState(() {
          _templates = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingState()
          : RefreshIndicator(
              onRefresh: _fetchTemplates,
              color: primaryGreen,
              child: _templates.isEmpty
                  ? _buildEmptyState()
                  : _buildTemplateList(),
            ),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: Colors.white),
      title: const Text(
        "Report Templates",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 18,
          letterSpacing: 0.5,
        ),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primaryGreen, accentGreen],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
        strokeWidth: 3,
      ),
    );
  }

  Widget _buildTemplateList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      itemCount: _templates.length,
      itemBuilder: (context, index) => _buildTemplateCard(_templates[index]),
    );
  }

  Widget _buildTemplateCard(dynamic t) {
    bool isGlobal = t['isForAllDepartments'] ?? false;
    List fields = t['fields'] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // Top Status Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: isGlobal
                  ? primaryGreen.withOpacity(0.05)
                  : Colors.blue.withOpacity(0.05),
              child: Row(
                children: [
                  Icon(
                    isGlobal
                        ? Icons.public_rounded
                        : Icons.corporate_fare_rounded,
                    size: 16,
                    color: isGlobal ? primaryGreen : Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isGlobal ? "GLOBAL TEMPLATE" : "DEPARTMENT SPECIFIC",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: isGlobal ? primaryGreen : Colors.blue,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  _cardActionButton(Icons.edit_note_rounded, Colors.blue, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorkReportSettingsScreen(template: t),
                      ),
                    ).then((_) => _fetchTemplates());
                  }),
                  const SizedBox(width: 12),
                  _cardActionButton(Icons.delete_sweep_rounded,
                      Colors.redAccent, () => _confirmDelete(t['_id'])),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: CrossFadeList(
                children: [
                  // Title Section
                  Text(
                    isGlobal
                        ? "Standard Company Report"
                        : "Custom Departmental Report",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isGlobal
                        ? "Active for all staff members"
                        : "Departments: ${t['departmentIds'].map((d) => d['name']).join(', ')}",
                    style:
                        TextStyle(fontSize: 13, color: textLight, height: 1.4),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Divider(height: 1, thickness: 0.5),
                  ),

                  // Fields Section
                  Row(
                    children: [
                      Text(
                        "STRUCTURE",
                        style: TextStyle(
                          fontSize: 10,
                          color: textLight,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        "${fields.length} Fields",
                        style: TextStyle(
                            fontSize: 10,
                            color: primaryGreen,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        fields.map((f) => _fieldChip(f['label'])).toList(),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textDark.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _cardActionButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 22, color: color.withOpacity(0.8)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryGreen.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.assignment_add,
                  size: 64, color: primaryGreen.withOpacity(0.2)),
            ),
            const SizedBox(height: 24),
            Text(
              "No templates yet",
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: textDark),
            ),
            const SizedBox(height: 12),
            Text(
              "Create your first work report template to start tracking daily activities.",
              textAlign: TextAlign.center,
              style: TextStyle(color: textLight, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      backgroundColor: primaryGreen,
      elevation: 4,
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WorkReportSettingsScreen()),
      ).then((_) => _fetchTemplates()),
      label: const Text(
        "NEW TEMPLATE",
        style: TextStyle(
            letterSpacing: 1, fontWeight: FontWeight.w900, color: Colors.white),
      ),
      icon: const Icon(Icons.add_rounded, color: Colors.white),
    );
  }

  void _confirmDelete(String id) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 24),
            const Icon(Icons.warning_amber_rounded,
                color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text("Delete Template?",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textDark)),
            const SizedBox(height: 12),
            Text(
              "Employees assigned to this template will no longer be able to submit their reports using this format.",
              textAlign: TextAlign.center,
              style: TextStyle(color: textLight, height: 1.5),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Cancel",
                        style: TextStyle(
                            color: textLight, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () async {
                      if (await _api.deleteTemplate(id)) {
                        Navigator.pop(context);
                        _fetchTemplates();
                      }
                    },
                    child: const Text("Delete",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// Helper Widget for neat spacing
class CrossFadeList extends StatelessWidget {
  final List<Widget> children;
  const CrossFadeList({Key? key, required this.children}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
