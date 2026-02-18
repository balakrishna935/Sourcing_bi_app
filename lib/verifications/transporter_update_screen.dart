import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mukadam_bi/verifications/transporter_verifcations/verificatrion_service.dart';
import 'package:path/path.dart' as p;

// ──────────────────────────── Validators (ALL OPTIONAL) ────────────────────────────
class DocValidators {
  /// PAN: ABCDE1234F  (5 letters + 4 digits + 1 letter)
  /// OPTIONAL: returns null if empty
  static String? pan(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final v = value.trim().toUpperCase();
    if (v.length != 10) {
      return 'PAN must be exactly 10 characters';
    }
    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(v)) {
      return 'Invalid PAN format (e.g. ABCDE1234F)';
    }
    return null;
  }

  /// Aadhaar: exactly 12 digits, must not start with 0 or 1
  /// OPTIONAL: returns null if empty
  static String? aadhaar(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final v = value.trim().replaceAll(' ', '');
    if (v.length != 12) {
      return 'Aadhaar must be exactly 12 digits';
    }
    if (!RegExp(r'^[2-9][0-9]{11}$').hasMatch(v)) {
      return 'Invalid Aadhaar (12 digits, cannot start with 0 or 1)';
    }
    return null;
  }

  /// Indian Vehicle Registration Number
  ///  Standard: KA01AB1234 / KA 01 AB 1234
  ///  BH series: 22BH1234AB
  /// OPTIONAL: returns null if empty
  static String? vehicleNumber(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final v = value.trim().toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
    final standard = RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z]{1,2}[0-9]{4}$');
    final bhSeries = RegExp(r'^[0-9]{2}BH[0-9]{4}[A-HJ-NP-Z]{1,2}$');
    if (!standard.hasMatch(v) && !bhSeries.hasMatch(v)) {
      return 'Invalid vehicle number (e.g. KA01AB1234)';
    }
    return null;
  }

  /// Indian Driving License
  /// OPTIONAL: returns null if empty
  static String? drivingLicense(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final v = value.trim().toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
    if (!RegExp(r'^[A-Z]{2}[0-9]{2}(19|20)[0-9]{2}[0-9]{7}$').hasMatch(v)) {
      return 'Invalid DL format (e.g. KA0120201234567)';
    }
    return null;
  }

  /// Voter ID / EPIC: 3 uppercase letters + 7 digits = 10 chars
  /// OPTIONAL: returns null if empty
  static String? voterId(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final v = value.trim().toUpperCase();
    if (v.length != 10) {
      return 'Voter ID must be exactly 10 characters';
    }
    if (!RegExp(r'^[A-Z]{3}[0-9]{7}$').hasMatch(v)) {
      return 'Invalid Voter ID format (e.g. ABC1234567)';
    }
    return null;
  }
}

// ──────────────────────────── Main Screen ────────────────────────────



class TransporterUpdateScreen extends StatefulWidget {
  final int transporterId;

  const TransporterUpdateScreen({super.key, required this.transporterId});

  @override
  State<TransporterUpdateScreen> createState() =>
      _TransporterUpdateScreenState();
}

class _TransporterUpdateScreenState extends State<TransporterUpdateScreen> {
  final VerificationService _service = VerificationService();
  final ImagePicker _picker = ImagePicker();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _panController = TextEditingController();
  final TextEditingController _aadharController = TextEditingController();
  final TextEditingController _rcController = TextEditingController();
  final TextEditingController _dlController = TextEditingController();
  final TextEditingController _voterIdController = TextEditingController();
  final TextEditingController _dummyController = TextEditingController();

  Map<String, dynamic>? _data;
  bool _isLoading = true;
  bool _isSubmitting = false;

  String? _localPanPath;
  String? _localAadharPath;
  String? _localProfilePath;
  String? _localRcPath;
  String? _localDlPath;
  String? _localVoterIdPath;

  // ── Professional Color Palette (matching VillagePlansDashboard) ──
  static const Color _primaryColor = Color(0xFF1E3A5F);
  static const Color _accentColor = Color(0xFF3B82F6);
  static const Color _successColor = Color(0xFF10B981);
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
    _loadDetails();
  }

  @override
  void dispose() {
    _panController.dispose();
    _aadharController.dispose();
    _rcController.dispose();
    _dlController.dispose();
    _voterIdController.dispose();
    _dummyController.dispose();
    super.dispose();
  }

  // ─────────── Data Loading ───────────
  void _loadDetails() async {
    try {
      final data = await _service.fetchTransporterDetails(widget.transporterId);
      setState(() {
        _data = data;
        _panController.text = data['pan_number'] ?? '';
        _aadharController.text = data['aadhar_number'] ?? '';
        _rcController.text = data['vehicle_number'] ?? '';
        _dlController.text = data['dl_number'] ?? '';
        _voterIdController.text = data['voter_id'] ?? '';
        _isLoading = false;
        _localPanPath = null;
        _localAadharPath = null;
        _localProfilePath = null;
        _localRcPath = null;
        _localDlPath = null;
        _localVoterIdPath = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
      setState(() => _isLoading = false);
    }
  }

  // ─────────── Helpers ───────────
  bool get _isFaceVerified =>
      (_data?['is_face_match_verified'] ?? false) &&
          (_data?['is_face_liveness_verified'] ?? false);

  // ─────────── Image Picker ───────────
  void _showPickerOptions(String type) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              const ListTile(
                title: Text(
                  'Select Image Source',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: _textPrimary,
                  ),
                ),
              ),
              ListTile(
                leading:
                const Icon(Icons.photo_library, color: _primaryColor),
                title: const Text('Gallery',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: _textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(type, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: _primaryColor),
                title: const Text('Camera',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: _textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(type, ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(String type, ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 100,
      );
      if (image == null) return;

      setState(() {
        switch (type) {
          case "PROFILE":
            _localProfilePath = image.path;
            break;
          case "PAN":
            _localPanPath = image.path;
            break;
          case "AADHAR":
            _localAadharPath = image.path;
            break;
          case "RC":
            _localRcPath = image.path;
            break;
          case "DL":
            _localDlPath = image.path;
            break;
          case "VOTER":
            _localVoterIdPath = image.path;
            break;
        }
      });
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  // ─────────── Submit ───────────
  void _handleUpdate() async {
    // Validate form first (only format checks — all optional)
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fix the errors before submitting"),
          backgroundColor: _errorColor,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String? panS3Key,
          aadharS3Key,
          profileS3Key,
          rcS3Key,
          dlS3Key,
          voterS3Key;

      final String contactNumber = _data?['contact_number'] ?? 'unknown';
      final String timestamp =
      DateTime.now().millisecondsSinceEpoch.toString();

      // ── Upload images ──
      if (!_isFaceVerified && _localProfilePath != null) {
        final ext = p.extension(_localProfilePath!).replaceAll('.', '');
        profileS3Key = await _service.uploadFileToS3(
          filePath: _localProfilePath!,
          s3ObjectName:
          "transporter/profilephoto/$contactNumber/profile_$timestamp.$ext",
        );
      }

      if (!(_data?['is_pan_verified'] ?? false) && _localPanPath != null) {
        final ext = p.extension(_localPanPath!).replaceAll('.', '');
        panS3Key = await _service.uploadFileToS3(
          filePath: _localPanPath!,
          s3ObjectName:
          "transporter/pancard/$contactNumber/pan_$timestamp.$ext",
        );
      }

      if (!(_data?['is_aadhaar_verified'] ?? false) &&
          _localAadharPath != null) {
        final ext = p.extension(_localAadharPath!).replaceAll('.', '');
        aadharS3Key = await _service.uploadFileToS3(
          filePath: _localAadharPath!,
          s3ObjectName:
          "transporter/aadharcard/$contactNumber/aadhar_$timestamp.$ext",
        );
      }

      if (!(_data?['is_rc_verified'] ?? false) && _localRcPath != null) {
        final ext = p.extension(_localRcPath!).replaceAll('.', '');
        rcS3Key = await _service.uploadFileToS3(
          filePath: _localRcPath!,
          s3ObjectName:
          "transporter/rcbook/$contactNumber/rc_$timestamp.$ext",
        );
      }

      if (!(_data?['is_dl_verified'] ?? false) && _localDlPath != null) {
        final ext = p.extension(_localDlPath!).replaceAll('.', '');
        dlS3Key = await _service.uploadFileToS3(
          filePath: _localDlPath!,
          s3ObjectName:
          "transporter/drivinglicense/$contactNumber/dl_$timestamp.$ext",
        );
      }

      if (!(_data?['voter_id_verified'] ?? false) &&
          _localVoterIdPath != null) {
        final ext = p.extension(_localVoterIdPath!).replaceAll('.', '');
        voterS3Key = await _service.uploadFileToS3(
          filePath: _localVoterIdPath!,
          s3ObjectName:
          "transporter/voterid/$contactNumber/voter_$timestamp.$ext",
        );
      }

      // ── Build payload ──
      final Map<String, dynamic> updateData = {};

      if (!_isFaceVerified && profileS3Key != null) {
        updateData["profile_photo"] = profileS3Key;
      }
      if (!(_data?['is_rc_verified'] ?? false)) {
        updateData["vehicle_number"] =
            _rcController.text.trim().toUpperCase();
        if (rcS3Key != null) updateData["rc_book"] = rcS3Key;
      }
      if (!(_data?['is_dl_verified'] ?? false)) {
        updateData["dl_number"] = _dlController.text.trim().toUpperCase();
        if (dlS3Key != null) updateData["driving_license"] = dlS3Key;
      }
      if (!(_data?['is_pan_verified'] ?? false)) {
        updateData["pan_number"] =
            _panController.text.trim().toUpperCase();
        if (panS3Key != null) updateData["pan_card"] = panS3Key;
      }
      if (!(_data?['is_aadhaar_verified'] ?? false)) {
        updateData["aadhar_number"] = _aadharController.text.trim();
        if (aadharS3Key != null) updateData["aadhar_card"] = aadharS3Key;
      }
      if (!(_data?['voter_id_verified'] ?? false)) {
        updateData["voter_id"] =
            _voterIdController.text.trim().toUpperCase();
        if (voterS3Key != null) updateData["voter_id_card"] = voterS3Key;
      }

      if (updateData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No changes to update')),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      bool success = await _service.updateTransporter(
          widget.transporterId, updateData);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Updated Successfully"),
            backgroundColor: _successColor,
          ),
        );
        if (mounted) Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update details")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ───────────────────────── UI Builders ─────────────────────────

  Widget _buildVerificationSection({
    required String label,
    required String marathiLabel,
    required bool isVerified,
    required TextEditingController controller,
    required String? networkImageUrl,
    required String? localPath,
    required String type,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    String? helperText,
    bool showTextField = true,
    bool showImagePicker = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: _textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      marathiLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: _textSecondary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              if (isVerified)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border:
                    Border.all(color: _successColor.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_rounded,
                          color: _successColor, size: 14),
                      SizedBox(width: 4),
                      Text(
                        "Verified",
                        style: TextStyle(
                          color: _successColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (showTextField) ...[
            TextFormField(
              controller: controller,
              enabled: !isVerified,
              validator: isVerified ? null : validator,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              textCapitalization: textCapitalization,
              keyboardType: keyboardType,
              maxLength: maxLength,
              inputFormatters: inputFormatters,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: _textPrimary,
              ),
              decoration: InputDecoration(
                labelText: "$label Number",
                labelStyle: const TextStyle(
                  color: _textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                hintText: "Enter $label Number",
                hintStyle: TextStyle(
                  color: _textSecondary.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
                helperText: helperText,
                helperStyle: const TextStyle(
                  color: _textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                errorStyle: const TextStyle(
                  color: _errorColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                counterText: '',
                prefixIcon: const Icon(Icons.badge_outlined,
                    color: _primaryColor),
                filled: true,
                fillColor: isVerified ? _dividerColor : _backgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                  const BorderSide(color: _borderColor, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                  const BorderSide(color: _primaryColor, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                  const BorderSide(color: _errorColor, width: 1.5),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                  const BorderSide(color: _errorColor, width: 1.5),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                  const BorderSide(color: _borderColor, width: 1),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (showImagePicker)
            GestureDetector(
              onTap: isVerified ? null : () => _showPickerOptions(type),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    if (localPath != null)
                      Image.file(File(localPath),
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover)
                    else if (networkImageUrl != null &&
                        networkImageUrl.isNotEmpty)
                      Image.network(
                        networkImageUrl,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      )
                    else
                      _buildPlaceholder(),
                    if (!isVerified)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _primaryColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _primaryColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            localPath != null ||
                                (networkImageUrl?.isNotEmpty ?? false)
                                ? Icons.edit_rounded
                                : Icons.add_a_photo_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_upload_outlined,
              size: 32, color: _accentColor.withOpacity(0.7)),
          const SizedBox(height: 8),
          const Text(
            "Upload Document",
            style: TextStyle(
              color: _accentColor,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Build ─────────────────────────
  @override
  Widget build(BuildContext context) {
    // ── Loading State ──
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _backgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            color: _primaryColor,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    bool isPanVerified = _data?['is_pan_verified'] ?? false;
    bool isAadharVerified = _data?['is_aadhaar_verified'] ?? false;
    bool isRcVerified = _data?['is_rc_verified'] ?? false;
    bool isDlVerified = _data?['is_dl_verified'] ?? false;
    bool isVoterVerified = _data?['voter_id_verified'] ?? false;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primaryColor,
        centerTitle: false,
        leading: IconButton(
          icon:
          const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _data?['name'] ?? "Update Details",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 19,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Verification Details / पडताळणी तपशील',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            children: [
              // ── Profile Photo (no text field, no validation) ──
              _buildVerificationSection(
                label: "Profile Photo",
                marathiLabel: "प्रोफाइल फोटो",
                type: "PROFILE",
                isVerified: _isFaceVerified,
                controller: _dummyController,
                networkImageUrl: _data?['profile_photo_url'],
                localPath: _localProfilePath,
                showTextField: false,
              ),

              // ── RC Book ──
              _buildVerificationSection(
                label: "RC Book",
                marathiLabel: "आर.सी. बुक (वाहन नोंदणी प्रमाणपत्र)",
                type: "RC",
                isVerified: isRcVerified,
                controller: _rcController,
                networkImageUrl: _data?['rc_book_url'],
                localPath: _localRcPath,
                validator: DocValidators.vehicleNumber,
                maxLength: 13,
                textCapitalization: TextCapitalization.characters,
                keyboardType: TextInputType.text,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'[A-Za-z0-9\s-]')),
                  UpperCaseTextFormatter(),
                ],
                helperText: 'Format: KA01AB1234',
              ),

              // ── Driving License ──
              _buildVerificationSection(
                label: "Driving License",
                marathiLabel: "वाहन चालक परवाना",
                type: "DL",
                isVerified: isDlVerified,
                controller: _dlController,
                networkImageUrl: _data?['driving_license_url'],
                localPath: _localDlPath,
                validator: DocValidators.drivingLicense,
                maxLength: 20,
                textCapitalization: TextCapitalization.characters,
                keyboardType: TextInputType.text,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'[A-Za-z0-9\s-]')),
                  UpperCaseTextFormatter(),
                ],
                helperText: 'Format: KA0120201234567',
              ),

              // ── PAN Card: 10 chars — ABCDE1234F ──
              _buildVerificationSection(
                label: "PAN Card",
                marathiLabel: "पॅन कार्ड",
                type: "PAN",
                isVerified: isPanVerified,
                controller: _panController,
                networkImageUrl: _data?['pan_card_url'],
                localPath: _localPanPath,
                validator: DocValidators.pan,
                maxLength: 10,
                textCapitalization: TextCapitalization.characters,
                keyboardType: TextInputType.text,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'[a-zA-Z0-9]')),
                  UpperCaseTextFormatter(),
                ],
                helperText:
                'Format: ABCDE1234F (5 letters + 4 digits + 1 letter)',
              ),

              // ── Aadhar Card: 12 digits ──
              _buildVerificationSection(
                label: "Aadhar Card",
                marathiLabel: "आधार कार्ड",
                type: "AADHAR",
                isVerified: isAadharVerified,
                controller: _aadharController,
                networkImageUrl: _data?['aadhar_card_url'],
                localPath: _localAadharPath,
                validator: DocValidators.aadhaar,
                maxLength: 12,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                helperText: '12-digit number (cannot start with 0 or 1)',
              ),

              // ── Voter ID: 10 chars — ABC1234567 ──
              _buildVerificationSection(
                label: "Voter ID",
                marathiLabel: "मतदार ओळखपत्र",
                type: "VOTER",
                isVerified: isVoterVerified,
                controller: _voterIdController,
                networkImageUrl: _data?['voter_id_card_url'],
                localPath: _localVoterIdPath,
                validator: DocValidators.voterId,
                maxLength: 10,
                textCapitalization: TextCapitalization.characters,
                keyboardType: TextInputType.text,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'[a-zA-Z0-9]')),
                  UpperCaseTextFormatter(),
                ],
                helperText: 'Format: ABC1234567 (3 letters + 7 digits)',
              ),

              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _handleUpdate,
                icon: _isSubmitting
                    ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(
                  _isSubmitting
                      ? "Updating... / अपडेट होत आहे..."
                      : "Save & Update Details / तपशील जतन करा",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  CUSTOM TEXT FORMATTER — Auto uppercase
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
