// lib/seeplan/planlistscreen.dart
// FULL CODE — DailyPlansScreen with LanguageProvider + SeePlanStrings

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mukadam_bi/seeplan/plan_Service_file.dart';
import 'package:mukadam_bi/seeplan/plan_service_model.dart';
import 'package:mukadam_bi/seeplan/village_execution_screen.dart';
import 'package:provider/provider.dart';

import 'package:url_launcher/url_launcher.dart';

import '../language_jsons/seeplan_strings.dart';
import '../provider/language_provider.dart';

class DailyPlansScreen extends StatefulWidget {
  final VillageVisitPlan plan;

  const DailyPlansScreen({super.key, required this.plan});

  @override
  State<DailyPlansScreen> createState() => _DailyPlansScreenState();
}

class _DailyPlansScreenState extends State<DailyPlansScreen> with RouteAware {
  int selectedDayIndex = 0;
  late VillageVisitPlan currentPlan;
  bool isLoading = false;
  final PlanService planService = PlanService();

  static final RouteObserver<ModalRoute<void>> routeObserver =
  RouteObserver<ModalRoute<void>>();

  // ---- Color Palette ----
  static const Color primaryColor = Color(0xFF1E3A5F);
  static const Color accentColor = Color(0xFF3B82F6);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color purpleColor = Color(0xFF8B5CF6);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    currentPlan = widget.plan;
    _loadPlanData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    super.didPopNext();
    _loadPlanData();
  }

  // ======================== DATA ========================
  Future<void> _loadPlanData() async {
    if (isLoading) return;
    setState(() => isLoading = true);
    try {
      final plans = await planService.fetchVisitPlans();
      final updatedPlan = plans.firstWhere(
            (p) => p.id == currentPlan.id,
        orElse: () => currentPlan,
      );
      if (mounted) {
        setState(() {
          currentPlan = updatedPlan;
          if (selectedDayIndex >= currentPlan.dailyPlans.length) {
            selectedDayIndex = currentPlan.dailyPlans.isNotEmpty
                ? currentPlan.dailyPlans.length - 1
                : 0;
          }
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading plan data: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _onRefresh() async {
    await _loadPlanData();
  }

  // ======================== HELPERS ========================
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return successColor;
      case 'inprogress':
        return warningColor;
      case 'planned':
        return accentColor;
      default:
        return textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle_rounded;
      case 'inprogress':
        return Icons.access_time_filled_rounded;
      case 'planned':
        return Icons.event_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('EEE, MMM dd, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _getDayName(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('EEE').format(date);
    } catch (e) {
      return '';
    }
  }

  String _getDayNumber(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd').format(date);
    } catch (e) {
      return '';
    }
  }

  Future<void> _openDirections(double latitude, double longitude) async {
    final lang = context.read<LanguageProvider>().language;
    final directionsUri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving');
    final navigationUri = Uri.parse(
        'google.navigation:q=$latitude,$longitude&mode=d');
    try {
      if (await launchUrl(directionsUri,
          mode: LaunchMode.externalApplication)) return;
      if (await launchUrl(navigationUri)) return;
      _showSnackBar(SeePlanStrings.get('couldnotopendir', lang));
    } catch (e) {
      _showSnackBar(SeePlanStrings.get('erroropeningdir', lang));
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(fontSize: 14)),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _navigateToExecution(VillageVisit village) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VillageExecutionScreen(village: village),
      ),
    ).then((_) => _loadPlanData());
  }

  // ======================== VILLAGE TAP HANDLER ========================
  void _handleVillageTap(VillageVisit village) {
    final status = village.status.toLowerCase();
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    final plannedDateOnly = DateTime(
      village.plannedDate.year,
      village.plannedDate.month,
      village.plannedDate.day,
    );

    // Past date: allow access to execution for ALL statuses
    if (plannedDateOnly.isBefore(todayDateOnly)) {
      _navigateToExecution(village);
      return;
    }

    // Today or future: completed visits show dialog
    if (status == 'completed') {
      _showCompletedDialog();
      return;
    }

    if (status == 'inprogress') {
      _navigateToExecution(village);
      return;
    }

    if (status == 'planned') {
      if (plannedDateOnly.isAfter(todayDateOnly)) {
        _showNotAvailableDialog(village.plannedDate);
        return;
      }
      _navigateToExecution(village);
      return;
    }

    _navigateToExecution(village);
  }

  // ======================== DIALOGS ========================
  void _showCompletedDialog() {
    final lang = context.read<LanguageProvider>().language;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: successColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: successColor, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              SeePlanStrings.get('visitcompleted', lang),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              SeePlanStrings.get('visitcompletedmsg', lang),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: successColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text(
                  SeePlanStrings.get('ok', lang),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotAvailableDialog(DateTime plannedDate) {
    final lang = context.read<LanguageProvider>().language;
    final formattedDate = DateFormat('dd MMM yyyy').format(plannedDate);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: warningColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.schedule_rounded,
                  color: warningColor, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              SeePlanStrings.get('notyetavailable', lang),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${SeePlanStrings.get('visitscheduledfor', lang)} $formattedDate.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: warningColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      SeePlanStrings.get('startvisitafter', lang),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: warningColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text(
                  SeePlanStrings.get('okgotit', lang),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRestrictedAccessDialog() {
    final lang = context.read<LanguageProvider>().language;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.block_rounded,
                  color: Colors.red, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              SeePlanStrings.get('planaccessdenied', lang),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              SeePlanStrings.get('cantaccessvillage', lang),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text(
                  SeePlanStrings.get('ok', lang),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ======================== BUILD ========================
  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().language;
    final dailyPlans = currentPlan.dailyPlans;
    final bool isMarathi = lang == 'mr';

    // Dynamic plan name
    // ✅ FIXED — In AppBar title:
    final planDisplayName = currentPlan.getDisplayName(lang);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              planDisplayName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '${currentPlan.startDate} - ${currentPlan.endDate}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (dailyPlans.isNotEmpty) _buildDaySelector(dailyPlans, lang),
              Expanded(
                child: dailyPlans.isEmpty
                    ? _buildEmptyState(lang)
                    : RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: primaryColor,
                  child: _buildVillageList(
                      dailyPlans[selectedDayIndex], lang),
                ),
              ),
            ],
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.1),
              child: const Center(
                child: CircularProgressIndicator(color: primaryColor),
              ),
            ),
        ],
      ),
    );
  }

  // ======================== DAY SELECTOR ========================
  Widget _buildDaySelector(List<DailyPlan> dailyPlans, String lang) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Text(
              SeePlanStrings.get('selectday', lang),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                letterSpacing: 0.3,
              ),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 74),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              itemCount: dailyPlans.length,
              itemBuilder: (context, index) {
                final dp = dailyPlans[index];
                final isSelected = index == selectedDayIndex;
                final statusColor = _getStatusColor(dp.status);

                return GestureDetector(
                  onTap: () => setState(() => selectedDayIndex = index),
                  child: Container(
                    width: 56,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                        colors: [
                          primaryColor,
                          primaryColor.withOpacity(0.8)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                          : null,
                      color: isSelected ? null : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? primaryColor
                            : Colors.grey.shade200,
                        width: isSelected ? 2 : 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                          : [],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getDayName(dp.visitDate),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? Colors.white70
                                  : textSecondary,
                              letterSpacing: 0.3,
                              height: 1.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _getDayNumber(dp.visitDate),
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: isSelected
                                  ? Colors.white
                                  : textPrimary,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : statusColor,
                              shape: BoxShape.circle,
                              boxShadow: isSelected
                                  ? [
                                BoxShadow(
                                  color:
                                  Colors.white.withOpacity(0.5),
                                  blurRadius: 4,
                                ),
                              ]
                                  : [],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ======================== VILLAGE LIST ========================
  Widget _buildVillageList(DailyPlan dailyPlan, String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey.shade50, backgroundColor],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      SeePlanStrings.get('villagestovisit', lang),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(dailyPlan.visitDate),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: textPrimary,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
        Expanded(
          child: dailyPlan.villageVisits.isEmpty
              ? _buildNoVillagesState(lang)
              : ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: dailyPlan.villageVisits.length,
            itemBuilder: (context, index) {
              return _buildVillageCard(
                  dailyPlan.villageVisits[index], index + 1, lang);
            },
          ),
        ),
      ],
    );
  }

  // ======================== NO VILLAGES STATE ========================
  Widget _buildNoVillagesState(String lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.location_off_rounded,
                size: 48, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 20),
          Text(
            SeePlanStrings.get('novillagesscheduled', lang),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            SeePlanStrings.get('novisitsplanned', lang),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ======================== EMPTY STATE ========================
  Widget _buildEmptyState(String lang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.event_busy_rounded,
                  size: 52, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 20),
            Text(
              SeePlanStrings.get('nodailyplans', lang),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              SeePlanStrings.get('noscheduledvisits', lang),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ======================== VILLAGE CARD ========================
  Widget _buildVillageCard(VillageVisit village, int index, String lang) {
    final statusColor = _getStatusColor(village.status);
    final latitude = village.villageLatitude ?? 21.4572;
    final longitude = village.villageLongitude ?? 80.1312;
    final bool isMarathi = lang == 'mr';
    final isPlanned = village.status.toLowerCase() == 'planned';

    // Dynamic: village name, taluka, district based on language

    // ✅ FIXED — In _buildVillageCard():
    final villageName = village.getDisplayVillage(lang);
    final talukaName = village.getDisplayTaluka(lang);
    final districtName = village.getDisplayDistrict(lang);

// Was checking isMarathi manually — now the method handles it





    // Status display text
    final displayStatus = isPlanned
        ? SeePlanStrings.get('upcomingplan', lang)
        : village.statusDisplay.isNotEmpty
        ? village.statusDisplay
        : village.status.replaceAll('_', ' ');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _handleVillageTap(village),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Index badge
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [statusColor, statusColor.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // DYNAMIC: Village name (English / Marathi)
                      Text(
                        villageName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: textPrimary,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const SizedBox(width: 5),
                          Expanded(
                            // DYNAMIC: Taluka, District (English / Marathi)
                            child: Text(
                              '$talukaName, $districtName',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Expected Registrations + Status
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: purpleColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: purpleColor.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.people_rounded,
                                    size: 15, color: purpleColor),
                                const SizedBox(width: 6),
                                Text(
                                  '${village.expectedRegistrations}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: purpleColor,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: statusColor.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 7),
                                  Flexible(
                                    child: Text(
                                      displayStatus,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.2,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Directions button
                GestureDetector(
                  onTap: () => _openDirections(latitude, longitude),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          successColor,
                          successColor.withOpacity(0.8)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: successColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.directions_rounded,
                        color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
