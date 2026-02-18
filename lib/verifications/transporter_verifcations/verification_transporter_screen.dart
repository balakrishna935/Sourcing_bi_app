// lib/verifications/transporter_verifcations/verification_transporter_screen.dart
// FULL CODE — PendingVerificationListScreen with LanguageProvider

import 'package:flutter/material.dart';
import 'package:mukadam_bi/verifications/transporter_verifcations/verification_model.dart';
import 'package:mukadam_bi/verifications/transporter_verifcations/verificatrion_service.dart';
import 'package:provider/provider.dart';
import '../../language_jsons/transport_verification_string.dart';
import '../../mukadan/authentication/userProvider.dart';
import '../transporter_update_screen.dart';
import '../../provider/language_provider.dart';

class PendingVerificationListScreen extends StatefulWidget {
  const PendingVerificationListScreen({super.key});

  @override
  State<PendingVerificationListScreen> createState() =>
      _PendingVerificationListScreenState();
}

class _PendingVerificationListScreenState
    extends State<PendingVerificationListScreen> {
  late Future<List<VerificationEntity>> futureVerifications;
  final VerificationService service = VerificationService();
  String searchQuery = '';

  // Color Palette
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

  @override
  void initState() {
    super.initState();
    _loadVerifications();
  }

  void _loadVerifications() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final int userId = userProvider.user?.id ?? 29;
    setState(() {
      futureVerifications = service.fetchPendingVerifications(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().language;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 1,
        title: Text(
          TransportVerificationStrings.get('transportverification', lang),
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
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
              decoration: InputDecoration(
                hintText:
                TransportVerificationStrings.get('searchbyname', lang),
                hintStyle: TextStyle(
                  color: textSecondary.withOpacity(0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: accentColor, size: 20),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: textSecondary.withOpacity(0.5), size: 18),
                  onPressed: () {
                    setState(() {
                      searchQuery = '';
                    });
                  },
                )
                    : null,
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                  const BorderSide(color: accentColor, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          // Content
          Expanded(
            child: FutureBuilder<List<VerificationEntity>>(
              future: futureVerifications,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoading();
                } else if (snapshot.hasError) {
                  return _buildErrorWidget(snapshot.error.toString(), lang);
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyWidget(lang);
                }

                final filteredEntities = snapshot.data!.where((item) {
                  if (item.entity.isFullyVerified) return false;
                  if (searchQuery.isEmpty) return true;
                  // Search both English and Marathi names
                  return item.entity.name
                      .toLowerCase()
                      .contains(searchQuery) ||
                      (item.entity.marathiName
                          ?.toLowerCase()
                          .contains(searchQuery) ??
                          false);
                }).toList();

                if (filteredEntities.isEmpty) {
                  return _buildEmptyWidget(lang);
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    _loadVerifications();
                    await futureVerifications;
                  },
                  color: primaryColor,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: filteredEntities.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildResultsHeader(
                            filteredEntities.length, lang);
                      }
                      final item = filteredEntities[index - 1];
                      final transporter = item.entity;

                      bool anyVerified = transporter.isAadhaarVerified ||
                          transporter.isPanVerified ||
                          transporter.isRcVerified ||
                          transporter.isDlVerified ||
                          transporter.isVoterIdVerified;

                      int verifiedCount = [
                        transporter.isAadhaarVerified,
                        transporter.isPanVerified,
                        transporter.isRcVerified,
                        transporter.isDlVerified,
                        transporter.isVoterIdVerified,
                      ].where((v) => v).length;

                      String statusText = anyVerified
                          ? TransportVerificationStrings.get('pending', lang)
                          : TransportVerificationStrings.get(
                          'notverified', lang);
                      Color themeColor =
                      anyVerified ? warningColor : errorColor;
                      IconData statusIcon = anyVerified
                          ? Icons.timelapse_rounded
                          : Icons.cancel_rounded;

                      return _buildVerificationCard(
                        transporter: transporter,
                        statusText: statusText,
                        themeColor: themeColor,
                        statusIcon: statusIcon,
                        verifiedCount: verifiedCount,
                        lang: lang,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ======================== RESULTS HEADER ========================
  Widget _buildResultsHeader(int count, String lang) {
    final resultWord = count != 1
        ? TransportVerificationStrings.get('results', lang)
        : TransportVerificationStrings.get('result', lang);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Text(
            '$count $resultWord',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // ======================== VERIFICATION CARD ========================
  Widget _buildVerificationCard({
    required EntityDetails transporter,
    required String statusText,
    required Color themeColor,
    required IconData statusIcon,
    required int verifiedCount,
    required String lang,
  }) {
    // ✅ Language-aware name display
    final String displayName = transporter.getDisplayName(lang);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor),
      ),
      color: cardColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          bool? updated = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  TransporterUpdateScreen(transporterId: transporter.id),
            ),
          );
          if (updated == true) _loadVerifications();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Avatar + Name + Status
              Row(
                children: [
                  // Avatar — always uses English name initial
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: primaryColor,
                    child: Text(
                      transporter.name.isNotEmpty
                          ? transporter.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name + Vehicle Type
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          // ✅ Shows ONLY the selected language name
                          displayName.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          // ✅ Language-aware vehicle type
                          transporter.getDisplayVehicleType(
                            lang,
                            TransportVerificationStrings.get(
                                'transporter', lang),
                          ),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, color: themeColor, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: themeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Location
              Row(
                children: [

                  Expanded(
                    child: Text(
                      // ✅ Language-aware location
                      transporter.getDisplayLocation(lang),
                      style: const TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Progress
              Row(
                children: [
                  const SizedBox(width: 10),
                  Text(
                    '$verifiedCount/5',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: themeColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Verification Chips
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildVerificationChip(
                    TransportVerificationStrings.get('aadhaar', lang),
                    transporter.isAadhaarVerified,
                  ),
                  _buildVerificationChip(
                    TransportVerificationStrings.get('pan', lang),
                    transporter.isPanVerified,
                  ),
                  _buildVerificationChip(
                    TransportVerificationStrings.get('rc', lang),
                    transporter.isRcVerified,
                  ),
                  _buildVerificationChip(
                    TransportVerificationStrings.get('dl', lang),
                    transporter.isDlVerified,
                  ),
                  _buildVerificationChip(
                    TransportVerificationStrings.get('voterid', lang),
                    transporter.isVoterIdVerified,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ======================== VERIFICATION CHIP ========================
  Widget _buildVerificationChip(String label, bool isVerified) {
    final Color chipColor = isVerified ? successColor : errorColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: chipColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 12,
            color: chipColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }

  // ======================== LOADING ========================
  Widget _buildLoading() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(48),
        child:
        CircularProgressIndicator(color: primaryColor, strokeWidth: 2.5),
      ),
    );
  }

  // ======================== ERROR WIDGET ========================
  Widget _buildErrorWidget(String errorMessage, String lang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: errorColor),
            const SizedBox(height: 16),
            Text(
              TransportVerificationStrings.get('somethingwentwrong', lang),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: textSecondary,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadVerifications,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(
                TransportVerificationStrings.get('tryagain', lang),
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
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

  // ======================== EMPTY WIDGET ========================
  Widget _buildEmptyWidget(String lang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              TransportVerificationStrings.get('noverificationsfound', lang),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              TransportVerificationStrings.get('nomatchingpending', lang),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _loadVerifications,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(
                TransportVerificationStrings.get('refresh', lang),
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: const BorderSide(color: borderColor, width: 1.5),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
