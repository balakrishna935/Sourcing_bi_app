// lib/seeplan/village_execution_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mukadam_bi/seeplan/plan_Service_file.dart';
import 'package:mukadam_bi/seeplan/execution_service.dart';
import 'package:mukadam_bi/seeplan/plan_service_model.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../geo_tagging.dart';
import '../language_jsons/execution_strings.dart';
import '../provider/language_provider.dart';
import 'official_display_names.dart';


class VillageExecutionScreen extends StatefulWidget {
  final VillageVisit village;

  const VillageExecutionScreen({super.key, required this.village});

  @override
  State<VillageExecutionScreen> createState() => _VillageExecutionScreenState();
}

class _VillageExecutionScreenState extends State<VillageExecutionScreen>
    with SingleTickerProviderStateMixin {
  bool _isStarted = false;
  bool _isCompleted = false;
  int todayMukkadamCount = 0;

  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  final GeoTaggingService _geoTaggingService = GeoTaggingService();
  static const Color _primaryColor = Color(0xFF1E3A5F);

  final PlanService _planService = PlanService();
  final ExecutionService _executionService = ExecutionService();

  String? _executionId;
  VillageExecution? _executionData;
  late List<String> _activeOfficials;

  // Controllers for each official
  final Map<String, TextEditingController> _feedbackControllers = {};
  final Map<String, TextEditingController> _nameControllers = {};
  final Map<String, TextEditingController> _phoneControllers = {};
  final Map<String, TextEditingController> _designationControllers = {};
  final Map<String, TextEditingController> _reasonNotMetControllers = {};
  final Map<String, TextEditingController> _customDesignationControllers = {};
  final Map<String, TextEditingController> _customLocationTypeControllers = {};

  // Dropdown selections (now store KEYS like 'chai_wala', not bilingual strings)
  final Map<String, String?> _selectedDesignations = {};
  final Map<String, String?> _selectedLocationTypes = {};

  // State tracking
  final Map<String, bool> _personMetStatus = {};
  final Map<String, bool> _isSubmitting = {};
  final Map<String, File?> _selectedImages = {};
  final Map<String, Position?> _capturedPositions = {};
  final Map<String, String> _locations = {};
  final Map<String, String?> _submittedMeetingIds = {};
  final Map<String, bool> _isOfficialSubmitted = {};
  final Map<String, bool> _isExpanded = {};
  final Map<String, bool> _isFetchingLocation = {};

  // Completion form
  final TextEditingController _villageFeedbackController = TextEditingController();
  final TextEditingController _totalRegistrationsController = TextEditingController();

  int _nextShopownerNumber = 3;
  int _nextMukkadamNumber = 1;
  int _nextInfluentialPersonNumber = 1;
  int _nextOtherPersonNumber = 1;

  late TabController _tabController;

  // Language-aware getter
  String get _lang => context.read<LanguageProvider>().language;

  // Key-based dropdown lists (values sent to backend are always English via VillageExecutionStrings.get(key, 'en'))
  final List<String> _shopownerDesignationKeys = [
    'chai_wala', 'pan_wala', 'kirana_store', 'medical_store',
    'hardware_store', 'stationary_shop', 'mobile_shop',
    'barber_shop', 'tailor_shop', 'other',
  ];

  final List<String> _pickupLocationTypeKeys = [
    'bus_stand', 'railway_station', 'market_area', 'main_chowk',
    'temple', 'school', 'hospital', 'post_office', 'panchayat', 'other',
  ];

  final Map<String, String> _officialDesignationMap = {
    'sarpanch': 'Sarpanch',
    'secretary': 'Secretary',
    'talathi': 'Talathi',
    'vdo': 'VDO',
    'principal': 'Principal',
    'agriculture_officer': 'Agriculture Officer',
    'anganwadi_worker': 'Anganwadi Worker',
    'asha_worker': 'ASHA Worker',
    'police_patil': 'Police Patil',
    'krishi_sahayak': 'Krishi Sahayak',
    'gram_panchayat_member': 'Gram Panchayat Member',
    'postman': 'Postman',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeOfficials();
    _checkExecutionStatus();
    _fetchMukkadamCount();
  }

  Future<void> _fetchMukkadamCount() async {
    final villageCode = widget.village.villageCode;
    if (villageCode.isEmpty) return;
    final count = await _executionService.fetchTodayMukkadamCount(villageCode);
    if (mounted) {
      setState(() {
        todayMukkadamCount = count;
      });
    }
  }

  Future<void> _checkExecutionStatus() async {
    final status = widget.village.status.toLowerCase();
    if (status == 'in_progress') {
      setState(() => _isStarted = true);
      await _loadExecutionData();
    } else if (status == 'completed') {
      setState(() {
        _isStarted = true;
        _isCompleted = true;
      });
      await _loadExecutionData();
    }
  }

  bool _canStartExecution() {
    try {
      final plannedDate = widget.village.plannedDate;
      final today = DateTime.now();
      final todayDateOnly = DateTime(today.year, today.month, today.day);
      final plannedDateOnly = DateTime(plannedDate.year, plannedDate.month, plannedDate.day);
      return plannedDateOnly.compareTo(todayDateOnly) <= 0;
    } catch (e) {
      debugPrint("Error parsing date: $e");
      return false;
    }
  }

  String _getStartButtonDisabledMessage() {
    try {
      final plannedDate = widget.village.plannedDate;
      final formattedDate = DateFormat('dd MMM yyyy').format(plannedDate);
      return "Visit is planned for $formattedDate. Cannot start execution before planned date.";
    } catch (e) {
      return "Cannot start execution before planned date.";
    }
  }

  Future<void> _loadExecutionData() async {
    setState(() => _isLoading = true);
    try {
      final villageDetails = await _executionService.fetchVillageVisitDetails(widget.village.id);
      if (villageDetails != null && villageDetails['execution'] != null) {
        final executionJson = villageDetails['execution'];
        setState(() {
          _executionData = VillageExecution.fromJson(executionJson);
          _executionId = _executionData!.id;
          _populateExistingData();
        });
      }
    } catch (e) {
      debugPrint("Error loading execution data: $e");
      _showSnackBar("Error loading data: $e", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _populateExistingData() {
    if (_executionData == null) return;

    _villageFeedbackController.text = _executionData!.villageFeedback;
    _totalRegistrationsController.text = _executionData!.totalRegistrations.toString();

    Map<String, int> typeCounters = {
      'shopowner': 0,
      'mukkadam': 0,
      'influential_person': 0,
      'other': 0,
    };

    for (var meeting in _executionData!.meetings) {
      String personType = meeting.personType;
      String internalKey = _findInternalKeyForPersonType(personType, typeCounters);

      if (!_activeOfficials.contains(internalKey)) {
        _activeOfficials.add(internalKey);
        _initializeOfficialControllers(internalKey);
        _updateNextNumbersFromOfficial(internalKey);
      }

      _isOfficialSubmitted[internalKey] = true;
      _submittedMeetingIds[internalKey] = meeting.id;
      _personMetStatus[internalKey] = meeting.personMet;

      if (meeting.personMet) {
        _nameControllers[internalKey]?.text = meeting.personName ?? '';
        _phoneControllers[internalKey]?.text = meeting.personPhone ?? '';
        _designationControllers[internalKey]?.text = meeting.personDesignation;
        _feedbackControllers[internalKey]?.text = meeting.meetingNotes ?? '';

        if (_isShopowner(internalKey)) {
          String? matchedKey = _findMatchingDesignationKey(
            meeting.personDesignation,
            _shopownerDesignationKeys,
          );
          if (matchedKey != null) {
            _selectedDesignations[internalKey] = matchedKey;
          } else {
            _selectedDesignations[internalKey] = 'other';
            _customDesignationControllers[internalKey]?.text = meeting.personDesignation;
          }
        } else if (_isHotspot(internalKey)) {
          String? matchedKey = _findMatchingDesignationKey(
            meeting.personDesignation,
            _pickupLocationTypeKeys,
          );
          if (matchedKey != null) {
            _selectedLocationTypes[internalKey] = matchedKey;
          } else {
            _selectedLocationTypes[internalKey] = 'other';
            _customLocationTypeControllers[internalKey]?.text = meeting.personDesignation;
          }
        }

        if (meeting.meetingLatitude != null && meeting.meetingLongitude != null) {
          _locations[internalKey] =
          "Lat: ${meeting.meetingLatitude!.toStringAsFixed(6)}, Long: ${meeting.meetingLongitude!.toStringAsFixed(6)}";
          _capturedPositions[internalKey] = Position(
            latitude: meeting.meetingLatitude!,
            longitude: meeting.meetingLongitude!,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );
        }
      } else {
        _reasonNotMetControllers[internalKey]?.text = meeting.reasonNotMet ?? '';
        _designationControllers[internalKey]?.text = meeting.personDesignation;
      }
    }
  }

  String _findInternalKeyForPersonType(String backendType, Map<String, int> typeCounters) {
    if (_isGovernmentOfficial(backendType) || backendType.startsWith('hotspot_') || backendType == 'village_poc') {
      return backendType;
    }

    String baseType = backendType;
    List<String> matchingKeys = _activeOfficials.where((key) {
      return _getValidPersonType(key) == baseType;
    }).toList();

    int currentIndex = typeCounters[baseType] ?? 0;

    if (currentIndex < matchingKeys.length) {
      typeCounters[baseType] = currentIndex + 1;
      return matchingKeys[currentIndex];
    }

    typeCounters[baseType] = currentIndex + 1;
    String newKey;
    if (baseType == 'shopowner') {
      newKey = 'shopowner_${_nextShopownerNumber}_optional';
      _nextShopownerNumber++;
    } else if (baseType == 'mukkadam') {
      newKey = 'mukkadam_$_nextMukkadamNumber';
      _nextMukkadamNumber++;
    } else if (baseType == 'influential_person') {
      newKey = 'influential_person_$_nextInfluentialPersonNumber';
      _nextInfluentialPersonNumber++;
    } else if (baseType == 'other') {
      newKey = 'other_$_nextOtherPersonNumber';
      _nextOtherPersonNumber++;
    } else {
      newKey = backendType;
    }
    return newKey;
  }

  void _updateNextNumbersFromOfficial(String official) {
    if (_isShopowner(official)) {
      final match = RegExp(r'shopowner_(\d+)').firstMatch(official);
      if (match != null) {
        int num = int.tryParse(match.group(1) ?? '0') ?? 0;
        if (num + 1 > _nextShopownerNumber) {
          _nextShopownerNumber = num + 1;
        }
      }
    } else if (_isMukkadam(official)) {
      final match = RegExp(r'mukkadam_(\d+)').firstMatch(official);
      if (match != null) {
        int num = int.tryParse(match.group(1) ?? '0') ?? 0;
        if (num + 1 > _nextMukkadamNumber) {
          _nextMukkadamNumber = num + 1;
        }
      }
    } else if (_isInfluentialPerson(official)) {
      final match = RegExp(r'influential_person_(\d+)').firstMatch(official);
      if (match != null) {
        int num = int.tryParse(match.group(1) ?? '0') ?? 0;
        if (num + 1 > _nextInfluentialPersonNumber) {
          _nextInfluentialPersonNumber = num + 1;
        }
      }
    } else if (_isOtherPerson(official)) {
      final match = RegExp(r'other_(\d+)').firstMatch(official);
      if (match != null) {
        int num = int.tryParse(match.group(1) ?? '0') ?? 0;
        if (num + 1 > _nextOtherPersonNumber) {
          _nextOtherPersonNumber = num + 1;
        }
      }
    }
  }

  /// Matches a backend designation value to a key in the given list
  String? _findMatchingDesignationKey(String backendValue, List<String> keys) {
    // Direct key match
    if (keys.contains(backendValue.toLowerCase())) return backendValue.toLowerCase();
    // Match by English display value from strings map
    for (var key in keys) {
      String english = VillageExecutionStrings.get(key, 'en');
      if (english.toLowerCase() == backendValue.toLowerCase()) {
        return key;
      }
    }
    return null;
  }

  void _initializeOfficials() {
    _activeOfficials = [];

    const mandatoryOfficials = [
      'shopowner_1_mandatory',
      'shopowner_2_mandatory',
      'hotspot_pickup_dropoff',
      'hotspot_banner_spot',
      'hotspot_wall_painting',
      'village_poc',
    ];
    _activeOfficials.addAll(mandatoryOfficials);

    const govtOfficials = [
      'sarpanch', 'secretary', 'talathi', 'postman', 'vdo',
      'principal', 'agriculture_officer', 'anganwadi_worker',
      'asha_worker', 'police_patil', 'krishi_sahayak', 'gram_panchayat_member',
    ];

    for (var official in govtOfficials) {
      if (widget.village.officialsToMeet.contains(official)) {
        _activeOfficials.add(official);
      }
    }

    _nextShopownerNumber = 3;
    _nextInfluentialPersonNumber = 1;
    _nextMukkadamNumber = 1;
    _nextOtherPersonNumber = 1;

    for (var official in _activeOfficials) {
      _initializeOfficialControllers(official);
    }
  }

  void _initializeOfficialControllers(String official) {
    _feedbackControllers[official] = TextEditingController();
    _nameControllers[official] = TextEditingController();
    _phoneControllers[official] = TextEditingController();
    _designationControllers[official] = TextEditingController();
    _reasonNotMetControllers[official] = TextEditingController();
    _customDesignationControllers[official] = TextEditingController();
    _customLocationTypeControllers[official] = TextEditingController();

    if (_isGovernmentOfficial(official)) {
      _designationControllers[official]?.text = _officialDesignationMap[official] ?? '';
    }

    if (_isMukkadam(official)) {
      _designationControllers[official]?.text = _getMukkadamDesignation(official);
    }

    _personMetStatus[official] = true;
    _isSubmitting[official] = false;
    _selectedImages[official] = null;
    _capturedPositions[official] = null;
    _locations[official] = "Not captured";
    _isOfficialSubmitted[official] = false;
    _submittedMeetingIds[official] = null;
    _isExpanded[official] = false;
    _selectedDesignations[official] = null;
    _selectedLocationTypes[official] = null;
    _isFetchingLocation[official] = false;
  }

  bool _isMukkadam(String official) {
    return official.startsWith('mukkadam_');
  }

  String _getMukkadamDesignation(String official) {
    final match = RegExp(r'mukkadam_(\d+)').firstMatch(official);
    if (match != null) {
      int num = int.tryParse(match.group(1) ?? '1') ?? 1;
      return 'Mukkadam $num';
    }
    return 'Mukkadam';
  }

  bool _isOtherPerson(String official) {
    return official.startsWith('other_') || official == 'other';
  }

  bool _isInfluentialPerson(String official) {
    return official.startsWith('influential_person');
  }

  bool _canAddMoreOfType(String type) {
    if (_isCompleted) return false;

    if (type == 'shopowner') {
      List<String> allShopowners = _activeOfficials
          .where((o) => _isShopowner(o))
          .toList();
      if (allShopowners.isEmpty) return true;
      String lastShopowner = allShopowners.last;
      return _isOfficialSubmitted[lastShopowner] == true;
    } else if (type == 'mukkadam') {
      List<String> allMukkadams = _activeOfficials
          .where((o) => _isMukkadam(o))
          .toList();
      if (allMukkadams.isEmpty) return true;
      String lastMukkadam = allMukkadams.last;
      return _isOfficialSubmitted[lastMukkadam] == true;
    } else if (type == 'influential_person') {
      List<String> allInfluentials = _activeOfficials
          .where((o) => _isInfluentialPerson(o))
          .toList();
      if (allInfluentials.isEmpty) return true;
      String lastInfluential = allInfluentials.last;
      return _isOfficialSubmitted[lastInfluential] == true;
    } else if (type == 'other') {
      List<String> allOthers = _activeOfficials
          .where((o) => _isOtherPerson(o))
          .toList();
      if (allOthers.isEmpty) return true;
      String lastOther = allOthers.last;
      return _isOfficialSubmitted[lastOther] == true;
    }

    return false;
  }

  void _addOptionalOfficial(String type) {
    if (!_canAddMoreOfType(type)) {
      String typeLabel = type == 'shopowner'
          ? VillageExecutionStrings.get('shopowner', _lang)
          : type == 'mukkadam'
          ? VillageExecutionStrings.get('mukkadam', _lang)
          : type == 'influential_person'
          ? VillageExecutionStrings.get('influential', _lang)
          : VillageExecutionStrings.get('other', _lang);
      _showSnackBar(
        "${VillageExecutionStrings.get('submit_previous_first', _lang)} $typeLabel ${VillageExecutionStrings.get('first_suffix', _lang)}",
        isError: true,
      );
      return;
    }

    setState(() {
      String newOfficial;
      if (type == 'shopowner') {
        newOfficial = 'shopowner_${_nextShopownerNumber}_optional';
        _nextShopownerNumber++;
      } else if (type == 'mukkadam') {
        newOfficial = 'mukkadam_$_nextMukkadamNumber';
        _nextMukkadamNumber++;
      } else if (type == 'influential_person') {
        newOfficial = 'influential_person_$_nextInfluentialPersonNumber';
        _nextInfluentialPersonNumber++;
      } else if (type == 'other') {
        newOfficial = 'other_$_nextOtherPersonNumber';
        _nextOtherPersonNumber++;
      } else {
        return;
      }

      _activeOfficials.add(newOfficial);
      _initializeOfficialControllers(newOfficial);
      _isExpanded[newOfficial] = true;
    });
  }

  void _removeOptionalOfficial(String official) {
    if (_isOfficialSubmitted[official] == true) {
      _showSnackBar(VillageExecutionStrings.get('cannot_remove_submitted', _lang), isError: true);
      return;
    }

    setState(() {
      _activeOfficials.remove(official);
      _feedbackControllers[official]?.dispose();
      _nameControllers[official]?.dispose();
      _phoneControllers[official]?.dispose();
      _designationControllers[official]?.dispose();
      _reasonNotMetControllers[official]?.dispose();
      _customDesignationControllers[official]?.dispose();
      _customLocationTypeControllers[official]?.dispose();

      _feedbackControllers.remove(official);
      _nameControllers.remove(official);
      _phoneControllers.remove(official);
      _designationControllers.remove(official);
      _reasonNotMetControllers.remove(official);
      _customDesignationControllers.remove(official);
      _customLocationTypeControllers.remove(official);
      _personMetStatus.remove(official);
      _isSubmitting.remove(official);
      _selectedImages.remove(official);
      _capturedPositions.remove(official);
      _locations.remove(official);
      _isOfficialSubmitted.remove(official);
      _submittedMeetingIds.remove(official);
      _isExpanded.remove(official);
      _selectedDesignations.remove(official);
      _selectedLocationTypes.remove(official);
      _isFetchingLocation.remove(official);
    });
  }

  bool _isOfficialMandatory(String official) {
    const mandatory = [
      'shopowner_1_mandatory',
      'shopowner_2_mandatory',
      'hotspot_pickup_dropoff',
      'hotspot_banner_spot',
      'hotspot_wall_painting',
      'village_poc',
    ];
    return mandatory.contains(official);
  }

  bool _isOfficialOptional(String official) {
    if (official.startsWith('influential_person')) return true;
    if (official.contains('optional')) return true;
    if (official.startsWith('shopowner_')) {
      final match = RegExp(r'shopowner_(\d+)').firstMatch(official);
      if (match != null) {
        int num = int.tryParse(match.group(1) ?? '0') ?? 0;
        return num >= 3;
      }
    }
    if (official.startsWith('mukkadam_')) return true;
    if (official.startsWith('other_') || official == 'other') return true;
    return false;
  }

  bool _isHotspot(String official) {
    return official.startsWith('hotspot_');
  }

  bool _isShopowner(String official) {
    return official.startsWith('shopowner_');
  }

  bool _isGovernmentOfficial(String official) {
    const govtOfficials = [
      'sarpanch', 'secretary', 'talathi', 'postman', 'vdo',
      'principal', 'agriculture_officer', 'anganwadi_worker',
      'asha_worker', 'police_patil', 'krishi_sahayak', 'gram_panchayat_member',
    ];
    return govtOfficials.contains(official);
  }

  bool _isValidPhoneNumber(String phone) {
    if (phone.isEmpty) return false;
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
    return digitsOnly.length == 10;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _villageFeedbackController.dispose();
    _totalRegistrationsController.dispose();
    for (var controller in _feedbackControllers.values) controller.dispose();
    for (var controller in _nameControllers.values) controller.dispose();
    for (var controller in _phoneControllers.values) controller.dispose();
    for (var controller in _designationControllers.values) controller.dispose();
    for (var controller in _reasonNotMetControllers.values) controller.dispose();
    for (var controller in _customDesignationControllers.values) controller.dispose();
    for (var controller in _customLocationTypeControllers.values) controller.dispose();
    super.dispose();
  }

  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      bool? shouldOpenSettings = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(VillageExecutionStrings.get('location_disabled', _lang)),
          content: Text(VillageExecutionStrings.get('enable_location', _lang)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(VillageExecutionStrings.get('cancel', _lang)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(VillageExecutionStrings.get('settings', _lang)),
            ),
          ],
        ),
      );

      if (shouldOpenSettings == true) {
        await Geolocator.openLocationSettings();
      }
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar(VillageExecutionStrings.get('location_denied', _lang), isError: true);
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      bool? shouldOpenSettings = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(VillageExecutionStrings.get('permission_required', _lang)),
          content: Text(VillageExecutionStrings.get('enable_location_settings', _lang)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(VillageExecutionStrings.get('cancel', _lang)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(VillageExecutionStrings.get('settings', _lang)),
            ),
          ],
        ),
      );

      if (shouldOpenSettings == true) {
        await openAppSettings();
      }
      return false;
    }

    return true;
  }

  Future<Position?> _determinePosition() async {
    bool hasPermission = await _checkLocationPermission();
    if (!hasPermission) return null;

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  void _showStartDialog() {
    if (!_canStartExecution()) {
      _showSnackBar(_getStartButtonDisabledMessage(), isError: true);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.play_arrow, color: Colors.green.shade700),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                VillageExecutionStrings.get('start', _lang),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${VillageExecutionStrings.get('start_visit_question', _lang)} ${widget.village.village}?",
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      VillageExecutionStrings.get('gps_will_be_captured', _lang),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(VillageExecutionStrings.get('cancel', _lang)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleStartExecution();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(VillageExecutionStrings.get('start', _lang)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleStartExecution() async {
    setState(() => _isLoading = true);
    try {
      Position? position = await _determinePosition();
      if (position == null) {
        setState(() => _isLoading = false);
        return;
      }

      final result = await _executionService.startVillageExecution(
        widget.village.id,
        position.latitude,
        position.longitude,
      );

      if (result != null) {
        _showSnackBar(VillageExecutionStrings.get('started', _lang));
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pop(context, true);
          }
        });
      } else {
        throw Exception("Failed to start execution");
      }
    } catch (e) {
      _showSnackBar("Error: $e", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleImageCapture(String official) async {
    setState(() => _isFetchingLocation[official] = true);

    try {
      bool permissionsGranted = await _geoTaggingService.checkAllPermissions(context);
      if (!permissionsGranted) {
        setState(() => _isFetchingLocation[official] = false);
        _showSnackBar(VillageExecutionStrings.get('permissions_required', _lang), isError: true);
        return;
      }

      Position? position = await _geoTaggingService.getCurrentPosition();
      if (position == null) {
        setState(() => _isFetchingLocation[official] = false);
        _showSnackBar(VillageExecutionStrings.get('could_not_get_gps', _lang), isError: true);
        return;
      }

      File? originalImage = await _geoTaggingService.pickImage(ImageSource.camera);
      if (originalImage == null) {
        setState(() => _isFetchingLocation[official] = false);
        return;
      }

      File? geoTaggedImage = await _geoTaggingService.addGeoTagToImage(originalImage, position);
      File finalImage = geoTaggedImage ?? originalImage;

      setState(() {
        _selectedImages[official] = finalImage;
        _capturedPositions[official] = position;
        _locations[official] = _geoTaggingService.formatCoordinates(position);
        _isFetchingLocation[official] = false;
      });
      _showSnackBar(VillageExecutionStrings.get('photo_captured', _lang));
    } catch (e) {
      setState(() => _isFetchingLocation[official] = false);
      _showSnackBar("Error: $e", isError: true);
    }
  }

  /// Always returns English designation for backend
  String _getFinalDesignation(String official) {
    if (_isGovernmentOfficial(official)) {
      return _designationControllers[official]?.text.trim() ?? '';
    }
    if (_isMukkadam(official)) {
      return _designationControllers[official]?.text.trim() ?? '';
    }
    if (_isShopowner(official)) {
      String? selectedKey = _selectedDesignations[official];
      if (selectedKey == 'other') {
        return _customDesignationControllers[official]?.text.trim() ?? '';
      }
      return VillageExecutionStrings.get(selectedKey ?? '', 'en');
    } else if (_isHotspot(official)) {
      String? selectedKey = _selectedLocationTypes[official];
      if (selectedKey == 'other') {
        return _customLocationTypeControllers[official]?.text.trim() ?? '';
      }
      return VillageExecutionStrings.get(selectedKey ?? '', 'en');
    } else {
      return _designationControllers[official]?.text.trim() ?? '';
    }
  }

  String _getValidPersonType(String official) {
    String personType = official.toLowerCase();

    if (personType.startsWith('other_') || personType == 'other') {
      return 'other';
    }
    if (personType.startsWith('mukkadam_')) {
      return 'mukkadam';
    }
    if (personType.startsWith('influential_person')) {
      return 'influential_person';
    }
    if (personType.startsWith('shopowner_')) {
      return 'shopowner';
    }
    if (personType.startsWith('hotspot_')) {
      return personType;
    }

    return personType;
  }

  Future<void> _submitOfficialData(String official) async {
    bool isGovtOfficial = _isGovernmentOfficial(official);
    bool isMukkadamOfficial = _isMukkadam(official);
    bool isHotspotOfficial = _isHotspot(official);
    bool isShopownerOfficial = _isShopowner(official);

    if (_personMetStatus[official]!) {
      if (_capturedPositions[official] == null) {
        _showSnackBar(VillageExecutionStrings.get('capture_gps', _lang), isError: true);
        return;
      }

      if (isHotspotOfficial) {
        String locationType = _getFinalDesignation(official);
        if (locationType.isEmpty) {
          _showSnackBar(VillageExecutionStrings.get('select_location', _lang), isError: true);
          return;
        }
      } else if (isShopownerOfficial) {
        String designation = _getFinalDesignation(official);
        if (designation.isEmpty) {
          _showSnackBar(VillageExecutionStrings.get('select_shop_type', _lang), isError: true);
          return;
        }
        if (_nameControllers[official]!.text.trim().isEmpty) {
          _showSnackBar(VillageExecutionStrings.get('enter_name', _lang), isError: true);
          return;
        }
      } else if (isGovtOfficial) {
        if (_nameControllers[official]!.text.trim().isEmpty) {
          _showSnackBar(VillageExecutionStrings.get('enter_name', _lang), isError: true);
          return;
        }
      } else if (isMukkadamOfficial) {
        if (_nameControllers[official]!.text.trim().isEmpty) {
          _showSnackBar(VillageExecutionStrings.get('enter_name', _lang), isError: true);
          return;
        }
      } else {
        if (_nameControllers[official]!.text.trim().isEmpty) {
          _showSnackBar(VillageExecutionStrings.get('enter_name', _lang), isError: true);
          return;
        }
      }

      String phone = _phoneControllers[official]!.text.trim();
      if (phone.isEmpty) {
        _showSnackBar(VillageExecutionStrings.get('enter_phone', _lang), isError: true);
        return;
      }
      if (!_isValidPhoneNumber(phone)) {
        _showSnackBar(VillageExecutionStrings.get('enter_valid_phone', _lang), isError: true);
        return;
      }
    } else {
      if (_reasonNotMetControllers[official]!.text.trim().isEmpty) {
        _showSnackBar(VillageExecutionStrings.get('enter_reason', _lang), isError: true);
        return;
      }

      String designation = _designationControllers[official]?.text.trim() ?? '';
      if (designation.isEmpty) {
        _showSnackBar(VillageExecutionStrings.get('enter_designation', _lang), isError: true);
        return;
      }
    }

    setState(() => _isSubmitting[official] = true);

    try {
      bool met = _personMetStatus[official]!;
      String personType = _getValidPersonType(official);
      String finalDesignation = met ? _getFinalDesignation(official) : _designationControllers[official]!.text.trim();

      debugPrint("🚀 Submitting: official=$official, personType=$personType, met=$met");

      final meetingResult = await _executionService.submitMeetingRecord(
        executionId: _executionId ?? _executionData?.id ?? widget.village.id,
        personType: personType,
        personMet: met,
        personName: met ? _nameControllers[official]!.text.trim() : null,
        personPhone: met ? _phoneControllers[official]!.text.trim() : null,
        personDesignation: finalDesignation,
        meetingNotes: met ? _feedbackControllers[official]!.text.trim() : null,
        reasonNotMet: !met ? _reasonNotMetControllers[official]!.text.trim() : null,
        meetingLatitude: _capturedPositions[official]?.latitude,
        meetingLongitude: _capturedPositions[official]?.longitude,
      );

      if (meetingResult == null) {
        throw Exception("Failed to submit meeting record");
      }

      String meetingId = meetingResult['id'];
      _submittedMeetingIds[official] = meetingId;

      if (_selectedImages[official] != null) {
        await _uploadProofImage(official, meetingId, personType);
      }

      setState(() {
        _isOfficialSubmitted[official] = true;
        _isExpanded[official] = false;
      });

      _showSnackBar(VillageExecutionStrings.get('submitted_msg', _lang));
    } catch (e) {
      _showSnackBar("Error: $e", isError: true);
    } finally {
      setState(() => _isSubmitting[official] = false);
    }
  }

  Future<void> _uploadProofImage(String official, String meetingId, String personType) async {
    try {
      await _executionService.uploadImageComplete(
        filePath: _selectedImages[official]!.path,
        executionId: _executionId ?? _executionData?.id ?? widget.village.id,
        meetingId: meetingId,
        personType: personType,
        imageType: _isHotspot(official) ? 'other' : 'meeting',
        latitude: _capturedPositions[official]?.latitude,
        longitude: _capturedPositions[official]?.longitude,
        caption: _personMetStatus[official]!
            ? "Meeting with ${_nameControllers[official]!.text}"
            : "Photo for ${_formatOfficialTitle(official)}",
      );
      debugPrint("✅ Image uploaded successfully for $official");
    } catch (e) {
      debugPrint("❌ Image upload error: $e");
    }
  }

  List<String> _getUnfilledMandatoryOfficials() {
    List<String> unfilled = [];

    for (var official in _activeOfficials) {
      if (_isOfficialMandatory(official) && _isOfficialSubmitted[official] != true) {
        unfilled.add(_formatOfficialTitle(official));
      }
    }

    for (var official in _activeOfficials) {
      if (_isGovernmentOfficial(official) && _isOfficialSubmitted[official] != true) {
        unfilled.add(_formatOfficialTitle(official));
      }
    }

    return unfilled;
  }

  void _showCompleteDialog() {
    List<String> unfilledOfficials = _getUnfilledMandatoryOfficials();

    if (unfilledOfficials.isNotEmpty) {
      _showUnfilledDetailsDialog(unfilledOfficials);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.check_circle, color: Colors.green.shade700),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                VillageExecutionStrings.get('complete', _lang),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _totalRegistrationsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: VillageExecutionStrings.get('registrations', _lang),
                    prefixIcon: const Icon(Icons.people),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _villageFeedbackController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: VillageExecutionStrings.get('feedback', _lang),
                    hintText: VillageExecutionStrings.get('enter_feedback', _lang),
                    prefixIcon: const Icon(Icons.feedback),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          VillageExecutionStrings.get('gps_on_submit', _lang),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(VillageExecutionStrings.get('cancel', _lang)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleCompleteExecution();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(VillageExecutionStrings.get('complete', _lang)),
          ),
        ],
      ),
    );
  }

  void _showUnfilledDetailsDialog(List<String> unfilledOfficials) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade400, Colors.orange.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.assignment_late_rounded, color: Colors.white, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    VillageExecutionStrings.get('incomplete_form', _lang),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        "${unfilledOfficials.length}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        VillageExecutionStrings.get('items_need_filled', _lang),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.3,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: unfilledOfficials.asMap().entries.map((entry) {
                    int index = entry.key;
                    String official = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                "${index + 1}",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              official,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(Icons.error_outline, size: 18, color: Colors.red.shade400),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    VillageExecutionStrings.get('go_back_fill', _lang),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCompleteExecution() async {
    List<String> unfilledOfficials = _getUnfilledMandatoryOfficials();
    if (unfilledOfficials.isNotEmpty) {
      _showUnfilledDetailsDialog(unfilledOfficials);
      return;
    }

    setState(() => _isLoading = true);

    try {
      Position? position = await _determinePosition();
      if (position == null) {
        setState(() => _isLoading = false);
        return;
      }

      if (_villageFeedbackController.text.trim().isEmpty) {
        _showSnackBar(VillageExecutionStrings.get('enter_feedback_msg', _lang), isError: true);
        setState(() => _isLoading = false);
        return;
      }

      final result = await _executionService.completeVillageExecution(
        widget.village.id,
        latitude: position.latitude,
        longitude: position.longitude,
        villageFeedback: _villageFeedbackController.text.trim(),
        totalRegistrations: int.tryParse(_totalRegistrationsController.text) ?? 0,
      );

      if (result != null) {
        setState(() {
          _isCompleted = true;
        });
        _showSnackBar(VillageExecutionStrings.get('completed_msg', _lang));

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context, true);
        });
      } else {
        throw Exception("Failed to complete execution");
      }
    } catch (e) {
      _showSnackBar("Error: $e", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String _formatOfficialTitle(String official) {
    return OfficialDisplayNames.getDisplayName(official, _lang);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      case 'planned':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getOfficialIcon(String official) {
    if (official.startsWith('shopowner')) return Icons.store;
    if (official.startsWith('mukkadam')) return Icons.engineering;
    if (official.startsWith('influential')) return Icons.star;
    if (official.startsWith('hotspot')) return Icons.location_on;
    if (official.startsWith('other')) return Icons.person_add;
    if (official == 'sarpanch') return Icons.account_balance;
    if (official == 'secretary') return Icons.person;
    if (official == 'talathi') return Icons.badge;
    if (official == 'postman') return Icons.mail;
    if (official == 'village_poc') return Icons.contact_phone;
    if (official == 'vdo') return Icons.business;
    if (official == 'principal') return Icons.school;
    if (official == 'agriculture_officer') return Icons.grass;
    if (official == 'anganwadi_worker') return Icons.child_care;
    if (official == 'asha_worker') return Icons.health_and_safety;
    if (official == 'police_patil') return Icons.local_police;
    if (official == 'krishi_sahayak') return Icons.agriculture;
    if (official == 'gram_panchayat_member') return Icons.groups;
    return Icons.person;
  }

  // ======================== BUILD ========================
  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(widget.village.status);
    // Watch provider to trigger rebuild on language change
    context.watch<LanguageProvider>();

    final villageName = widget.village.getDisplayVillage(_lang);
    final talukaName = widget.village.getDisplayTaluka(_lang);
    final districtName = widget.village.getDisplayDistrict(_lang);


    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              villageName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '$talukaName, $districtName',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_isStarted
          ? _buildNotStartedView()
          : _buildExecutionView(),
    );
  }

  Widget _buildNotStartedView() {
    bool canStart = _canStartExecution();
    final plannedDate = widget.village.plannedDate;
    final formattedDate = DateFormat('dd MMM yyyy').format(plannedDate);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: canStart ? Colors.blue.shade50 : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                canStart ? Icons.play_circle_filled : Icons.schedule,
                size: 80,
                color: canStart ? Colors.blue.shade700 : Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              canStart
                  ? VillageExecutionStrings.get('ready', _lang)
                  : VillageExecutionStrings.get('not_available', _lang),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              canStart
                  ? "${VillageExecutionStrings.get('start_visit_to', _lang)} ${widget.village.village}"
                  : "${VillageExecutionStrings.get('planned_for', _lang)} $formattedDate",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            if (!canStart) ...{
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text(
                  VillageExecutionStrings.get('start_on_planned_date', _lang),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            },
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: canStart ? _showStartDialog : null,
              icon: const Icon(Icons.play_arrow),
              label: Text(VillageExecutionStrings.get('start', _lang)),
              style: ElevatedButton.styleFrom(
                backgroundColor: canStart ? Colors.green : Colors.grey.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExecutionView() {
    return Column(
      children: [
        _buildProgressCard(),
        _buildTabBar(),
        Expanded(child: _buildTabBarView()),
      ],
    );
  }

  Widget _buildProgressCard() {
    List<String> trackableOfficials = _activeOfficials
        .where((o) => _isOfficialMandatory(o) || _isGovernmentOfficial(o))
        .toList();

    int totalOfficials = trackableOfficials.length;
    int submittedCount = trackableOfficials
        .where((o) => _isOfficialSubmitted[o] == true)
        .length;
    double progress = totalOfficials > 0 ? submittedCount / totalOfficials : 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(Icons.people, '${widget.village.expectedRegistrations}', VillageExecutionStrings.get('expected', _lang), Colors.blue),
              _buildStatItem(Icons.engineering, '$todayMukkadamCount', VillageExecutionStrings.get('mukkadams_today', _lang), Colors.deepPurple),
              _buildStatItem(Icons.check_circle, '$submittedCount/$totalOfficials', VillageExecutionStrings.get('officials', _lang), Colors.green),
              _buildStatItem(Icons.trending_up, '${(progress * 100).toInt()}%', VillageExecutionStrings.get('progress', _lang), Colors.orange),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? Colors.green : Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 4)],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.indigo,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        tabs: [
          Tab(text: VillageExecutionStrings.get('tab_shops_spots', _lang)),
          Tab(text: VillageExecutionStrings.get('tab_officials', _lang)),
          Tab(text: VillageExecutionStrings.get('tab_others', _lang)),
        ],
      ),
    );
  }

  Widget _buildTabBarView() {
    List<String> shopsAndSpots = _activeOfficials.where((o) => _isOfficialMandatory(o)).toList();
    List<String> officials = _activeOfficials.where((o) => _isGovernmentOfficial(o)).toList();
    List<String> others = _activeOfficials.where((o) =>
    (_isShopowner(o) && !_isOfficialMandatory(o)) ||
        _isMukkadam(o) ||
        _isInfluentialPerson(o) ||
        _isOtherPerson(o)
    ).toList();

    return TabBarView(
      controller: _tabController,
      children: [
        _buildOfficialsList(shopsAndSpots, showAddButtons: false),
        _buildOfficialsList(officials, showAddButtons: false),
        _buildOthersTab(others),
      ],
    );
  }

  Widget _buildOfficialsList(List<String> officials, {required bool showAddButtons}) {
    return Column(
      children: [
        Expanded(
          child: officials.isEmpty
              ? Center(
            child: Text(
              VillageExecutionStrings.get('no_officials', _lang),
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: officials.length,
            itemBuilder: (context, index) {
              return _buildOfficialCard(officials[index]);
            },
          ),
        ),
        if (!_isCompleted)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showCompleteDialog,
                icon: const Icon(Icons.done_all),
                label: Text(VillageExecutionStrings.get('complete_visit', _lang)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOthersTab(List<String> others) {
    List<String> shopowners = others.where((o) => _isShopowner(o)).toList();
    List<String> influentials = others.where((o) => _isInfluentialPerson(o)).toList();
    List<String> mukkadams = others.where((o) => _isMukkadam(o)).toList();
    List<String> otherPersons = others.where((o) => _isOtherPerson(o)).toList();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCategorySection(
                  title: VillageExecutionStrings.get('shopowners', _lang), officials: shopowners,
                  addButtonText: VillageExecutionStrings.get('add_shop', _lang), onAdd: () => _addOptionalOfficial('shopowner'),
                  canAdd: _canAddMoreOfType('shopowner'), icon: Icons.store, color: Colors.blue,
                ),
                const SizedBox(height: 16),
                _buildCategorySection(
                  title: VillageExecutionStrings.get('influential_persons', _lang), officials: influentials,
                  addButtonText: VillageExecutionStrings.get('add_influential', _lang), onAdd: () => _addOptionalOfficial('influential_person'),
                  canAdd: _canAddMoreOfType('influential_person'), icon: Icons.star, color: Colors.purple,
                ),
                const SizedBox(height: 16),
                _buildCategorySection(
                  title: VillageExecutionStrings.get('mukkadams', _lang), officials: mukkadams,
                  addButtonText: VillageExecutionStrings.get('add_mukkadam', _lang), onAdd: () => _addOptionalOfficial('mukkadam'),
                  canAdd: _canAddMoreOfType('mukkadam'), icon: Icons.engineering, color: Colors.orange,
                ),
                const SizedBox(height: 16),
                _buildCategorySection(
                  title: VillageExecutionStrings.get('other_persons', _lang), officials: otherPersons,
                  addButtonText: VillageExecutionStrings.get('add_other', _lang), onAdd: () => _addOptionalOfficial('other'),
                  canAdd: _canAddMoreOfType('other'), icon: Icons.person_add, color: Colors.teal,
                ),
              ],
            ),
          ),
        ),
        if (!_isCompleted)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showCompleteDialog,
                icon: const Icon(Icons.done_all),
                label: Text(VillageExecutionStrings.get('complete_visit', _lang)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategorySection({
    required String title, required List<String> officials,
    required String addButtonText, required VoidCallback onAdd,
    required bool canAdd, required IconData icon, required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
                ),
                if (!_isCompleted)
                  ElevatedButton.icon(
                    onPressed: canAdd ? onAdd : null,
                    icon: Icon(Icons.add, size: 16, color: canAdd ? color : Colors.grey),
                    label: Text(
                      addButtonText,
                      style: TextStyle(fontSize: 11, color: canAdd ? color : Colors.grey),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: canAdd ? color : Colors.grey.shade300),
                      ),
                      disabledBackgroundColor: Colors.grey.shade100,
                    ),
                  ),
              ],
            ),
          ),
          if (officials.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  VillageExecutionStrings.get('none_added', _lang),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                ),
              ),
            )
          else
            ...officials.map((official) => _buildOfficialCard(official)),
        ],
      ),
    );
  }

  Widget _buildOfficialCard(String official) {
    String title = _formatOfficialTitle(official);
    bool isMet = _personMetStatus[official] ?? true;
    bool isSubmitted = _isOfficialSubmitted[official] ?? false;
    bool isMandatory = _isOfficialMandatory(official);
    bool isOptional = _isOfficialOptional(official);
    bool isHotspot = _isHotspot(official);
    bool isShopowner = _isShopowner(official);
    bool isGovtOfficial = _isGovernmentOfficial(official);
    bool isMukkadamOfficial = _isMukkadam(official);
    bool isOther = _isOtherPerson(official);
    bool isExpanded = _isExpanded[official] ?? false;
    bool isFetchingLoc = _isFetchingLocation[official] ?? false;

    Color borderColor = isSubmitted
        ? Colors.green.shade300
        : isMandatory
        ? Colors.red.shade200
        : isOptional
        ? Colors.orange.shade200
        : Colors.blue.shade200;

    return Card(
      margin: const EdgeInsets.only(bottom: 12, left: 12, right: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 2),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: borderColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_getOfficialIcon(official), color: borderColor),
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: isSubmitted
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 14),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(VillageExecutionStrings.get('submitted', _lang), style: const TextStyle(color: Colors.green, fontSize: 10), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                Text(
                  VillageExecutionStrings.get('tap_to_view', _lang),
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            )
                : Text(
              _locations[official] ?? VillageExecutionStrings.get('not_captured', _lang),
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isOptional && !isSubmitted)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    onPressed: () => _removeOptionalOfficial(official),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                IconButton(
                  icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () {
                    setState(() {
                      _isExpanded[official] = !isExpanded;
                    });
                  },
                ),
              ],
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isSubmitted)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.visibility, size: 14, color: Colors.blue.shade700),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              VillageExecutionStrings.get('view_only', _lang),
                              style: TextStyle(fontSize: 10, color: Colors.blue.shade700, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Person Met Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(child: Text(VillageExecutionStrings.get('met', _lang), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                      Switch(
                        value: isMet,
                        onChanged: isSubmitted
                            ? null
                            : (value) {
                          setState(() {
                            _personMetStatus[official] = value;
                          });
                        },
                        activeColor: Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // FIELDS FOR PERSON MET
                  if (isMet) ...[
                    _buildTextField("${VillageExecutionStrings.get('name', _lang)} ${isSubmitted ? '' : '*'}", _nameControllers[official]!, isSubmitted),
                    const SizedBox(height: 12),

                    _buildTextField(
                      "${VillageExecutionStrings.get('phone', _lang)} ${isSubmitted ? '' : '*'}",
                      _phoneControllers[official]!,
                      isSubmitted,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 12),

                    if (isGovtOfficial) ...[
                      _buildTextField(VillageExecutionStrings.get('designation', _lang), _designationControllers[official]!, true),
                      const SizedBox(height: 12),
                    ] else if (isMukkadamOfficial) ...[
                      _buildTextField(VillageExecutionStrings.get('designation', _lang), _designationControllers[official]!, true),
                      const SizedBox(height: 12),
                    ] else if (isShopowner) ...[
                      if (isSubmitted) ...[
                        _buildTextField(VillageExecutionStrings.get('shop_type', _lang), TextEditingController(text: _getFinalDesignation(official)), true),
                      ] else ...[
                        _buildDropdownField(
                          "${VillageExecutionStrings.get('shop_type', _lang)} *",
                          _shopownerDesignationKeys,
                          _selectedDesignations[official],
                              (value) { setState(() { _selectedDesignations[official] = value; }); },
                        ),
                        const SizedBox(height: 12),
                        if (_selectedDesignations[official] == 'other')
                          _buildTextField("${VillageExecutionStrings.get('custom', _lang)} *", _customDesignationControllers[official]!, isSubmitted),
                      ],
                      const SizedBox(height: 12),
                    ] else if (isHotspot) ...[
                      if (isSubmitted) ...[
                        _buildTextField(VillageExecutionStrings.get('location_type', _lang), TextEditingController(text: _getFinalDesignation(official)), true),
                      ] else ...[
                        _buildDropdownField(
                          "${VillageExecutionStrings.get('location_type', _lang)} *",
                          _pickupLocationTypeKeys,
                          _selectedLocationTypes[official],
                              (value) { setState(() { _selectedLocationTypes[official] = value; }); },
                        ),
                        const SizedBox(height: 12),
                        if (_selectedLocationTypes[official] == 'other')
                          _buildTextField("${VillageExecutionStrings.get('custom', _lang)} *", _customLocationTypeControllers[official]!, isSubmitted),
                      ],
                      const SizedBox(height: 12),
                    ] else ...[
                      _buildTextField(VillageExecutionStrings.get('designation', _lang), _designationControllers[official]!, isSubmitted),
                      const SizedBox(height: 12),
                    ],

                    _buildTextField(VillageExecutionStrings.get('notes', _lang), _feedbackControllers[official]!, isSubmitted, maxLines: 3),
                    const SizedBox(height: 16),

                    if (isSubmitted && _locations[official] != null && _locations[official] != "Not captured") ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.green.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _locations[official]!,
                                style: TextStyle(fontSize: 11, color: Colors.green.shade700),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (!isSubmitted) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isFetchingLoc ? null : () => _handleImageCapture(official),
                          icon: isFetchingLoc
                              ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                              : Icon(_selectedImages[official] != null ? Icons.check_circle : Icons.camera_alt),
                          label: Text(
                            isFetchingLoc
                                ? "GPS..."
                                : _selectedImages[official] != null
                                ? VillageExecutionStrings.get('captured', _lang)
                                : VillageExecutionStrings.get('capture_photo', _lang),
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedImages[official] != null ? Colors.green : Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],

                    if (_selectedImages[official] != null) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImages[official]!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ],

                  if (!isMet) ...[
                    if (isGovtOfficial || isMukkadamOfficial) ...[
                      _buildTextField(VillageExecutionStrings.get('designation', _lang), _designationControllers[official]!, true),
                    ] else ...[
                      _buildTextField("${VillageExecutionStrings.get('designation', _lang)} ${isSubmitted ? '' : '*'}", _designationControllers[official]!, isSubmitted),
                    ],
                    const SizedBox(height: 12),
                    _buildTextField("${VillageExecutionStrings.get('reason', _lang)} ${isSubmitted ? '' : '*'}", _reasonNotMetControllers[official]!, isSubmitted, maxLines: 3),
                  ],

                  const SizedBox(height: 16),

                  if (!isSubmitted)
                    Row(
                      children: [
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: _isSubmitting[official] == true ? null : () => _submitOfficialData(official),
                          icon: _isSubmitting[official] == true
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.save, size: 18),
                          label: Text(
                            _isSubmitting[official] == true
                                ? VillageExecutionStrings.get('saving', _lang)
                                : VillageExecutionStrings.get('submit', _lang),
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                        ),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      String label,
      TextEditingController controller,
      bool isReadOnly, {
        int maxLines = 1,
        int? maxLength,
        TextInputType keyboardType = TextInputType.text,
        List<TextInputFormatter>? inputFormatters,
      }) {
    return TextField(
      controller: controller,
      readOnly: isReadOnly,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 11),
        counterText: maxLength != null ? null : '',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: isReadOnly,
        fillColor: isReadOnly ? Colors.grey.shade100 : null,
      ),
    );
  }

  /// Language-aware dropdown: stores keys, displays localized text
  Widget _buildDropdownField(
      String label,
      List<String> keys,
      String? selectedKey,
      void Function(String?)? onChanged,
      ) {
    return DropdownButtonFormField<String>(
      value: selectedKey,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 11),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: keys.map((key) => DropdownMenuItem(
        value: key,
        child: Text(VillageExecutionStrings.get(key, _lang), style: const TextStyle(fontSize: 12)),
      )).toList(),
      onChanged: onChanged,
      isExpanded: true,
    );
  }
}
