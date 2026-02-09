import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'new_announcement_screen.dart';
import '../../api/announcement_api_service.dart';
import '../../models/announcement_model.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({Key? key}) : super(key: key);

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  List<AnnouncementItem> _announcements = [];
  List<AnnouncementItem> _allAnnouncements = []; // Master list
  List<AnnouncementItem> _filteredAnnouncements = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _canSend = false;

  String _searchQuery = '';
  DateTimeRange? _selectedDateRange;
  String? _selectedBranch; // Store Branch ID
  List<String> _availableBranches = ['All Branches'];

  @override
  void initState() {
    super.initState();
    _loadPermissions();
    _loadAnnouncements();
  }

  Future<void> _loadPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final adminId = prefs.getString('adminId'); // null for employees
    // final role = prefs.getString('role');         // 'admin' / 'manager' / 'employee' ...

    setState(() {
      // Only admins / managers etc. can send, employees cannot
      // _canSend = adminId != null && role != null && role != 'employee';
      _canSend = adminId != null;
    });
  }

  Future<void> _loadAnnouncements() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final data = await AnnouncementApiService.getCompanyAnnouncements();
      final list = data
          .map<AnnouncementItem>((json) => AnnouncementItem.fromJson(json))
          .toList();

      setState(() {
        _allAnnouncements = list;
        // Extract unique branch names for the filter dropdown
        _availableBranches = [
          'All Branches',
          ...list
              .expand((e) => e.targetBranches.map((b) => b['name'].toString()))
              .toSet()
        ];
        _applyFilters(); // Initial filter apply
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredAnnouncements = _allAnnouncements.where((item) {
        // 1. Search Filter (Remains the same)
        final matchesSearch = item.title
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            item.description.toLowerCase().contains(_searchQuery.toLowerCase());

        // 2. Date Filter (Remains the same)
        bool matchesDate = true;
        if (_selectedDateRange != null) {
          matchesDate = item.createdAt.isAfter(_selectedDateRange!.start) &&
              item.createdAt.isBefore(
                  _selectedDateRange!.end.add(const Duration(days: 1)));
        }

        // 3. STRICT Branch Filter
        bool matchesBranch = true;
        if (_selectedBranch != null && _selectedBranch != 'All Branches') {
          // Changed: Removed 'item.isAllBranches ||'
          // Now only shows items where the specific branch name exists in the target list
          matchesBranch =
              item.targetBranches.any((b) => b['name'] == _selectedBranch);
        }

        return matchesSearch && matchesDate && matchesBranch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color topBarColor = Color(0xFF232B2F);

    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7F9), // Light grey background for contrast
      appBar: AppBar(
        backgroundColor: topBarColor,
        elevation: 0,
        title: const Text('Announcements'),
      ),
      body: Column(
        children: [
          _buildFilterBar(), // Sticky Filter Bar at top
          Expanded(child: _buildListArea()),
        ],
      ),
      floatingActionButton: _canSend ? _buildFab() : null,
    );
  }

  Widget _buildListArea() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_filteredAnnouncements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const Text('No announcements match your filters'),
            TextButton(
                onPressed: () => _loadAnnouncements(),
                child: const Text('Reset All'))
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAnnouncements,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredAnnouncements.length,
        itemBuilder: (context, index) {
          return _buildAnnouncementCard(_filteredAnnouncements[index]);
        },
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: const Color(0xFF232B2F),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          // Search Bar
          TextField(
            onChanged: (val) {
              _searchQuery = val;
              _applyFilters();
            },
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search announcements...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Date Filter Chip
              Expanded(
                child: ActionChip(
                  avatar: const Icon(Icons.calendar_today,
                      size: 16, color: Colors.black),
                  label: Text(
                    _selectedDateRange == null ? 'Date Range' : 'Filtered Date',
                    style:
                        const TextStyle(color: Colors.blueGrey, fontSize: 12),
                  ),
                  backgroundColor: Colors.white.withOpacity(0.1),
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _selectedDateRange = picked);
                      _applyFilters();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Branch Dropdown Filter
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    // Change color if a specific branch is selected
                    color: (_selectedBranch != null &&
                            _selectedBranch != 'All Branches')
                        ? Colors.blueAccent.withOpacity(0.2)
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (_selectedBranch != null &&
                              _selectedBranch != 'All Branches')
                          ? Colors.blueAccent
                          : Colors.transparent,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedBranch ?? 'All Branches',
                      dropdownColor: const Color(0xFF232B2F),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      isExpanded: true,
                      onChanged: (val) {
                        setState(() => _selectedBranch = val);
                        _applyFilters();
                      },
                      items: _availableBranches
                          .map(
                              (b) => DropdownMenuItem(value: b, child: Text(b)))
                          .toList(),
                    ),
                  ),
                ),
              ),
              if (_selectedDateRange != null ||
                  (_selectedBranch != null &&
                      _selectedBranch != 'All Branches'))
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.redAccent),
                  onPressed: () {
                    setState(() {
                      _selectedDateRange = null;
                      _selectedBranch = 'All Branches';
                      _searchQuery = '';
                    });
                    _applyFilters();
                  },
                )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Failed to load announcements',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(_errorMessage, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadAnnouncements,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_announcements.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadAnnouncements,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _announcements.length,
        itemBuilder: (context, index) {
          final announcement = _announcements[index];
          return _buildAnnouncementCard(announcement);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.campaign_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'No announcements yet',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF4B5563),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the + button to create your\nfirst announcement.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(AnnouncementItem announcement) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Title + Pinned badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title on the left
                Expanded(
                  child: Text(
                    announcement.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Right side: CreatedBy and time + optional PINNED
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // DateTime chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        announcement.formattedDate,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    if (announcement.isPinned) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'PINNED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              announcement.description,
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF4B5563),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // Footer: Branches only in left, remove the right-side author/time here
            Row(
              children: [
                // Branches
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.business_outlined,
                          size: 16, color: Color(0xFF9CA3AF)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          announcement.branchText,
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF6B7280)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Created by: ${announcement.createdByName ?? 'Unknown'}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Stats row
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatChip(
                    '👁️ ${announcement.totalViews}', Colors.blue[100]),
                const SizedBox(width: 8),
                _buildStatChip(
                    '📖 ${announcement.totalReads}', Colors.green[100]),
                const SizedBox(width: 8),
                // New: time chip next to stats
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    announcement.formattedDateTime,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: announcement.status == 'published'
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    announcement.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: announcement.status == 'published'
                          ? Colors.green[700]
                          : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String text, Color? backgroundColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildFab() {
    // Define your theme colors locally for clarity
    const Color primaryGreen = Color(0xFF206C5E);
    const Color primaryGradientEnd = Color(0xFF2BA98A);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const NewAnnouncementScreen()),
          );
          if (result == true) {
            _loadAnnouncements(); // Refresh on success
          }
        },
        child: Container(
          height: 56, // Standard height for an extended FAB
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28), // Fully rounded corners
            gradient: const LinearGradient(
              colors: [primaryGreen, primaryGradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryGreen.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min, // Shrink to fit content
            children: const [
              Icon(Icons.add, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Text(
                'Send Announcement',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
