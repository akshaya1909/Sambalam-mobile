import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../api/api.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../utils/utils.dart';
import '../../widgets/widgets.dart';

class AttendanceReportScreen extends StatefulWidget {
  final String? userId; // If provided, shows attendance for specific user

  const AttendanceReportScreen({Key? key, this.userId}) : super(key: key);

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  bool _isLoading = true;
  List<Attendance> _attendanceRecords = [];
  List<User> _users = [];
  User? _selectedUser;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, List<Attendance>> _attendanceMap = {};
  String? _companyId;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    
    setState(() {
      _companyId = user?['companyId'];
      _userRole = user?['role'];
    });
    
    if (_companyId != null && (_userRole == 'hr' || _userRole == 'admin')) {
      if (widget.userId != null) {
        // Load specific user's attendance
        await _fetchUserById(widget.userId!);
        await _fetchAttendanceForUser(widget.userId!);
      } else {
        // Load all users and attendance for the company
        await _fetchUsers();
      }
    } else {
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You do not have permission to access this page')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _fetchUserById(String userId) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final user = await apiService.getUserById(userId);
      
      setState(() {
        _selectedUser = user;
      });
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching user: ${e.toString()}')),
      );
    }
  }

  Future<void> _fetchUsers() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final users = await apiService.getCompanyUsers(_companyId!);
      
      // Filter to only show employees
      final employees = users.where((user) => user.role == 'employee').toList();
      
      setState(() {
        _users = employees;
        if (_users.isNotEmpty) {
          _selectedUser = _users.first;
          _fetchAttendanceForUser(_selectedUser!.id);
        } else {
          _isLoading = false;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching users: ${e.toString()}')),
      );
    }
  }

  Future<void> _fetchAttendanceForUser(String userId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final attendanceRecords = await apiService.getUserAttendanceRecords(userId);
      
      // Create a map of date to attendance records
      final attendanceMap = <DateTime, List<Attendance>>{};
      for (final record in attendanceRecords) {
        final date = DateTime(
          record.checkInTime.year,
          record.checkInTime.month,
          record.checkInTime.day,
        );
        
        if (attendanceMap.containsKey(date)) {
          attendanceMap[date]!.add(record);
        } else {
          attendanceMap[date] = [record];
        }
      }
      
      setState(() {
        _attendanceRecords = attendanceRecords;
        _attendanceMap = attendanceMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching attendance records: ${e.toString()}')),
      );
    }
  }

  List<Attendance> _getAttendanceForSelectedDay() {
    final date = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );
    
    return _attendanceMap[date] ?? [];
  }

  Color _getAttendanceStatusColor(String status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'half-day':
        return Colors.orange;
      case 'absent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildCalendarDayMarker(DateTime day, List<Attendance> events) {
    if (events.isEmpty) return Container();
    
    // Get the status of the first attendance record for the day
    final status = events.first.status;
    
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getAttendanceStatusColor(status),
      ),
    );
  }

  Widget _buildAttendanceDetails() {
    final attendanceRecords = _getAttendanceForSelectedDay();
    
    if (attendanceRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: AppTheme.textSecondaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No attendance records for ${DateFormat('dd MMM yyyy').format(_selectedDay)}',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: attendanceRecords.length,
      itemBuilder: (context, index) {
        final record = attendanceRecords[index];
        final checkInTime = DateFormat('hh:mm a').format(record.checkInTime);
        final checkOutTime = record.checkOutTime != null
            ? DateFormat('hh:mm a').format(record.checkOutTime!)
            : 'Not checked out';
        
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd MMM yyyy').format(record.checkInTime),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Chip(
                      label: Text(
                        record.status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: _getAttendanceStatusColor(record.status),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Check In',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.login,
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                checkInTime,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Check Out',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.logout,
                                color: record.checkOutTime != null
                                    ? AppTheme.primaryColor
                                    : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                checkOutTime,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: record.checkOutTime != null
                                      ? Colors.black
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (record.remarks != null && record.remarks!.isNotEmpty) ...[  
                  const SizedBox(height: 16),
                  const Text(
                    'Remarks',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    record.remarks!,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Attendance Report',
        showBackButton: true,
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading attendance records...')
          : Column(
              children: [
                if (widget.userId == null && _users.isNotEmpty) ...[  
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: DropdownButtonFormField<User>(
                      value: _selectedUser,
                      decoration: const InputDecoration(
                        labelText: 'Select Employee',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: _users.map((user) {
                        return DropdownMenuItem<User>(
                          value: user,
                          child: Text(user.name ?? 'Unnamed User'),
                        );
                      }).toList(),
                      onChanged: (user) {
                        if (user != null) {
                          setState(() {
                            _selectedUser = user;
                          });
                          _fetchAttendanceForUser(user.id);
                        }
                      },
                    ),
                  ),
                ],
                if (_selectedUser != null) ...[  
                  TableCalendar<Attendance>(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    calendarFormat: CalendarFormat.month,
                    eventLoader: (day) {
                      final date = DateTime(day.year, day.month, day.day);
                      return _attendanceMap[date] ?? [];
                    },
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    calendarStyle: CalendarStyle(
                      markersMaxCount: 1,
                      markerDecoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, day, events) {
                        return _buildCalendarDayMarker(day, events);
                      },
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: _buildAttendanceDetails(),
                  ),
                ],
              ],
            ),
    );
  }
}