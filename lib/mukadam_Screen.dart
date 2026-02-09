import 'package:call_log/call_log.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mukadam_bi/call_stack.dart';
import 'package:mukadam_bi/referral/user_referral_mukadam_screen.dart';
import 'package:mukadam_bi/seeplan/plan_list_screen.dart';
import 'package:mukadam_bi/seeplan/villages_list_screen.dart';


import 'package:mukadam_bi/transport/Transport_provider/transport_provider_Screen.dart';
import 'package:mukadam_bi/verifications/mukadam_dashboard/mukadam_dashborad.dart';
import 'package:mukadam_bi/verifications/transporter_verifcations/verification_transporter_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'AnalyticsDebugService.dart';

import 'dial_pad_screen.dart';

import 'firebase_message.dart';
import 'getTransport/gettransportscreen.dart';

import 'mukadan/authentication/screens/sendOtpScreen.dart';
import 'mukadan/authentication/userProvider.dart';
import 'mukadan/quick_registration/quick_registration_Screen.dart';

import 'notes/end_Screen.dart';
import 'notes/todo_screen.dart';
import 'notes/visitApiService.dart';

import 'package:geolocator/geolocator.dart' as geo;

class MukadamDashboard extends StatefulWidget {
  const MukadamDashboard({super.key});

  @override
  State<MukadamDashboard> createState() => _MukadamDashboardState();
}

class _MukadamDashboardState extends State<MukadamDashboard> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  late final List<Widget> _pages;
  bool _isCalling = false;

  // Professional Color Palette
  static const Color _primaryColor = Color(0xFF1E3A5F);
  static const Color _accentColor = Color(0xFF3B82F6);
  static const Color _successColor = Color(0xFF10B981);
  static const Color _warningColor = Color(0xFFF59E0B);
  static const Color _errorColor = Color(0xFFEF4444);
  static const Color _purpleColor = Color(0xFF8B5CF6);
  static const Color _backgroundColor = Color(0xFFF8FAFC);
  static const Color _cardColor = Colors.white;
  static const Color _textPrimary = Color(0xFF1F2937);
  static const Color _textSecondary = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pages = [
      _buildDashboardContent(),
      const DialPadScreen(),
    ];
    _setupFCM();

    _initializeAnalytics();
  }

  Future<void> _initializeAnalytics() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user != null) {
      await FirebaseAnalytics.instance.setUserId(
        id: userProvider.user!.id.toString(),
      );
      await FirebaseAnalytics.instance.setUserProperty(
        name: 'user_role',
        value: userProvider.user!.role ?? 'unknown',
      );
      await FirebaseAnalytics.instance.setUserProperty(
        name: 'user_mobile',
        value: userProvider.user!.mobileNumber ?? 'unknown',
      );
    }
    await FirebaseAnalytics.instance.logScreenView(
      screenName: 'MukadamDashboard',
      screenClass: 'MukadamDashboard',
    );
  }

  Future<void> _initiateCall() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String userMobile = userProvider.user?.mobileNumber ?? "";

    await AnalyticsDebugService.logDebugEvent('central_team_number', params: {
      'user_id': userProvider.user?.id ?? 'unknown',
      'user_mobile': userMobile,
      'time': DateTime.now().toIso8601String(),
    });

    if (userMobile.isEmpty) {
      _showSnackBar("User mobile number not found", isError: true);
      return;
    }

    setState(() => _isCalling = true);

    try {
      final String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // This call internally saves centralPhone to SharedPreferences
      await VisitApiService().fetchTodayVisits(todayDate);

      final prefs = await SharedPreferences.getInstance();
      final String centralPhone = prefs.getString("centralPhone") ?? "";
      final int? userId = prefs.getInt('bg_user_id');

      if (centralPhone.isEmpty) {
        throw Exception("Central team phone number not available.");
      }

      final response = await CallApiService.makeCall(
        fromNumber: centralPhone,
        toNumber: userMobile,
        userId: userId,
      );

      if (response['success'] == true) {
        _showSnackBar(response['message'] ?? "Call initiated successfully");
      } else {
        throw Exception(response['message'] ?? "Failed to initiate call");
      }
    } catch (e) {
      _showSnackBar(e.toString().replaceAll("Exception: ", ""), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isCalling = false);
      }
    }
  }


  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 14)),
        backgroundColor: isError ? _errorColor : _successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _setupFCM() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user != null) {
      print('--- INITIALIZING FCM ON DASHBOARD ---');
      await FirebaseMsg().initFCM(
        userProvider.user!.id.toString(),
        userProvider.user!.mobileNumber.toString(),
      );
    }
  }

  // At the top of mukadam_Screen.dart — add this import
   // ✅ Import your SmsService file

// Then update _syncAllData() — replace the SMS section:



  Future<void> _handleLogout() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.logout_rounded, color: _errorColor, size: 32),
            ),
            const SizedBox(height: 20),
            const Text(
              'Logout',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Are you sure you want to logout?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: _textSecondary),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _errorColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      await AnalyticsDebugService.logDebugEvent('user_logout', params: {
        'user_id': userProvider.user?.id ?? 'unknown',
        'username': userProvider.user?.username ?? 'unknown',
        'logout_time': DateTime.now().toIso8601String(),
      });

      await FirebaseAnalytics.instance.setUserId(id: null);
      await userProvider.logout();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const PhoneEntryScreen()),
              (route) => false,
        );
      }
    }
  }

  void _onItemTapped(int index) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    String tabName = index == 0 ? "Home" : "Create Plan";

    AnalyticsDebugService.logDebugEvent('bottom_navigation_click', params: {
      'user_id': userProvider.user?.id ?? 'unknown',
      'tab_index': index,
      'tab_name': tabName,
      'time': DateTime.now().toIso8601String(),
    });

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: _primaryColor,
        title: const Text(
          "Mukadam Management",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _handleLogout,
            icon: const Icon(
              Icons.logout_rounded,
              color: Colors.white,
              size: 22,
            ),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _selectedIndex < _pages.length
          ? _pages[_selectedIndex]
          : const Center(child: Text("Page not found")),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _selectedIndex == 0 ? _buildCallFAB() : null,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildCallFAB() {
    return Container(
      height: 60,
      width: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_successColor, _successColor.withGreen(200)],
        ),
        boxShadow: [
          BoxShadow(
            color: _successColor.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: _isCalling ? null : _initiateCall,
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: const CircleBorder(),
        child: _isCalling
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.5,
          ),
        )
            : const Icon(Icons.call_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      children: [
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.05,
          children: [
            _buildActionCard(
              "Quick\nRegistration",
              Icons.bolt_rounded,
              _warningColor,
              const QuickMukkadamRegistrationScreen(),
            ),
            _buildActionCard(
              "See\nPlans",
              Icons.route_rounded,
              _warningColor,
              const VillagePlansDashboard(),
            ),
            _buildActionCard(
              "Transport\nRegistration",
              Icons.local_shipping_rounded,
              _errorColor,
              const TransportProviderScreen(),
            ),
            _buildActionCard(
              "On\nBoarded",
              Icons.people_alt_rounded,
              _successColor,
              const DirectoryScreen(),
            ),
            _buildActionCard(
              "Mukadam\nVerification",
              Icons.verified_user_rounded,
              _accentColor,
              const MukkadamListScreen(),
            ),
            _buildActionCard(
              "Transport\nVerification",
              Icons.fact_check_rounded,
              _errorColor,
              const PendingVerificationListScreen(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, Widget destination) {
    return GestureDetector(
      onTap: () async {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        String validEventName = title
            .replaceAll('\n', '_')
            .replaceAll(' ', '_')
            .toLowerCase();

        await AnalyticsDebugService.logDebugEvent(validEventName, params: {
          'user_id': userProvider.user?.id ?? 'unknown',
          'card_title': title.replaceAll('\n', ' '),
          'destination_screen': destination.runtimeType.toString(),
          'click_time': DateTime.now().toIso8601String(),
        });

        if (mounted) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => destination));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: _textPrimary,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideCard(String title, String subtitle, IconData icon, Widget destination) {
    return GestureDetector(
      onTap: () async {
        await AnalyticsDebugService.logDebugEvent('dashboard_wide_card_click', params: {
          'card_title': title,
          'subtitle': subtitle,
          'destination_screen': destination.runtimeType.toString(),
          'click_time': DateTime.now().toIso8601String(),
        });

        if (mounted) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => destination));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: _textSecondary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.grey.shade300,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.grid_view_rounded, "Home", 0),
              const SizedBox(width: 60),
              _navItem(Icons.dialpad_rounded, "Dialpad", 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    bool isActive = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? _accentColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? _accentColor : _textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? _accentColor : _textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildPlanTile(Map<String, dynamic> plan) {
  return ListTile(
    title: Text(plan['purpose'] ?? "No Purpose"),
    subtitle: Text(plan['location_summary'] ?? "No locations selected"),
  );
}
