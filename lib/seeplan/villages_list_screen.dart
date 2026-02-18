// lib/seeplan/villageslistscreen.dart
// FULL CODE — VillagePlansDashboard with LanguageProvider + SeePlanStrings

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mukadam_bi/seeplan/plan_Service_file.dart';
import 'package:mukadam_bi/seeplan/plan_list_screen.dart';
import 'package:mukadam_bi/seeplan/plan_service_model.dart';
import 'package:provider/provider.dart';

import '../language_jsons/seeplan_strings.dart';
import '../provider/language_provider.dart';

class VillagePlansDashboard extends StatefulWidget {
  const VillagePlansDashboard({super.key});

  @override
  State<VillagePlansDashboard> createState() => _VillagePlansDashboardState();
}

class _VillagePlansDashboardState extends State<VillagePlansDashboard>
    with SingleTickerProviderStateMixin {
  final PlanService planService = PlanService();
  List<VillageVisitPlan> plans = [];
  bool isLoading = true;
  String errorMessage = '';

  // Filter states
  String selectedFilter = 'today';
  DateTime? startDate;
  DateTime? endDate;

  // Stats
  int totalPlans = 0;
  int completedPlans = 0;
  int inProgressPlans = 0;
  int plannedPlans = 0;
  int totalVillages = 0;

  // ---- Color Palette (matching MukadamDashboard) ----
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
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color dividerColor = Color(0xFFF3F4F6);

  // ---- Helper: get translated string ----
  String _t(String key) {
    final lang = context.read<LanguageProvider>().language;
    return SeePlanStrings.get(key, lang);
  }

  @override
  void initState() {
    super.initState();
    loadPlans();
  }

  // ======================== DATA LOADING ========================
  Future<void> loadPlans() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      String? apiStatus;
      if (selectedFilter != 'today' && selectedFilter != 'all') {
        apiStatus = selectedFilter;
      }

      String? dateFrom = selectedFilter != 'today' && startDate != null
          ? DateFormat('yyyy-MM-dd').format(startDate!)
          : null;
      String? dateTo = selectedFilter != 'today' && endDate != null
          ? DateFormat('yyyy-MM-dd').format(endDate!)
          : null;

      final plans = await planService.fetchVisitPlans(
        status: apiStatus,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );

      List<VillageVisitPlan> filteredPlans;

      if (selectedFilter == 'today') {
        final today = DateTime.now();
        final todayDateOnly = DateTime(today.year, today.month, today.day);
        filteredPlans = plans.where((plan) {
          try {
            final planStartDate = DateTime.parse(plan.startDate);
            final planEndDate = DateTime.parse(plan.endDate);
            final planStartDateOnly = DateTime(
                planStartDate.year, planStartDate.month, planStartDate.day);
            final planEndDateOnly = DateTime(
                planEndDate.year, planEndDate.month, planEndDate.day);
            return (todayDateOnly.isAtSameMomentAs(planStartDateOnly) ||
                todayDateOnly.isAfter(planStartDateOnly)) &&
                (todayDateOnly.isAtSameMomentAs(planEndDateOnly) ||
                    todayDateOnly.isBefore(planEndDateOnly));
          } catch (_) {
            return false;
          }
        }).toList();
      } else if (selectedFilter == 'planned') {
        final today = DateTime.now();
        final todayDateOnly = DateTime(today.year, today.month, today.day);
        filteredPlans = plans.where((plan) {
          try {
            final planStartDate = DateTime.parse(plan.startDate);
            final planStartDateOnly = DateTime(
                planStartDate.year, planStartDate.month, planStartDate.day);
            if (planStartDateOnly.isBefore(todayDateOnly)) return false;
            if (startDate != null) {
              final filterFrom =
              DateTime(startDate!.year, startDate!.month, startDate!.day);
              if (planStartDateOnly.isBefore(filterFrom)) return false;
            }
            if (endDate != null) {
              final filterTo =
              DateTime(endDate!.year, endDate!.month, endDate!.day);
              if (planStartDateOnly.isAfter(filterTo)) return false;
            }
            return true;
          } catch (_) {
            return true;
          }
        }).toList();
      } else {
        filteredPlans = plans.where((plan) {
          try {
            final planStartDate = DateTime.parse(plan.startDate);
            final planStartDateOnly = DateTime(
                planStartDate.year, planStartDate.month, planStartDate.day);
            if (startDate != null) {
              final filterFrom =
              DateTime(startDate!.year, startDate!.month, startDate!.day);
              if (planStartDateOnly.isBefore(filterFrom)) return false;
            }
            if (endDate != null) {
              final filterTo =
              DateTime(endDate!.year, endDate!.month, endDate!.day);
              if (planStartDateOnly.isAfter(filterTo)) return false;
            }
            return true;
          } catch (_) {
            return true;
          }
        }).toList();
      }

      // Sort: for today filter, completed goes to the bottom
      if (selectedFilter == 'today') {
        filteredPlans.sort((a, b) {
          final aCompleted = a.status == 'completed' ? 1 : 0;
          final bCompleted = b.status == 'completed' ? 1 : 0;
          if (aCompleted != bCompleted) return aCompleted.compareTo(bCompleted);
          try {
            final dateA = DateTime.parse(a.startDate);
            final dateB = DateTime.parse(b.startDate);
            return dateA.compareTo(dateB);
          } catch (_) {
            return a.startDate.compareTo(b.startDate);
          }
        });
      } else {
        filteredPlans.sort((a, b) {
          try {
            final dateA = DateTime.parse(a.startDate);
            final dateB = DateTime.parse(b.startDate);
            return dateA.compareTo(dateB);
          } catch (_) {
            return a.startDate.compareTo(b.startDate);
          }
        });
      }

      _calculateStats(filteredPlans);

      setState(() {
        this.plans = filteredPlans;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  void _calculateStats(List<VillageVisitPlan> plans) {
    totalPlans = plans.length;
    completedPlans = plans.where((p) => p.status == 'completed').length;
    inProgressPlans = plans.where((p) => p.status == 'inprogress').length;
    plannedPlans = plans.where((p) => p.status == 'planned').length;
    totalVillages = plans.fold(
        0,
            (sum, plan) =>
        sum +
            plan.dailyPlans.fold(0, (s, dp) => s + dp.villageVisits.length));
  }

  void onFilterChanged(String filter) {
    setState(() {
      selectedFilter = filter;
    });
    loadPlans();
  }

  // ======================== DATE PICKERS ========================
  Future<void> selectStartDate() async {
    final lang = context.read<LanguageProvider>().language;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      helpText: SeePlanStrings.get('selectstartdate', lang),
      confirmText: SeePlanStrings.get('ok', lang),
      cancelText: SeePlanStrings.get('cancel', lang),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        startDate = picked;
        if (selectedFilter == 'today') selectedFilter = 'all';
        if (endDate != null && endDate!.isBefore(startDate!)) endDate = null;
      });
      loadPlans();
    }
  }

  Future<void> selectEndDate() async {
    final lang = context.read<LanguageProvider>().language;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? startDate ?? DateTime.now(),
      firstDate: startDate ?? DateTime(2024),
      lastDate: DateTime(2030),
      helpText: SeePlanStrings.get('selectenddate', lang),
      confirmText: SeePlanStrings.get('ok', lang),
      cancelText: SeePlanStrings.get('cancel', lang),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        endDate = picked;
        if (selectedFilter == 'today') selectedFilter = 'all';
      });
      loadPlans();
    }
  }

  void clearDateFilter() {
    setState(() {
      startDate = null;
      endDate = null;
    });
    loadPlans();
  }

  // ======================== HELPERS ========================
  String _getStatusDisplayText(String status, String statusDisplay) {
    final lang = context.read<LanguageProvider>().language;
    if (status == 'planned') return SeePlanStrings.get('upcomingplan', lang);
    if (statusDisplay.isNotEmpty) return statusDisplay;
    return status.replaceAll('_', ' ');
  }

  Color getStatusColor(String status) {
    switch (status) {
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

  Color getStatusBgColor(String status) {
    switch (status) {
      case 'completed':
        return successColor.withOpacity(0.1);
      case 'inprogress':
        return warningColor.withOpacity(0.1);
      case 'planned':
        return accentColor.withOpacity(0.1);
      default:
        return dividerColor;
    }
  }

  IconData getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle_rounded;
      case 'inprogress':
        return Icons.timelapse_rounded;
      case 'planned':
        return Icons.event_note_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  // ✅ FIXED — In _getVillageNames():
  List<String> _getVillageNames(VillageVisitPlan plan, String lang) {
    final List<String> names = [];
    for (var dp in plan.dailyPlans) {
      for (var visit in dp.villageVisits) {
        names.add(visit.getDisplayVillage(lang));
      }
    }
    return names;
  }




  // ======================== BUILD ========================
  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().language;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              SeePlanStrings.get('villagevisitplans', lang),
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              '$totalPlans ${SeePlanStrings.get('plans', lang)} · $totalVillages ${SeePlanStrings.get('villages', lang)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadPlans,
          color: primaryColor,
          backgroundColor: cardColor,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildStatsSection(lang)),
              SliverToBoxAdapter(child: _buildFiltersSection(lang)),
              _buildContentSection(lang),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  // ======================== STATS SECTION ========================
  Widget _buildStatsSection(String lang) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel(SeePlanStrings.get('overview', lang)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  SeePlanStrings.get('completed', lang),
                  completedPlans.toString(),
                  Icons.check_circle_outline_rounded,
                  successColor,
                  successColor.withOpacity(0.1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  SeePlanStrings.get('inprogress', lang),
                  inProgressPlans.toString(),
                  Icons.timelapse_rounded,
                  warningColor,
                  warningColor.withOpacity(0.1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  SeePlanStrings.get('upcoming', lang),
                  plannedPlans.toString(),
                  Icons.event_note_rounded,
                  accentColor,
                  accentColor.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: textPrimary,
              letterSpacing: -0.5,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ======================== FILTERS SECTION ========================
  Widget _buildFiltersSection(String lang) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel(SeePlanStrings.get('filters', lang)),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildFilterChip(
                    SeePlanStrings.get('today', lang), 'today', Icons.today_rounded),
                const SizedBox(width: 8),
                _buildFilterChip(
                    SeePlanStrings.get('all', lang), 'all', Icons.grid_view_rounded),
                const SizedBox(width: 8),
                _buildFilterChip(SeePlanStrings.get('upcoming', lang), 'planned',
                    Icons.event_note_rounded),
                const SizedBox(width: 8),
                _buildFilterChip(SeePlanStrings.get('completed', lang),
                    'completed', Icons.check_circle_rounded),
                const SizedBox(width: 8),
                _buildFilterChip(SeePlanStrings.get('inprogress', lang),
                    'inprogress', Icons.timelapse_rounded),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildSimpleDateFilter(lang),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = selectedFilter == value;
    Color chipColor;
    switch (value) {
      case 'today':
        chipColor = purpleColor;
        break;
      case 'completed':
        chipColor = successColor;
        break;
      case 'inprogress':
        chipColor = warningColor;
        break;
      case 'planned':
        chipColor = accentColor;
        break;
      default:
        chipColor = primaryColor;
    }
    return GestureDetector(
      onTap: () => onFilterChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? chipColor : borderColor,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: chipColor.withOpacity(0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: isSelected ? Colors.white : textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleDateFilter(String lang) {
    final hasStart = startDate != null;
    final hasEnd = endDate != null;
    final dateFormat = DateFormat('dd MMM yy');
    return Row(
      children: [
        // Start Date
        Expanded(
          child: GestureDetector(
            onTap: selectStartDate,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: hasStart ? primaryColor : borderColor,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      color: hasStart ? primaryColor : textSecondary,
                      size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          SeePlanStrings.get('from', lang),
                          style: TextStyle(
                            fontSize: 9,
                            color: hasStart ? primaryColor : textSecondary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          hasStart
                              ? dateFormat.format(startDate!)
                              : SeePlanStrings.get('selectdate', lang),
                          style: TextStyle(
                            fontSize: 12,
                            color: hasStart ? textPrimary : textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.arrow_forward_rounded,
              size: 14, color: textSecondary.withOpacity(0.5)),
        ),
        // End Date
        Expanded(
          child: GestureDetector(
            onTap: selectEndDate,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: hasEnd ? primaryColor : borderColor,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.event_rounded,
                      color: hasEnd ? primaryColor : textSecondary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          SeePlanStrings.get('to', lang),
                          style: TextStyle(
                            fontSize: 9,
                            color: hasEnd ? primaryColor : textSecondary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          hasEnd
                              ? dateFormat.format(endDate!)
                              : SeePlanStrings.get('selectdate', lang),
                          style: TextStyle(
                            fontSize: 12,
                            color: hasEnd ? textPrimary : textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Clear button
        if (hasStart || hasEnd) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: clearDateFilter,
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: errorColor.withOpacity(0.3)),
              ),
              child: const Icon(Icons.close_rounded,
                  size: 16, color: errorColor),
            ),
          ),
        ],
      ],
    );
  }

  // ======================== CONTENT SECTION ========================
  Widget _buildContentSection(String lang) {
    if (isLoading) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: CircularProgressIndicator(
              color: primaryColor, strokeWidth: 2.5),
        ),
      );
    }
    if (errorMessage.isNotEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildErrorWidget(lang),
      );
    }
    if (plans.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildEmptyWidget(lang),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 300 + index * 80),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 12 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: _buildPlanCard(plans[index], lang),
            );
          },
          childCount: plans.length,
        ),
      ),
    );
  }

  // ======================== PLAN CARD ========================
  Widget _buildPlanCard(VillageVisitPlan plan, String lang) {
    final statusColor = getStatusColor(plan.status);
    final statusBgColor = getStatusBgColor(plan.status);
    final statusIcon = getStatusIcon(plan.status);
    final bool isMarathi = lang == 'mr';

    int totalVillages = 0;
    int completedVillages = 0;
    for (var dp in plan.dailyPlans) {
      totalVillages += dp.villageVisits.length;
      completedVillages +=
          dp.villageVisits.where((v) => v.status == 'completed').length;
    }
    double progress =
    totalVillages > 0 ? completedVillages / totalVillages : 0;

    final villageNames = _getVillageNames(plan, lang);
    final villageDisplayText = villageNames.isNotEmpty
        ? villageNames.join(', ')
        : SeePlanStrings.get('novillages', lang);

    // Dynamic: show Marathi plan name if available
    // ✅ FIXED — In _buildPlanCard():
    final planDisplayName = plan.getDisplayName(lang);
// Was: plan.planName / plan.marathiPlanName (showed BOTH)


    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DailyPlansScreen(plan: plan),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            planDisplayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: textPrimary,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              _getStatusDisplayText(
                                  plan.status, plan.statusDisplay),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right_rounded,
                        color: textSecondary.withOpacity(0.5), size: 20),
                  ],
                ),
                const SizedBox(height: 14),
                // Info Row
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _buildInfoItem(Icons.calendar_today_rounded,
                              '${plan.startDate} → ${plan.endDate}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 14, color: textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '$villageDisplayText ($totalVillages)',
                              style: const TextStyle(
                                fontSize: 11,
                                color: textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          _buildInfoItem(Icons.view_day_outlined,
                              '${plan.dailyPlans.length} ${SeePlanStrings.get('days', lang)}'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Progress Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$completedVillages ${SeePlanStrings.get('of', lang)} $totalVillages ${SeePlanStrings.get('villages', lang).toLowerCase()}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: dividerColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: textSecondary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: textPrimary,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ======================== SECTION LABEL ========================
  Widget _buildSectionLabel(String label) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: textPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  // ======================== ERROR WIDGET ========================
  Widget _buildErrorWidget(String lang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: errorColor.withOpacity(0.3)),
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  size: 36, color: errorColor),
            ),
            const SizedBox(height: 20),
            Text(
              SeePlanStrings.get('somethingwentwrong', lang),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: textSecondary,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: loadPlans,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(
                SeePlanStrings.get('tryagain', lang),
                style:
                const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ======================== EMPTY WIDGET ========================
  Widget _buildEmptyWidget(String lang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: dividerColor,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor),
              ),
              child: Icon(Icons.inbox_rounded,
                  size: 36, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 20),
            Text(
              SeePlanStrings.get('noplansfound', lang),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              SeePlanStrings.get('tryadjustingfilters', lang),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: textSecondary,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  selectedFilter = 'today';
                  startDate = null;
                  endDate = null;
                });
                loadPlans();
              },
              icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
              label: Text(
                SeePlanStrings.get('clearfilters', lang),
                style:
                const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                side: const BorderSide(color: primaryColor, width: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
