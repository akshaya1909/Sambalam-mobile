import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../services/employee_service.dart';
import 'background_verification_screen.dart'; // Import detailed screen

class VerificationStaffListScreen extends StatefulWidget {
  final String companyId;
  final String userId; // Current logged in admin ID (needed for next screen)

  const VerificationStaffListScreen({
    Key? key,
    required this.companyId,
    required this.userId,
  }) : super(key: key);

  @override
  _VerificationStaffListScreenState createState() =>
      _VerificationStaffListScreenState();
}

class _VerificationStaffListScreenState
    extends State<VerificationStaffListScreen> {
  final EmployeeService _api = EmployeeService();
  List<Map<String, dynamic>> _staffList = [];
  List<Map<String, dynamic>> _filteredList = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchStaff();
  }

  Future<void> _fetchStaff() async {
    try {
      final data = await _api.getCompanyVerificationSummary(widget.companyId);
      setState(() {
        _staffList = data;
        _filteredList = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Handle error
    }
  }

  void _filterStaff(String query) {
    setState(() {
      _filteredList = _staffList
          .where((s) =>
              s['name'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F2937), // Dark header like image
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Verification Staff List",
            style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: _filterStaff,
                  decoration: InputDecoration(
                    hintText: "Search staff by name",
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Showing ${_filteredList.length} staff",
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    itemCount: _filteredList.length,
                    separatorBuilder: (ctx, i) =>
                        const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    itemBuilder: (ctx, index) {
                      final staff = _filteredList[index];
                      return ListTile(
                        tileColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: _getAvatarColor(index),
                          child: Text(
                            _getInitials(staff['name']),
                            style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                          ),
                        ),
                        title: Text(staff['name'],
                            style:
                                const TextStyle(fontWeight: FontWeight.w500)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildStatusBadge(staff['status']),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                        onTap: () {
                          // Navigate to Detail Screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  BackgroundVerificationScreen(
                                userId: widget.userId,
                                employeeId: staff[
                                    '_id'], // Pass the clicked employee's ID
                                companyId: widget.companyId,
                              ),
                            ),
                          ).then((_) =>
                              _fetchStaff()); // Refresh list when coming back
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;
    String text;

    switch (status) {
      case 'Verified':
        color = Colors.green;
        icon = Icons.check_circle;
        text = "Verified";
        break;
      case 'Pending':
        color = Colors.blue;
        icon = Icons.access_time_filled;
        text = "Pending";
        break;
      default:
        color = Colors.red;
        icon = Icons.error; // Using error icon for exclamation mark look
        text = "Not Started";
    }

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
              color: color, fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return "";
    List<String> parts = name.trim().split(" ");
    if (parts.length > 1) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Color _getAvatarColor(int index) {
    final colors = [
      Colors.green.shade100,
      Colors.purple.shade100,
      Colors.orange.shade100,
      Colors.blue.shade100,
      Colors.teal.shade100,
    ];
    return colors[index % colors.length];
  }
}
