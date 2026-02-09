import 'package:flutter/material.dart';
import '../../api/announcement_api_service.dart';
import '../../models/announcement_model.dart';
import 'package:intl/intl.dart';

class EmployeeAnnouncementScreen extends StatefulWidget {
  const EmployeeAnnouncementScreen({Key? key}) : super(key: key);

  @override
  State<EmployeeAnnouncementScreen> createState() =>
      _EmployeeAnnouncementScreenState();
}

class _EmployeeAnnouncementScreenState
    extends State<EmployeeAnnouncementScreen> {
  List<AnnouncementItem> _allAnnouncements = [];
  List<AnnouncementItem> _filteredAnnouncements = [];
  bool _isLoading = true;
  String _searchQuery = '';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    try {
      setState(() => _isLoading = true);
      final data = await AnnouncementApiService.getCompanyAnnouncements();
      final list = data
          .map<AnnouncementItem>((json) => AnnouncementItem.fromJson(json))
          .toList();

      setState(() {
        _allAnnouncements = list;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredAnnouncements = _allAnnouncements.where((item) {
        final matchesSearch = item.title
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            item.description.toLowerCase().contains(_searchQuery.toLowerCase());

        bool matchesDate = true;
        if (_selectedDate != null) {
          matchesDate = item.createdAt.year == _selectedDate!.year &&
              item.createdAt.month == _selectedDate!.month &&
              item.createdAt.day == _selectedDate!.day;
        }
        return matchesSearch && matchesDate;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Modern soft background
      appBar: AppBar(
        title: const Text("Announcements",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredAnnouncements.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadAnnouncements,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: _filteredAnnouncements.length,
                          itemBuilder: (context, index) => _AnnouncementCard(
                              announcement: _filteredAnnouncements[index]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            onChanged: (val) {
              _searchQuery = val;
              _applyFilters();
            },
            decoration: InputDecoration(
              hintText: "Search updates...",
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2023),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _selectedDate = date);
                      _applyFilters();
                    }
                  },
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(_selectedDate == null
                      ? "Filter by Date"
                      : DateFormat('dd MMM yyyy').format(_selectedDate!)),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    foregroundColor: Colors.blueGrey,
                  ),
                ),
              ),
              if (_selectedDate != null || _searchQuery.isNotEmpty)
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedDate = null;
                      _searchQuery = '';
                    });
                    _applyFilters();
                  },
                  icon: const Icon(Icons.clear_all, color: Colors.redAccent),
                )
            ],
          ),
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
          const Text("No announcements found",
              style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final AnnouncementItem announcement;
  const _AnnouncementCard({required this.announcement});

  @override
  Widget build(BuildContext context) {
    // Professional color palette
    const Color primaryBlue = Color(0xFF2563EB);
    const Color pinnedAmber = Color(0xFFD97706);
    final Color accentColor = announcement.isPinned ? pinnedAmber : primaryBlue;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Left Accent Decorative Stripe
              Container(
                width: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [accentColor, accentColor.withOpacity(0.5)],
                  ),
                ),
              ),

              // 2. Main Content Area
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Header Bar
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      color: accentColor.withOpacity(0.05),
                      child: Row(
                        children: [
                          Icon(
                            announcement.isPinned
                                ? Icons.push_pin_rounded
                                : Icons.campaign_rounded,
                            size: 16,
                            color: accentColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            announcement.isPinned
                                ? "PRIORITY UPDATE"
                                : "NEW ANNOUNCEMENT",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                              color: accentColor,
                            ),
                          ),
                          const Spacer(),
                          // Time with AM/PM IST
                          Text(
                            announcement
                                .formattedDate, // Uses your getter with AM/PM
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[500],
                            ),
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
                            announcement.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            announcement.description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF475569),
                              height: 1.6,
                            ),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 20),

                          // Footer Row
                          Row(
                            children: [
                              // Author Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.account_circle_outlined,
                                        size: 14, color: Colors.blueGrey),
                                    const SizedBox(width: 6),
                                    Text(
                                      announcement.createdByName ?? 'Admin',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              // Target Scope Badge
                              Row(
                                children: [
                                  Icon(Icons.layers_outlined,
                                      size: 14, color: Colors.grey[400]),
                                  const SizedBox(width: 4),
                                  Text(
                                    announcement.isAllBranches
                                        ? "Global"
                                        : "Branch Specific",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
