import 'package:flutter/material.dart';
import 'package:mukadam_bi/verifications/transporter_verifcations/verification_model.dart';
import 'package:mukadam_bi/verifications/transporter_verifcations/verificatrion_service.dart';
import 'package:provider/provider.dart';
import '../../mukadan/authentication/userProvider.dart';
import '../transporter_update_screen.dart';

class PendingVerificationListScreen extends StatefulWidget {
  const PendingVerificationListScreen({super.key});

  @override
  State<PendingVerificationListScreen> createState() =>
      _PendingVerificationListScreenState();
}

class _PendingVerificationListScreenState
    extends State<PendingVerificationListScreen> {
  late Future<List<VerificationEntity>> _futureVerifications;
  final VerificationService _service = VerificationService();
  String _searchQuery = "";

  // ── Color Palette ──
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

  @override
  void initState() {
    super.initState();
    _loadVerifications();
  }

  void _loadVerifications() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final int userId = userProvider.user?.id ?? 29;
    setState(() {
      _futureVerifications = _service.fetchPendingVerifications(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Transport Verification',
          style: TextStyle(
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
          // ── Search Bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
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
              decoration: InputDecoration(
                hintText: "Search by name...",
                hintStyle: TextStyle(
                  color: _textSecondary.withOpacity(0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: _accentColor, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: _textSecondary.withOpacity(0.5), size: 18),
                  onPressed: () {
                    setState(() {
                      _searchQuery = "";
                    });
                  },
                )
                    : null,
                filled: true,
                fillColor: _cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                  const BorderSide(color: _accentColor, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // ── Content ──
          Expanded(
            child: FutureBuilder<List<VerificationEntity>>(
              future: _futureVerifications,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoading();
                } else if (snapshot.hasError) {
                  return _buildErrorWidget(snapshot.error.toString());
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyWidget();
                }

                final filteredEntities = snapshot.data!.where((item) {
                  if (item.entity.isFullyVerified) return false;
                  if (_searchQuery.isEmpty) return true;
                  // ✅ UPDATED: Search both English and Marathi names
                  return item.entity.name
                      .toLowerCase()
                      .contains(_searchQuery) ||
                      (item.entity.marathiName
                          ?.toLowerCase()
                          .contains(_searchQuery) ??
                          false);
                }).toList();

                if (filteredEntities.isEmpty) {
                  return _buildEmptyWidget();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    _loadVerifications();
                    await _futureVerifications;
                  },
                  color: _primaryColor,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: filteredEntities.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildResultsHeader(filteredEntities.length);
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

                      String statusText =
                      anyVerified ? "Pending" : "Not Verified";
                      Color themeColor =
                      anyVerified ? _warningColor : _errorColor;
                      IconData statusIcon = anyVerified
                          ? Icons.timelapse_rounded
                          : Icons.cancel_rounded;

                      return _buildVerificationCard(
                        transporter: transporter,
                        statusText: statusText,
                        themeColor: themeColor,
                        statusIcon: statusIcon,
                        verifiedCount: verifiedCount,
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

  // ── RESULTS HEADER ──
  Widget _buildResultsHeader(int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Text(
            '$count result${count != 1 ? 's' : ''}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _accentColor,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // ── VERIFICATION CARD ──
  Widget _buildVerificationCard({
    required EntityDetails transporter,
    required String statusText,
    required Color themeColor,
    required IconData statusIcon,
    required int verifiedCount,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: _borderColor),
      ),
      color: _cardColor,
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
          if (updated == true) {
            _loadVerifications();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Row: Avatar + Name + Status ──
              Row(
                children: [
                  // Avatar — uses original English name initial
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: _primaryColor,
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
                          // ✅ UPDATED: Shows "NAME / मराठी नाव"
                          transporter.displayName.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          transporter.vehicleType ?? 'Transporter',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

              // ── Location ──
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: _textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      transporter.baseLocation,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Progress Bar ──
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

              // ── Verification Chips ──
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildVerificationChip(
                      "Aadhaar", transporter.isAadhaarVerified),
                  _buildVerificationChip("PAN", transporter.isPanVerified),
                  _buildVerificationChip("RC", transporter.isRcVerified),
                  _buildVerificationChip("DL", transporter.isDlVerified),
                  _buildVerificationChip(
                      "Voter ID", transporter.isVoterIdVerified),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── VERIFICATION CHIP ──
  Widget _buildVerificationChip(String label, bool isVerified) {
    final Color chipColor = isVerified ? _successColor : _errorColor;
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

  // ── LOADING ──
  Widget _buildLoading() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(48),
        child: CircularProgressIndicator(
          color: _primaryColor,
          strokeWidth: 2.5,
        ),
      ),
    );
  }

  // ── ERROR WIDGET ──
  Widget _buildErrorWidget(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: _errorColor),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: _textSecondary,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadVerifications,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Try Again',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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

  // ── EMPTY WIDGET ──
  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No Verifications Found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'No matching pending verifications\nwere found.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: _textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _loadVerifications,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Refresh',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primaryColor,
                side: const BorderSide(color: _borderColor, width: 1.5),
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
