// lib/verifications/mukadam_dashboard/mukadam_dashborad.dart
// FULL CODE — MukkadamListScreen with LanguageProvider + language-aware display

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../language_jsons/mukadam_verification_string.dart';
import '../../mukadan/authentication/userProvider.dart';
import '../../provider/language_provider.dart';
import '../update_screen.dart';
import 'mukadam_service.dart';
import 'mukkadam_data_model.dart';

class MukkadamListScreen extends StatefulWidget {
  const MukkadamListScreen({super.key});

  @override
  State<MukkadamListScreen> createState() => _MukkadamListScreenState();
}

class _MukkadamListScreenState extends State<MukkadamListScreen> {
  late Future<List<MukkadamDataModel>> futureMukkadams;
  final MukkadamService mukkadamService = MukkadamService();
  String searchQuery = '';

  // Color Palette (matching VillagePlansDashboard)
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

  @override
  void initState() {
    super.initState();
    futureMukkadams = _loadMukkadams();
  }

  Future<List<MukkadamDataModel>> _loadMukkadams() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final int userId = userProvider.user?.id ?? 1;
    return mukkadamService.fetchMukkadams(userId);
  }

  void _refresh() {
    setState(() {
      futureMukkadams = _loadMukkadams();
    });
  }

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
        title: Text(
          MukadamVerificationStrings.get('mukadamverification', lang),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: backgroundColor,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textPrimary,
              ),
              cursorColor: primaryColor,
              decoration: InputDecoration(
                hintText: MukadamVerificationStrings.get('searchbyname', lang),
                hintStyle: const TextStyle(
                  color: textSecondary,
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: textSecondary,
                  size: 20,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 10, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                  const BorderSide(color: accentColor, width: 1.5),
                ),
              ),
            ),
          ),
          // Body Content
          Expanded(child: _buildBody(lang)),
        ],
      ),
    );
  }

  Widget _buildBody(String lang) {
    return FutureBuilder<List<MukkadamDataModel>>(
      future: futureMukkadams,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
                color: primaryColor, strokeWidth: 2.5),
          );
        }

        if (snapshot.hasError) {
          return _buildStatusMessage(
            icon: Icons.wifi_off_rounded,
            iconColor: errorColor,
            title: MukadamVerificationStrings.get('somethingwentwrong', lang),
            subtitle: snapshot.error.toString(),
            actionLabel: MukadamVerificationStrings.get('tryagain', lang),
            onAction: _refresh,
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildStatusMessage(
            icon: Icons.people_outline_rounded,
            iconColor: textSecondary,
            title: MukadamVerificationStrings.get('nomukkadamsfound', lang),
            subtitle: MukadamVerificationStrings.get('nounverifiedprofiles', lang),
          );
        }

        final filteredMukkadams = snapshot.data!.where((m) {
          // Filter out fully verified
          if (m.isFullyVerified || m.isAllVerified) return false;

          // Search filter: search both English and Marathi names
          if (searchQuery.isNotEmpty) {
            return m.mukkadamName.toLowerCase().contains(searchQuery) ||
                (m.marathiName?.toLowerCase().contains(searchQuery) ?? false);
          }
          return true;
        }).toList();

        if (filteredMukkadams.isEmpty) {
          return _buildStatusMessage(
            icon: searchQuery.isNotEmpty
                ? Icons.search_off_rounded
                : Icons.people_outline_rounded,
            iconColor: textSecondary,
            title: searchQuery.isNotEmpty
                ? MukadamVerificationStrings.get('nomatchingresults', lang)
                : MukadamVerificationStrings.get('nomukkadamsfound', lang),
            subtitle: searchQuery.isNotEmpty
                ? MukadamVerificationStrings.get('tryadjustingsearch', lang)
                : MukadamVerificationStrings.get('nounverifiedprofiles', lang),
          );
        }

        return RefreshIndicator(
          color: primaryColor,
          onRefresh: () async => _refresh(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: filteredMukkadams.length + 1,
            physics: const AlwaysScrollableScrollPhysics(),
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${filteredMukkadams.length} ${MukadamVerificationStrings.get('unverifiedprofile', lang)}${filteredMukkadams.length > 1 ? MukadamVerificationStrings.get('plural_s', lang) : ''}',
                    style: const TextStyle(
                      color: textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }
              return _buildMukkadamCard(filteredMukkadams[index - 1], lang);
            },
          ),
        );
      },
    );
  }

  Widget _buildMukkadamCard(MukkadamDataModel mukkadam, String lang) {
    final bool isAnyVerified = mukkadam.isAnyVerified;
    final Color statusColor = isAnyVerified ? warningColor : errorColor;
    final String statusText = isAnyVerified
        ? MukadamVerificationStrings.get('pending', lang)
        : MukadamVerificationStrings.get('notverified', lang);

    // ✅ Language-aware name display
    final String displayName = mukkadam.getDisplayName(lang);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    MukkadamUpdateScreen(mukkadamId: mukkadam.id),
              ),
            );
            _refresh();
          },
          splashColor: accentColor.withOpacity(0.05),
          child: Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                // Avatar — always uses English name initial
                CircleAvatar(
                  radius: 22,
                  backgroundColor: primaryColor.withOpacity(0.08),
                  child: Text(
                    mukkadam.mukkadamName.isNotEmpty
                        ? mukkadam.mukkadamName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: primaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + Status
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              // ✅ Shows ONLY the selected language name
                              displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: textPrimary,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Location
                      Text(
                        mukkadam.getDisplayLocation(lang),
                        style: const TextStyle(
                          color: textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Verification progress
                      Row(
                        children: [
                          _buildDot(
                              MukadamVerificationStrings.get('aadhaar', lang),
                              mukkadam.isAadharVerified),
                          const SizedBox(width: 10),
                          _buildDot(
                              MukadamVerificationStrings.get('pan', lang),
                              mukkadam.isPanVerified),
                          const SizedBox(width: 10),
                          _buildDot(
                              MukadamVerificationStrings.get('voter', lang),
                              mukkadam.isVoterIdVerified),
                          const SizedBox(width: 10),
                          _buildDot(
                              MukadamVerificationStrings.get('face', lang),
                              mukkadam.isFaceVerified),
                          const Spacer(),
                          Text(
                            '${mukkadam.verifiedCount}/4',
                            style: const TextStyle(
                              color: textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded,
                    color: borderColor, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDot(String label, bool isVerified) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: isVerified ? successColor : borderColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            color: isVerified ? textPrimary : textSecondary,
            fontSize: 10,
            fontWeight: isVerified ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusMessage({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 44, color: iconColor.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: textSecondary,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: borderColor),
                  ),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
