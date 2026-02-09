import 'package:flutter/material.dart';

import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/login/login_screen.dart';
import '../screens/auth/otp/otp_screen.dart';
import '../screens/auth/secure_pin/create_secure_pin_screen.dart';
import '../screens/auth/secure_pin/secure_pin_screen.dart';
import '../screens/auth/biometric/login_via_biometric_screen.dart';
import '../screens/auth/company/enter_company_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/leave/leave_history_screen.dart';
import '../screens/leave/leave_request_screen.dart';
import '../screens/leave/leave_approval_screen.dart';
import '../screens/user/user_management_screen.dart';
import '../screens/user/user_form_screen.dart';
import '../screens/home/employee_home_screen.dart';
import '../screens/home/admin_home_screen.dart';
import '../screens/attendance/attendance_report_screen.dart';
import '../screens/auth/company/choose_company_option_screen.dart';
import '../screens/auth/company/create_company_screen.dart';
import '../screens/admin/announcements_screen.dart'; // adjust path

class Routes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String createSecurePin = '/create-secure-pin';
  static const String securePin = '/secure-pin';
  static const String biometric = '/biometric';
  static const String company = '/company';
  static const String home = '/home';
  static const String leaveHistory = '/leave-history';
  static const String leaveRequest = '/leave-request';
  static const String leaveApproval = '/leave-approval';
  static const String userManagement = '/user-management';
  static const String userForm = '/user-form';
  static const String attendanceReport = '/attendance-report';
  static const String chooseCompanyOption = '/choose-company-option';
  static const String createCompany = '/create-company';
  static const String announcements = '/announcements';
  static const String employeeHome = '/employee-home';
  static const String adminHome = '/admin-home';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case otp:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => OtpScreen(
            phoneNumber: args?['phoneNumber'] ?? '',
          ),
        );
      case createSecurePin:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => CreateSecurePinScreen(
            phoneNumber: args?['phoneNumber'] ?? '',
            companyId: args?['companyId'] ?? '', // ADD THIS LINE
            isResetMode: args?['isResetMode'] ?? false,
          ),
        );
      case securePin:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => SecurePinScreen(
            phoneNumber: args?['phoneNumber'] ?? '',
            companyId: args?['companyId'] ?? '',
            role: args?['role'] ?? 'employee',
          ),
        );
      case biometric:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => LoginViaBiometricScreen(
            phoneNumber: args?['phoneNumber'] ?? '',
          ),
        );
      case company:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => EnterCompanyScreen(
            phoneNumber: args?['phoneNumber'] ?? '',
          ),
        );
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case leaveHistory:
        return MaterialPageRoute(builder: (_) => const LeaveHistoryScreen());
      case leaveRequest:
        return MaterialPageRoute(builder: (_) => const LeaveRequestScreen());
      case leaveApproval:
        return MaterialPageRoute(builder: (_) => const LeaveApprovalScreen());
      case userManagement:
        return MaterialPageRoute(builder: (_) => const UserManagementScreen());
      case userForm:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => UserFormScreen(
            user: args?['user'],
          ),
        );
      case attendanceReport:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => AttendanceReportScreen(
            userId: args?['userId'],
          ),
        );
      case chooseCompanyOption:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ChooseCompanyOptionScreen(
            phoneNumber: args?['phoneNumber'] ?? '',
          ),
        );

      case createCompany:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => CreateCompanyScreen(
            phoneNumber: args?['phoneNumber'] ?? '',
          ),
        );

      case announcements:
        final args = settings.arguments; // if you later pass announcementId
        return MaterialPageRoute(
          builder: (_) => const AnnouncementsScreen(),
        );
      case employeeHome:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => EmployeeHomeScreen(
            phoneNumber: args?['phoneNumber'] ?? '',
            companyId: args?['companyId'] ?? '',
          ),
        );

      case adminHome:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => AdminHomeScreen(
            // Pass any required parameters for your Admin screen here
            role: args?['role'] ?? 'admin',
            phoneNumber: args?['phoneNumber'] ?? '',
            allowedBranchIds: args?['allowedBranchIds'],
            planExpiryBanner: "Welcome Admin",
            onAddStaff: () {},
            onInviteStaff: () {},
            onReports: () {},
            onEditAttendance: () {},
            onHelp: () {},
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
