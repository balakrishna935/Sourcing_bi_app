// lib/referral/user_referral_mukadam_screen.dart
// FULL CODE — DirectoryScreen + MukkadamCard with LanguageProvider

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mukadam_bi/referral/referral_service.dart';
//import 'package:mukadam_bi/referral/referralservice.dart';
import 'package:mukadam_bi/referral/registration_response.dart';
import 'package:provider/provider.dart';
//import '../getTransport/get_transport_screen.dart';
import '../getTransport/gettransportscreen.dart';
import '../mukadan/authentication/userProvider.dart';
//import '../verifications/mukadam_dashboard/mukadamservice.dart';
//import '../verifications/mukadam_dashboard/mukkadamdatamodel.dart';
import '../provider/language_provider.dart';
import '../language_jsons/directory_strings.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<MukkadamDataModell>> mukkadamFuture;
  String searchQuery = '';
  late TabController tabController;
  final TextEditingController searchController = TextEditingController();

  // Professional Color Palette
  static const Color primaryColor = Color(0xFF1E3A5F);
  static const Color accentColor = Color(0xFF3B82F6);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color dividerColor = Color(0xFFF3F4F6);
  static const Color verifiedGreen = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    tabController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user != null) {
      setState(() {
        mukkadamFuture =
            MukkadamServiceee().fetchVerifiedMukkadams(userProvider.user!.id);
      });
    } else {
      setState(() {
        mukkadamFuture = Future.error('User not logged in');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().language;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          DirectoryStrings.get('onboardedmembers', lang),
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(lang),
          _buildTabBar(lang),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                _buildRegistrationList(lang),
                TransportDirectoryScreen(searchQuery: searchQuery),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ======================== SEARCH BAR ========================
  Widget _buildSearchBar(String lang) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: searchController,
          onChanged: (value) {
            setState(() {
              searchQuery = value.toLowerCase();
            });
          },
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: textPrimary,
          ),
          decoration: InputDecoration(
            hintText: DirectoryStrings.get('searchbyname', lang),
            hintStyle: const TextStyle(
              color: textSecondary,
              fontWeight: FontWeight.w400,
              fontSize: 15,
            ),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 14, right: 10),
              child: Icon(Icons.search_rounded, color: textSecondary, size: 22),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 46),
            suffixIcon: searchQuery.isNotEmpty
                ? GestureDetector(
              onTap: () {
                searchController.clear();
                setState(() {
                  searchQuery = '';
                });
              },
              child: const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.close_rounded,
                    color: textSecondary, size: 20),
              ),
            )
                : null,
            suffixIconConstraints: const BoxConstraints(minWidth: 40),
            filled: false,
            border: InputBorder.none,
            contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
        ),
      ),
    );
  }

  // ======================== TAB BAR ========================
  Widget _buildTabBar(String lang) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      decoration: BoxDecoration(
        color: dividerColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: TabBar(
        controller: tabController,
        indicator: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: primaryColor,
        unselectedLabelColor: textSecondary,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          letterSpacing: 0.1,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        splashBorderRadius: BorderRadius.circular(10),
        tabs: [
          Tab(
            height: 42,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.grid_view_rounded, size: 18),
                const SizedBox(width: 8),
                Text(DirectoryStrings.get('registrations', lang)),
              ],
            ),
          ),
          Tab(
            height: 42,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_shipping_rounded, size: 18),
                const SizedBox(width: 8),
                Text(DirectoryStrings.get('transport', lang)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ======================== REGISTRATION LIST ========================
  Widget _buildRegistrationList(String lang) {
    return FutureBuilder<List<MukkadamDataModell>>(
      future: mukkadamFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState(lang);
        } else if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString(), lang);
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            icon: Icons.people_outline_rounded,
            title: DirectoryStrings.get('noregistrations', lang),
            subtitle: DirectoryStrings.get('noregistrationsfound', lang),
            lang: lang,
          );
        }

        final filteredMukkadams = snapshot.data!.where((m) {
          // Search both English and Marathi names
          bool matchesSearch =
              m.mukkadamName.toLowerCase().contains(searchQuery) ||
                  (m.marathiName?.toLowerCase().contains(searchQuery) ?? false);
          bool isVerified =
              m.isFullyVerified || m.isPanVerified || m.isAadharVerified;
          return matchesSearch && isVerified;
        }).toList();

        if (filteredMukkadams.isEmpty) {
          return _buildEmptyState(
            icon: Icons.verified_user_outlined,
            title: DirectoryStrings.get('noverifiedregistrations', lang),
            subtitle: DirectoryStrings.get('noverifiedregistrationsfound', lang),
            lang: lang,
          );
        }

        return RefreshIndicator(
          color: primaryColor,
          backgroundColor: cardColor,
          onRefresh: () async => _loadData(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: filteredMukkadams.length,
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            itemBuilder: (context, index) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 350 + (index * 60)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 16 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: MukkadamCard(
                    mukkadam: filteredMukkadams[index],
                    lang: lang,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ======================== LOADING STATE ========================
  Widget _buildLoadingState(String lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              strokeWidth: 3.5,
              valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
              backgroundColor: primaryColor.withOpacity(0.12),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            DirectoryStrings.get('loadingdirectory', lang),
            style: const TextStyle(
              color: textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ======================== ERROR STATE ========================
  Widget _buildErrorState(String error, String lang) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: errorColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  size: 36, color: errorColor),
            ),
            const SizedBox(height: 20),
            Text(
              DirectoryStrings.get('somethingwentwrong', lang),
              style: const TextStyle(
                color: textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: textSecondary, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(
                DirectoryStrings.get('retry', lang),
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 12),
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

  // ======================== EMPTY STATE ========================
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String lang,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: dividerColor,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor),
              ),
              child: Icon(icon, size: 40, color: textSecondary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                color: textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: textSecondary, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// MukkadamCard — now accepts `lang` and uses getDisplayName(lang)
// ================================================================
class MukkadamCard extends StatelessWidget {
  final MukkadamDataModell mukkadam;
  final String lang;

  const MukkadamCard({
    super.key,
    required this.mukkadam,
    required this.lang,
  });

  // Reuse same palette
  static const Color primaryColor = Color(0xFF1E3A5F);
  static const Color accentColor = Color(0xFF3B82F6);
  static const Color successColor = Color(0xFF10B981);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    // ✅ Language-aware name display
    final String displayName = mukkadam.getDisplayName(lang);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {},
          splashColor: accentColor.withOpacity(0.06),
          highlightColor: accentColor.withOpacity(0.03),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar — always uses English name initial
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF1E3A5F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      mukkadam.mukkadamName.isNotEmpty
                          ? mukkadam.mukkadamName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ✅ Shows ONLY the selected language name
                      Text(
                        displayName.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: textPrimary,
                          letterSpacing: -0.2,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),

                      // Location + Crew
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 13, color: textSecondary),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              mukkadam.village.isNotEmpty
                                  ? '${mukkadam.village}, ${mukkadam.district}'
                                  : mukkadam.district,
                              style: const TextStyle(
                                color: textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Text('•',
                                style: TextStyle(
                                    color: borderColor, fontSize: 12)),
                          ),
                          const Icon(Icons.groups_outlined,
                              size: 14, color: textSecondary),
                          const SizedBox(width: 3),
                          Text(
                            '${DirectoryStrings.get('crew', lang)}: ${mukkadam.crewSize.isNotEmpty ? mukkadam.crewSize : '-'}',
                            style: const TextStyle(
                              color: textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Verified badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: successColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded,
                                color: Color(0xFF10B981), size: 13),
                            const SizedBox(width: 4),
                            Text(
                              DirectoryStrings.get('fullyverified', lang),
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
