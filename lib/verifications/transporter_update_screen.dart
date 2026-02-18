import 'dart:io';
import 'package:devlipi/devlipi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mukadam_bi/verifications/transporter_verifcations/verificatrion_service.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:translator/translator.dart';
import '../language_jsons/transporter_update_strings.dart';
import '../provider/language_provider.dart';

// ──────────────────────────── Validators (ALL OPTIONAL, language-aware) ────────────────────────────
class DocValidators {
  static String? pan(String? value, String lang) {
    if (value == null || value.trim().isEmpty) return null;
    final v = value.trim().toUpperCase();
    if (v.length != 10) {
      return TransporterUpdateStrings.get('pan_length_error', lang);
    }
    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(v)) {
      return TransporterUpdateStrings.get('pan_format_error', lang);
    }
    return null;
  }

  static String? aadhaar(String? value, String lang) {
    if (value == null || value.trim().isEmpty) return null;
    final v = value.trim().replaceAll(' ', '');
    if (v.length != 12) {
      return TransporterUpdateStrings.get('aadhar_length_error', lang);
    }
    if (!RegExp(r'^[2-9][0-9]{11}$').hasMatch(v)) {
      return TransporterUpdateStrings.get('aadhar_format_error', lang);
    }
    return null;
  }

  static String? vehicleNumber(String? value, String lang) {
    if (value == null || value.trim().isEmpty) return null;
    final v = value.trim().toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
    final standard = RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z]{1,2}[0-9]{4}$');
    final bhSeries = RegExp(r'^[0-9]{2}BH[0-9]{4}[A-HJ-NP-Z]{1,2}$');
    if (!standard.hasMatch(v) && !bhSeries.hasMatch(v)) {
      return TransporterUpdateStrings.get('rc_format_error', lang);
    }
    return null;
  }

  static String? drivingLicense(String? value, String lang) {
    if (value == null || value.trim().isEmpty) return null;
    final v = value.trim().toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
    if (!RegExp(r'^[A-Z]{2}[0-9]{2}(19|20)[0-9]{2}[0-9]{7}$').hasMatch(v)) {
      return TransporterUpdateStrings.get('dl_format_error', lang);
    }
    return null;
  }

  static String? voterId(String? value, String lang) {
    if (value == null || value.trim().isEmpty) return null;
    final v = value.trim().toUpperCase();
    if (v.length != 10) {
      return TransporterUpdateStrings.get('voter_length_error', lang);
    }
    if (!RegExp(r'^[A-Z]{3}[0-9]{7}$').hasMatch(v)) {
      return TransporterUpdateStrings.get('voter_format_error', lang);
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
  final GoogleTranslator _translator = GoogleTranslator();

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

  // ✅ Marathi name for language-aware AppBar
  String? _marathiName;

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

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  TRANSLATION HELPER
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<String> _toMarathi(String text) async {
    if (text.trim().isEmpty) return text;
    try {
      final result = await _translator.translate(text, from: 'en', to: 'mr');
      if (result.text.toLowerCase() != text.toLowerCase()) {
        return result.text;
      }
    } catch (_) {}
    return Devlipi.transliterate(text);
  }

  // ─────────── Data Loading ───────────
  void _loadDetails() async {
    try {
      final data = await _service.fetchTransporterDetails(widget.transporterId);

      // ✅ Translate name for Marathi display
      final String englishName = data['name'] ?? '';
      String? translatedName;
      if (englishName.trim().isNotEmpty) {
        translatedName = await _toMarathi(englishName);
      }

      setState(() {
        _data = data;
        _marathiName = translatedName;
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
      final lang = context.read<LanguageProvider>().language;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${TransporterUpdateStrings.get('error', lang)}: $e")),
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
    final lang = context.read<LanguageProvider>().language;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                title: Text(
                  TransporterUpdateStrings.get('select_image_source', lang),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: _textPrimary,
                  ),
                ),
              ),
              ListTile(
                leading:
                const Icon(Icons.photo_library, color: _primaryColor),
                title: Text(
                    TransporterUpdateStrings.get('gallery', lang),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: _textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(type, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: _primaryColor),
                title: Text(
                    TransporterUpdateStrings.get('camera', lang),
                    style: const TextStyle(
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
    final lang = context.read<LanguageProvider>().language;

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TransporterUpdateStrings.get('fix_errors', lang)),
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
          SnackBar(content: Text(TransporterUpdateStrings.get('no_changes', lang))),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      bool success = await _service.updateTransporter(
          widget.transporterId, updateData);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TransporterUpdateStrings.get('updated_successfully', lang)),
            backgroundColor: _successColor,
          ),
        );
        if (mounted) Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(TransporterUpdateStrings.get('failed_to_update', lang))),
        );
      }
    } catch (e) {
      final lang = context.read<LanguageProvider>().language;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${TransporterUpdateStrings.get('error', lang)}: $e")));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ───────────────────────── UI Builders ─────────────────────────

  Widget _buildVerificationSection({
    required String labelKey,
    required String lang,
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
    String? helperTextKey,
    bool showTextField = true,
    bool showImagePicker = true,
  }) {
    // ✅ Resolve display label based on selected language
    final String displayLabel = TransporterUpdateStrings.get(labelKey, lang);
    final String? helperText =
    helperTextKey != null ? TransporterUpdateStrings.get(helperTextKey, lang) : null;

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
                child: Text(
                  displayLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: _textPrimary,
                    letterSpacing: -0.3,
                  ),
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
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded,
                          color: _successColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        TransporterUpdateStrings.get('verified', lang),
                        style: const TextStyle(
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
                labelText:
                "$displayLabel ${TransporterUpdateStrings.get('number', lang)}",
                labelStyle: const TextStyle(
                  color: _textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                hintText:
                "${TransporterUpdateStrings.get('enter', lang)} $displayLabel ${TransporterUpdateStrings.get('number', lang)}",
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
                        errorBuilder: (_, __, ___) =>
                            _buildPlaceholder(lang),
                      )
                    else
                      _buildPlaceholder(lang),
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

  Widget _buildPlaceholder(String lang) {
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
          Text(
            TransporterUpdateStrings.get('upload_document', lang),
            style: const TextStyle(
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
    final lang = context.watch<LanguageProvider>().language;

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

    // ✅ Language-aware name display
    final String englishName = _data?['name'] ?? '';
    final String displayName = (lang == 'mr' &&
        _marathiName != null &&
        _marathiName!.isNotEmpty)
        ? _marathiName!
        : englishName;

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
              displayName.isNotEmpty
                  ? displayName
                  : TransporterUpdateStrings.get('update_details', lang),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 19,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              TransporterUpdateStrings.get('verification_details', lang),
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
              // ── Profile Photo ──
              _buildVerificationSection(
                labelKey: 'profile_photo',
                lang: lang,
                type: "PROFILE",
                isVerified: _isFaceVerified,
                controller: _dummyController,
                networkImageUrl: _data?['profile_photo_url'],
                localPath: _localProfilePath,
                showTextField: false,
              ),

              // ── RC Book ──
              _buildVerificationSection(
                labelKey: 'rc_book',
                lang: lang,
                type: "RC",
                isVerified: isRcVerified,
                controller: _rcController,
                networkImageUrl: _data?['rc_book_url'],
                localPath: _localRcPath,
                validator: (v) => DocValidators.vehicleNumber(v, lang),
                maxLength: 13,
                textCapitalization: TextCapitalization.characters,
                keyboardType: TextInputType.text,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'[A-Za-z0-9\s-]')),
                  UpperCaseTextFormatter(),
                ],
                helperTextKey: 'rc_helper',
              ),

              // ── Driving License ──
              _buildVerificationSection(
                labelKey: 'driving_license',
                lang: lang,
                type: "DL",
                isVerified: isDlVerified,
                controller: _dlController,
                networkImageUrl: _data?['driving_license_url'],
                localPath: _localDlPath,
                validator: (v) => DocValidators.drivingLicense(v, lang),
                maxLength: 20,
                textCapitalization: TextCapitalization.characters,
                keyboardType: TextInputType.text,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'[A-Za-z0-9\s-]')),
                  UpperCaseTextFormatter(),
                ],
                helperTextKey: 'dl_helper',
              ),

              // ── PAN Card ──
              _buildVerificationSection(
                labelKey: 'pan_card',
                lang: lang,
                type: "PAN",
                isVerified: isPanVerified,
                controller: _panController,
                networkImageUrl: _data?['pan_card_url'],
                localPath: _localPanPath,
                validator: (v) => DocValidators.pan(v, lang),
                maxLength: 10,
                textCapitalization: TextCapitalization.characters,
                keyboardType: TextInputType.text,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'[a-zA-Z0-9]')),
                  UpperCaseTextFormatter(),
                ],
                helperTextKey: 'pan_helper',
              ),

              // ── Aadhar Card ──
              _buildVerificationSection(
                labelKey: 'aadhar_card',
                lang: lang,
                type: "AADHAR",
                isVerified: isAadharVerified,
                controller: _aadharController,
                networkImageUrl: _data?['aadhar_card_url'],
                localPath: _localAadharPath,
                validator: (v) => DocValidators.aadhaar(v, lang),
                maxLength: 12,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                helperTextKey: 'aadhar_helper',
              ),

              // ── Voter ID ──
              _buildVerificationSection(
                labelKey: 'voter_id',
                lang: lang,
                type: "VOTER",
                isVerified: isVoterVerified,
                controller: _voterIdController,
                networkImageUrl: _data?['voter_id_card_url'],
                localPath: _localVoterIdPath,
                validator: (v) => DocValidators.voterId(v, lang),
                maxLength: 10,
                textCapitalization: TextCapitalization.characters,
                keyboardType: TextInputType.text,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'[a-zA-Z0-9]')),
                  UpperCaseTextFormatter(),
                ],
                helperTextKey: 'voter_helper',
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
                      ? TransporterUpdateStrings.get('updating', lang)
                      : TransporterUpdateStrings.get('save_update', lang),
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
