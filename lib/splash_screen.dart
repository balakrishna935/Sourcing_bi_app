import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mukadam_Screen.dart';
import 'mukadan/authentication/screens/sendOtpScreen.dart';
import 'mukadan/authentication/userProvider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with WidgetsBindingObserver {
  bool _isChecking = true;
  String _errorMessage = "";
  String _failedPermission = "";

  /// All permissions that MUST be granted before the user can proceed.
  /// Media permissions (photos/videos/audio) are resolved at runtime
  /// based on Android SDK version.
  final List<Permission> _basePermissions = [
    Permission.notification,       // Notifications
    Permission.locationWhenInUse,  // Location
    Permission.contacts,           // Contacts
    Permission.phone,              // Phone
    Permission.camera,
    Permission.sms,// Camera (photos + video capture)
  ];

  /// Builds the full required permission list including OS-specific media permissions
  Future<List<Permission>> _getRequiredPermissions() async {
    final List<Permission> permissions = List.from(_basePermissions);

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 33) {
        // Android 13+ uses granular media permissions
        permissions.addAll([
          Permission.photos,     // READ_MEDIA_IMAGES + READ_MEDIA_VIDEO
          Permission.videos,     // READ_MEDIA_VIDEO
          Permission.audio,      // READ_MEDIA_AUDIO
        ]);
      } else {
        // Android 12 and below uses storage permission
        permissions.add(Permission.storage);
      }
    }

    return permissions;
  }

  /// Permission label and icon mapping for the UI

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp(shouldRequest: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-check when user returns from settings
      Future.delayed(const Duration(milliseconds: 500), () {
        _initializeApp(shouldRequest: false);
      });
    }
  }

  Future<void> _initializeApp({required bool shouldRequest}) async {
    if (!mounted) return;

    setState(() {
      _isChecking = true;
      _errorMessage = "";
      _failedPermission = "";
    });

    try {
      final requiredPermissions = await _getRequiredPermissions();

      for (var p in requiredPermissions) {
        var status = await p.status;

        if (!status.isGranted) {
          if (shouldRequest) {
            status = await p.request();
          }

          if (!status.isGranted) {
            final label = _getPermissionLabel(p);
            final icon = _getPermissionIcon(p);

            if (status.isPermanentlyDenied) {
              _setDenied(
                "$label permission is permanently denied.\nPlease enable it from App Settings.",
                label,
                icon,
                isPermanentlyDenied: true,
              );
            } else {
              _setDenied(
                "Please allow $label permission to use this app.",
                label,
                icon,
              );
            }
            return;
          }
        }
      }

      // All permissions granted — proceed
      _proceedToNextScreen();
    } catch (e) {
      _setDenied(
        "Initialization failed. Please check settings manually.",
        "ERROR",
        Icons.error_outline,
      );
    }
  }

  String _getPermissionLabel(Permission permission) {
    if (permission == Permission.notification) return "NOTIFICATIONS";
    if (permission == Permission.locationWhenInUse) return "LOCATION";
    if (permission == Permission.contacts) return "CONTACTS";
    if (permission == Permission.phone) return "PHONE";
    if (permission == Permission.camera) return "CAMERA";
    if (permission == Permission.photos) return "PHOTOS & MEDIA";
    if (permission == Permission.videos) return "VIDEOS";
    if (permission == Permission.audio) return "MUSIC & AUDIO";
    if (permission == Permission.storage) return "STORAGE";
    if (permission == Permission.sms) return "SMS";
    return permission.toString().split('.').last.toUpperCase();
  }

  IconData _getPermissionIcon(Permission permission) {
    if (permission == Permission.notification) return Icons.notifications_active;
    if (permission == Permission.locationWhenInUse) return Icons.location_on;
    if (permission == Permission.contacts) return Icons.contacts;
    if (permission == Permission.phone) return Icons.phone;
    if (permission == Permission.camera) return Icons.camera_alt;
    if (permission == Permission.photos) return Icons.photo_library;
    if (permission == Permission.videos) return Icons.videocam;
    if (permission == Permission.audio) return Icons.music_note;
    if (permission == Permission.storage) return Icons.folder;
    if (permission == Permission.sms) return Icons.sms;
    return Icons.security;
  }

  bool _isPermanentlyDenied = false;
  IconData _failedIcon = Icons.warning_amber_rounded;

  void _setDenied(String message, String permissionName, IconData icon,
      {bool isPermanentlyDenied = false}) {
    if (mounted) {
      setState(() {
        _isChecking = false;
        _errorMessage = message;
        _failedPermission = permissionName;
        _failedIcon = icon;
        _isPermanentlyDenied = isPermanentlyDenied;
      });
    }
  }

  Future<void> _proceedToNextScreen() async {
    if (!mounted) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.loadSavedUser();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => userProvider.isAuthenticated
              ? const MukadamDashboard()
              : const PhoneEntryScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/company.jpeg', width: 200),
                const SizedBox(height: 60),
                if (_isChecking)
                  const Column(
                    children: [
                      CircularProgressIndicator(color: Colors.blue),
                      SizedBox(height: 20),
                      Text(
                        "Checking permissions...",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  )
                else
                  _buildRequirementUI(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequirementUI() {
    return Column(
      children: [
        // Permission icon
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(_failedIcon, size: 48, color: Colors.orange.shade700),
        ),
        const SizedBox(height: 20),

        // Permission name
        Text(
          _failedPermission,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),

        // Error message
        Text(
          _errorMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 12),

        // Required permissions info box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "All permissions are mandatory for the app to function properly.",
                  style: TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),

        // Open Settings button
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () => openAppSettings(),
          icon: const Icon(Icons.settings, color: Colors.white),
          label: const Text(
            "OPEN APP SETTINGS",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Retry button
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            side: const BorderSide(color: Colors.blue),
          ),
          onPressed: () => _initializeApp(shouldRequest: true),
          icon: const Icon(Icons.refresh),
          label: const Text("I've Enabled All — Check Again"),
        ),
      ],
    );
  }
}
