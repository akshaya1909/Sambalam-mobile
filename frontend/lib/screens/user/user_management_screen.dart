import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/api.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../utils/utils.dart';
import '../../widgets/widgets.dart';
import 'user_form_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<User> _employees = [];
  List<User> _hrUsers = [];
  late TabController _tabController;
  String? _companyId;
  String? _userId;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    
    setState(() {
      _userId = user?['id'];
      _companyId = user?['companyId'];
      _userRole = user?['role'];
    });
    
    if (_companyId != null && _userRole == 'admin') {
      _fetchUsers();
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

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final users = await apiService.getCompanyUsers(_companyId!);
      
      final employees = <User>[];
      final hrUsers = <User>[];
      
      for (final user in users) {
        if (user.role == 'employee') {
          employees.add(user);
        } else if (user.role == 'hr') {
          hrUsers.add(user);
        }
      }
      
      setState(() {
        _employees = employees;
        _hrUsers = hrUsers;
        _isLoading = false;
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

  Future<void> _deleteUser(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.deleteUser(user.id);
      
      // Refresh the users list
      await _fetchUsers();
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user.name} deleted successfully')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting user: ${e.toString()}')),
      );
    }
  }

  Widget _buildUserCard(User user) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                  backgroundImage: user.profileImage != null
                      ? NetworkImage(user.profileImage!)
                      : null,
                  child: user.profileImage == null
                      ? Text(
                          (user.name != null && user.name!.isNotEmpty) 
  ? user.name![0].toUpperCase() 
  : '?',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 16),
                          const SizedBox(width: 4),
                          Text(user.phoneNumber),
                        ],
                      ),
                      if (user.email != null && user.email!.isNotEmpty) ...[  
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.email, size: 16),
                            const SizedBox(width: 4),
                            Text(user.email!),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => _deleteUser(user),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete',
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserFormScreen(user: user),
                      ),
                    ).then((_) => _fetchUsers());
                  },
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  tooltip: 'Edit',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(List<User> users) {
    if (users.isEmpty) {
      return const EmptyState(
        icon: Icons.people_outline,
        title: 'No Users',
        message: 'There are no users in this category.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: users.length,
      itemBuilder: (context, index) {
        return _buildUserCard(users[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'User Management',
        showBackButton: true,
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading users...')
          : Column(
              children: [
                TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.primaryColor,
                  unselectedLabelColor: AppTheme.textSecondaryColor,
                  indicatorColor: AppTheme.primaryColor,
                  tabs: [
                    Tab(text: 'Employees (${_employees.length})'),
                    Tab(text: 'HR (${_hrUsers.length})'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      RefreshIndicator(
                        onRefresh: _fetchUsers,
                        color: AppTheme.primaryColor,
                        child: _buildUserList(_employees),
                      ),
                      RefreshIndicator(
                        onRefresh: _fetchUsers,
                        color: AppTheme.primaryColor,
                        child: _buildUserList(_hrUsers),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const UserFormScreen(),
            ),
          ).then((_) => _fetchUsers());
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}