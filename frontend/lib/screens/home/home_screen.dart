import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../api/company_api_service.dart';
import '../../../models/company_model.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  bool _isCheckedIn = false;
  String _lastCheckInTime = '--:--';
  String _lastCheckOutTime = '--:--';
  String _userRole = 'employee'; // Default role
  String _userName = 'User';
  String _companyName = 'Company';
  Position? _currentPosition;
  XFile? _capturedImage;
  final ImagePicker _picker = ImagePicker();
  Company? _company;
  bool _isLoadingCompany = true;
  final CompanyApiService _companyApi = CompanyApiService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkLocationPermission();
    _loadCompanyDetails();
  }

  Future<void> _loadCompanyDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final companyId = prefs.getString('companyId');

      if (companyId != null) {
        final company = await _companyApi.getCompanyById(companyId);
        if (mounted) {
          setState(() {
            _company = company;
            if (company != null && company.name.isNotEmpty) {
              _companyName = company.name;
            }
            _isLoadingCompany = false;
          });
        }
      } else {
        setState(() {
          _isLoadingCompany = false;
        });
      }
    } catch (e) {
      print('Error loading company: $e');
      setState(() {
        _isLoadingCompany = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    final storageService = Provider.of<StorageService>(context, listen: false);
    final role = await storageService.getUserRole() ?? 'employee';

    // In a real app, you would fetch these from an API
    // For now, we'll use mock data
    setState(() {
      _userRole = role;
      _userName = 'John Doe'; // Mock data
    });
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Location services are disabled. Please enable them.')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Location permissions are permanently denied, we cannot request permissions.'),
        ),
      );
      return;
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      print('Error getting location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  Future<void> _takeSelfie() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
      );
      setState(() {
        _capturedImage = photo;
      });
    } catch (e) {
      print('Error taking selfie: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking selfie: $e')),
      );
    }
  }

  Future<void> _markAttendance() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current location
      await _getCurrentLocation();
      if (_currentPosition == null) {
        throw Exception('Could not get current location');
      }

      // Take selfie
      await _takeSelfie();
      if (_capturedImage == null) {
        throw Exception('Could not capture image');
      }

      // In a real app, you would send this data to your backend
      // For now, we'll just simulate a successful check-in/out
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      final now = DateTime.now();
      final formattedTime = DateFormat('HH:mm').format(now);

      setState(() {
        _isCheckedIn = !_isCheckedIn;
        if (_isCheckedIn) {
          _lastCheckInTime = formattedTime;
        } else {
          _lastCheckOutTime = formattedTime;
        }
        _isLoading = false;
        _capturedImage = null; // Clear image after successful submission
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_isCheckedIn
                ? 'Checked in successfully'
                : 'Checked out successfully')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _signOut() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();

      // Navigate to login screen
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sambalam HR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _signOut,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // User info card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Theme.of(context).primaryColor,
                              child: Text(
                                _userName.isNotEmpty ? _userName[0] : 'U',
                                style: const TextStyle(
                                  fontSize: 32,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _userName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _companyName,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Chip(
                              label: Text(
                                _userRole.toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Theme.of(context).primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Attendance card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Today\'s Attendance',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    const Text(
                                      'Check In',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _lastCheckInTime,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    const Text(
                                      'Check Out',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _lastCheckOutTime,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _markAttendance,
                                icon: Icon(
                                    _isCheckedIn ? Icons.logout : Icons.login),
                                label: Text(
                                    _isCheckedIn ? 'Check Out' : 'Check In'),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_capturedImage != null)
                              Center(
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Image.network(
                                    _capturedImage!.path,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child:
                                            Text('Image preview not available'),
                                      );
                                    },
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Quick actions
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildActionCard(
                          icon: Icons.calendar_today,
                          title: 'Leave Request',
                          onTap: () {
                            Navigator.pushNamed(context, '/leave-history');
                          },
                        ),
                        _buildActionCard(
                          icon: Icons.attach_money,
                          title: 'Salary Slip',
                          onTap: () {
                            // TODO: Implement salary slip
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Salary slip functionality not implemented yet')),
                            );
                          },
                        ),
                        _buildActionCard(
                          icon: Icons.people,
                          title: 'Team',
                          onTap: () {
                            // TODO: Implement team view
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Team view functionality not implemented yet')),
                            );
                          },
                        ),
                        _buildActionCard(
                          icon: Icons.notifications,
                          title: 'Announcements',
                          onTap: () {
                            // TODO: Implement announcements
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Announcements functionality not implemented yet')),
                            );
                          },
                        ),
                      ],
                    ),
                    // Additional admin/HR actions
                    if (_userRole == 'admin' || _userRole == 'hr') ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Admin Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildActionCard(
                            icon: Icons.person_add,
                            title: 'User Management',
                            onTap: () {
                              Navigator.pushNamed(context, '/user-management');
                            },
                          ),
                          _buildActionCard(
                            icon: Icons.approval,
                            title: 'Approve Leaves',
                            onTap: () {
                              Navigator.pushNamed(context, '/leave-approval');
                            },
                          ),
                          _buildActionCard(
                            icon: Icons.assessment,
                            title: 'Attendance Reports',
                            onTap: () {
                              Navigator.pushNamed(
                                  context, '/attendance-report');
                            },
                          ),
                          _buildActionCard(
                            icon: Icons.settings,
                            title: 'Settings',
                            onTap: () {
                              // TODO: Implement settings
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Settings functionality not implemented yet')),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Theme.of(context).primaryColor),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
