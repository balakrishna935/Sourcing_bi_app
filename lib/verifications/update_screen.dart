import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'mukadam_dashboard/mukadam_service.dart';

class MukkadamUpdateScreen extends StatefulWidget {
  final int mukkadamId;

  const MukkadamUpdateScreen({super.key, required this.mukkadamId});

  @override
  State<MukkadamUpdateScreen> createState() => _MukkadamUpdateScreenState();
}

class _MukkadamUpdateScreenState extends State<MukkadamUpdateScreen> {
  final MukkadamService _service = MukkadamService();
  final ImagePicker _picker = ImagePicker();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _panController = TextEditingController();
  final TextEditingController _aadharController = TextEditingController();
  final TextEditingController _voterController = TextEditingController();
  final TextEditingController _dummyController = TextEditingController();

  Map<String, dynamic>? _data;
  bool _isLoading = true;

  String? _localPanPath;
  String? _localAadharPath;
  String? _localProfilePath;

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
    _voterController.dispose();
    _dummyController.dispose();
    super.dispose();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  VALIDATION METHODS (all optional — only validate if non-empty)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// PAN: 10 characters — 5 uppercase letters + 4 digits + 1 uppercase letter
  /// Example: ABCDE1234F
  /// OPTIONAL: returns null if empty
  String? _validatePAN(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional — skip validation if empty
    }
    final pan = value.trim().toUpperCase();
    final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
    if (pan.length != 10) {
      return 'PAN must be exactly 10 characters\nपॅन अचूक 10 अक्षरांचा असावा';
    }
    if (!panRegex.hasMatch(pan)) {
      return 'Invalid PAN format (e.g. ABCDE1234F)\nअवैध पॅन स्वरूप (उदा. ABCDE1234F)';
    }
    return null;
  }

  /// Aadhaar: 12 digits, must not start with 0 or 1
  /// Example: 234567890123
  /// OPTIONAL: returns null if empty
  String? _validateAadhar(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional — skip validation if empty
    }
    final aadhar = value.trim().replaceAll(' ', '');
    if (aadhar.length != 12) {
      return 'Aadhaar must be exactly 12 digits\nआधार अचूक 12 अंकांचा असावा';
    }
    final aadharRegex = RegExp(r'^[2-9]{1}[0-9]{11}$');
    if (!aadharRegex.hasMatch(aadhar)) {
      return 'Invalid Aadhaar (12 digits, cannot start with 0 or 1)\nअवैध आधार (12 अंक, 0 किंवा 1 ने सुरू होऊ शकत नाही)';
    }
    return null;
  }

  /// Voter ID (EPIC): 10 characters — 3 uppercase letters + 7 digits
  /// Example: ABC1234567
  /// OPTIONAL: returns null if empty
  String? _validateVoterID(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional — skip validation if empty
    }
    final voter = value.trim().toUpperCase();
    if (voter.length != 10) {
      return 'Voter ID must be exactly 10 characters\nमतदार ओळखपत्र अचूक 10 अक्षरांचे असावे';
    }
    final voterRegex = RegExp(r'^[A-Z]{3}[0-9]{7}$');
    if (!voterRegex.hasMatch(voter)) {
      return 'Invalid Voter ID format (e.g. ABC1234567)\nअवैध मतदार ओळखपत्र स्वरूप (उदा. ABC1234567)';
    }
    return null;
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  DATA LOADING
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  void _loadDetails() async {
    try {
      final data = await _service.fetchMukkadamDetails(widget.mukkadamId);
      setState(() {
        _data = data;
        _panController.text = data['pan_number'] ?? '';
        _aadharController.text = data['aadhar_number'] ?? '';
        _voterController.text = data['voter_id_number'] ?? '';
        _isLoading = false;
        _localPanPath = null;
        _localAadharPath = null;
        _localProfilePath = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error / त्रुटी: $e")));
      setState(() => _isLoading = false);
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  IMAGE PICKER
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

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
                  'Select Image Source / प्रतिमा स्रोत निवडा',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: _textPrimary,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: _primaryColor),
                title: const Text('Gallery / गॅलरी',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: _textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(type, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: _primaryColor),
                title: const Text('Camera / कॅमेरा',
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
        if (type == "PAN") {
          _localPanPath = image.path;
        } else if (type == "AADHAR") {
          _localAadharPath = image.path;
        } else if (type == "PROFILE") {
          _localProfilePath = image.path;
        }
      });
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  UPDATE HANDLER (with validation)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  void _handleUpdate() async {
    // Validate form first
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Please fix the errors before submitting\nकृपया सबमिट करण्यापूर्वी त्रुटी दुरुस्त करा"),
          backgroundColor: _errorColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? panS3Key;
      String? aadharS3Key;
      String? profileS3Key;

      final String mobileNumber = _data?['mobile_numbers'] ?? 'unknown';
      final String timestamp =
      DateTime.now().millisecondsSinceEpoch.toString();

      if (_localPanPath != null) {
        final String extension =
        p.extension(_localPanPath!).replaceAll('.', '');
        final String pan = _panController.text.trim().isEmpty
            ? "pan"
            : _panController.text.trim().toUpperCase();
        final String s3Path =
            "mukadamapp/pancard/$mobileNumber/${pan}_$timestamp.$extension";
        panS3Key = await _service.uploadFileToS3(
            filePath: _localPanPath!, s3ObjectName: s3Path);
      }

      if (_localAadharPath != null) {
        final String extension =
        p.extension(_localAadharPath!).replaceAll('.', '');
        final String aadhar = _aadharController.text.trim().isEmpty
            ? "aadhar"
            : _aadharController.text.trim();
        final String s3Path =
            "mukadamapp/aadharcard/$mobileNumber/${aadhar}_$timestamp.$extension";
        aadharS3Key = await _service.uploadFileToS3(
            filePath: _localAadharPath!, s3ObjectName: s3Path);
      }

      if (_localProfilePath != null) {
        final String extension =
        p.extension(_localProfilePath!).replaceAll('.', '');
        final String s3Path =
            "mukadamapp/profilephoto/$mobileNumber/profile_$timestamp.$extension";
        profileS3Key = await _service.uploadFileToS3(
            filePath: _localProfilePath!, s3ObjectName: s3Path);
      }

      final updateData = {
        "pan_number": _panController.text.trim().toUpperCase(),
        "aadhar_number": _aadharController.text.trim().replaceAll(' ', ''),
        "voter_id_number": _voterController.text.trim().toUpperCase(),
        if (panS3Key != null) "pan_card_s3_key": panS3Key,
        if (aadharS3Key != null) "aadhar_card_s3_key": aadharS3Key,
        if (profileS3Key != null) "profile_photo_s3_key": profileS3Key,
      };

      bool success =
      await _service.updateMukkadam(widget.mukkadamId, updateData);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
            Text("Updated Successfully / यशस्वीरित्या अपडेट केले"),
            backgroundColor: _successColor,
          ),
        );
        _loadDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  "Failed to update details / तपशील अपडेट करण्यात अयशस्वी")),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error / त्रुटी: $e")));
      setState(() => _isLoading = false);
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  VERIFICATION SECTION BUILDER
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

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
                      "$label / $marathiLabel",
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: _textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (isVerified)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                        "Verified / सत्यापित",
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
                labelText: "$label Number / $marathiLabel क्रमांक",
                labelStyle: const TextStyle(
                  color: _textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                hintText:
                "Enter $label Number / $marathiLabel क्रमांक प्रविष्ट करा",
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
                prefixIcon:
                const Icon(Icons.badge_outlined, color: _primaryColor),
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
            "Upload Document / कागदपत्र अपलोड करा",
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

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  BUILD
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

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

    bool isFaceVerified = (_data?['is_face_match_verified'] ?? false) &&
        (_data?['is_face_liveness_verified'] ?? false);
    bool isPanVerified = _data?['is_pan_verified'] ?? false;
    bool isAadharVerified = _data?['is_aadhaar_verified'] ?? false;
    bool isVoterVerified = _data?['is_voter_id_verified'] ?? false;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primaryColor,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _data?['mukkadam_name'] ?? "Update Details / तपशील अपडेट करा",
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            children: [
              // ── Profile Photo (no text field, no validation) ──
              _buildVerificationSection(
                label: "Profile Photo",
                marathiLabel: "प्रोफाइल फोटो",
                type: "PROFILE",
                isVerified: isFaceVerified,
                controller: _dummyController,
                networkImageUrl: _data?['profile_photo_url'],
                localPath: _localProfilePath,
                showTextField: false,
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
                validator: _validatePAN,
                maxLength: 10,
                textCapitalization: TextCapitalization.characters,
                keyboardType: TextInputType.text,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                  UpperCaseTextFormatter(),
                ],
                helperText:
                'Format / स्वरूप: ABCDE1234F (5 letters/अक्षरे + 4 digits/अंक + 1 letter/अक्षर)',
              ),

              // ── Aadhar Card: 12 digits, cannot start with 0 or 1 ──
              _buildVerificationSection(
                label: "Aadhar Card",
                marathiLabel: "आधार कार्ड",
                type: "AADHAR",
                isVerified: isAadharVerified,
                controller: _aadharController,
                networkImageUrl: _data?['aadhar_card_url'],
                localPath: _localAadharPath,
                validator: _validateAadhar,
                maxLength: 12,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                helperText:
                '12-digit number (cannot start with 0 or 1) / 12-अंकी क्रमांक (0 किंवा 1 ने सुरू होऊ शकत नाही)',
              ),

              // ── Voter ID: 10 chars — ABC1234567 ──
              _buildVerificationSection(
                label: "Voter ID",
                marathiLabel: "मतदार ओळखपत्र",
                type: "VOTER",
                isVerified: isVoterVerified,
                controller: _voterController,
                networkImageUrl: null,
                localPath: null,
                showImagePicker: false,
                validator: _validateVoterID,
                maxLength: 10,
                textCapitalization: TextCapitalization.characters,
                keyboardType: TextInputType.text,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                  UpperCaseTextFormatter(),
                ],
                helperText:
                'Format / स्वरूप: ABC1234567 (3 letters/अक्षरे + 7 digits/अंक)',
              ),

              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _handleUpdate,
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text(
                  "Save & Update Details / जतन करा आणि अपडेट करा",
                  style: TextStyle(
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
