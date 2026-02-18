import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:mukadam_bi/transport/Transport_provider/transport_model.dart';
import '../../notes/data.dart';
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
  void _showImagePickerOptions(String type) {
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
                Column(
                  children: [
                    const Text(
                      'Choose an option',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                    Text(
                      'एक पर्याय निवडा',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _textSecondary,
                      ),
                    ),
                  ],
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
                  title: const Text('Camera / कॅमेरा',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Take a photo / फोटो काढा'),
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
                  title: const Text('Gallery / गॅलरी',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle:
                  const Text('Choose from gallery / गॅलरीतून निवडा'),
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

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedState == null ||
          _selectedDistrict == null ||
          _selectedTaluka == null ||
          _selectedVillage == null) {
        _showSnackBar("Please select all location fields / कृपया सर्व स्थान फील्ड निवडा",
            isError: true);
        return;
      }

      if (_profilePhotoPath == null) {
        _showSnackBar("Profile photo is mandatory / प्रोफाइल फोटो आवश्यक आहे",
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
        _showSnackBar('Provider created successfully! / प्रदाता यशस्वीरित्या तयार झाला!');
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

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : _backgroundColor,
      appBar: _buildAppBar(isDark),
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
                    title: 'Basic Information',
                    subtitle: 'मूलभूत माहिती',
                    icon: Icons.person,
                    isDark: isDark,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _nameController,
                          label: 'Provider Name',
                          labelMarathi: 'प्रदात्याचे नाव',
                          hint: 'Enter full name / पूर्ण नाव प्रविष्ट करा',
                          icon: Icons.badge_outlined,
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Name is required / नाव आवश्यक आहे'
                              : null,
                          required: true,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _contactNumberController,
                          label: 'Contact Number',
                          labelMarathi: 'संपर्क क्रमांक',
                          hint: '10 digit mobile number / १० अंकी मोबाइल क्रमांक',
                          icon: Icons.phone_android,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (v) => (v == null || v.length != 10)
                              ? 'Enter valid 10 digit mobile / वैध १० अंकी मोबाइल प्रविष्ट करा'
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
                    title: 'Location Details',
                    subtitle: 'स्थान तपशील',
                    icon: Icons.location_on,
                    isDark: isDark,
                    child: Column(
                      children: [
                        _buildSearchableDropdown(
                          value: _selectedState,
                          items: _states,
                          displayKey: 'state_name_english',
                          label: 'State',
                          labelMarathi: 'राज्य',
                          hint: 'Select State / राज्य निवडा',
                          icon: Icons.public,
                          onChanged: (val) {
                            setState(() => _selectedState = val);
                            if (val != null)
                              _loadDistricts(val['state_code']);
                          },
                          required: true,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildSearchableDropdown(
                          value: _selectedDistrict,
                          items: _districts,
                          displayKey: 'districtnameenglish',
                          label: 'District',
                          labelMarathi: 'जिल्हा',
                          hint: 'Select District / जिल्हा निवडा',
                          icon: Icons.map,
                          onChanged: (val) {
                            setState(() => _selectedDistrict = val);
                            if (val != null)
                              _loadTalukas(_selectedState!['state_code'],
                                  val['districtcode'].toString());
                          },
                          required: true,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildSearchableDropdown(
                          value: _selectedTaluka,
                          items: _talukas,
                          displayKey: 'subdistrictnameenglish',
                          label: 'Taluka',
                          labelMarathi: 'तालुका',
                          hint: 'Select Taluka / तालुका निवडा',
                          icon: Icons.location_city,
                          onChanged: (val) {
                            setState(() => _selectedTaluka = val);
                            if (val != null)
                              _loadVillages(_selectedState!['state_code'],
                                  val['subdistrictcode'].toString());
                          },
                          required: true,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildSearchableDropdown(
                          value: _selectedVillage,
                          items: _villages,
                          displayKey: 'villagenameenglish',
                          label: 'Village',
                          labelMarathi: 'गाव',
                          hint: 'Select Village / गाव निवडा',
                          icon: Icons.home,
                          onChanged: (val) =>
                              setState(() => _selectedVillage = val),
                          required: true,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Vehicle & Driver Details Card
                  _buildSectionCard(
                    title: 'Vehicle & Driver Details',
                    subtitle: 'वाहन आणि चालक तपशील',
                    icon: Icons.directions_car,
                    isDark: isDark,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _capacityController,
                          label: 'Capacity',
                          labelMarathi: 'क्षमता',
                          hint: 'Enter capacity / क्षमता प्रविष्ट करा',
                          icon: Icons.fitness_center_outlined,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return 'Required / आवश्यक';
                            if (int.tryParse(v) == null)
                              return 'Invalid number / अवैध क्रमांक';
                            return null;
                          },
                          required: true,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildVehicleDropdown(isDark),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _vehicleController,
                          label: 'Vehicle Number',
                          labelMarathi: 'वाहन क्रमांक',
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
                              return 'Enter a valid vehicle number / वैध वाहन क्रमांक प्रविष्ट करा';
                            }
                            return null;
                          },
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _dlNumberController,
                          label: 'DL Number',
                          labelMarathi: 'डीएल क्रमांक',
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
                              return 'Enter a valid DL number (10-16 chars) / वैध डीएल क्रमांक प्रविष्ट करा';
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
                              label: 'Driver DOB',
                              labelMarathi: 'चालकाची जन्मतारीख',
                              hint: 'Select date / तारीख निवडा',
                              icon: Icons.calendar_today_outlined,
                              isDark: isDark,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _maxDistanceController,
                          label: 'Max Distance (KM)',
                          labelMarathi: 'कमाल अंतर (किमी)',
                          hint: 'Enter maximum distance / कमाल अंतर प्रविष्ट करा',
                          icon: Icons.social_distance_outlined,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required / आवश्यक' : null,
                          required: true,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Document Numbers Card
                  _buildSectionCard(
                    title: 'Document Numbers',
                    subtitle: 'कागदपत्र क्रमांक',
                    icon: Icons.badge,
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSubsectionHeader(
                            'Aadhar Details', 'आधार तपशील', isDark),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _aadharNumberController,
                          label: '',
                          labelMarathi: '',
                          hint: 'Enter 12-digit Aadhar Number / १२ अंकी आधार क्रमांक प्रविष्ट करा',
                          icon: Icons.fingerprint_outlined,
                          keyboardType: TextInputType.number,
                          maxLength: 12,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (v) {
                            if (v != null && v.isNotEmpty && v.length != 12) {
                              return 'Aadhar must be 12 digits / आधार १२ अंकी असणे आवश्यक';
                            }
                            return null;
                          },
                          isDark: isDark,
                        ),
                        const SizedBox(height: 24),
                        _buildSubsectionHeader(
                            'PAN Details', 'पॅन तपशील', isDark),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _panNumberController,
                          label: '',
                          labelMarathi: '',
                          hint: 'Enter PAN (e.g., ABCDE1234F) / पॅन प्रविष्ट करा',
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
                                return 'PAN must be 10 characters / पॅन १० अक्षरांचा असावा';
                              }
                              final panRegex =
                              RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');
                              if (!panRegex.hasMatch(v)) {
                                return 'Invalid PAN format (e.g., ABCDE1234F) / अवैध पॅन स्वरूप';
                              }
                            }
                            return null;
                          },
                          isDark: isDark,
                        ),
                        const SizedBox(height: 24),
                        _buildSubsectionHeader(
                            'Voter ID Details', 'मतदार ओळखपत्र तपशील', isDark),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _voterIdController,
                          label: '',
                          labelMarathi: '',
                          hint: 'Enter Voter ID (e.g., ABC1234567) / मतदार ओळखपत्र प्रविष्ट करा',
                          icon: Icons.how_to_vote_outlined,
                          maxLength: 10,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[A-Za-z0-9]')),
                            UpperCaseTextFormatter(),
                          ],
                          validator: (v) {
                            if (v != null && v.isNotEmpty && v.length != 10) {
                              return 'Voter ID must be 10 characters / मतदार ओळखपत्र १० अक्षरांचे असावे';
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
                    title: 'Upload Documents',
                    subtitle: 'कागदपत्रे अपलोड करा',
                    icon: Icons.cloud_upload_outlined,
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Profile Photo * / प्रोफाइल फोटो *',
                            isDark: isDark, required: false),
                        const SizedBox(height: 8),
                        _buildDocumentUploadCard(
                            'Profile Photo', 'प्रोफाइल फोटो', 'profile',
                            _profilePhotoPath, isDark),
                        const SizedBox(height: 16),
                        _buildDocumentUploadCard(
                            'Aadhar Card', 'आधार कार्ड', 'aadhar',
                            _aadharCardPath, isDark),
                        const SizedBox(height: 16),
                        _buildDocumentUploadCard(
                            'PAN Card', 'पॅन कार्ड', 'pan',
                            _panCardPath, isDark),
                        const SizedBox(height: 16),
                        _buildDocumentUploadCard(
                            'Voter ID Card', 'मतदार ओळखपत्र', 'voter',
                            _voterIdPath, isDark),
                        const SizedBox(height: 16),
                        _buildDocumentUploadCard(
                            'Driving License', 'वाहन चालक परवाना', 'dl',
                            _dlPath, isDark),
                        const SizedBox(height: 16),
                        _buildDocumentUploadCard(
                            'RC Book', 'आरसी पुस्तक', 'rc',
                            _rcPath, isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Status & Notes Card
                  _buildSectionCard(
                    title: 'Additional Info',
                    subtitle: 'अतिरिक्त माहिती',
                    icon: Icons.info_outline,
                    isDark: isDark,
                    child: Column(
                      children: [
                        _buildStatusToggle(isDark),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _notesController,
                          label: 'Notes',
                          labelMarathi: 'टिपा',
                          hint: 'Enter any specific requirements... / कोणत्याही विशिष्ट आवश्यकता प्रविष्ट करा...',
                          icon: Icons.notes_outlined,
                          maxLines: 3,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Submit Button
                  _buildSubmitButton(isDark),
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
                        'Please wait... / कृपया प्रतीक्षा करा...',
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

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transport Registration',
            style: GoogleFonts.inter(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            'वाहतूक प्रदाता नोंदणी',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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

  /// Updated _buildTextField with optional labelMarathi for bilingual label
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String labelMarathi = '',
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel(label, required: required, isDark: isDark),
                if (labelMarathi.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      labelMarathi,
                      style: GoogleFonts.inter(
                        color: isDark ? Colors.grey[500] : _textSecondary.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
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

  /// Updated _buildSearchableDropdown with labelMarathi for bilingual label
  Widget _buildSearchableDropdown({
    required Map<String, dynamic>? value,
    required List<Map<String, dynamic>> items,
    required String displayKey,
    required String label,
    String labelMarathi = '',
    required String hint,
    required IconData icon,
    required void Function(Map<String, dynamic>?) onChanged,
    required bool isDark,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel(label, required: required, isDark: isDark),
                if (labelMarathi.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      labelMarathi,
                      style: GoogleFonts.inter(
                        color: isDark ? Colors.grey[500] : _textSecondary.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
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
                hintText: "Search... / शोधा...",
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
          (required && v == null) ? 'This field is required / हे फील्ड आवश्यक आहे' : null,
        ),
      ],
    );
  }

  Widget _buildVehicleDropdown(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Vehicle Type', required: true, isDark: isDark),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'वाहन प्रकार',
                  style: GoogleFonts.inter(
                    color: isDark ? Colors.grey[500] : _textSecondary.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        DropdownButtonFormField<String>(
          validator: (v) => (v == null || v.isEmpty)
              ? 'Vehicle type is required / वाहन प्रकार आवश्यक आहे'
              : null,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: 'Select type / प्रकार निवडा',
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

  /// Updated _buildDocumentUploadCard with Marathi label
  Widget _buildDocumentUploadCard(
      String label, String labelMarathi, String documentType, String? path, bool isDark) {
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
                onTap: () => _showImagePickerOptions(documentType),
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
                                  ? '$label Uploaded'
                                  : 'Upload $label',
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
                            Text(
                              hasFile
                                  ? '$labelMarathi अपलोड झाले'
                                  : '$labelMarathi अपलोड करा',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: hasFile
                                    ? _successColor.withOpacity(0.8)
                                    : (isDark
                                    ? Colors.grey[500]
                                    : _textSecondary),
                              ),
                            ),
                            if (!hasFile)
                              Text(
                                'Tap to select / निवडण्यासाठी टॅप करा',
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
                                style: TextStyle(
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

  /// Updated _buildSubsectionHeader with Marathi subtitle
  Widget _buildSubsectionHeader(
      String title, String titleMarathi, bool isDark) {
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : _textPrimary,
              ),
            ),
            Text(
              titleMarathi,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[500] : _textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusToggle(bool isDark) {
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
                    'Active Status / सक्रिय स्थिती',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? Colors.white : _textPrimary,
                    ),
                  ),
                  Text(
                    _isActive
                        ? 'Provider is ready for orders / प्रदाता ऑर्डरसाठी तयार आहे'
                        : 'Provider is inactive / प्रदाता निष्क्रिय आहे',
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

  Widget _buildSubmitButton(bool isDark) {
    return Container(
      width: double.infinity,
      height: 60,
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
        onPressed: _isLoadingLocations ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          disabledBackgroundColor: Colors.grey[400],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_circle_outline, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Create Transport Provider',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            Text(
              'वाहतूक प्रदाता तयार करा',
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.85),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
