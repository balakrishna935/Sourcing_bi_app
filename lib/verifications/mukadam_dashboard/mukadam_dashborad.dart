import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../mukadan/authentication/userProvider.dart';
import '../update_screen.dart';
import 'mukadam_service.dart';
import 'mukkadam_data_model.dart';

class MukkadamListScreen extends StatefulWidget {
  const MukkadamListScreen({super.key});

  @override
  State<MukkadamListScreen> createState() => _MukkadamListScreenState();
}

class _MukkadamListScreenState extends State<MukkadamListScreen> {
  late Future<List<MukkadamDataModel>> _futureMukkadams;
  final MukkadamService _mukkadamService = MukkadamService();
  String _searchQuery = "";

  // ── Color Palette (matching VillagePlansDashboard) ──
  static const Color _primaryColor = Color(0xFF1E3A5F);
  static const Color _accentColor = Color(0xFF3B82F6);
  static const Color _successColor = Color(0xFF10B981);
  static const Color _warningColor = Color(0xFFF59E0B);
  static const Color _errorColor = Color(0xFFEF4444);
  static const Color _backgroundColor = Color(0xFFF8FAFC);
  static const Color _cardColor = Colors.white;
  static const Color _textPrimary = Color(0xFF1F2937);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _borderColor = Color(0xFFE5E7EB);
  static const Color _dividerColor = Color(0xFFF3F4F6);

  @override
  void initState() {
    super.initState();
    _futureMukkadams = _loadMukkadams();
  }

  Future<List<MukkadamDataModel>> _loadMukkadams() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final int userId = userProvider.user?.id ?? 1;
    return _mukkadamService.fetchMukkadams(userId);
  }

  void _refresh() {
    setState(() {
      _futureMukkadams = _loadMukkadams();
    });
  }

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
        title: const Text(
          'Mukadam Verification',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Search Bar (outside AppBar) ──
          Container(
            color: _backgroundColor,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _textPrimary,
              ),
              cursorColor: _primaryColor,
              decoration: InputDecoration(
                hintText: 'Search by name...',
                hintStyle: const TextStyle(
                  color: _textSecondary,
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: _textSecondary,
                  size: 20,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                  const BorderSide(color: _accentColor, width: 1.5),
                ),
              ),
            ),
          ),
          // ── Body Content ──
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return FutureBuilder<List<MukkadamDataModel>>(
      future: _futureMukkadams,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: _primaryColor,
              strokeWidth: 2.5,
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildStatusMessage(
            icon: Icons.wifi_off_rounded,
            iconColor: _errorColor,
            title: 'Something went wrong',
            subtitle: snapshot.error.toString(),
            actionLabel: 'Try Again',
            onAction: _refresh,
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildStatusMessage(
            icon: Icons.people_outline_rounded,
            iconColor: _textSecondary,
            title: 'No Mukkadams Found',
            subtitle:
            'There are no unverified profiles\nto display at the moment.',
          );
        }

        final filteredMukkadams = snapshot.data!.where((m) {
          if (m.isFullyVerified || m.isAllVerified) return false;
          if (_searchQuery.isNotEmpty) {
            // ✅ UPDATED — Search both English and Marathi names
            return m.mukkadamName.toLowerCase().contains(_searchQuery) ||
                (m.marathiName?.toLowerCase().contains(_searchQuery) ?? false);
          }
          return true;
        }).toList();

        if (filteredMukkadams.isEmpty) {
          return _buildStatusMessage(
            icon: _searchQuery.isNotEmpty
                ? Icons.search_off_rounded
                : Icons.people_outline_rounded,
            iconColor: _textSecondary,
            title: _searchQuery.isNotEmpty
                ? 'No Matching Results'
                : 'No Mukkadams Found',
            subtitle: _searchQuery.isNotEmpty
                ? 'Try adjusting your search.'
                : 'There are no unverified profiles to display.',
          );
        }

        return RefreshIndicator(
          color: _primaryColor,
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
                    '${filteredMukkadams.length} unverified profile${filteredMukkadams.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }
              return _buildMukkadamCard(filteredMukkadams[index - 1]);
            },
          ),
        );
      },
    );
  }

  Widget _buildMukkadamCard(MukkadamDataModel mukkadam) {
    final bool isAnyVerified = mukkadam.isAnyVerified;
    final Color statusColor = isAnyVerified ? _warningColor : _errorColor;
    final String statusText = isAnyVerified ? 'Pending' : 'Not Verified';

    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
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
          splashColor: _accentColor.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                // Avatar — uses original English name initial
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _primaryColor.withOpacity(0.08),
                  child: Text(
                    mukkadam.mukkadamName.isNotEmpty
                        ? mukkadam.mukkadamName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: _primaryColor,
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
                              // ✅ UPDATED — Shows "Name / मराठी नाव"
                              mukkadam.displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: _textPrimary,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
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
                        mukkadam.village.isNotEmpty
                            ? mukkadam.village
                            : mukkadam.district,
                        style: const TextStyle(
                          color: _textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Verification progress
                      Row(
                        children: [
                          _buildDot('Aadhaar', mukkadam.isAadharVerified),
                          const SizedBox(width: 10),
                          _buildDot('PAN', mukkadam.isPanVerified),
                          const SizedBox(width: 10),
                          _buildDot('Voter', mukkadam.isVoterIdVerified),
                          const SizedBox(width: 10),
                          _buildDot('Face', mukkadam.isFaceVerified),
                          const Spacer(),
                          Text(
                            '${mukkadam.verifiedCount}/4',
                            style: const TextStyle(
                              color: _textSecondary,
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
                const Icon(
                  Icons.chevron_right_rounded,
                  color: _borderColor,
                  size: 20,
                ),
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
            color: isVerified ? _successColor : _borderColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            color: isVerified ? _textPrimary : _textSecondary,
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
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: _textSecondary,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: _primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: _borderColor),
                  ),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
