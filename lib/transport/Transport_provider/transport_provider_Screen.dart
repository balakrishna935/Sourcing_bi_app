import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:mukadam_bi/transport/Transport_provider/transport_model.dart';
import '../../notes/data.dart';
import '../../provider/language_provider.dart';
import '../../language_jsons/app_strings.dart';
import 'Transport_Service.dart';

// ── Helper: Uppercase Text Formatter for Voter ID / PAN ──
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class TransportProviderScreen extends StatefulWidget {
  const TransportProviderScreen({super.key});

  @override
  State<TransportProviderScreen> createState() =>
      _TransportProviderScreenState();
}

class _TransportProviderScreenState extends State<TransportProviderScreen> {
  final _formKey = GlobalKey<FormState>();
  final TransportProviderService _service = TransportProviderService();
  final DataEntryService _dataEntryService = DataEntryService();
  final ImagePicker _picker = ImagePicker();

  // ── Professional Color Palette ──
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

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactNumberController =
  TextEditingController();
  final TextEditingController _maxDistanceController = TextEditingController();
  final TextEditingController _vehicleTypeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _vehicleController = TextEditingController();
  final TextEditingController _dlNumberController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _aadharNumberController = TextEditingController();
  final TextEditingController _panNumberController = TextEditingController();
  final TextEditingController _voterIdController = TextEditingController();

  // File Paths
  String? _profilePhotoPath;
  String? _aadharCardPath;
  String? _panCardPath;
  String? _voterIdPath;
  String? _dlPath;
  String? _rcPath;

  DateTime? _selectedDob;
  bool _isActive = true;
  bool _isLoadingLocations = false;

  List<Map<String, dynamic>> _states = [];
  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _talukas = [];
  List<Map<String, dynamic>> _villages = [];

  Map<String, dynamic>? _selectedState;
  Map<String, dynamic>? _selectedDistrict;
  Map<String, dynamic>? _selectedTaluka;
  Map<String, dynamic>? _selectedVillage;

  final List<String> _vehicles = ['Truck', 'Van', 'Bike', 'Car'];

  @override
  void initState() {
    super.initState();
    _loadStates();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactNumberController.dispose();
    _maxDistanceController.dispose();
    _vehicleTypeController.dispose();
    _notesController.dispose();
    _capacityController.dispose();
    _vehicleController.dispose();
    _dlNumberController.dispose();
    _dobController.dispose();
    _aadharNumberController.dispose();
    _panNumberController.dispose();
    _voterIdController.dispose();
    super.dispose();
  }

  // ─── Show bottom sheet with Camera & Gallery options ───
  void _showImagePickerOptions(String type, String lang) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  AppStrings.get('choose_option', lang),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_alt, color: _primaryColor),
                  ),
                  title: Text(AppStrings.get('camera', lang),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(AppStrings.get('take_photo', lang)),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(type, ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                    const Icon(Icons.photo_library, color: _primaryColor),
                  ),
                  title: Text(AppStrings.get('gallery', lang),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(AppStrings.get('choose_from_gallery', lang)),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(type, ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(String type, ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        if (type == 'profile') _profilePhotoPath = pickedFile.path;
        if (type == 'aadhar') _aadharCardPath = pickedFile.path;
        if (type == 'pan') _panCardPath = pickedFile.path;
        if (type == 'voter') _voterIdPath = pickedFile.path;
        if (type == 'dl') _dlPath = pickedFile.path;
        if (type == 'rc') _rcPath = pickedFile.path;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
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
    if (picked != null && picked != _selectedDob) {
      setState(() {
        _selectedDob = picked;
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _loadStates() async {
    setState(() => _isLoadingLocations = true);
    try {
      final states = await _dataEntryService.getStates();
      setState(() {
        _states = states;
        _isLoadingLocations = false;
      });
    } catch (e) {
      setState(() => _isLoadingLocations = false);
      _showSnackBar("Error loading states: $e", isError: true);
    }
  }

  Future<void> _loadDistricts(String stateCode) async {
    setState(() {
      _districts = [];
      _talukas = [];
      _villages = [];
      _selectedDistrict = null;
      _selectedTaluka = null;
      _selectedVillage = null;
      _isLoadingLocations = true;
    });
    try {
      final districts = await _dataEntryService.getDistricts(stateCode);
      setState(() {
        _districts = districts;
        _isLoadingLocations = false;
      });
    } catch (e) {
      setState(() => _isLoadingLocations = false);
      _showSnackBar("Error loading districts: $e", isError: true);
    }
  }

  Future<void> _loadTalukas(String stateCode, String districtCode) async {
    setState(() {
      _talukas = [];
      _villages = [];
      _selectedTaluka = null;
      _selectedVillage = null;
      _isLoadingLocations = true;
    });
    try {
      final talukas =
      await _dataEntryService.getTalukas(stateCode, districtCode);
      setState(() {
        _talukas = talukas;
        _isLoadingLocations = false;
      });
    } catch (e) {
      setState(() => _isLoadingLocations = false);
      _showSnackBar("Error loading talukas: $e", isError: true);
    }
  }

  Future<void> _loadVillages(String stateCode, String talukaCode) async {
    setState(() {
      _villages = [];
      _selectedVillage = null;
      _isLoadingLocations = true;
    });
    try {
      final villages =
      await _dataEntryService.getVillages(stateCode, talukaCode);
      setState(() {
        _villages = villages;
        _isLoadingLocations = false;
      });
    } catch (e) {
      setState(() => _isLoadingLocations = false);
      _showSnackBar("Error loading villages: $e", isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? _errorColor : _successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _submitForm(String lang) async {
    if (_formKey.currentState!.validate()) {
      if (_selectedState == null ||
          _selectedDistrict == null ||
          _selectedTaluka == null ||
          _selectedVillage == null) {
        _showSnackBar(AppStrings.get('select_all_location', lang),
            isError: true);
        return;
      }

      if (_profilePhotoPath == null) {
        _showSnackBar(AppStrings.get('profile_photo_mandatory', lang),
            isError: true);
        return;
      }

      setState(() => _isLoadingLocations = true);

      final baseProvider = TransportProvider(
        name: _nameController.text,
        contactNumber: _contactNumberController.text,
        state: _selectedState!['state_name_english'],
        stateCode: _selectedState!['state_code'],
        district: _selectedDistrict!['districtnameenglish'],
        districtCode: _selectedDistrict!['districtcode'].toString(),
        taluka: _selectedTaluka!['subdistrictnameenglish'],
        talukaCode: _selectedTaluka!['subdistrictcode'].toString(),
        village: _selectedVillage!['villagenameenglish'],
        villageCode: _selectedVillage!['villagecode'].toString(),
        maxDistance: int.parse(_maxDistanceController.text),
        vehicleType: _vehicleTypeController.text,
        isActive: _isActive,
        notes: _notesController.text,
        capacity: int.tryParse(_capacityController.text),
        vehicleNumber: _vehicleController.text,
        dlNumber: _dlNumberController.text,
        driverDob: _selectedDob,
        aadharNumber: _aadharNumberController.text,
        panNumber: _panNumberController.text,
        voterId: _voterIdController.text,
      );

      try {
        await _service.createTransportProvider(
          provider: baseProvider,
          profilePath: _profilePhotoPath,
          aadharPath: _aadharCardPath,
          panPath: _panCardPath,
          voterPath: _voterIdPath,
          dlPath: _dlPath,
          rcPath: _rcPath,
        );
        _showSnackBar(AppStrings.get('provider_created_success', lang));
        Navigator.pop(context);
      } catch (e) {
        _showSnackBar('Error: $e', isError: true);
      } finally {
        setState(() => _isLoadingLocations = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = context.watch<LanguageProvider>().language;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : _backgroundColor,
      appBar: _buildAppBar(isDark, lang),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Information Card
                  _buildSectionCard(
                    title: AppStrings.get('basic_details', lang),
                    subtitle: AppStrings.get('basic_details_sub', lang),
                    icon: Icons.person,
                    isDark: isDark,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _nameController,
                          label: AppStrings.get('provider_name', lang),
                          hint: AppStrings.get('enter_full_name', lang),
                          icon: Icons.badge_outlined,
                          validator: (v) => (v == null || v.isEmpty)
                              ? AppStrings.get('name_required', lang)
                              : null,
                          required: true,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _contactNumberController,
                          label: AppStrings.get('contact_number', lang),
                          hint: AppStrings.get('ten_digit_mobile', lang),
                          icon: Icons.phone_android,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (v) => (v == null || v.length != 10)
                              ? AppStrings.get('valid_mobile_required', lang)
                              : null,
                          required: true,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Location Details Card
                  _buildSectionCard(
                    title: AppStrings.get('location_details', lang),
                    subtitle: AppStrings.get('location_details_sub', lang),
                    icon: Icons.location_on,
                    isDark: isDark,
                    child: Column(
                      children: [
                        _buildSearchableDropdown(
                          value: _selectedState,
                          items: _states,
                          displayKey: 'state_name_english',
                          label: AppStrings.get('state', lang),
                          hint: AppStrings.get('select_state', lang),
                          icon: Icons.public,
                          onChanged: (val) {
                            setState(() => _selectedState = val);
                            if (val != null)
                              _loadDistricts(val['state_code']);
                          },
                          required: true,
                          isDark: isDark,
                          lang: lang,
                        ),
                        const SizedBox(height: 16),
                        _buildSearchableDropdown(
                          value: _selectedDistrict,
                          items: _districts,
                          displayKey: 'districtnameenglish',
                          label: AppStrings.get('district', lang),
                          hint: AppStrings.get('select_district', lang),
                          icon: Icons.map,
                          onChanged: (val) {
                            setState(() => _selectedDistrict = val);
                            if (val != null)
                              _loadTalukas(_selectedState!['state_code'],
                                  val['districtcode'].toString());
                          },
                          required: true,
                          isDark: isDark,
                          lang: lang,
                        ),
                        const SizedBox(height: 16),
                        _buildSearchableDropdown(
                          value: _selectedTaluka,
                          items: _talukas,
                          displayKey: 'subdistrictnameenglish',
                          label: AppStrings.get('taluka', lang),
                          hint: AppStrings.get('select_taluka', lang),
                          icon: Icons.location_city,
                          onChanged: (val) {
                            setState(() => _selectedTaluka = val);
                            if (val != null)
                              _loadVillages(_selectedState!['state_code'],
                                  val['subdistrictcode'].toString());
                          },
                          required: true,
                          isDark: isDark,
                          lang: lang,
                        ),
                        const SizedBox(height: 16),
                        _buildSearchableDropdown(
                          value: _selectedVillage,
                          items: _villages,
                          displayKey: 'villagenameenglish',
                          label: AppStrings.get('village', lang),
                          hint: AppStrings.get('select_village', lang),
                          icon: Icons.home,
                          onChanged: (val) =>
                              setState(() => _selectedVillage = val),
                          required: true,
                          isDark: isDark,
                          lang: lang,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Vehicle & Driver Details Card
                  _buildSectionCard(
                    title: AppStrings.get('vehicle_driver_details', lang),
                    subtitle: AppStrings.get('vehicle_driver_details_sub', lang),
                    icon: Icons.directions_car,
                    isDark: isDark,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _capacityController,
                          label: AppStrings.get('capacity', lang),
                          hint: AppStrings.get('enter_capacity', lang),
                          icon: Icons.fitness_center_outlined,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return AppStrings.get('required', lang);
                            if (int.tryParse(v) == null)
                              return AppStrings.get('invalid_number', lang);
                            return null;
                          },
                          required: true,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildVehicleDropdown(isDark, lang),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _vehicleController,
                          label: AppStrings.get('vehicle_number', lang),
                          hint: 'e.g. MH12AB1234',
                          icon: Icons.confirmation_number_outlined,
                          maxLength: 15,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[A-Za-z0-9 ]')),
                            UpperCaseTextFormatter(),
                          ],
                          validator: (v) {
                            if (v != null && v.isNotEmpty && v.length < 6) {
                              return AppStrings.get('valid_vehicle_number', lang);
                            }
                            return null;
                          },
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _dlNumberController,
                          label: AppStrings.get('dl_number', lang),
                          hint: 'e.g. MH0120190001234',
                          icon: Icons.assignment_ind_outlined,
                          maxLength: 16,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[A-Za-z0-9]')),
                            UpperCaseTextFormatter(),
                          ],
                          validator: (v) {
                            if (v != null && v.isNotEmpty && v.length < 10) {
                              return AppStrings.get('valid_dl_number', lang);
                            }
                            return null;
                          },
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => _selectDate(context),
                          child: AbsorbPointer(
                            child: _buildTextField(
                              controller: _dobController,
                              label: AppStrings.get('driver_dob', lang),
                              hint: AppStrings.get('select_date', lang),
                              icon: Icons.calendar_today_outlined,
                              isDark: isDark,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _maxDistanceController,
                          label: AppStrings.get('max_distance', lang),
                          hint: AppStrings.get('enter_max_distance', lang),
                          icon: Icons.social_distance_outlined,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (v) =>
                          (v == null || v.isEmpty) ? AppStrings.get('required', lang) : null,
                          required: true,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Document Numbers Card
                  _buildSectionCard(
                    title: AppStrings.get('document_numbers', lang),
                    subtitle: AppStrings.get('document_numbers_sub', lang),
                    icon: Icons.badge,
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSubsectionHeader(
                            AppStrings.get('aadhar_details', lang), isDark),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _aadharNumberController,
                          label: '',
                          hint: AppStrings.get('enter_aadhar', lang),
                          icon: Icons.fingerprint_outlined,
                          keyboardType: TextInputType.number,
                          maxLength: 12,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (v) {
                            if (v != null && v.isNotEmpty && v.length != 12) {
                              return AppStrings.get('aadhar_must_12', lang);
                            }
                            return null;
                          },
                          isDark: isDark,
                        ),
                        const SizedBox(height: 24),
                        _buildSubsectionHeader(
                            AppStrings.get('pan_details', lang), isDark),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _panNumberController,
                          label: '',
                          hint: AppStrings.get('enter_pan', lang),
                          icon: Icons.credit_card_outlined,
                          maxLength: 10,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[A-Za-z0-9]')),
                            UpperCaseTextFormatter(),
                          ],
                          validator: (v) {
                            if (v != null && v.isNotEmpty) {
                              if (v.length != 10) {
                                return AppStrings.get('pan_must_10', lang);
                              }
                              final panRegex =
                              RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');
                              if (!panRegex.hasMatch(v)) {
                                return AppStrings.get('invalid_pan_format', lang);
                              }
                            }
                            return null;
                          },
                          isDark: isDark,
                        ),
                        const SizedBox(height: 24),
                        _buildSubsectionHeader(
                            AppStrings.get('voter_details', lang), isDark),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _voterIdController,
                          label: '',
                          hint: AppStrings.get('enter_voter_id', lang),
                          icon: Icons.how_to_vote_outlined,
                          maxLength: 10,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[A-Za-z0-9]')),
                            UpperCaseTextFormatter(),
                          ],
                          validator: (v) {
                            if (v != null && v.isNotEmpty && v.length != 10) {
                              return AppStrings.get('voter_must_10', lang);
                            }
                            return null;
                          },
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Upload Documents Card
                  _buildSectionCard(
                    title: AppStrings.get('upload_documents', lang),
                    subtitle: AppStrings.get('upload_documents_sub', lang),
                    icon: Icons.cloud_upload_outlined,
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(AppStrings.get('profile_photo_required_label', lang),
                            isDark: isDark, required: false),
                        const SizedBox(height: 8),
                        _buildDocumentUploadCard(
                            AppStrings.get('profile_photo_label', lang), 'profile',
                            _profilePhotoPath, isDark, lang),
                        const SizedBox(height: 16),
                        _buildDocumentUploadCard(
                            AppStrings.get('aadhar_card_label', lang), 'aadhar',
                            _aadharCardPath, isDark, lang),
                        const SizedBox(height: 16),
                        _buildDocumentUploadCard(
                            AppStrings.get('pan_card_label', lang), 'pan',
                            _panCardPath, isDark, lang),
                        const SizedBox(height: 16),
                        _buildDocumentUploadCard(
                            AppStrings.get('voter_id_card_label', lang), 'voter',
                            _voterIdPath, isDark, lang),
                        const SizedBox(height: 16),
                        _buildDocumentUploadCard(
                            AppStrings.get('driving_license_label', lang), 'dl',
                            _dlPath, isDark, lang),
                        const SizedBox(height: 16),
                        _buildDocumentUploadCard(
                            AppStrings.get('rc_book_label', lang), 'rc',
                            _rcPath, isDark, lang),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Status & Notes Card
                  _buildSectionCard(
                    title: AppStrings.get('additional_info', lang),
                    subtitle: AppStrings.get('additional_info_sub', lang),
                    icon: Icons.info_outline,
                    isDark: isDark,
                    child: Column(
                      children: [
                        _buildStatusToggle(isDark, lang),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _notesController,
                          label: AppStrings.get('notes', lang),
                          hint: AppStrings.get('enter_notes', lang),
                          icon: Icons.notes_outlined,
                          maxLines: 3,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Submit Button
                  _buildSubmitButton(isDark, lang),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),

          // Loading Overlay
          if (_isLoadingLocations)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: _primaryColor,
                        strokeWidth: 4,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.get('please_wait', lang),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : _textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // ══════════════   WIDGET BUILDERS   ══════════════════
  // ═══════════════════════════════════════════════════════

  PreferredSizeWidget _buildAppBar(bool isDark, String lang) {
    return AppBar(
      title: Text(
        AppStrings.get('transport_registration_title', lang),
        style: GoogleFonts.inter(
          fontSize: 19,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: -0.3,
        ),
      ),
      centerTitle: false,
      backgroundColor: _primaryColor,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded,
            size: 22, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? const Color(0xFF334155) : _borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.03),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _primaryColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : _textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : _textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildLabel(String text,
      {bool required = false, required bool isDark}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: GoogleFonts.inter(
          color: isDark ? Colors.grey[300] : _textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        children: [
          if (required)
            const TextSpan(
              text: ' *',
              style:
              TextStyle(color: _errorColor, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool required = false,
    int? maxLength,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildLabel(label, required: required, isDark: isDark),
          ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          maxLength: maxLength,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: isDark ? Colors.white : _textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: isDark
                    ? Colors.grey[500]
                    : _textSecondary.withOpacity(0.6)),
            prefixIcon: Icon(icon, color: _primaryColor, size: 22),
            counterText: "",
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : _dividerColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color:
                  isDark ? const Color(0xFF334155) : _borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color:
                  isDark ? const Color(0xFF334155) : _borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
              const BorderSide(color: _accentColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
              const BorderSide(color: _errorColor, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
              const BorderSide(color: _errorColor, width: 2),
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchableDropdown({
    required Map<String, dynamic>? value,
    required List<Map<String, dynamic>> items,
    required String displayKey,
    required String label,
    required String hint,
    required IconData icon,
    required void Function(Map<String, dynamic>?) onChanged,
    required bool isDark,
    required String lang,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildLabel(label, required: required, isDark: isDark),
          ),
        DropdownSearch<Map<String, dynamic>>(
          items: (filter, loadProps) => items,
          selectedItem: value,
          itemAsString: (item) => item[displayKey]?.toString() ?? '',
          onChanged: onChanged,
          compareFn: (item1, item2) =>
          item1[displayKey] == item2[displayKey],
          filterFn: (item, filter) => item[displayKey]
              .toString()
              .toLowerCase()
              .contains(filter.toLowerCase()),
          decoratorProps: DropDownDecoratorProps(
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: _primaryColor, size: 22),
              hintText: hint,
              hintStyle: TextStyle(
                  color: isDark
                      ? Colors.grey[500]
                      : _textSecondary.withOpacity(0.6)),
              filled: true,
              fillColor:
              isDark ? const Color(0xFF0F172A) : _dividerColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF334155)
                        : _borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF334155)
                        : _borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                const BorderSide(color: _accentColor, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                const BorderSide(color: _errorColor, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16),
            ),
          ),
          popupProps: PopupProps.menu(
            showSearchBox: true,
            searchFieldProps: TextFieldProps(
              decoration: InputDecoration(
                hintText: AppStrings.get('search_hint', lang),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
            menuProps: MenuProps(
              backgroundColor:
              isDark ? const Color(0xFF1E293B) : _cardColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          validator: (v) =>
          (required && v == null) ? AppStrings.get('field_required', lang) : null,
        ),
      ],
    );
  }

  Widget _buildVehicleDropdown(bool isDark, String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildLabel(AppStrings.get('vehicle_type', lang),
              required: true, isDark: isDark),
        ),
        DropdownButtonFormField<String>(
          validator: (v) => (v == null || v.isEmpty)
              ? AppStrings.get('vehicle_type_required', lang)
              : null,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: AppStrings.get('select_type', lang),
            hintStyle: TextStyle(
                color: isDark
                    ? Colors.grey[500]
                    : _textSecondary.withOpacity(0.6)),
            prefixIcon: const Icon(Icons.local_shipping_outlined,
                color: _primaryColor, size: 22),
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : _dividerColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color:
                  isDark ? const Color(0xFF334155) : _borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color:
                  isDark ? const Color(0xFF334155) : _borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
              const BorderSide(color: _accentColor, width: 2),
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          value: _vehicleTypeController.text.isEmpty
              ? null
              : _vehicleTypeController.text,
          items: _vehicles
              .map((v) => DropdownMenuItem(
            value: v,
            child: Text(v,
                style: GoogleFonts.inter(fontSize: 15)),
          ))
              .toList(),
          onChanged: (val) =>
              setState(() => _vehicleTypeController.text = val!),
          dropdownColor:
          isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ],
    );
  }

  Widget _buildDocumentUploadCard(
      String label, String documentType, String? path, bool isDark, String lang) {
    final bool hasFile = path != null;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : _dividerColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasFile
              ? _successColor
              : (isDark ? const Color(0xFF334155) : _borderColor),
          width: hasFile ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showImagePickerOptions(documentType, lang),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: hasFile
                              ? _successColor.withOpacity(0.1)
                              : _primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          hasFile ? Icons.check_circle : Icons.upload_file,
                          color: hasFile ? _successColor : _primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasFile
                                  ? '$label ${AppStrings.get('uploaded', lang)}'
                                  : label,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: hasFile
                                    ? _successColor
                                    : (isDark
                                    ? Colors.white
                                    : _textPrimary),
                              ),
                            ),
                            if (!hasFile)
                              Text(
                                AppStrings.get('tap_to_select', lang),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.grey[500]
                                      : _textSecondary,
                                ),
                              ),
                            if (hasFile)
                              Text(
                                p.basename(path),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _successColor,
                                ),
                                maxLines: 1,
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
          ),
          Container(
            width: 1,
            height: 50,
            color: isDark ? const Color(0xFF334155) : _borderColor,
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _pickImage(documentType, ImageSource.camera),
              borderRadius:
              const BorderRadius.horizontal(right: Radius.circular(12)),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: const Icon(
                  Icons.camera_alt,
                  color: _primaryColor,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubsectionHeader(String title, bool isDark) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 28,
          decoration: BoxDecoration(
            color: _primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : _textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusToggle(bool isDark, String lang) {
    return Container(
      decoration: BoxDecoration(
        color: _isActive
            ? _successColor.withOpacity(0.05)
            : (isDark ? const Color(0xFF0F172A) : _dividerColor),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isActive
              ? _successColor
              : (isDark ? const Color(0xFF334155) : _borderColor),
          width: _isActive ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isActive
                    ? _successColor.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _isActive
                    ? Icons.check_circle_outline
                    : Icons.pause_circle_outline,
                color: _isActive ? _successColor : _textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.get('active_status', lang),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? Colors.white : _textPrimary,
                    ),
                  ),
                  Text(
                    _isActive
                        ? AppStrings.get('ready_for_orders', lang)
                        : AppStrings.get('provider_inactive', lang),
                    style: TextStyle(
                        color: isDark ? Colors.grey[400] : _textSecondary,
                        fontSize: 12),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: _isActive,
              activeColor: _successColor,
              onChanged: (val) => setState(() => _isActive = val),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(bool isDark, String lang) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryColor, _accentColor],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.3),
            spreadRadius: 0,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoadingLocations ? null : () => _submitForm(lang),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          disabledBackgroundColor: Colors.grey[400],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_outline, size: 24),
            const SizedBox(width: 12),
            Text(
              AppStrings.get('create_transport_provider', lang),
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
