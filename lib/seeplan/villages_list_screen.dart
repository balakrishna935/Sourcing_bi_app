import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:mukadam_bi/seeplan/plan_Service_file.dart';
import 'package:mukadam_bi/seeplan/plan_list_screen.dart';
import 'package:mukadam_bi/seeplan/plan_service_model.dart';

class VillagePlansDashboard extends StatefulWidget {
  const VillagePlansDashboard({super.key});

  @override
  State<VillagePlansDashboard> createState() => _VillagePlansDashboardState();
}

class _VillagePlansDashboardState extends State<VillagePlansDashboard>
    with SingleTickerProviderStateMixin {
  final PlanService _planService = PlanService();

  List<VillageVisitPlan> _plans = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // Filter states - single unified filter (mutually exclusive)
  // Possible values: 'today', 'all', 'planned', 'in_progress', 'completed'
  String _selectedFilter = 'today'; // DEFAULT set to 'today'
  DateTime? _startDate;
  DateTime? _endDate;

  bool isMarathi = false;       // ✅ ADD
  bool isTranslating = false;   // ✅ ADD



  // Stats
  int _totalPlans = 0;
  int _completedPlans = 0;
  int _inProgressPlans = 0;
  int _plannedPlans = 0;
  int _totalVillages = 0;



  static const Map<String, String> _mr = {
    'Today': 'आज',
    'All': 'सर्व',
    'Upcoming': 'आगामी',
    'Completed': 'पूर्ण',
    'In Progress': 'प्रगतीपथावर',
    'Overview': 'आढावा',
    'Filters': 'फिल्टर',
    'Village Visit Plans': 'गाव भेट योजना',
    'Plans': 'योजना',
    'Villages': 'गावे',
    'Days': 'दिवस',
    'Upcoming Plan': 'आगामी योजना',
    'No Plans Found': 'योजना सापडल्या नाहीत',
    'Something went wrong': 'काहीतरी चूक झाली',
    'Try Again': 'पुन्हा प्रयत्न करा',
    'Clear Filters': 'फिल्टर काढा',
  };


  static String _label(String eng) {
    final mr = _mr[eng];
    return mr != null ? '$eng / $mr' : eng;
  }





  // ── Professional Color Palette (matching MukadamDashboard) ──
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
  static const Color _borderColor = Color(0xFFE5E7EB);
  static const Color _dividerColor = Color(0xFFF3F4F6);

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Determine API status parameter based on selected filter
      String? apiStatus;
      if (_selectedFilter != 'today' && _selectedFilter != 'all') {
        apiStatus = _selectedFilter;
      }

      // Only use date filters if NOT 'today' filter
      String? dateFrom = (_selectedFilter != 'today' && _startDate != null)
          ? DateFormat('yyyy-MM-dd').format(_startDate!)
          : null;
      String? dateTo = (_selectedFilter != 'today' && _endDate != null)
          ? DateFormat('yyyy-MM-dd').format(_endDate!)
          : null;

      final plans = await _planService.fetchVisitPlans(
        status: apiStatus,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );

      List<VillageVisitPlan> filteredPlans;

      // If 'today' filter is active, filter plans for today
      if (_selectedFilter == 'today') {
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

            // Check if today falls within the plan's date range
            return (todayDateOnly.isAtSameMomentAs(planStartDateOnly) ||
                todayDateOnly.isAfter(planStartDateOnly)) &&
                (todayDateOnly.isAtSameMomentAs(planEndDateOnly) ||
                    todayDateOnly.isBefore(planEndDateOnly));
          } catch (_) {
            return false;
          }
        }).toList();
      } else if (_selectedFilter == 'planned') {
        // ── CHANGE 3: Upcoming filter - only show plans with startDate >= today ──
        final today = DateTime.now();
        final todayDateOnly = DateTime(today.year, today.month, today.day);

        filteredPlans = plans.where((plan) {
          try {
            final planStartDate = DateTime.parse(plan.startDate);
            final planStartDateOnly = DateTime(
                planStartDate.year, planStartDate.month, planStartDate.day);

            // Only show plans whose start date is today or in the future
            if (planStartDateOnly.isBefore(todayDateOnly)) {
              return false;
            }

            if (_startDate != null) {
              final filterFrom = DateTime(
                  _startDate!.year, _startDate!.month, _startDate!.day);
              if (planStartDateOnly.isBefore(filterFrom)) {
                return false;
              }
            }

            if (_endDate != null) {
              final filterTo = DateTime(
                  _endDate!.year, _endDate!.month, _endDate!.day);
              if (planStartDateOnly.isAfter(filterTo)) {
                return false;
              }
            }

            return true;
          } catch (_) {
            return true;
          }
        }).toList();
      } else {
        // Original date range filtering for 'all', 'completed', 'in_progress'
        filteredPlans = plans.where((plan) {
          try {
            final planStartDate = DateTime.parse(plan.startDate);
            final planStartDateOnly = DateTime(
                planStartDate.year, planStartDate.month, planStartDate.day);

            if (_startDate != null) {
              final filterFrom = DateTime(
                  _startDate!.year, _startDate!.month, _startDate!.day);
              if (planStartDateOnly.isBefore(filterFrom)) {
                return false;
              }
            }

            if (_endDate != null) {
              final filterTo = DateTime(
                  _endDate!.year, _endDate!.month, _endDate!.day);
              if (planStartDateOnly.isAfter(filterTo)) {
                return false;
              }
            }

            return true;
          } catch (_) {
            return true;
          }
        }).toList();
      }

      // ── CHANGE 2: For 'today' filter, sort completed plans to the bottom ──
      if (_selectedFilter == 'today') {
        filteredPlans.sort((a, b) {
          // Completed plans go to the bottom
          final aCompleted = a.status == 'completed' ? 1 : 0;
          final bCompleted = b.status == 'completed' ? 1 : 0;
          if (aCompleted != bCompleted) {
            return aCompleted.compareTo(bCompleted);
          }
          // Within same status group, sort by start date
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
        _plans = filteredPlans;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _calculateStats(List<VillageVisitPlan> plans) {
    _totalPlans = plans.length;
    _completedPlans = plans.where((p) => p.status == 'completed').length;
    _inProgressPlans = plans.where((p) => p.status == 'in_progress').length;
    _plannedPlans = plans.where((p) => p.status == 'planned').length;
    _totalVillages = plans.fold(
        0,
            (sum, plan) =>
        sum +
            plan.dailyPlans
                .fold(0, (s, dp) => s + dp.villageVisits.length));
  }

  // Single unified filter handler - only one filter active at a time
  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _loadPlans();
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      helpText: 'Select Start Date',
      confirmText: 'OK',
      cancelText: 'Cancel',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        // Switch away from 'today' when using date range
        if (_selectedFilter == 'today') {
          _selectedFilter = 'all';
        }
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = null;
        }
      });
      _loadPlans();
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2024),
      lastDate: DateTime(2030),
      helpText: 'Select End Date',
      confirmText: 'OK',
      cancelText: 'Cancel',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
        // Switch away from 'today' when using date range
        if (_selectedFilter == 'today') {
          _selectedFilter = 'all';
        }
      });
      _loadPlans();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _loadPlans();
  }

  String _getStatusDisplayText(String status, String statusDisplay) {
    if (status == 'planned') {
      return 'Upcoming Plan';
    }
    if (statusDisplay.isNotEmpty) {
      return statusDisplay;
    }
    return status.replaceAll('_', ' ');
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return _successColor;
      case 'in_progress':
        return _warningColor;
      case 'planned':
        return _accentColor;
      default:
        return _textSecondary;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'completed':
        return _successColor.withOpacity(0.1);
      case 'in_progress':
        return _warningColor.withOpacity(0.1);
      case 'planned':
        return _accentColor.withOpacity(0.1);
      default:
        return _dividerColor;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle_rounded;
      case 'in_progress':
        return Icons.timelapse_rounded;
      case 'planned':
        return Icons.event_note_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  List<String> _getVillageNames(VillageVisitPlan plan) {
    final List<String> names = [];
    for (var dp in plan.dailyPlans) {
      for (var visit in dp.villageVisits) {
        if (visit.village.isNotEmpty) {
          names.add(visit.village);
        }
      }
    }
    return names;
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  BUILD
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Village Visit Plans',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              '$_totalPlans Plans · $_totalVillages Villages',
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
          onRefresh: _loadPlans,
          color: _primaryColor,
          backgroundColor: _cardColor,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildStatsSection()),
              SliverToBoxAdapter(child: _buildFiltersSection()),
              _buildContentSection(),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  // ── STATS SECTION ─────────────────────────────────────────────
  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('Overview'),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  _label('Completed'),
                  _completedPlans.toString(),
                  Icons.check_circle_outline_rounded,
                  _successColor,
                  _successColor.withOpacity(0.1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  _label('In Progress'),
                  _inProgressPlans.toString(),
                  Icons.timelapse_rounded,
                  _warningColor,
                  _warningColor.withOpacity(0.1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  _label('Upcoming'),
                  _plannedPlans.toString(),
                  Icons.event_note_rounded,
                  _accentColor,
                  _accentColor.withOpacity(0.1),
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
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
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
              color: _textPrimary,
              letterSpacing: -0.5,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: _textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── FILTERS SECTION ───────────────────────────────────────────
  Widget _buildFiltersSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('Filters'),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildFilterChip(_label('Today'), 'today', Icons.today_rounded),
                const SizedBox(width: 8),
                _buildFilterChip(_label('All'), 'all', Icons.grid_view_rounded),
                const SizedBox(width: 8),
                _buildFilterChip(
                    _label('Upcoming'), 'planned', Icons.event_note_rounded),
                const SizedBox(width: 8),
                // ── CHANGE 1: Swapped Completed and In Progress order ──
                _buildFilterChip(
                    _label('Completed'), 'completed', Icons.check_circle_rounded),
                const SizedBox(width: 8),
                _buildFilterChip(
                    _label('In Progress'), 'in_progress', Icons.timelapse_rounded),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildSimpleDateFilter(),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _selectedFilter == value;
    Color chipColor;

    switch (value) {
      case 'today':
        chipColor = _purpleColor;
        break;
      case 'completed':
        chipColor = _successColor;
        break;
      case 'in_progress':
        chipColor = _warningColor;
        break;
      case 'planned':
        chipColor = _accentColor;
        break;
      default:
        chipColor = _primaryColor;
    }

    return GestureDetector(
      onTap: () => _onFilterChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : _cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? chipColor : _borderColor,
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
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : _textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : _textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleDateFilter() {
    final hasStart = _startDate != null;
    final hasEnd = _endDate != null;
    final dateFormat = DateFormat('dd MMM yy');

    return Row(
      children: [
        // ── Start Date ──
        Expanded(
          child: GestureDetector(
            onTap: _selectStartDate,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: hasStart ? _primaryColor : _borderColor,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    color: hasStart ? _primaryColor : _textSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'From',
                          style: TextStyle(
                            fontSize: 9,
                            color: hasStart ? _primaryColor : _textSecondary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          hasStart
                              ? dateFormat.format(_startDate!)
                              : 'Select date',
                          style: TextStyle(
                            fontSize: 12,
                            color: hasStart ? _textPrimary : _textSecondary,
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
              size: 14, color: _textSecondary.withOpacity(0.5)),
        ),

        // ── End Date ──
        Expanded(
          child: GestureDetector(
            onTap: _selectEndDate,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: hasEnd ? _primaryColor : _borderColor,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event_rounded,
                    color: hasEnd ? _primaryColor : _textSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'To',
                          style: TextStyle(
                            fontSize: 9,
                            color: hasEnd ? _primaryColor : _textSecondary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          hasEnd
                              ? dateFormat.format(_endDate!)
                              : 'Select date',
                          style: TextStyle(
                            fontSize: 12,
                            color: hasEnd ? _textPrimary : _textSecondary,
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

        // ── Clear button ──
        if (hasStart || hasEnd) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _clearDateFilter,
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: _errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _errorColor.withOpacity(0.3)),
              ),
              child: Icon(Icons.close_rounded, size: 16, color: _errorColor),
            ),
          ),
        ],
      ],
    );
  }

  // ── CONTENT SECTION ───────────────────────────────────────────
  Widget _buildContentSection() {
    if (_isLoading) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: CircularProgressIndicator(
            color: _primaryColor,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildErrorWidget(),
      );
    }

    if (_plans.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildEmptyWidget(),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 300 + (index * 80)),
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
              child: _buildPlanCard(_plans[index]),
            );
          },
          childCount: _plans.length,
        ),
      ),
    );
  }

  // ── PLAN CARD ─────────────────────────────────────────────────
  Widget _buildPlanCard(VillageVisitPlan plan) {
    final statusColor = _getStatusColor(plan.status);
    final statusBgColor = _getStatusBgColor(plan.status);
    final statusIcon = _getStatusIcon(plan.status);

    int totalVillages = 0;
    int completedVillages = 0;
    for (var dp in plan.dailyPlans) {
      totalVillages += dp.villageVisits.length;
      completedVillages +=
          dp.villageVisits.where((v) => v.status == 'completed').length;
    }
    double progress =
    totalVillages > 0 ? completedVillages / totalVillages : 0;

    final villageNames = _getVillageNames(plan);
    final villageDisplayText =
    villageNames.isNotEmpty ? villageNames.join(', ') : 'No villages';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
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
                // ── Top Row: Icon + Name + Status + Arrow ──
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
                            plan.displayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: _textPrimary,
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
                    Icon(
                      Icons.chevron_right_rounded,
                      color: _textSecondary.withOpacity(0.5),
                      size: 20,
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Info Row ──
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _buildInfoItem(
                            Icons.calendar_today_rounded,
                            '${plan.startDate} – ${plan.endDate}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 14, color: _textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '$villageDisplayText ($totalVillages)',
                              style: const TextStyle(
                                fontSize: 11,
                                color: _textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          _buildInfoItem(
                            Icons.view_day_outlined,
                            '${plan.dailyPlans.length} Days',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ── Progress Bar ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$completedVillages of $totalVillages villages',
                      style: const TextStyle(
                        fontSize: 11,
                        color: _textSecondary,
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
                          color: _dividerColor,
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
        Icon(icon, size: 14, color: _textSecondary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: _textPrimary,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ── SECTION LABEL HELPER ──────────────────────────────────────
  Widget _buildSectionLabel(String label) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: _primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: _textPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  // ── ERROR WIDGET ──────────────────────────────────────────────
  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: _errorColor.withOpacity(0.3)),
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 36,
                color: _errorColor,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: _textSecondary,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPlans,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text(
                'Try Again',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── EMPTY WIDGET ──────────────────────────────────────────────
  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _dividerColor,
                shape: BoxShape.circle,
                border: Border.all(color: _borderColor),
              ),
              child: Icon(
                Icons.inbox_rounded,
                size: 36,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Plans Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try adjusting your filters or\ncheck back later',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: _textSecondary,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedFilter = 'today';
                  _startDate = null;
                  _endDate = null;
                });
                _loadPlans();
              },
              icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
              label: const Text(
                'Clear Filters',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primaryColor,
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                side: const BorderSide(color: _primaryColor, width: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
