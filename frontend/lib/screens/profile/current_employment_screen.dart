import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../api/employee_api_service.dart';

class CurrentEmploymentScreen extends StatefulWidget {
  final String employeeId;

  const CurrentEmploymentScreen({Key? key, required this.employeeId})
      : super(key: key);

  @override
  State<CurrentEmploymentScreen> createState() =>
      _CurrentEmploymentScreenState();
}

class _CurrentEmploymentScreenState extends State<CurrentEmploymentScreen> {
  final _api = EmployeeApiService();
  bool _isLoading = true;
  bool _hasError = false;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final profile =
          await _api.getEmployeeProfileById(employeeId: widget.employeeId);
      if (mounted) {
        setState(() {
          _data = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color bg = Color(0xFFF8FAFC); // Light background

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black87, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Current Employment',
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(
                  child: Text('Failed to load details',
                      style: GoogleFonts.inter()))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildSectionCard(
                        title: 'Work Information',
                        children: [
                          _DetailRow(
                              label: 'Branch Name', value: _data['branches']),
                          _DetailRow(
                              label: 'Department', value: _data['departments']),
                          _DetailRow(
                              label: 'Job Title', value: _data['jobTitle']),
                          _DetailRow(
                              label: 'Employee Type',
                              value: _data['employeeType']),
                          _DetailRow(
                              label: 'Date of Joining',
                              value: _data['dateOfJoining']),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildSectionCard(
                        title: 'Official Documents',
                        children: [
                          _DetailRow(
                              label: 'Employee ID',
                              value: _data['employeeCode']),
                          _DetailRow(
                              label: 'Official Email',
                              value: _data['officialEmail']),
                          _DetailRow(
                              label: 'PF Number', value: _data['pfNumber']),
                          _DetailRow(
                              label: 'ESI Number', value: _data['esiNumber']),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSectionCard(
      {required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String? value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final displayValue =
        (value == null || value!.trim().isEmpty) ? '-' : value!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF64748B), // Slate 500
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              displayValue,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF334155), // Slate 700
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
