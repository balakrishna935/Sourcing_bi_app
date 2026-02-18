import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mukadam_bi/mukadan/quick_registration/quick_registration_service.dart';
import 'package:provider/provider.dart';

import '../../geo_tagging.dart';
import '../../language_jsons/app_strings.dart';
import '../../notes/data.dart';
import '../../provider/language_provider.dart';
import '../authentication/userProvider.dart';

class QuickMukkadamRegistrationScreen extends StatefulWidget {
  const QuickMukkadamRegistrationScreen({super.key});

  @override
  State<QuickMukkadamRegistrationScreen> createState() => _QuickMukkadamRegistrationScreenState();
}

class _QuickMukkadamRegistrationScreenState extends State<QuickMukkadamRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final DataEntryService _dataEntryService = DataEntryService();
  final ImagePicker _picker = ImagePicker();
  final GeoTaggingService _geoTaggingService = GeoTaggingService();

  // ── Professional Color Palette ──
  static const Color _primaryColor = Color(0xFF1E3A5F);
  static const Color _accentColor = Color(0xFF3B82F6);
  static const Color _successColor = Color(0xFF10B981);
  static const Color _warningColor = Color(0xFFF59E0B);
  static const Color _errorColor = Color(0xFFEF4444);
  static const Color _purpleColor = Color(0xFF8B5CF6);
  static const Color _backgroundColor = Color(0xFFF8FAFC);
  static const Color _cardColor = Colors.white;
  static const Color _textPrimary = Color(0xFF1F2937);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _borderColor = Color(0xFFE5E7EB);
  static const Color _dividerColor = Color(0xFFF3F4F6);

  // Controllers
  final TextEditingController _mukkadamNameController = TextEditingController();
  final TextEditingController _mobileNumbersController = TextEditingController();
  final TextEditingController _crewSizeController = TextEditingController();
  final TextEditingController _maxCrewCapacityController = TextEditingController();

  final TextEditingController _altContact1NameController = TextEditingController();
  final TextEditingController _altPhone1Controller = TextEditingController();
  final TextEditingController _altContact2NameController = TextEditingController();
  final TextEditingController _altPhone2Controller = TextEditingController();

  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  final TextEditingController _latController = TextEditingController();
  final TextEditingController _longController = TextEditingController();

  final TextEditingController _aadharNumberController = TextEditingController();
  final TextEditingController _panNumberController = TextEditingController();
  final TextEditingController _voterIdNumberController = TextEditingController();

  // Rate Card Controllers
  final TextEditingController aprilPruningController = TextEditingController();
  final TextEditingController bagalBaliFutRemovalController = TextEditingController();
  final TextEditingController berryThinningController = TextEditingController();
  final TextEditingController bunchSelectionController = TextEditingController();
  final TextEditingController bunchThinningController = TextEditingController();
  final TextEditingController bunchTyingController = TextEditingController();
  final TextEditingController bunchVariationController = TextEditingController();
  final TextEditingController defaultRateController = TextEditingController();
  final TextEditingController failFutRemovalController = TextEditingController();
  final TextEditingController fingerThinningController = TextEditingController();
  final TextEditingController firstDippingController = TextEditingController();
  final TextEditingController firstFailFutRemovalController = TextEditingController();
  final TextEditingController harvestingController = TextEditingController();
  final TextEditingController newPlantationController = TextEditingController();
  final TextEditingController otherRateController = TextEditingController();
  final TextEditingController paperRemovalController = TextEditingController();
  final TextEditingController paperWrappingController = TextEditingController();
  final TextEditingController pastingController = TextEditingController();
  final TextEditingController pruningController = TextEditingController();
  final TextEditingController secondDippingController = TextEditingController();
  final TextEditingController secondFailFutRemovalController = TextEditingController();
  final TextEditingController shendaToppingController = TextEditingController();
  final TextEditingController shootTyingController = TextEditingController();
  final TextEditingController shootTyingClipsController = TextEditingController();
  final TextEditingController shootTyingStringsController = TextEditingController();
  final TextEditingController thirdDippingController = TextEditingController();

  // Kharad Tender Rates Controllers
  final TextEditingController _tenderTotalPriceController = TextEditingController();
  String _tenderReferenceImageUrl = '';

  static const List<String> _tenderActivityNames = [
    'छाटणी',
    'शूट निवड (विरळणी)',
    'बगल व बाकी काढणे',
    'शेंडा स्टॉपिंग',
    'दुसरी बगल काढणे',
    'नवीन वरायटी चे टेंडर (ARRA, Allison)',
    'सबकॅन',
    'रेग्युलर वरायटी चे टेंडर (Thompson, Sonaka, Crimson, Sharad, etc.)',
    'पेटीसिंग',
    'काडी बांधणे (क्लिप्ससह)',
  ];

  final List<TextEditingController> _tenderPriceControllers = List.generate(
    10,
        (_) => TextEditingController(),
  );

  bool _hasAnyTenderActivity() {
    return _tenderPriceControllers.any((c) => c.text.trim().isNotEmpty);
  }

  List<int>? _rateCardImageBytes;

  Future<void> _loadRateCardImage() async {
    final imageBytes = await quickRegistrationService().fetchRateCardImage();
    if (mounted && imageBytes != null) {
      setState(() {
        _rateCardImageBytes = imageBytes;
      });
    }
  }

  File? _selectedImage;
  File? _profilePhoto;
  File? _aadharCardPhoto;
  File? _panCardPhoto;
  File? _bankProofPhoto;

  bool _isPermanent = false;
  bool _isLoadingLocations = false;
  String _smartphoneAvailability = 'yes';
  String _transportMode = 'own_bike';

  bool _whatsappNotification = false;
  bool _smsNotification = false;
  bool _callNotification = false;

  List<Map<String, dynamic>> _states = [];
  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _talukas = [];
  List<Map<String, dynamic>> _villages = [];

  Map<String, dynamic>? _selectedState;
  Map<String, dynamic>? _selectedDistrict;
  Map<String, dynamic>? _selectedTaluka;
  Map<String, dynamic>? _selectedVillage;

  @override
  void initState() {
    super.initState();
    _loadStates();
    _loadRateCardImage();
  }

  @override
  void dispose() {
    _tenderTotalPriceController.dispose();
    for (var c in _tenderPriceControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // --- Location Permission & Service Check ---
  Future<bool> _checkLocationPermissionsAndService() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          await _showLocationServiceDialog();
        }
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            final lang = context.read<LanguageProvider>().language;
            _showSnackBar(AppStrings.get('location_permission_msg', lang));
          }
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          await _showPermissionSettingsDialog();
        }
        return false;
      }

      return true;
    } catch (e) {
      _showSnackBar('Error checking location permissions: $e');
      return false;
    }
  }

  // --- Location Logic ---
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocations = true);
    try {
      Position position = await _determinePosition();
      setState(() {
        _latController.text = position.latitude.toStringAsFixed(6);
        _longController.text = position.longitude.toStringAsFixed(6);
        _isLoadingLocations = false;
      });
    } catch (e) {
      setState(() => _isLoadingLocations = false);
      _showSnackBar(e.toString());
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        await _showLocationServiceDialog();
      }
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          final lang = context.read<LanguageProvider>().language;
          _showSnackBar(AppStrings.get('location_permission_msg', lang));
        }
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        await _showPermissionSettingsDialog();
      }
      return Future.error('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _showLocationServiceDialog() async {
    final lang = context.read<LanguageProvider>().language;
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.location_off, color: _warningColor, size: 28),
              const SizedBox(width: 12),
              Text(AppStrings.get('location_service_required', lang)),
            ],
          ),
          content: Text(AppStrings.get('location_service_msg', lang)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppStrings.get('cancel', lang), style: TextStyle(color: _textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openLocationSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(AppStrings.get('open_settings', lang)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showPermissionSettingsDialog() async {
    final lang = context.read<LanguageProvider>().language;
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.lock_outline, color: _warningColor, size: 28),
              const SizedBox(width: 12),
              Text(AppStrings.get('location_permission_required', lang)),
            ],
          ),
          content: Text(AppStrings.get('location_permission_msg', lang)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppStrings.get('cancel', lang), style: TextStyle(color: _textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(AppStrings.get('open_settings', lang)),
            ),
          ],
        );
      },
    );
  }

  Future<void> showImagePickerOptionsWithLocationCheck() async {
    final result = await _geoTaggingService.captureGeoTaggedImage(context);

    if (result.success && result.imageFile != null) {
      setState(() {
        _selectedImage = result.imageFile;
        if (result.position != null) {
          _latController.text = result.position!.latitude.toStringAsFixed(6);
          _longController.text = result.position!.longitude.toStringAsFixed(6);
        }
      });
    } else if (result.errorMessage != null &&
        result.errorMessage != "Image capture cancelled") {
      _showSnackBar(result.errorMessage!);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
      await _getCurrentLocation();
    }
  }

  Future<void> _pickDocumentImage(ImageSource source, String documentType) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        switch (documentType) {
          case 'profile':
            _profilePhoto = File(image.path);
            break;
          case 'aadhar':
            _aadharCardPhoto = File(image.path);
            break;
          case 'pan':
            _panCardPhoto = File(image.path);
            break;
          case 'bank':
            _bankProofPhoto = File(image.path);
            break;
        }
      });
    }
  }

  void _showDocumentPickerOptions(String documentType) {
    final lang = context.read<LanguageProvider>().language;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
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
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt, color: _primaryColor),
              ),
              title: Text(AppStrings.get('camera', lang), style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(AppStrings.get('take_photo', lang)),
              onTap: () {
                Navigator.pop(context);
                _pickDocumentImage(ImageSource.camera, documentType);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library, color: _primaryColor),
              ),
              title: Text(AppStrings.get('gallery', lang), style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(AppStrings.get('choose_from_gallery', lang)),
              onTap: () {
                Navigator.pop(context);
                _pickDocumentImage(ImageSource.gallery, documentType);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectStartDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
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
    if (picked != null) {
      setState(() {
        _startDateController.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  Future<void> _selectEndDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
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
    if (picked != null) {
      setState(() {
        _endDateController.text = picked.toIso8601String().split('T')[0];
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
      _showSnackBar("Error loading states: $e");
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
      _showSnackBar("Error loading districts: $e");
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
      final talukas = await _dataEntryService.getTalukas(stateCode, districtCode);
      setState(() {
        _talukas = talukas;
        _isLoadingLocations = false;
      });
    } catch (e) {
      setState(() => _isLoadingLocations = false);
      _showSnackBar("Error loading talukas: $e");
    }
  }

  Future<void> _loadVillages(String stateCode, String talukaCode) async {
    setState(() {
      _villages = [];
      _selectedVillage = null;
      _isLoadingLocations = true;
    });
    try {
      final villages = await _dataEntryService.getVillages(stateCode, talukaCode);
      setState(() {
        _villages = villages;
        _isLoadingLocations = false;
      });
    } catch (e) {
      setState(() => _isLoadingLocations = false);
      _showSnackBar("Error loading villages: $e");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  bool _hasNegativeRates() {
    final List<TextEditingController> rateControllers = [
      aprilPruningController, bagalBaliFutRemovalController, berryThinningController,
      bunchSelectionController, bunchThinningController, bunchTyingController,
      bunchVariationController, defaultRateController, failFutRemovalController,
      fingerThinningController, firstDippingController, firstFailFutRemovalController,
      harvestingController, newPlantationController, otherRateController,
      paperRemovalController, paperWrappingController, pastingController,
      pruningController, secondDippingController, secondFailFutRemovalController,
      shendaToppingController, shootTyingController, shootTyingClipsController,
      shootTyingStringsController, thirdDippingController,
    ];

    for (var controller in rateControllers) {
      if (controller.text.trim().isNotEmpty) {
        final value = double.tryParse(controller.text.trim());
        if (value != null && value < 0) {
          return true;
        }
      }
    }
    return false;
  }

  void _submitQuickForm() async {
    final lang = context.read<LanguageProvider>().language;

    if (_mukkadamNameController.text.trim().isEmpty) {
      _showSnackBar(AppStrings.get('mukkadam_name_required', lang));
      return;
    }

    if (_mobileNumbersController.text.trim().length != 10) {
      _showSnackBar(AppStrings.get('valid_mobile_required', lang));
      return;
    }

    if (_formKey.currentState!.validate()) {
      if (_selectedState == null || _selectedDistrict == null || _selectedTaluka == null || _selectedVillage == null) {
        _showSnackBar(AppStrings.get('select_all_location', lang));
        return;
      }

      if (_profilePhoto == null) {
        _showSnackBar(AppStrings.get('profile_photo_mandatory', lang));
        return;
      }

      if (_crewSizeController.text.isEmpty) {
        _showSnackBar(AppStrings.get('crew_size_mandatory', lang));
        return;
      }

      if (_startDateController.text.isEmpty) {
        _showSnackBar(AppStrings.get('start_date_mandatory', lang));
        return;
      }

      if (_selectedImage == null) {
        _showSnackBar(AppStrings.get('location_photo_mandatory', lang));
        return;
      }

      if (_hasAnyTenderActivity() && _tenderTotalPriceController.text.trim().isEmpty) {
        _showSnackBar(AppStrings.get('tender_total_required', lang));
        return;
      }

      if (_latController.text.isEmpty || _longController.text.isEmpty) {
        _showSnackBar(AppStrings.get('gps_mandatory', lang));
        return;
      }

      if (_hasNegativeRates()) {
        _showSnackBar(AppStrings.get('negative_rates_error', lang));
        return;
      }

      setState(() => _isLoadingLocations = true);

      final Map<String, dynamic> mukkadamData = {
        "mukkadam_name": _mukkadamNameController.text,
        "mobile_numbers": _mobileNumbersController.text,
        "crew_size": _crewSizeController.text,
        "max_crew_capacity": _maxCrewCapacityController.text,
        "alternative_contact_1_name": _altContact1NameController.text,
        "alternative_mobile_1": _altPhone1Controller.text,
        "alternative_contact_2_name": _altContact2NameController.text,
        "alternative_mobile_2": _altPhone2Controller.text,
        "start_date": _startDateController.text,
        "end_date": _endDateController.text,
        "current_latitude": _latController.text,
        "current_longitude": _longController.text,
        "has_smartphone": _smartphoneAvailability,
        "is_permanent": _isPermanent,
        "transport_mode": _transportMode,
        "notification_preferences": {
          "whatsapp": _whatsappNotification,
          "sms": _smsNotification,
          "call": _callNotification,
        },
        "tender_activities": {
          "activities": List.generate(_tenderActivityNames.length, (i) => {
            "name": _tenderActivityNames[i],
            "price": _tenderPriceControllers[i].text.trim(),
          }),
          "total_price": _tenderTotalPriceController.text.trim(),
          "reference_image_url": _tenderReferenceImageUrl,
        },
        "aadhar_number": _aadharNumberController.text,
        "pan_number": _panNumberController.text,
        "voter_id_number": _voterIdNumberController.text,
        "state": _selectedState!['state_name_english'],
        "state_code": _selectedState!['state_code'],
        "district": _selectedDistrict!['districtnameenglish'],
        "district_code": _selectedDistrict!['districtcode'].toString(),
        "taluka": _selectedTaluka!['subdistrictnameenglish'],
        "taluka_code": _selectedTaluka!['subdistrictcode'].toString(),
        "village": _selectedVillage!['villagenameenglish'],
        "village_code": _selectedVillage!['villagecode'].toString(),
        "rate_card": {
          "pruning_activities": {
            "pruning": pruningController.text,
            "april_pruning": aprilPruningController.text,
            "pasting": pastingController.text,
            "fail_fut_removal": failFutRemovalController.text,
            "first_fail_fut_removal": firstFailFutRemovalController.text,
            "second_fail_fut_removal": secondFailFutRemovalController.text,
            "bagal_bali_fut_removal": bagalBaliFutRemovalController.text,
          },
          "dipping_activities": {
            "first_dipping": firstDippingController.text,
            "second_dipping": secondDippingController.text,
            "third_dipping": thirdDippingController.text,
          },
          "shoot_tying": {
            "shoot_tying_strings": shootTyingStringsController.text,
            "shoot_tying_clips": shootTyingClipsController.text,
          },
          "thinning_activities": {
            "bunch_thinning": bunchThinningController.text,
            "finger_thinning": fingerThinningController.text,
            "berry_thinning": berryThinningController.text,
          },
          "bunch_management": {
            "bunch_selection": bunchSelectionController.text,
            "bunch_tying": bunchTyingController.text,
            "bunch_variation": bunchVariationController.text,
          },
          "other_activities": {
            "shenda_topping": shendaToppingController.text,
            "paper_wrapping": paperWrappingController.text,
            "paper_removal": paperRemovalController.text,
            "harvesting": harvestingController.text,
            "new_plantation": newPlantationController.text,
          },
        },
      };

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final String? authToken = userProvider.token;

      if (authToken == null) {
        setState(() => _isLoadingLocations = false);
        _showSnackBar(AppStrings.get('session_expired', lang));
        return;
      }

      final response = await quickRegistrationService().quickRegisterMukkadam(
        mukkadamData: mukkadamData,
        profilePhotoPath: _profilePhoto?.path,
        aadharCardPath: _aadharCardPhoto?.path,
        panCardPath: _panCardPhoto?.path,
        bankProofPath: _bankProofPhoto?.path,
        locationCapturePath: _selectedImage?.path,
        authToken: authToken,
      );

      setState(() => _isLoadingLocations = false);

      if (mounted) {
        if (response['success']) {
          _showSnackBar(AppStrings.get('registration_successful', lang));
          Navigator.pop(context);
        } else {
          final message = response['message'] ?? 'Registration failed';
          _showSnackBar("Failed: $message");

          if (response['logout_required'] == true) {
            // Add your logout logic here
          }
        }
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
                  _buildSectionCard(
                    title: AppStrings.get('basic_details', lang),
                    subtitle: AppStrings.get('basic_details_sub', lang),
                    icon: Icons.person,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _mukkadamNameController,
                          label: AppStrings.get('mukkadam_name', lang),
                          hint: AppStrings.get('enter_full_name', lang),
                          icon: Icons.person_outline,
                          required: true,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _mobileNumbersController,
                          label: AppStrings.get('mobile_number', lang),
                          hint: AppStrings.get('ten_digit_mobile', lang),
                          icon: Icons.phone_android,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          required: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildSectionCard(
                    title: AppStrings.get('location_details', lang),
                    subtitle: AppStrings.get('location_details_sub', lang),
                    icon: Icons.location_on,
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
                            if (val != null) _loadDistricts(val['state_code']);
                          },
                          required: true,
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
                            if (val != null) _loadTalukas(_selectedState!['state_code'], val['districtcode'].toString());
                          },
                          required: true,
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
                            if (val != null) _loadVillages(_selectedState!['state_code'], val['subdistrictcode'].toString());
                          },
                          required: true,
                          lang: lang,
                        ),
                        const SizedBox(height: 16),
                        _buildSearchableDropdown(
                          value: _selectedVillage,
                          items: _villages,
                          displayKey: 'villagenameenglish',
                          label: AppStrings.get('village_residence', lang),
                          hint: AppStrings.get('select_village', lang),
                          icon: Icons.home,
                          onChanged: (val) => setState(() => _selectedVillage = val),
                          required: true,
                          lang: lang,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildSectionCard(
                    title: AppStrings.get('smartphone_availability', lang),
                    subtitle: AppStrings.get('smartphone_availability_sub', lang),
                    icon: Icons.smartphone,
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildRadioOption(
                            title: AppStrings.get('yes', lang),
                            value: 'yes',
                            groupValue: _smartphoneAvailability,
                            onChanged: (val) => setState(() => _smartphoneAvailability = val!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildRadioOption(
                            title: AppStrings.get('no', lang),
                            value: 'no',
                            groupValue: _smartphoneAvailability,
                            onChanged: (val) => setState(() => _smartphoneAvailability = val!),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildSectionCard(
                    title: AppStrings.get('crew_details', lang),
                    subtitle: AppStrings.get('crew_details_sub', lang),
                    icon: Icons.groups,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _crewSizeController,
                          label: AppStrings.get('current_crew_size', lang),
                          hint: "e.g., 15",
                          icon: Icons.groups_outlined,
                          keyboardType: TextInputType.number,
                          validator: (v) => (v == null || v.isEmpty) ? AppStrings.get('crew_size_required', lang) : null,
                          required: true,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _maxCrewCapacityController,
                          label: AppStrings.get('max_crew_capacity', lang),
                          hint: AppStrings.get('max_workers', lang),
                          icon: Icons.group_add,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 20),
                        _buildLabel(AppStrings.get('alternative_contact_1', lang), isDark: isDark),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildTextField(
                                controller: _altContact1NameController,
                                label: "",
                                hint: AppStrings.get('contact_name', lang),
                                icon: Icons.person_outline,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: _buildTextField(
                                controller: _altPhone1Controller,
                                label: "",
                                hint: AppStrings.get('phone_number', lang),
                                icon: Icons.phone,
                                keyboardType: TextInputType.phone,
                                maxLength: 10,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildLabel(AppStrings.get('alternative_contact_2', lang), isDark: isDark),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildTextField(
                                controller: _altContact2NameController,
                                label: "",
                                hint: AppStrings.get('contact_name', lang),
                                icon: Icons.person_outline,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: _buildTextField(
                                controller: _altPhone2Controller,
                                label: "",
                                hint: AppStrings.get('phone_number', lang),
                                icon: Icons.phone,
                                keyboardType: TextInputType.phone,
                                maxLength: 10,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildSectionCard(
                    title: AppStrings.get('availability', lang),
                    subtitle: AppStrings.get('availability_sub', lang),
                    icon: Icons.event_available,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: _selectStartDate,
                                child: AbsorbPointer(
                                  child: _buildTextField(
                                    controller: _startDateController,
                                    label: AppStrings.get('start_date', lang),
                                    hint: AppStrings.get('select_date', lang),
                                    icon: Icons.calendar_today,
                                    validator: (v) => (v == null || v.isEmpty) ? AppStrings.get('start_date_required', lang) : null,
                                    required: true,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: _selectEndDate,
                                child: AbsorbPointer(
                                  child: _buildTextField(
                                    controller: _endDateController,
                                    label: AppStrings.get('end_date', lang),
                                    hint: AppStrings.get('select_date', lang),
                                    icon: Icons.calendar_today,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : _borderColor,
                            ),
                          ),
                          child: CheckboxListTile(
                            title: Text(AppStrings.get('is_permanent', lang), style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(AppStrings.get('available_year_round', lang), style: const TextStyle(fontSize: 12)),
                            value: _isPermanent,
                            activeColor: _primaryColor,
                            onChanged: (val) => setState(() => _isPermanent = val!),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildSectionCard(
                    title: AppStrings.get('location_photo_capture', lang),
                    subtitle: AppStrings.get('location_photo_capture_sub', lang),
                    icon: Icons.add_a_photo,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(AppStrings.get('gps_coordinates', lang), isDark: isDark, required: true),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildReadOnlyTextField(
                                controller: _latController,
                                label: AppStrings.get('latitude', lang),
                                icon: Icons.my_location,
                                isDark: isDark,
                                lang: lang,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildReadOnlyTextField(
                                controller: _longController,
                                label: AppStrings.get('longitude', lang),
                                icon: Icons.location_searching,
                                isDark: isDark,
                                lang: lang,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildLabel(AppStrings.get('capture_location_photo', lang), isDark: isDark, required: true),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: showImagePickerOptionsWithLocationCheck,
                          child: Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _selectedImage != null ? _successColor : (isDark ? const Color(0xFF334155) : Colors.grey[300]!),
                                width: 2,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: _selectedImage == null
                                ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: _primaryColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.add_a_photo, size: 48, color: _primaryColor),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  AppStrings.get('tap_to_capture', lang),
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            )
                                : Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _successColor,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.check_circle, color: Colors.white, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          AppStrings.get('captured', lang),
                                          style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildSectionCard(
                    title: AppStrings.get('transport_mode', lang),
                    subtitle: AppStrings.get('transport_mode_sub', lang),
                    icon: Icons.directions_car,
                    child: Column(
                      children: [
                        _buildRadioListOption(title: AppStrings.get('own_bike', lang), value: 'own_bike', groupValue: _transportMode, icon: Icons.two_wheeler, onChanged: (val) => setState(() => _transportMode = val!), isDark: isDark),
                        const SizedBox(height: 8),
                        _buildRadioListOption(title: AppStrings.get('own_pickup', lang), value: 'own_pickup', groupValue: _transportMode, icon: Icons.local_shipping, onChanged: (val) => setState(() => _transportMode = val!), isDark: isDark),
                        const SizedBox(height: 8),
                        _buildRadioListOption(title: AppStrings.get('no_vehicle', lang), value: 'no_vehicle', groupValue: _transportMode, icon: Icons.directions_walk, onChanged: (val) => setState(() => _transportMode = val!), isDark: isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildSectionCard(
                    title: AppStrings.get('notification_preferences', lang),
                    subtitle: AppStrings.get('notification_preferences_sub', lang),
                    icon: Icons.notifications_active,
                    child: Column(
                      children: [
                        _buildCheckboxOption(title: AppStrings.get('whatsapp', lang), subtitle: AppStrings.get('receive_updates_whatsapp', lang), icon: Icons.message, value: _whatsappNotification, onChanged: (val) => setState(() => _whatsappNotification = val!), isDark: isDark),
                        const SizedBox(height: 8),
                        _buildCheckboxOption(title: AppStrings.get('sms', lang), subtitle: AppStrings.get('receive_updates_sms', lang), icon: Icons.sms, value: _smsNotification, onChanged: (val) => setState(() => _smsNotification = val!), isDark: isDark),
                        const SizedBox(height: 8),
                        _buildCheckboxOption(title: AppStrings.get('phone_call', lang), subtitle: AppStrings.get('receive_updates_call', lang), icon: Icons.phone, value: _callNotification, onChanged: (val) => setState(() => _callNotification = val!), isDark: isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildSectionCard(
                    title: AppStrings.get('documents_id', lang),
                    subtitle: AppStrings.get('documents_id_sub', lang),
                    icon: Icons.badge,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(AppStrings.get('profile_photo', lang), isDark: isDark, required: true),
                        const SizedBox(height: 8),
                        _buildDocumentUploadCard(AppStrings.get('profile_photo_label', lang), 'profile', _profilePhoto, isDark, lang),
                        const SizedBox(height: 24),

                        _buildSubsectionHeader(AppStrings.get('voter_details', lang), isDark),
                        const SizedBox(height: 12),
                        _buildTextField(controller: _voterIdNumberController, label: "", hint: AppStrings.get('enter_voter_id', lang), icon: Icons.how_to_vote, maxLength: 10, inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')), UpperCaseTextFormatter()]),
                        const SizedBox(height: 24),

                        _buildSubsectionHeader(AppStrings.get('aadhar_details', lang), isDark),
                        const SizedBox(height: 12),
                        _buildTextField(controller: _aadharNumberController, label: "", hint: AppStrings.get('enter_aadhar', lang), icon: Icons.credit_card, keyboardType: TextInputType.number, maxLength: 12, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                        const SizedBox(height: 12),
                        _buildOrDivider(isDark, lang),
                        const SizedBox(height: 12),
                        _buildDocumentUploadCard(AppStrings.get('aadhar_card', lang), 'aadhar', _aadharCardPhoto, isDark, lang),
                        const SizedBox(height: 24),

                        _buildSubsectionHeader(AppStrings.get('pan_details', lang), isDark),
                        const SizedBox(height: 12),
                        _buildTextField(controller: _panNumberController, label: "", hint: AppStrings.get('enter_pan', lang), icon: Icons.credit_card, maxLength: 10, inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')), UpperCaseTextFormatter()]),
                        const SizedBox(height: 12),
                        _buildOrDivider(isDark, lang),
                        const SizedBox(height: 12),
                        _buildDocumentUploadCard(AppStrings.get('pan_card', lang), 'pan', _panCardPhoto, isDark, lang),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildRateCardSection(isDark, lang),
                  const SizedBox(height: 30),

                  _buildKharadTenderRatesSection(isDark, lang),
                  const SizedBox(height: 20),

                  _buildSubmitButton(isDark, lang),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
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
                      const CircularProgressIndicator(color: _primaryColor, strokeWidth: 4),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.get('please_wait', lang),
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : _textPrimary),
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

  Widget _buildKharadTenderRatesSection(bool isDark, String lang) {
    final hasActivity = _hasAnyTenderActivity();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : _borderColor),
        boxShadow: [BoxShadow(color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.03), spreadRadius: 0, blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: _primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.assignment, color: _primaryColor, size: 24),
            ),
            title: Text(AppStrings.get('kharad_tender_rates', lang), style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? Colors.white : _textPrimary, letterSpacing: -0.3)),
            subtitle: Text(AppStrings.get('kharad_tender_rates_sub', lang), style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.grey[400] : _textSecondary, fontWeight: FontWeight.w600)),
            initiallyExpanded: false,
            children: [
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF172554) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? const Color(0xFF1E40AF) : const Color(0xFFBFDBFE)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _rateCardImageBytes != null
                      ? Image.memory(Uint8List.fromList(_rateCardImageBytes!), width: double.infinity, fit: BoxFit.contain)
                      : Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.photo_camera, size: 24, color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6)),
                        const SizedBox(width: 10),
                        Expanded(child: Text('📷 ${AppStrings.get('loading_rate_card', lang)}', style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF)))),
                        const SizedBox(width: 8),
                        SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? const Color(0xFF60A5FA) : _accentColor)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(_tenderActivityNames.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(width: 28, height: 28, decoration: BoxDecoration(color: _primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Center(child: Text('${index + 1}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: _primaryColor)))),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(color: isDark ? const Color(0xFF0F172A).withOpacity(0.5) : Colors.grey[100], borderRadius: BorderRadius.circular(10), border: Border.all(color: isDark ? const Color(0xFF334155) : _borderColor)),
                          child: Text(_tenderActivityNames[index], style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : _textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _tenderPriceControllers[index],
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                          style: GoogleFonts.inter(fontSize: 14, color: isDark ? Colors.white : _textPrimary),
                          decoration: InputDecoration(
                            hintText: AppStrings.get('price', lang),
                            hintStyle: TextStyle(color: isDark ? Colors.grey[500] : _textSecondary.withOpacity(0.6), fontSize: 13),
                            prefixIcon: const Icon(Icons.currency_rupee, size: 16, color: _primaryColor),
                            filled: true, fillColor: isDark ? const Color(0xFF0F172A) : _dividerColor,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : _borderColor)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : _borderColor)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _accentColor, width: 1.5)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      text: '${AppStrings.get('total_price', lang)} ',
                      style: GoogleFonts.inter(color: isDark ? Colors.grey[300] : _textSecondary, fontSize: 14, fontWeight: FontWeight.w600),
                      children: [if (hasActivity) const TextSpan(text: '*', style: TextStyle(color: _errorColor, fontWeight: FontWeight.bold))],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _tenderTotalPriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                    style: GoogleFonts.inter(fontSize: 15, color: isDark ? Colors.white : _textPrimary),
                    decoration: InputDecoration(
                      hintText: AppStrings.get('total_tender_price', lang),
                      hintStyle: TextStyle(color: isDark ? Colors.grey[500] : _textSecondary.withOpacity(0.6)),
                      prefixIcon: const Icon(Icons.currency_rupee, color: _primaryColor, size: 22),
                      filled: true, fillColor: isDark ? const Color(0xFF0F172A) : _dividerColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : _borderColor)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : _borderColor)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _accentColor, width: 2)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required String subtitle, required IconData icon, required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : _cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? const Color(0xFF334155) : _borderColor), boxShadow: [BoxShadow(color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.03), spreadRadius: 0, blurRadius: 10, offset: const Offset(0, 2))]),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: _primaryColor, size: 24)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? Colors.white : _textPrimary, letterSpacing: -0.3)),
              Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.grey[400] : _textSecondary, fontWeight: FontWeight.w600)),
            ])),
          ]),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildLabel(String text, {bool required = false, required bool isDark}) {
    return RichText(
      text: TextSpan(text: text, style: GoogleFonts.inter(color: isDark ? Colors.grey[300] : _textSecondary, fontSize: 14, fontWeight: FontWeight.w600), children: [if (required) const TextSpan(text: ' *', style: TextStyle(color: _errorColor, fontWeight: FontWeight.bold))]),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required String hint, required IconData icon, TextInputType keyboardType = TextInputType.text, String? Function(String?)? validator, bool required = false, int? maxLength, List<TextInputFormatter>? inputFormatters, String? subtitle}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (label.isNotEmpty) Padding(padding: EdgeInsets.only(bottom: subtitle != null ? 2 : 8), child: _buildLabel(label, required: required, isDark: isDark)),
      if (subtitle != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.grey[400] : _textSecondary, fontWeight: FontWeight.w600))),
      TextFormField(
        controller: controller, keyboardType: keyboardType, validator: validator, maxLength: maxLength, inputFormatters: inputFormatters,
        style: GoogleFonts.inter(fontSize: 15, color: isDark ? Colors.white : _textPrimary),
        decoration: InputDecoration(
          hintText: hint, hintStyle: TextStyle(color: isDark ? Colors.grey[500] : _textSecondary.withOpacity(0.6)),
          prefixIcon: Icon(icon, color: _primaryColor, size: 22), counterText: "",
          filled: true, fillColor: isDark ? const Color(0xFF0F172A) : _dividerColor,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : _borderColor)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : _borderColor)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _accentColor, width: 2)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _errorColor, width: 1.5)),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _errorColor, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    ]);
  }

  Widget _buildReadOnlyTextField({required TextEditingController controller, required String label, required IconData icon, required bool isDark, required String lang}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.grey[400] : _textSecondary)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(color: isDark ? const Color(0xFF0F172A).withOpacity(0.5) : _dividerColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? const Color(0xFF334155) : _borderColor)),
        child: Row(children: [
          Icon(icon, color: _textSecondary, size: 20), const SizedBox(width: 10),
          Expanded(child: Text(controller.text.isEmpty ? AppStrings.get('auto_captured', lang) : controller.text)),
          if (controller.text.isNotEmpty) Icon(Icons.lock_outline, color: _textSecondary, size: 16),
        ]),
      ),
    ]);
  }

  Widget _buildSearchableDropdown({required Map<String, dynamic>? value, required List<Map<String, dynamic>> items, required String displayKey, required String label, required String hint, required IconData icon, required void Function(Map<String, dynamic>?) onChanged, bool required = false, required String lang}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (label.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 8), child: _buildLabel(label, required: required, isDark: isDark)),
      DropdownSearch<Map<String, dynamic>>(
        items: (filter, loadProps) => items, selectedItem: value, itemAsString: (item) => item[displayKey]?.toString() ?? '', onChanged: onChanged,
        compareFn: (item1, item2) => item1[displayKey] == item2[displayKey],
        filterFn: (item, filter) => item[displayKey].toString().toLowerCase().contains(filter.toLowerCase()),
        decoratorProps: DropDownDecoratorProps(decoration: InputDecoration(
          prefixIcon: Icon(icon, color: _primaryColor, size: 22), hintText: hint,
          hintStyle: TextStyle(color: isDark ? Colors.grey[500] : _textSecondary.withOpacity(0.6)),
          filled: true, fillColor: isDark ? const Color(0xFF0F172A) : _dividerColor,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : _borderColor)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : _borderColor)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _accentColor, width: 2)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _errorColor, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        )),
        popupProps: PopupProps.menu(
          showSearchBox: true,
          searchFieldProps: TextFieldProps(decoration: InputDecoration(hintText: AppStrings.get('search', lang), prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
          menuProps: MenuProps(backgroundColor: isDark ? const Color(0xFF1E293B) : _cardColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
        validator: (v) => (required && v == null) ? AppStrings.get('field_required', lang) : null,
      ),
    ]);
  }

  Widget _buildRadioOption({required String title, required String value, required String groupValue, required void Function(String?) onChanged}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: isSelected ? _primaryColor.withOpacity(0.1) : (isDark ? const Color(0xFF0F172A) : _dividerColor), borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? _primaryColor : (isDark ? const Color(0xFF334155) : _borderColor), width: isSelected ? 2 : 1)),
        child: Row(children: [
          Container(width: 20, height: 20, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isSelected ? _primaryColor : Colors.grey[400]!, width: 2), color: isSelected ? _primaryColor : Colors.transparent), child: isSelected ? const Center(child: CircleAvatar(radius: 4, backgroundColor: Colors.white)) : null),
          const SizedBox(width: 12),
          Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, color: isSelected ? _primaryColor : (isDark ? Colors.grey[300] : _textPrimary))),
        ]),
      ),
    );
  }

  Widget _buildRadioListOption({required String title, required String value, required String groupValue, required IconData icon, required void Function(String?) onChanged, required bool isDark}) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: isSelected ? _primaryColor.withOpacity(0.1) : (isDark ? const Color(0xFF0F172A) : _dividerColor), borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? _primaryColor : (isDark ? const Color(0xFF334155) : _borderColor), width: isSelected ? 2 : 1)),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: isSelected ? _primaryColor.withOpacity(0.2) : (isDark ? const Color(0xFF1E293B) : Colors.grey[100]), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: isSelected ? _primaryColor : _textSecondary, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, color: isSelected ? _primaryColor : (isDark ? Colors.grey[300] : _textPrimary)))),
          Container(width: 22, height: 22, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isSelected ? _primaryColor : Colors.grey[400]!, width: 2), color: isSelected ? _primaryColor : Colors.transparent), child: isSelected ? const Center(child: CircleAvatar(radius: 5, backgroundColor: Colors.white)) : null),
        ]),
      ),
    );
  }

  Widget _buildCheckboxOption({required String title, required String subtitle, required IconData icon, required bool value, required void Function(bool?) onChanged, required bool isDark}) {
    return Container(
      decoration: BoxDecoration(color: value ? _primaryColor.withOpacity(0.1) : (isDark ? const Color(0xFF0F172A) : _dividerColor), borderRadius: BorderRadius.circular(12), border: Border.all(color: value ? _primaryColor : (isDark ? const Color(0xFF334155) : _borderColor), width: value ? 2 : 1)),
      child: CheckboxListTile(
        title: Row(children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: value ? _primaryColor.withOpacity(0.2) : (isDark ? const Color(0xFF1E293B) : Colors.grey[100]), borderRadius: BorderRadius.circular(6)), child: Icon(icon, color: value ? _primaryColor : _textSecondary, size: 18)),
          const SizedBox(width: 12),
          Text(title, style: TextStyle(fontWeight: value ? FontWeight.w600 : FontWeight.w500, color: value ? _primaryColor : null)),
        ]),
        subtitle: Padding(padding: const EdgeInsets.only(left: 42), child: Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : _textSecondary))),
        value: value, activeColor: _primaryColor, onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        controlAffinity: ListTileControlAffinity.trailing,
      ),
    );
  }

  Widget _buildDocumentUploadCard(String label, String documentType, File? file, bool isDark, String lang) {
    return Container(
      decoration: BoxDecoration(color: isDark ? const Color(0xFF0F172A) : _dividerColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: file != null ? _successColor : (isDark ? const Color(0xFF334155) : _borderColor), width: file != null ? 2 : 1)),
      child: Row(children: [
        Expanded(child: Material(color: Colors.transparent, child: InkWell(
          onTap: () => _showDocumentPickerOptions(documentType), borderRadius: BorderRadius.circular(12),
          child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: file != null ? _successColor.withOpacity(0.1) : _primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(file != null ? Icons.check_circle : Icons.upload_file, color: file != null ? _successColor : _primaryColor, size: 24)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(file == null ? '${AppStrings.get('upload', lang)} $label' : '$label ${AppStrings.get('uploaded', lang)}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: file != null ? _successColor : (isDark ? Colors.white : _textPrimary))),
              if (file == null) Text(AppStrings.get('tap_to_select', lang), style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[500] : _textSecondary)),
            ])),
          ])),
        ))),
        Container(width: 1, height: 50, color: isDark ? const Color(0xFF334155) : _borderColor),
        Material(color: Colors.transparent, child: InkWell(onTap: () => _pickDocumentImage(ImageSource.camera, documentType), borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)), child: Container(padding: const EdgeInsets.all(16), child: const Icon(Icons.camera_alt, color: _primaryColor, size: 24)))),
      ]),
    );
  }

  Widget _buildSubsectionHeader(String title, bool isDark) {
    return Row(children: [
      Container(width: 4, height: 20, decoration: BoxDecoration(color: _primaryColor, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : _textPrimary)),
    ]);
  }

  Widget _buildOrDivider(bool isDark, String lang) {
    return Row(children: [
      Expanded(child: Divider(color: isDark ? const Color(0xFF334155) : _borderColor)),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(AppStrings.get('or', lang), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.grey[500] : _textSecondary))),
      Expanded(child: Divider(color: isDark ? const Color(0xFF334155) : _borderColor)),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════
  // UPDATED: _buildRateCardSection now passes lang to _buildRateCardGrid
  // ═══════════════════════════════════════════════════════════════
  Widget _buildRateCardSection(bool isDark, String lang) {
    return Container(
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : _cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? const Color(0xFF334155) : _borderColor), boxShadow: [BoxShadow(color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.03), spreadRadius: 0, blurRadius: 10, offset: const Offset(0, 2))]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.currency_rupee, color: _primaryColor, size: 24)),
            title: Text(AppStrings.get('rate_card_details', lang), style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? Colors.white : _textPrimary, letterSpacing: -0.3)),
            subtitle: Text(AppStrings.get('rate_card_details_sub', lang), style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.grey[400] : _textSecondary, fontWeight: FontWeight.w600)),
            initiallyExpanded: false,
            children: [const SizedBox(height: 10), _buildRateCardGrid(isDark, lang)],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // UPDATED: _buildRateCardGrid now accepts lang and uses AppStrings
  // ═══════════════════════════════════════════════════════════════
  Widget _buildRateCardGrid(bool isDark, String lang) {
    return Column(children: [
      _buildTwoFieldRow(defaultRateController, AppStrings.get('rc_default_rate', lang), pruningController, AppStrings.get('rc_pruning', lang), isDark),
      _buildTwoFieldRow(aprilPruningController, AppStrings.get('rc_april_pruning', lang), pastingController, AppStrings.get('rc_pasting', lang), isDark),
      _buildTwoFieldRow(failFutRemovalController, AppStrings.get('rc_fail_fut_removal', lang), firstFailFutRemovalController, AppStrings.get('rc_1st_fail_fut_rem', lang), isDark),
      _buildTwoFieldRow(secondFailFutRemovalController, AppStrings.get('rc_2nd_fail_fut_rem', lang), bagalBaliFutRemovalController, AppStrings.get('rc_bagal_bali_fut', lang), isDark),
      _buildTwoFieldRow(firstDippingController, AppStrings.get('rc_1st_dipping', lang), secondDippingController, AppStrings.get('rc_2nd_dipping', lang), isDark),
      _buildTwoFieldRow(thirdDippingController, AppStrings.get('rc_3rd_dipping', lang), shootTyingController, AppStrings.get('rc_shoot_tying', lang), isDark),
      _buildTwoFieldRow(shootTyingStringsController, AppStrings.get('rc_shoot_tying_strings', lang), shootTyingClipsController, AppStrings.get('rc_shoot_tying_clips', lang), isDark),
      _buildTwoFieldRow(bunchThinningController, AppStrings.get('rc_bunch_thinning', lang), fingerThinningController, AppStrings.get('rc_finger_thinning', lang), isDark),
      _buildTwoFieldRow(berryThinningController, AppStrings.get('rc_berry_thinning', lang), bunchSelectionController, AppStrings.get('rc_bunch_selection', lang), isDark),
      _buildTwoFieldRow(bunchTyingController, AppStrings.get('rc_bunch_tying', lang), bunchVariationController, AppStrings.get('rc_bunch_variation', lang), isDark),
      _buildTwoFieldRow(shendaToppingController, AppStrings.get('rc_shenda_topping', lang), paperWrappingController, AppStrings.get('rc_paper_wrapping', lang), isDark),
      _buildTwoFieldRow(paperRemovalController, AppStrings.get('rc_paper_removal', lang), harvestingController, AppStrings.get('rc_harvesting', lang), isDark),
      _buildTwoFieldRow(newPlantationController, AppStrings.get('rc_new_plantation', lang), otherRateController, AppStrings.get('rc_other', lang), isDark),
    ]);
  }

  Widget _buildTwoFieldRow(TextEditingController c1, String l1, TextEditingController c2, String l2, bool isDark) {
    return Padding(padding: const EdgeInsets.only(bottom: 12.0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: _buildRateField(c1, l1, isDark)), const SizedBox(width: 12), Expanded(child: _buildRateField(c2, l2, isDark))]));
  }

  Widget _buildRateField(TextEditingController controller, String label, bool isDark) {
    return TextFormField(
      controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
      style: GoogleFonts.inter(fontSize: 14, color: isDark ? Colors.white : _textPrimary),
      decoration: InputDecoration(
        labelText: label, labelStyle: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : _textSecondary),
        prefixIcon: const Icon(Icons.currency_rupee, size: 16, color: _primaryColor),
        filled: true, fillColor: isDark ? const Color(0xFF0F172A) : _dividerColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : _borderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : _borderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _accentColor, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }

  Widget _buildSubmitButton(bool isDark, String lang) {
    return Container(
      width: double.infinity, height: 56,
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [_primaryColor, _accentColor], begin: Alignment.centerLeft, end: Alignment.centerRight), borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: _primaryColor.withOpacity(0.3), spreadRadius: 0, blurRadius: 12, offset: const Offset(0, 4))]),
      child: ElevatedButton(
        onPressed: _isLoadingLocations ? null : _submitQuickForm,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), disabledBackgroundColor: Colors.grey[400]),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.check_circle_outline, size: 24), const SizedBox(width: 12),
          Text(AppStrings.get('register_mukkadam', lang), style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ]),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark, String lang) {
    return AppBar(
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(AppStrings.get('quick_registration_title', lang), style: GoogleFonts.inter(fontSize: 19, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.3)),
        Text(AppStrings.get('quick_registration_subtitle', lang), style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w600)),
      ]),
      centerTitle: false, backgroundColor: _primaryColor, elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, size: 22, color: Colors.white), onPressed: () => Navigator.pop(context)),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(text: newValue.text.toUpperCase(), selection: newValue.selection);
  }
}
