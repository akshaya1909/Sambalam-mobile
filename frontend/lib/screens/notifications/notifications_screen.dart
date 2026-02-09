import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/notification_api.dart';
import '../../api/company_api_service.dart'; // To fetch employees
import '../../models/notification_model.dart';
import '../../models/staff_model.dart';
import '../help/help_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationApiService _api = NotificationApiService();
  final CompanyApiService _companyApi = CompanyApiService();
  static const Color _primary = Color(0xFF206C5E);

  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String _companyId = '';

  // Filters
  String _selectedType = "All Notifications";
  Staff? _selectedEmployee; // If null, "All Employees"

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    _companyId = prefs.getString('companyId') ?? '';

    if (_companyId.isNotEmpty) {
      try {
        final data = await _api.getNotifications(
          companyId: _companyId,
          type: _selectedType,
          employeeId:
              _selectedEmployee?.id, // Assuming Staff model has 'id' or '_id'
        );
        setState(() {
          _notifications = data;
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openMap(double lat, double lng) async {
    final googleMapsUrl =
        Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Could not open maps")));
    }
  }

  // --- UI COMPONENTS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notifications',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const HelpScreen(), // Ensure HelpScreen is defined
                ),
              );
            },
            icon: const Icon(Icons.help_outline, size: 16),
            label: const Text("Help"),
            style: TextButton.styleFrom(foregroundColor: _primary),
          )
        ],
      ),
      body: Column(
        children: [
          // --- Filter Row ---
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: Colors.white,
            child: Row(
              children: [
                Text("Filters",
                    style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                const SizedBox(width: 12),
                // Type Filter Button
                Expanded(
                  child: InkWell(
                    onTap: () => _showTypeFilterBottomSheet(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                              child: Text(_selectedType,
                                  overflow: TextOverflow.ellipsis)),
                          const Icon(Icons.keyboard_arrow_down, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Employee Filter Button
                Expanded(
                  child: InkWell(
                    onTap: () => _showEmployeeFilterBottomSheet(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              _selectedEmployee?.name ?? "All Employees",
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // --- Notification List ---
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: _primary))
                : _notifications.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          return _buildNotificationCard(_notifications[index]);
                        },
                      ),
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
          Icon(Icons.notifications_off_outlined,
              size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text("No notifications found",
              style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notif) {
    final data = notif.data;
    final isAttendance = notif.type == 'Attendance';

    // FIX: Convert to Local Time before formatting
    final DateTime localTime = notif.createdAt.toLocal();

    // Format Date: "Dec 26"
    final dateStr = DateFormat("MMM dd").format(localTime);
    // Format Time: "03:28 PM"
    final timeStr = DateFormat("h:mm a").format(localTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Employee Avatar
              _buildAvatar(data?.employeePhoto, data?.employeeName ?? "U"),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                        fontSize: 15, color: Colors.black, height: 1.3),
                    children: [
                      TextSpan(
                        text: data?.employeeName ?? "Employee",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                          text:
                              " ${notif.title.replaceAll(data?.employeeName ?? '', '').trim()}"),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(dateStr,
                  style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),

          // Content Row (Image + Address)
          if (isAttendance && data != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selfie Image
                if (data.image != null && data.image!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      // Ensure base URL is correct
                      "https://sambalam.ifoxclicks.com${data.image}",
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, _, __) => Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image),
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Display the Local Time here
                          Text(timeStr,
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.black87)),
                          const SizedBox(width: 8),
                          const Text("|", style: TextStyle(color: Colors.grey)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              data.address ?? "Location not available",
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey[700]),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (data.lat != null && data.lng != null)
                        OutlinedButton.icon(
                          onPressed: () => _openMap(data.lat!, data.lng!),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            side: const BorderSide(color: Colors.blue),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 0),
                            minimumSize: const Size(0, 32),
                          ),
                          icon:
                              const Icon(Icons.location_on_outlined, size: 16),
                          label: const Text("Show Location",
                              style: TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                )
              ],
            )
          ] else ...[
            // Generic Body for other notifications
            Text(notif.body, style: const TextStyle(color: Colors.grey))
          ]
        ],
      ),
    );
  }

  Widget _buildAvatar(String? url, String name) {
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(url), // Add base URL if needed
      );
    }
    return CircleAvatar(
      radius: 20,
      backgroundColor: Colors.grey[200],
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : "U",
        style:
            const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
      ),
    );
  }

  // --- BOTTOM SHEETS ---

  void _showTypeFilterBottomSheet() {
    final types = [
      "All Notifications",
      "Attendance",
      "Leave Request",
      "Notes",
      "Live Track",
      "Payments"
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Select Notification Type",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                ...types.map((type) => RadioListTile<String>(
                      value: type,
                      groupValue: _selectedType,
                      activeColor: _primary,
                      title: Row(
                        children: [
                          Icon(_getIconForType(type),
                              size: 20, color: Colors.black54),
                          const SizedBox(width: 12),
                          Text(type),
                        ],
                      ),
                      onChanged: (val) {
                        setState(() => _selectedType = val!);
                        _loadData();
                        Navigator.pop(context);
                      },
                    )),
              ],
            ),
          );
        });
      },
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'Attendance':
        return Icons.calendar_today;
      case 'Leave Request':
        return Icons.luggage;
      case 'Notes':
        return Icons.note;
      case 'Live Track':
        return Icons.location_on;
      case 'Payments':
        return Icons.currency_rupee;
      default:
        return Icons.notifications;
    }
  }

  void _showEmployeeFilterBottomSheet() async {
    // Fetch employees for the list
    List<Staff> employees =
        await _companyApi.getCompanyStaffList(companyId: _companyId);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 20),
                const Text("Select Staff",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: "Search employee",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      ListTile(
                        title: const Text("Select All Employees"),
                        leading: _selectedEmployee == null
                            ? const Icon(Icons.check_box, color: _primary)
                            : const Icon(Icons.check_box_outline_blank),
                        onTap: () {
                          setState(() => _selectedEmployee = null);
                          _loadData();
                          Navigator.pop(context);
                        },
                      ),
                      const Divider(),
                      ...employees.map((emp) => ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey[200],
                              child: Text(emp.name[0],
                                  style: const TextStyle(color: Colors.black)),
                            ),
                            title: Text(emp.name),
                            trailing: _selectedEmployee?.id == emp.id
                                ? const Icon(Icons.check, color: _primary)
                                : null,
                            onTap: () {
                              setState(() => _selectedEmployee = emp);
                              _loadData();
                              Navigator.pop(context);
                            },
                          )),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Apply"),
                    ),
                  ),
                )
              ],
            );
          },
        );
      },
    );
  }
}
