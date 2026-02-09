import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/announcement_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/announcement_model.dart';

class EmployeeNotificationsScreen extends StatefulWidget {
  final String companyId;
  const EmployeeNotificationsScreen({Key? key, required this.companyId})
      : super(key: key);

  @override
  State<EmployeeNotificationsScreen> createState() =>
      _EmployeeNotificationsScreenState();
}

class _EmployeeNotificationsScreenState
    extends State<EmployeeNotificationsScreen> {
  List<AnnouncementItem> _allAnnouncements = [];
  List<AnnouncementItem> _filteredItems = [];
  bool _isLoading = true;

  // Categories
  final List<String> _categories = [
    "All Notifications",
    "Announcement",
    "Attendance",
    "Leave Request",
    "Notes"
  ];

  String _selectedCategory = "All Notifications";

  // Theme Colors
  final Color _primaryStart = const Color(0xFF1769AA);
  final Color _primaryEnd = const Color(0xFF00BFA5);

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      setState(() => _isLoading = true);
      // Fetching announcements from your API
      final data = await AnnouncementApiService.getCompanyAnnouncements();
      final items = data
          .map<AnnouncementItem>(
              (json) => AnnouncementItem.fromJson(json as Map<String, dynamic>))
          .toList();

      setState(() {
        _allAnnouncements = items;
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error fetching data: $e');
    }
  }

  void _applyFilter() {
    setState(() {
      if (_selectedCategory == "All Notifications" ||
          _selectedCategory == "Announcement") {
        // Since we are currently only fetching announcements,
        // both 'All' and 'Announcement' show the same list.
        _filteredItems = _allAnnouncements;
      } else {
        // Other categories are empty for now as they require different API calls
        _filteredItems = [];
      }
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = "All Notifications";
      _applyFilter();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Notifications',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryStart, _primaryEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredItems.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _fetchData,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredItems.length,
                          itemBuilder: (context, index) =>
                              _buildAnnouncementCard(_filteredItems[index]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          // Dropdown for Categories
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  icon: const Icon(Icons.filter_list,
                      size: 20, color: Colors.blueGrey),
                  style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedCategory = newValue;
                        _applyFilter();
                      });
                    }
                  },
                  items:
                      _categories.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Reset Button
          TextButton.icon(
            onPressed: _resetFilters,
            icon: const Icon(Icons.restart_alt,
                size: 18, color: Colors.redAccent),
            label: const Text("Reset",
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              backgroundColor: Colors.redAccent.withOpacity(0.05),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(AnnouncementItem item) {
    Color typeColor = Colors.blue;
    if (item.isPinned) typeColor = Colors.orange;

    return GestureDetector(
      onTap: () async {
        // 1. Get current User ID from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('userId');

        if (userId != null) {
          // 2. Update Backend
          await AnnouncementApiService.markAsRead(item.id, userId);

          // 3. Show full detail or just update UI locally if needed
          _showDetailDialog(item);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(
                    item.isPinned
                        ? Icons.push_pin_rounded
                        : Icons.campaign_rounded,
                    size: 18,
                    color: typeColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.isPinned ? "PINNED ANNOUNCEMENT" : "OFFICIAL NOTICE",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: typeColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    item.formattedDate,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.description,
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF475569), height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        "- From ${item.createdByName ?? 'Admin'}",
                        style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailDialog(AnnouncementItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.title),
        content: Text(item.description),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"))
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded,
              size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("No notifications for $_selectedCategory",
              style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
