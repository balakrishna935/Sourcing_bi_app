import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mukadam_bi/firebase_message.dart';
import 'package:mukadam_bi/firebase_options.dart';
import 'package:mukadam_bi/provider/language_provider.dart';
import 'package:mukadam_bi/splash_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mukadam_Screen.dart';
import 'mukadan/authentication/auth_service/auth_service.dart';
import 'mukadan/authentication/userProvider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);

  await FirebaseAnalytics.instance.logAppOpen();

  Map<Permission, PermissionStatus> statuses = await [
    Permission.location,
    Permission.notification,
  ].request();

  await OtpApiService.init();

  print('--- APP STARTUP ---');
  if (OtpApiService.sessionToken != null) {
    print('Session Token found: ${OtpApiService.sessionToken}');
  } else {
    print('No Session Token found. User needs to login.');
  }
  print('-------------------');

  final userProvider = UserProvider();
  await userProvider.loadSavedUser();

  if (userProvider.user != null) {
    print('Logged in User ID: ${userProvider.user!.id}');
    print('Logged in User ID: ${userProvider.user!.username}');
    print('Logged in User ID: ${userProvider.user!.mobileNumber}');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bg_user_id', userProvider.user!.id);
  } else {
    print('No user data found in provider.');
  }

  await dotenv.load(fileName: ".env");

  try {
    await FirebaseAnalytics.instance.logEvent(
      name: 'app_started_manually',
      parameters: {
        'user_id': userProvider.user?.id ?? 'guest',
      },
    );
  } catch (e) {
    print(e.toString());
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: userProvider),
        ChangeNotifierProvider(create: (_) => LanguageProvider()..loadLanguage()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mukkadam Registration',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance)
      ],
    );
  }
}

// Made this public so it can be imported into mukadam_registration_Screen.dart
Future<Position> determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return Future.error('Location permissions are permanently denied.');
  }

  return await Geolocator.getCurrentPosition();
}

// --- Section Widgets ---

class LocationCaptureSection extends StatelessWidget {
  final VoidCallback onCapture;
  final String? imagePath;
  final double? latitude;
  final double? longitude;

  const LocationCaptureSection({
    super.key,
    required this.onCapture,
    this.imagePath,
    this.latitude,
    this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            onPressed: onCapture,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Capture Photo & Location'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: Colors.blue.shade50,
              foregroundColor: Colors.blue.shade900,
            ),
          ),
          if (imagePath != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Captured: ${imagePath!.split('/').last}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (latitude != null && longitude != null) ...[
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: Text(
                'Coordinates: $latitude, $longitude',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> requestPermissionsAndStartService() async {
  PermissionStatus nStatus = await Permission.notification.request();

  if (!nStatus.isGranted) {
    print("Notification permission denied. Service cannot start on Android 14.");
    return;
  }

  PermissionStatus lStatus = await Permission.location.request();

  if (lStatus.isGranted) {
    await Permission.locationAlways.request();
    await Future.delayed(const Duration(seconds: 2));
  }
}
