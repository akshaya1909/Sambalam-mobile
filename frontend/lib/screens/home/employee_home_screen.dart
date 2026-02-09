import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart' as permission;
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../api/company_api_service.dart';
import '../../../models/company_model.dart';
import '../../../api/api_service.dart';
import '../../../api/attendance_api_service.dart';
import '../../../widgets/employee_bottom_nav.dart';
import '../leave/leaves_screen.dart';
import '../profile/profile_screen.dart';
import '../notes/notes_screen.dart';
import '../notifications/employee_notifications_screen.dart';

class EmployeeHomeScreen extends StatefulWidget {
  final String phoneNumber;
  final String companyId;
  final bool hideInternalNav;

  const EmployeeHomeScreen({
    Key? key,
    required this.phoneNumber,
    required this.companyId,
    this.hideInternalNav = false,
  }) : super(key: key);

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  final AttendanceApiService _attendanceApi = AttendanceApiService();
  final CompanyApiService _companyApi = CompanyApiService();

  /// New primary gradient and neutrals
  final Color _primaryStart = const Color(0xFF1769AA); // deep blue
  final Color _primaryEnd = const Color(0xFF00BFA5); // teal
  final Color _accentSoft = const Color(0xFFE3F2FD);
  final Color _danger = const Color(0xFFD32F2F);
  final Color _surfaceDark = const Color(0xFF0F172A);

  bool _isRequestingLocation = false;
  bool _isRequestingCamera = false;
  bool _hasLocation = false;
  bool _hasCamera = false;
  bool _gpsOn = false;
  bool _locationPermissionGranted = false;

  List<CameraDescription> _availableCameras = [];
  int _currentCameraIndex = 0;

  bool _isLoadingCompany = true;
  Company? _company;
  String? _companyName;

  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;

  int _selectedTab = 0;

  bool _isPunching = false;
  String _punchLabel = 'Punch In';
  String? _employeeId;
  bool _hasNewNotifications = true;

  String get _todayLabel {
    final now = DateTime.now().toLocal();
    return DateFormat('dd MMMM').format(now);
  }

  @override
  void initState() {
    super.initState();
    _loadCompanyDetails();
    _ensurePermissions();
    _loadEmployeeIdAndStatus();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _loadCompanyDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final companyId = prefs.getString('companyId');

      if (companyId != null) {
        final company = await _companyApi.getCompanyById(companyId);
        if (!mounted) return;
        setState(() {
          _company = company;
          _companyName = _company?.name ?? 'Your Workplace';
          _isLoadingCompany = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _isLoadingCompany = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading company: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingCompany = false;
      });
    }
  }

  Future<void> _ensurePermissions() async {
    await _checkLocationAndCamera();

    if (!_hasLocation) {
      final status = await permission.Permission.location.request();
      final service = await permission.Permission.location.serviceStatus;

      final granted =
          status.isGranted && service == permission.ServiceStatus.enabled;
      if (!mounted) return;
      setState(() {
        _locationPermissionGranted = status.isGranted;
        _gpsOn = service == permission.ServiceStatus.enabled;
        _hasLocation = granted;
      });

      if (!granted) {
        await _showLocationDialog();
        await _checkLocationAndCamera();
      }
    }

    if (_hasLocation && !_hasCamera) {
      await _requestCamera();
      await _checkLocationAndCamera();
    }
  }

  Future<void> _loadEmployeeIdAndStatus() async {
    final prefs = await SharedPreferences.getInstance();

    // Directly retrieve from storage to ensure we have the latest data after refresh
    final savedEmployeeId = prefs.getString('employeeId');
    final savedCompanyId = prefs.getString('companyId');

    if (savedEmployeeId == null || savedCompanyId == null) {
      debugPrint('ERROR: IDs missing from storage after refresh');
      return;
    }

    setState(() {
      _employeeId = savedEmployeeId;
    });

    await _loadTodayStatus();
  }

  Future<void> _loadTodayStatus() async {
    try {
      // Ensure we don't call the API with empty values
      if (_employeeId == null || _employeeId!.isEmpty) return;

      // Get company ID from prefs if widget.companyId is empty
      String cId = widget.companyId;
      if (cId.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        cId = prefs.getString('companyId') ?? '';
      }

      if (cId.isEmpty) return;

      final res = await _attendanceApi.getTodayStatus(
        employeeId: _employeeId!,
        companyId: cId,
      );

      final status = res['status'] as String?;
      if (!mounted) return;
      setState(() {
        if (status == 'in') {
          _punchLabel = 'Punch Out';
        } else if (status == 'out' || status == 'completed') {
          _punchLabel = 'Completed';
        } else {
          _punchLabel = 'Punch In';
        }
      });
    } catch (e) {
      debugPrint('Today status error: $e');
      if (!mounted) return;
      setState(() => _punchLabel = 'Punch In');
    }
  }

  Future<void> _checkLocationAndCamera() async {
    final locStatus = await permission.Permission.location.status;
    final locService = await permission.Permission.location.serviceStatus;
    final camStatus = await permission.Permission.camera.status;

    if (!mounted) return;
    setState(() {
      _locationPermissionGranted = locStatus.isGranted;
      _gpsOn = locService == permission.ServiceStatus.enabled;
      _hasLocation = _locationPermissionGranted && _gpsOn;
      _hasCamera = camStatus.isGranted;
    });

    if (_hasLocation && _hasCamera) {
      await _initCameraPreview();
    }
  }

  Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<File> _takeCircularPicture() async {
    final picture = await _cameraController!.takePicture();
    final bytes = await picture.readAsBytes();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(260, 260);

    final paint = Paint();
    final image = await _decodeImage(bytes);

    // ❌ remove const here
    final ovalRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.clipPath(
      Path()..addOval(ovalRect),
    );

    paint.isAntiAlias = true;
    final isFrontCamera = _cameraController!.description.lensDirection ==
        CameraLensDirection.front;

    if (isFrontCamera) {
      // Mirror the canvas before drawing the image
      canvas.save();
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      ovalRect,
      paint,
    );

    if (isFrontCamera) {
      canvas.restore();
    }

    final recorded = recorder.endRecording();
    final img = await recorded.toImage(260, 260);
    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);

    final dir = await getTemporaryDirectory();
    final filePath = p.join(
      dir.path,
      'attendance_circle_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    final file = File(filePath);
    await file.writeAsBytes(pngBytes!.buffer.asUint8List());

    return file;
  }

  Future<void> _showLocationDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Location access needed',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: const Text(
            'To record your attendance, enable location access from Settings.',
          ),
          actionsPadding:
              const EdgeInsets.only(left: 24, right: 24, bottom: 16),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await permission.openAppSettings();
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  await _checkLocationAndCamera();
                  if (_hasLocation && !_hasCamera) {
                    await _requestCamera();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryStart,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Open Settings',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _requestLocation() async {
    if (!mounted) return;
    setState(() => _isRequestingLocation = true);
    try {
      final serviceStatus = await permission.Permission.location.serviceStatus;
      if (serviceStatus != permission.ServiceStatus.enabled) {
        await _showLocationDialog();
        return;
      }

      final status = await permission.Permission.location.request();
      final service = await permission.Permission.location.serviceStatus;

      final granted =
          status.isGranted && service == permission.ServiceStatus.enabled;

      if (!mounted) return;
      setState(() {
        _hasLocation = granted;
      });

      if (granted) {
        if (!_hasCamera) {
          await _requestCamera();
        } else {
          await _initCameraPreview();
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isRequestingLocation = false);
      }
    }
  }

  Future<void> _requestCamera() async {
    if (!mounted) return;
    setState(() => _isRequestingCamera = true);
    try {
      final status = await permission.Permission.camera.request();
      if (status.isGranted) {
        if (!mounted) return;
        setState(() => _hasCamera = true);
        if (_hasLocation) {
          await _initCameraPreview();
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isRequestingCamera = false);
      }
    }
  }

  Future<void> _initCameraPreview() async {
    if (_availableCameras.isEmpty) {
      _availableCameras = await availableCameras();
      if (_availableCameras.isEmpty) return;
    }

    await _cameraController?.dispose();
    _cameraController = CameraController(
      _availableCameras[_currentCameraIndex],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    _initializeControllerFuture = _cameraController!.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _toggleCamera() async {
    if (_availableCameras.isEmpty) {
      _availableCameras = await availableCameras();
      if (_availableCameras.isEmpty) return;
    }

    _currentCameraIndex = (_currentCameraIndex + 1) % _availableCameras.length;
    await _cameraController?.dispose();

    final newController = CameraController(
      _availableCameras[_currentCameraIndex],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    if (!mounted) return;
    setState(() {
      _cameraController = newController;
      _initializeControllerFuture = newController.initialize();
    });
  }

  Future<void> _onPunch() async {
    final prefs = await SharedPreferences.getInstance();
    final String? effectiveEmployeeId =
        _employeeId ?? prefs.getString('employeeId');
    final String? effectiveCompanyId = widget.companyId.isNotEmpty
        ? widget.companyId
        : prefs.getString('companyId');

    if (effectiveEmployeeId == null || effectiveCompanyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expired. Please login again.')),
      );
      return;
    }

    if (!_hasLocation || !_hasCamera || _cameraController == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enable location and camera first')),
      );
      return;
    }

    try {
      if (!mounted) return;
      setState(() => _isPunching = true);
      await _initializeControllerFuture;

      final file = await _takeCircularPicture();
      setState(() => _isPunching = false);

      final bool? isConfirmed = await _showImagePreviewDialog(file);

      if (isConfirmed != true) {
        // User clicked cancel/retake
        return;
      }

      // 3. User confirmed, now proceed with location and API call
      setState(() => _isPunching = true);

      double? lat;
      double? lng;
      String? address;

      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
        lat = position.latitude;
        lng = position.longitude;

        try {
          final placemarks = await placemarkFromCoordinates(lat, lng);
          final placemark = placemarks.first;
          address =
              '${placemark.street}, ${placemark.locality}, ${placemark.postalCode}, ${placemark.country}';
        } catch (geoError) {
          debugPrint('Geocoding failed: $geoError');
          address = 'Lat: $lat, Lng: $lng';
        }
      } catch (e) {
        debugPrint('GPS Error: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('GPS unavailable: $e')),
        );
      }

      final res = await _attendanceApi.punchAttendance(
        employeeId: effectiveEmployeeId,
        companyId: effectiveCompanyId,
        punchedFrom: 'Mobile',
        photoFile: file,
        lat: lat,
        lng: lng,
        address: address,
      );

      final message = res['message'] as String? ?? 'Attendance updated';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

      final status = res['status'] as String?;
      setState(() {
        if (status == 'in') {
          _punchLabel = 'Punch Out';
        } else if (status == 'out') {
          _punchLabel = 'Completed';
        }
        _isPunching = false;
      });
      if (!mounted) return;

      // Determine the message based on the status returned from API
      String successMessage = (status == 'in')
          ? 'You have successfully punched in!'
          : 'You have successfully punched out!';

      setState(() => _isPunching = false);
      await _loadTodayStatus();
      // SHOW POPUP
      await _showPunchSuccessDialog(successMessage);
    } catch (e) {
      debugPrint('Punch error: $e');
      String errorMessage = e.toString().replaceAll('Exception:', '').trim();
      if (!mounted) return;
      if (e.toString().contains('Already punched in and out')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance already completed for today'),
          ),
        );
        setState(() => _punchLabel = 'Completed');
      } else if (errorMessage.contains('Out of range') ||
          errorMessage.contains('away from the office')) {
        _showErrorDialog('Location Restricted', errorMessage);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPunching = false);
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    // Helper to clean the message if it contains JSON or "Exception:" strings
    String cleanMessage = message;

    // 1. Remove JSON formatting if present
    if (message.contains('"message":')) {
      // Regex to extract value between "message":" and "
      final regExp = RegExp(r'"message":"([^"]+)"');
      final match = regExp.firstMatch(message);
      if (match != null) {
        cleanMessage = match.group(1)!;
      }
    }

    // 2. Remove common "Exception:" prefix if it exists
    cleanMessage = cleanMessage.replaceAll('Exception:', '').trim();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.only(top: 30),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Prominent Warning Icon
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _danger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_disabled_rounded,
                color: _danger,
                size: 42,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: Color(0xFF1E293B), // Slate-900 for modern feel
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        content: Text(
          cleanMessage,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.blueGrey.shade600,
            height: 1.5,
            fontWeight: FontWeight.w400,
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryStart,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showImagePreviewDialog(File imageFile) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Confirm Attendance Photo',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _primaryStart, width: 3),
                  image: DecorationImage(
                    image: FileImage(imageFile),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Does this photo look clear?',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _danger),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('Retake', style: TextStyle(color: _danger)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryStart,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Confirm',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildPrimaryGradientButton({
    required String label,
    required VoidCallback? onPressed,
    bool isDanger = false,
    bool isLoading = false,
    IconData? icon,
  }) {
    final colors = isDanger
        ? [_danger, _danger.withOpacity(0.8)]
        : [_primaryStart, _primaryEnd];

    return Container(
      decoration: BoxDecoration(
        gradient: onPressed == null
            ? null
            : LinearGradient(
                colors: colors,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        color: onPressed == null ? Colors.grey[600] : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else if (icon != null)
              Icon(icon, color: Colors.white),
            if (!isLoading && icon != null) const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 17,
                color: Colors.white,
                fontWeight:
                    onPressed == null ? FontWeight.w400 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final height = media.size.height;
    final paddingHorizontal = width * 0.04; // responsive padding

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: paddingHorizontal,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryStart, _primaryEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.15),
                              Colors.white.withOpacity(0.02),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.35),
                            width: 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          (_companyName != null && _companyName!.isNotEmpty)
                              ? _companyName![0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _companyName ??
                                  (_isLoadingCompany
                                      ? 'Loading...'
                                      : 'Your Workplace'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Secure attendance',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => EmployeeNotificationsScreen(
                                companyId: widget.companyId,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _todayLabel,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.verified_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Mark your presence',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
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

          // Camera + overlays
          Expanded(
            child: Container(
              width: double.infinity,
              color: _surfaceDark,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_hasLocation &&
                          _hasCamera &&
                          _cameraController != null &&
                          _initializeControllerFuture != null)
                        FutureBuilder<void>(
                          future: _initializeControllerFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.done) {
                              // No manual mirror for front camera
                              final preview = CameraPreview(_cameraController!);

                              return FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: _cameraController!
                                      .value.previewSize!.height,
                                  height: _cameraController!
                                      .value.previewSize!.width,
                                  child: preview,
                                ),
                              );
                            }
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            );
                          },
                        )
                      else
                        Container(color: _surfaceDark),

                      // Circular mask
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _CircleMaskPainter(),
                        ),
                      ),

                      // Top-right camera switch
                      Positioned(
                        right: paddingHorizontal,
                        top: 18,
                        child: GestureDetector(
                          onTap: () async {
                            if (_hasLocation && _hasCamera) {
                              await _toggleCamera();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: const Icon(
                              Icons.cameraswitch_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      // Permission overlays
                      if (!_hasLocation)
                        _LocationOverlay(
                          themeGradient: LinearGradient(
                            colors: [_primaryStart, _primaryEnd],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          isRequesting: _isRequestingLocation,
                          onAllow: _requestLocation,
                        )
                      else if (!_hasCamera)
                        _CameraOverlay(
                          themeGradient: LinearGradient(
                            colors: [_primaryStart, _primaryEnd],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          isRequesting: _isRequestingCamera,
                          onAllow: _requestCamera,
                        ),
                    ],
                  );
                },
              ),
            ),
          ),

          // Punch button
          if (_hasCamera && _locationPermissionGranted && _gpsOn)
            Container(
              color: _surfaceDark,
              padding: EdgeInsets.fromLTRB(
                paddingHorizontal,
                12,
                paddingHorizontal,
                20,
              ),
              child: _buildPrimaryGradientButton(
                label: _punchLabel,
                onPressed: (_isPunching || _punchLabel == 'Completed')
                    ? null
                    : _onPunch,
                isDanger: _punchLabel == 'Punch Out',
                isLoading: _isPunching,
                icon: _isPunching
                    ? null
                    : _punchLabel == 'Punch In'
                        ? Icons.login_rounded
                        : Icons.logout_rounded,
              ),
            ),

          // Notes strip
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MyNotesScreen(),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: _accentSoft,
                border: Border(
                  top: BorderSide(
                    color: Colors.black.withOpacity(0.05),
                  ),
                ),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.event_note_rounded,
                    size: 18,
                    color: Colors.black54,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'View today\'s notes',
                    style: TextStyle(
                      fontSize: 15,
                      letterSpacing: 0.2,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom navigation
          widget.hideInternalNav
              ? const SizedBox.shrink() // Hide if it's a sub-screen
              : EmployeeBottomNav(
                  selectedIndex: _selectedTab,
                  activeColor: _primaryStart,
                  onItemSelected: (index) {
                    if (index == 0) {
                      setState(() => _selectedTab = 0);
                    } else if (index == 1) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => LeavesScreen(
                            phoneNumber: widget.phoneNumber,
                            companyId: widget.companyId,
                          ),
                        ),
                      );
                    } else if (index == 2) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProfileScreen(
                            phoneNumber: widget.phoneNumber,
                            companyId: widget.companyId,
                          ),
                        ),
                      );
                    }
                  },
                ),
        ],
      ),
    );
  }

  Future<void> _showPunchSuccessDialog(String message) async {
    return showDialog(
      context: context,
      barrierDismissible: false, // User must click Okay
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 10),
              Text('Success', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(message),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryStart,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  // 1. Pop the dialog
                  Navigator.of(context).pop();

                  // 2. Navigate to Profile Screen
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProfileScreen(
                        phoneNumber: widget.phoneNumber,
                        companyId: widget.companyId,
                      ),
                    ),
                  );
                },
                child:
                    const Text('Okay', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Location permission overlay with gradient CTA
class _LocationOverlay extends StatelessWidget {
  final Gradient themeGradient;
  final bool isRequesting;
  final VoidCallback onAllow;

  const _LocationOverlay({
    Key? key,
    required this.themeGradient,
    required this.isRequesting,
    required this.onAllow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;

    return Container(
      alignment: Alignment.bottomCenter,
      padding: EdgeInsets.symmetric(horizontal: width * 0.12, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text(
            'Location access required',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Turn on location to record accurate in and out time from your device.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          Container(
            decoration: BoxDecoration(
              gradient: themeGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isRequesting ? null : onAllow,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: isRequesting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Allow location',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Camera permission overlay with gradient CTA
class _CameraOverlay extends StatelessWidget {
  final Gradient themeGradient;
  final bool isRequesting;
  final VoidCallback onAllow;

  const _CameraOverlay({
    Key? key,
    required this.themeGradient,
    required this.isRequesting,
    required this.onAllow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;

    return Container(
      alignment: Alignment.bottomCenter,
      padding: EdgeInsets.symmetric(horizontal: width * 0.12, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text(
            'Camera access required',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Enable camera to capture a selfie for secure attendance.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          Container(
            decoration: BoxDecoration(
              gradient: themeGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isRequesting ? null : onAllow,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: isRequesting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Allow camera',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular mask painter with slightly higher radius and offset
class _CircleMaskPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 40);
    final radius = 160.0; // tweak for your design

    final overlayRect = Offset.zero & size;
    canvas.saveLayer(overlayRect, Paint());

    // Draw semi‑transparent dark over full area
    final darkPaint = Paint()..color = Colors.black.withOpacity(0.38);
    canvas.drawRect(overlayRect, darkPaint);

    // Clear the circle so camera is 100% visible there
    final clearPaint = Paint()..blendMode = BlendMode.clear;
    canvas.drawCircle(center, radius, clearPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
