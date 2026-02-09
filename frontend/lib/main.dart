import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:developer';

import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'api/api_service.dart';
import 'utils/routes.dart';
import 'utils/theme.dart';
import 'utils/constants.dart';
import 'screens/splash/splash_screen.dart';
import 'services/notification_service.dart';
import 'widgets/common/connectivity_wrapper.dart'; // Add this import
import 'widgets/common/maintenance_mode_screen.dart';

@pragma('vm:entry-point') // needed for background on some platforms
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Called when app is in background/terminated and a data+notification message arrives
  log('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // await FirebaseAuth.instance.useAuthEmulator('10.80.210.30', 9099);
    log('Firebase Emulator Connected to :9099');
    await StorageService.init();
  } catch (e) {
    print('Failed to initialize Firebase: $e');
    // Continue without Firebase for now
  }

  await NotificationService.init();
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      // Show a snackbar so the user knows a new announcement arrived while they were looking
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        SnackBar(
          content: Text('New Announcement: ${notification.title}'),
          action: SnackBarAction(
              label: 'View',
              onPressed: () {
                navigatorKey.currentState?.pushNamed('/announcements');
              }),
        ),
      );
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    // Called when user taps a notification and the app is brought to foreground
    final data =
        message.data; // we sent announcementId, companyId in data from backend
    final announcementId = data['announcementId'];

    // Use your navigator key or context to navigate
    // Example: open AnnouncementsScreen
    navigatorKey.currentState?.pushNamed(
      '/announcements', // or use MaterialPageRoute
      arguments: announcementId, // optional for detail
    );
  });

  runApp(const MyApp());
  // NEW: handle case when app was launched by tapping a notification
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    final data = initialMessage.data;
    final announcementId = data['announcementId'];
    navigatorKey.currentState?.pushNamed(
      Routes.announcements,
      arguments: announcementId,
    );
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(
          create: (_) => ApiService(),
        ),
        Provider<StorageService>(
          create: (_) => StorageService(),
        ),
        ChangeNotifierProvider<AuthService>(
          create: (context) {
            final auth = AuthService(
              apiService: context.read<ApiService>(),
              storageService: context.read<StorageService>(),
            );
            // Trigger the check as soon as the app starts
            auth.checkMaintenanceStatus();
            return auth;
          },
        ),
      ],
      child: Consumer<AuthService>(
        builder: (context, auth, _) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: AppConstants.appName,
            theme: AppTheme.getTheme(),
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              if (auth.isMaintenanceMode) {
                return const MaintenanceModeScreen(); // Shows the lock screen
              }
              return GlobalConnectivityWrapper(child: child!);
            },
            initialRoute: Routes.splash,
            onGenerateRoute: Routes.generateRoute,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
