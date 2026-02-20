// lib/main.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mukadam_bi/mukadan/registration/registration_Service.dart';
import 'package:image_picker/image_picker.dart';
import '../../main.dart';
import '../../notes/data.dart';
import '../authentication/auth_service/auth_service.dart';
import 'adress.dart';
import 'higher_registration_screen.dart';
import 'middle_footer_Screen.dart' hide WorkHistorySection; // Import the image_picker package


final String mainToken=dotenv.env['MAIN_TOKEN']!;

// --- Section Widgets (These remain the same as your previous optimized code) ---



// --- Main Registration Screen ---

class MukkadamRegistrationScreen extends StatefulWidget {
  const MukkadamRegistrationScreen({super.key});

  @override
  State<MukkadamRegistrationScreen> createState() => _MukkadamRegistrationScreenState();
}

class _MukkadamRegistrationScreenState extends State<MukkadamRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> _issueStatesList = [];
  List<Map<String, dynamic>> _issueDistrictsList = [];
  List<Map<String, dynamic>> _issueTalukasList = [];
  List<Map<String, dynamic>> _workTalukasList = [];

  Map<String, bool> _paymentModes = {
    'upi': false,
    'bank': false,
    'cash': false,
  };


  bool _isLocationLoading = false;

  final TextEditingController _workVillageController = TextEditingController();
  final TextEditingController _workVillageCodeController = TextEditingController();
  List<Map<String, dynamic>> _workVillagesList = [];


  final TextEditingController _bikeBeyondKmController = TextEditingController();
  final TextEditingController _freeFromDateController = TextEditingController();
  final TextEditingController _bikeChargePerBikeController = TextEditingController();
  final TextEditingController _pickupChargeDetailsController = TextEditingController();
  final TextEditingController _currentlyStationedAtController = TextEditingController();


  //rate card









  // 1. Define the list variable
  List<Map<String, dynamic>> _teamMembersList = [];

// 2. Add member helper
  void _addTeamMember() {
    if (_teamMemberNameController.text.isNotEmpty) {
      setState(() {
        _teamMembersList.add({
          "name": _teamMemberNameController.text,
          //"age": _teamMemberAgeController.text,
          "gender": _teamMemberGender ?? "no mention",
          "mobile": _teamMemberMobileController.text,
          //"aadhar": _teamMemberAadharController.text,
        });
        // Clear fields
        _teamMemberNameController.clear();
        _teamMemberAgeController.clear();
        _teamMemberMobileController.clear();
        _teamMemberAadharController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter member name')));
    }
  }

// 3. Remove member helper
  void _removeTeamMember(int index) {
    setState(() => _teamMembersList.removeAt(index));
  }







  List<Map<String, dynamic>> _workHistoryList = [];
  List<Map<String, dynamic>> _locationIssuesList = [];
  List<Map<String, dynamic>> _preferredWorkLocationsList = [];


  void _addWorkHistoryEntry() {
    if (_workLocationController.text.isNotEmpty &&
        _workStateCodeController.text.isNotEmpty) {
      setState(() {
        _workHistoryList.add({
          "location": _workLocationController.text,
          "state": _workStateController.text,
          "state_code": _workStateCodeController.text,
          "district": _workDistrictController.text,
          "district_code": _workDistrictCodeController.text,
          "village": _workVillageController.text,
          "village_code": _workVillageCodeController.text,
        });

        // Clear controllers for the next entry
        _workLocationController.clear();
        _workStateController.clear();
        _workStateCodeController.clear();
        _workDistrictController.clear();
        _workDistrictCodeController.clear();
        _workVillageController.clear();
        _workVillageCodeController.clear();

        // Reset dropdown lists
        _workDistrictsList = [];
        _workVillagesList = [];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill location and state before adding')),
      );
    }
  }



  void _addLocationIssue() {
    if (_issueStateCode.text.isNotEmpty && _issueReasonController.text.isNotEmpty) {
      setState(() {
        _locationIssuesList.add({
          "state": _issueStateName.text,
          "state_code": _issueStateCode.text,
          "district": _issueDistrictName.text,
          "district_code": _issueDistrictCode.text,
          "taluka": _issueTalukaName.text,
          "taluka_code": _issueTalukaCode.text,
          "village": _issueVillageName.text,      // Added
          "village_code": _issueVillageCode.text, // Added
          "reason": _issueReasonController.text,
          "severity": _issueSeverity ?? "Medium",
        });
        // ... clear your controllers as before ...
        _issueVillageName.clear();
        _issueVillageCode.clear();
        _issueVillagesList = [];
      });
    }
  }


// 2. Helper to remove a Location Issue
  void _removeLocationIssue(int index) {
    setState(() {
      _locationIssuesList.removeAt(index);
    });
  }

// 3. Update _submitForm to send the list
  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submitting Mukkadam Registration Data...')),
      );

      // 1. Aggregate all form data into the exact map structure required by the API
      final Map<String, dynamic> mukkadamData = {
        "mukkadam_name": _mukkadamNameController.text,
        "mobile_numbers": _mobileNumbersController.text,
        "crew_size": _crewSizeController.text, // API expects String "123"
        "has_smartphone": _hasSmartphone ?? "no",
        "is_permanent": _isPermanent,

        //crew details
        "max_crew_capacity": _maxCrewCapacityController.text,
        "splitting_logic": _splittingLogicController.text,
        "deputy_mukkadam_name": _deputyMukkadamNameController.text,
        "deputy_mukkadam_mobile": _deputyMukkadamMobileController.text,







        // Current Location Details
        "state": _stateController.text,
        "state_code": _stateCodeController.text,
        "district": _districtController.text,
        "district_code": _districtCodeController.text,
        "taluka": _talukaController.text,
        "taluka_code": _talukaCodeController.text,
        "village": _villageController.text,
        "village_code": _villageCodeController.text,

        // Home Location Details
        "home_state": _homeStateController.text,
        "home_state_code": _homeStateCodeController.text,
        "home_district": _homeDistrictController.text,
        "home_district_code": _homeDistrictCodeController.text,
        "home_taluka": _homeTalukaController.text,
        "home_taluka_code": _homeTalukaCodeController.text,
        "home_village": _homeVillageController.text,
        "home_village_code": _homeVillageCodeController.text,
        "home_location": _homeLocationController.text,

        "team_members":_teamMembersList,

        // Work History (Using the controllers you added)
        "work_history":_workHistoryList,

        // Location Issues (Using Postman-style defaults if empty)
        "location_issues": _locationIssuesList,

        // Nested Objects
        "rate_card": {
          "aprilPruning": _aprilPruningController.text,
          "bagalBaliFutRemoval": _bagalBaliFutRemovalController.text,
          "berryThinning": _berryThinningController.text,
          "bunchSelection": _bunchSelectionController.text,
          "bunchThinning": _bunchThinningController.text,
          "bunchTying": _bunchTyingController.text,
          "bunchVariation": _bunchVariationController.text,
          "default_rate": double.tryParse(_defaultRateController.text) ?? 0,
          "fingerThinning": _fingerThinningController.text,
          "firstDipping": _firstDippingController.text,
          "firstFailFutRemoval": _firstFailFutRemovalController.text,
          "harvesting": _harvestingController.text,
          "newPlantation": _newPlantationController.text,
          "other": _otherRateController.text,
          "paperRemoval": _paperRemovalController.text,
          "paperWrapping": _paperWrappingController.text,
          "pasting": _pastingController.text,
          "pruning": _pruningController.text,
          "secondDipping": _secondDippingController.text,
          "secondFailFutRemoval": _secondFailFutRemovalController.text,
          "shendaTopping": _shendaToppingController.text,
          "shootTyingClips": _shootTyingClipsController.text,
          "shootTyingStrings": _shootTyingStringsController.text,
          "thirdDipping": _thirdDippingController.text,
        },
        //payment
        "payment_details": {
          "modes": _paymentModes,
          "upiId": _upiIdController.text,
          "bankNameBranch": _bankNameController.text,
          "accountNumber": _accountNumberController.text,
          "ifscCode": _ifscCodeController.text,

          "payment_frequency": _paymentFrequency,
          "advance_required": _advanceRequired,
        },
        "notification_preferences": {
          "whatsapp": _whatsappNotifications,
          "sms": _smsNotifications,
          "call": _callNotifications,
          "preferred_time": _preferredTimeController.text,
          "language": _languageController.text,
        },
        "transport_charges": {
          "bikeBeyondKm":_bikeBeyondKmController.text,
          "freeFromDate": _freeFromDateController.text,
          "currentlyStationedAt": _currentlyStationedAtController.text,
          "pickupChargeDetails": _pickupChargeDetailsController.text,
          "bikeChargePerBike": _bikeChargePerBikeController.text,
        },

        // Other Fields
        "start_date": _startDate?.toIso8601String().split('T')[0],
        "end_date": _endDate?.toIso8601String().split('T')[0],
        "daily_work_timing": _dailyWorkTimingController.text,




        "number_of_children": int.tryParse(_numberOfChildrenController.text) ?? 0,
        "children_caretaker": _childrenCaretakerController.text,
        "max_travel_distance":_maxTravelDistanceController.text,
        "current_latitude": _latitudeController.text,
        "current_longitude": _longitudeController.text,

        //transport mode
        "transport_mode": _transportMode ?? "no_vehicle",
        "bikeBeyondKm":_bikeBeyondKmController.text,
        "freeFromDate": _freeFromDateController.text,
        "currentlyStationedAt": _currentlyStationedAtController.text,
        "pickupChargeDetails": _pickupChargeDetailsController.text,
        "bikeChargePerBike": _bikeChargePerBikeController.text,


        "work_mode": _workMode ?? "daily_up_down",
        "move_in_preferred_region": _moveInPreferredRegionController.text,
        "referral_source": _referralSourceController.text,
        "referred_by": _referredByController.text.isNotEmpty ? _referredByController.text : null,
        "referral_source_text": _referralSourceTextController.text,
        "other_commitments": _otherCommitmentsController.text,
        "aadhar_number": _aadharNumberController.text,
        "pan_number": _panNumberController.text,

        // Empty Lists for Required API Fields
        "preferred_work_locations": _preferredWorkLocationsListt,
      };

      // 2. Call the RegistrationService
     

      final response = await RegistrationService().registerMukkadam(
        mukkadamData: mukkadamData,
        authToken: s3AuthToken,
        profilePhotoPath: _profilePhotoPath,
        aadharCardPath: _aadharCardPath,
        panCardPath: _panCardPath,
        bankProofPath: _bankProofPath,
        locationCapturePath: _locationCapturePath,
      );

      // 3. Handle the response
      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration successful! ID: ${response['data']['id']}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: ${response['message']}')),
        );
      }
    }
  }


  // 3. Add this method to remove an entry
  void _removeWorkHistoryEntry(int index) {
    setState(() {
      _workHistoryList.removeAt(index);
    });
  }




  //rate Card

  // Controllers
  final TextEditingController _aprilPruningController = TextEditingController();
  final TextEditingController _bagalBaliFutRemovalController = TextEditingController();
  final TextEditingController _berryThinningController = TextEditingController();
  final TextEditingController _bunchSelectionController = TextEditingController();
  final TextEditingController _bunchThinningController = TextEditingController();
  final TextEditingController _bunchTyingController = TextEditingController();
  final TextEditingController _bunchVariationController = TextEditingController();
  final TextEditingController _defaultRateController = TextEditingController();
  final TextEditingController _fingerThinningController = TextEditingController();
  final TextEditingController _firstDippingController = TextEditingController();
  final TextEditingController _firstFailFutRemovalController = TextEditingController();
  final TextEditingController _harvestingController = TextEditingController();
  final TextEditingController _newPlantationController = TextEditingController();
  final TextEditingController _otherRateController = TextEditingController();
  final TextEditingController _paperRemovalController = TextEditingController();
  final TextEditingController _paperWrappingController = TextEditingController();
  final TextEditingController _pastingController = TextEditingController();
  final TextEditingController _pruningController = TextEditingController();
  final TextEditingController _secondDippingController = TextEditingController();
  final TextEditingController _secondFailFutRemovalController = TextEditingController();
  final TextEditingController _shendaToppingController = TextEditingController();
  final TextEditingController _shootTyingClipsController = TextEditingController();
  final TextEditingController _shootTyingStringsController = TextEditingController();
  final TextEditingController _thirdDippingController = TextEditingController();







  final TextEditingController _issueStateName = TextEditingController();
  final TextEditingController _issueStateCode = TextEditingController();
  final TextEditingController _issueDistrictName = TextEditingController();
  final TextEditingController _issueDistrictCode = TextEditingController();
  final TextEditingController _issueTalukaName = TextEditingController();
  final TextEditingController _issueTalukaCode = TextEditingController();



  // Controllers for Basic Details
  final TextEditingController _mukkadamNameController = TextEditingController();
  final TextEditingController _mobileNumbersController = TextEditingController();
  final TextEditingController _villageController = TextEditingController();
  final TextEditingController _crewSizeController = TextEditingController();

  final DataEntryService _locationService = DataEntryService();

// Lists to hold API data
  List<Map<String, dynamic>> _statesList = [];
  List<Map<String, dynamic>> _districtsList = [];
  List<Map<String, dynamic>> _talukasList = [];
  List<Map<String, dynamic>> _villagesList = [];


  // Work History Controllers
  final TextEditingController _workLocationController = TextEditingController();
  final TextEditingController _workStateController = TextEditingController();
  final TextEditingController _workStateCodeController = TextEditingController();
  final TextEditingController _workDistrictController = TextEditingController();
  final TextEditingController _workDistrictCodeController = TextEditingController();


  // Current Location Controllers
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _stateCodeController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _districtCodeController = TextEditingController();
  final TextEditingController _talukaController = TextEditingController();
  final TextEditingController _talukaCodeController = TextEditingController();
  final TextEditingController _villageCodeController = TextEditingController();

  // Home Location Controllers
  final TextEditingController _homeStateController = TextEditingController();
  final TextEditingController _homeStateCodeController = TextEditingController();
  final TextEditingController _homeDistrictController = TextEditingController();
  final TextEditingController _homeDistrictCodeController = TextEditingController();
  final TextEditingController _homeTalukaController = TextEditingController();
  final TextEditingController _homeTalukaCodeController = TextEditingController();
  final TextEditingController _homeVillageController = TextEditingController();
  final TextEditingController _homeVillageCodeController = TextEditingController();
  final TextEditingController _issueVillageName = TextEditingController();
  final TextEditingController _issueVillageCode = TextEditingController();
  List<Map<String, dynamic>> _issueVillagesList = [];
  List<Map<String, dynamic>> _workStatesList = [];
  List<Map<String, dynamic>> _workDistrictsList = [];


  @override
  void initState() {
    super.initState();
    _loadStates();
    _loadHomeStates();
    _loadWorkStates();
    _fetchReferralSources();
    _loadIssueStates();
  }

  Future<void> _loadIssueStates() async {
    final data = await _locationService.getStates();
    setState(() => _issueStatesList = data);
  }


  void _handleIssueStateSelection(Map<String, dynamic>? selection) async {
    if (selection == null) return;
    setState(() {
      _isIssueLocationLoading = true;
      _issueStateName.text = selection['state_name_english'];
      _issueStateCode.text = selection['state_code'].toString();
      _issueDistrictsList = []; _issueTalukasList = []; _issueVillagesList = [];
      _issueDistrictCode.clear(); _issueTalukaCode.clear(); _issueVillageCode.clear();
    });
    try {
      final districts = await _locationService.getDistricts(_issueStateCode.text);
      setState(() => _issueDistrictsList = districts);
    } finally {
      setState(() => _isIssueLocationLoading = false);
    }
  }

  void _handleIssueDistrictSelection(Map<String, dynamic>? selection) async {
    if (selection == null) return;
    setState(() {
      _isIssueLocationLoading = true;
      _issueDistrictName.text = selection['districtnameenglish'];
      _issueDistrictCode.text = selection['districtcode'].toString();
      _issueTalukasList = []; _issueVillagesList = [];
      _issueTalukaCode.clear(); _issueVillageCode.clear();
    });
    try {
      final talukas = await _locationService.getTalukas(_issueStateCode.text, _issueDistrictCode.text);
      setState(() => _issueTalukasList = talukas);
    } finally {
      setState(() => _isIssueLocationLoading = false);
    }
  }

  void _handleIssueTalukaSelection(Map<String, dynamic>? selection) async {
    if (selection == null) return;
    setState(() {
      _isIssueLocationLoading = true;
      _issueTalukaName.text = selection['subdistrictnameenglish'];
      _issueTalukaCode.text = selection['subdistrictcode'].toString();
      _issueVillagesList = [];
      _issueVillageName.clear();
      _issueVillageCode.clear();
    });
    try {
      final data = await _locationService.getVillages(_issueStateCode.text, _issueTalukaCode.text);
      setState(() => _issueVillagesList = data);
    } finally {
      setState(() => _isIssueLocationLoading = false);
    }
  }

  void _handleIssueVillageSelection(Map<String, dynamic>? selection) {
    if (selection == null) return;
    setState(() {
      _issueVillageName.text = selection['villagenameenglish'];
      _issueVillageCode.text = selection['villagecode'].toString();
    });
  }



  Future<void> _loadWorkStates() async {
    try {
      final data = await _locationService.getStates();
      setState(() => _workStatesList = data);
    } catch (e) {
      print("Error loading work states: $e");
    }
  }

  // 1. Define these controllers and lists in your _MukkadamRegistrationScreenState if not already present:
  // final TextEditingController _workTalukaController = TextEditingController();
  // final TextEditingController _workTalukaCodeController = TextEditingController();
  // List<Map<String, dynamic>> _workTalukasList = [];
  // bool _isWorkLocationLoading = false;
  void _handleWorkStateSelection(Map<String, dynamic>? selection) async {
    if (selection == null) return;

    setState(() {
      _isWorkLocationLoading = true;
      _workStateController.text = selection['state_name_english'];
      _workStateCodeController.text = selection['state_code'].toString();

      // Reset all downstream levels
      _workDistrictController.clear();
      _workDistrictCodeController.clear();
      _workDistrictsList = [];

      _workTalukaController.clear();
      _workTalukaCodeController.clear();
      _workTalukasList = [];

      _workVillageController.clear();
      _workVillageCodeController.clear();
      _workVillagesList = [];
    });

    try {
      final districts = await _locationService.getDistricts(_workStateCodeController.text);
      setState(() => _workDistrictsList = districts);
    } catch (e) {
      print("Error loading work districts: $e");
    } finally {
      setState(() => _isWorkLocationLoading = false);
    }
  }

  void _handleWorkDistrictSelection(Map<String, dynamic>? selection) async {
    if (selection == null) return;

    setState(() {
      _isWorkLocationLoading = true;
      _workDistrictController.text = selection['districtnameenglish'];
      _workDistrictCodeController.text = selection['districtcode'].toString();

      // Reset downstream
      _workTalukaController.clear();
      _workTalukaCodeController.clear();
      _workTalukasList = [];

      _workVillageController.clear();
      _workVillageCodeController.clear();
      _workVillagesList = [];
    });

    try {
      final talukas = await _locationService.getTalukas(
          _workStateCodeController.text,
          _workDistrictCodeController.text
      );
      setState(() => _workTalukasList = talukas);
    } catch (e) {
      print("Error loading work talukas: $e");
    } finally {
      setState(() => _isWorkLocationLoading = false);
    }
  }

  void _handleWorkTalukaSelection(Map<String, dynamic>? selection) async {
    if (selection == null) return;

    setState(() {
      _isWorkLocationLoading = true;
      _workTalukaController.text = selection['subdistrictnameenglish'];
      _workTalukaCodeController.text = selection['subdistrictcode'].toString();

      // Reset village level
      _workVillageController.clear();
      _workVillageCodeController.clear();
      _workVillagesList = [];
    });

    try {
      final villages = await _locationService.getVillages(
          _workStateCodeController.text,
          _workTalukaCodeController.text
      );
      setState(() => _workVillagesList = villages);
    } catch (e) {
      print("Error loading work villages: $e");
    } finally {
      setState(() => _isWorkLocationLoading = false);
    }
  }

  void _handleWorkVillageSelection(Map<String, dynamic>? selection) {
    if (selection == null) return;
    setState(() {
      _workVillageController.text = selection['villagenameenglish'] ?? '';
      _workVillageCodeController.text = selection['villagecode']?.toString() ?? '';
    });
  }
// Add this handler for Location Issues Village












// --- WORK HISTORY HANDLERS ---




// --- WORK HISTORY HANDLERS ---














  Future<void> _loadHomeStates() async {
    try {
      final data = await _locationService.getStates();
      setState(() => _homeStatesList = data);
    } catch (e) {
      print("Error loading home states: $e");
    }
  }

  Future<void> _loadStates() async {
    try {
      final data = await _locationService.getStates();
      setState(() => _statesList = data);
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> _fetchReferralSources() async {
    try {
      // Getting the token from OtpApiService which loads it from SharedPreferences
      final String? token = OtpApiService.sessionToken;

      if (token == null) {
        print("No authorization token found");
        return;
      }

      final response = await http.get(
        Uri.parse('https://supply.bharatintelligence.ai/api/mukkadam/dropdown_list/'),
        headers: {
          'Authorization': 'Token $mainToken',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _referralOptions = jsonDecode(response.body);
          print(_referralOptions);
        });
      } else {
        print("Failed to load referrals: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching referrals: $e");
    }
  }


// Example for Current Location (Repeat logic for Home Location)
  // --- Current Location Handlers ---











// Repeat this pattern for _handleHomeStateSelection, _handleHomeDistrictSelection, etc.


  bool _isPermanent = false;
  String? _hasSmartphone = 'yes';

  final TextEditingController _workTalukaController = TextEditingController();
  final TextEditingController _workTalukaCodeController = TextEditingController();

  // Work History Lists


  // Loading state for Work History
  //bool _isWorkLocationLoading = false;

  bool _isWorkLocationLoading = false;


  List<dynamic> _referralOptions = [];
  dynamic _selectedReferral;


  String? _locationCapturePath;
  double? _capturedLat;
  double? _capturedLong;


  // Lists for Home Location dropdowns
  List<Map<String, dynamic>> _homeStatesList = [];
  List<Map<String, dynamic>> _homeDistrictsList = [];
  List<Map<String, dynamic>> _homeTalukasList = [];
  List<Map<String, dynamic>> _homeVillagesList = [];

  //caputure location

  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  // Controllers for Crew Details
  final TextEditingController _maxCrewCapacityController = TextEditingController();
  final TextEditingController _splittingLogicController = TextEditingController();
  final TextEditingController _deputyMukkadamNameController = TextEditingController();
  final TextEditingController _deputyMukkadamMobileController = TextEditingController();
  final TextEditingController _teamMemberNameController = TextEditingController();
  final TextEditingController _teamMemberAgeController = TextEditingController();
  String? _teamMemberGender;
  final TextEditingController _teamMemberMobileController = TextEditingController();
  final TextEditingController _teamMemberAadharController = TextEditingController();
  // For multiple team members, you'd manage a List of objects/controllers
  final List<Map<String, dynamic>> _teamMembers = [];
  final List<Map<String, dynamic>> _workHistory = []; // Placeholder for work history
  final List<Map<String, dynamic>> _teamAvailabilities = []; // Placeholder for team availabilities

  // Controllers for Children Details
  final TextEditingController _numberOfChildrenController = TextEditingController();
  final TextEditingController _childrenCaretakerController = TextEditingController();

  // Controllers for Availability
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _startDateTextController = TextEditingController(); // New controller
  final TextEditingController _endDateTextController = TextEditingController();   // New controller
  final TextEditingController _dailyWorkTimingController = TextEditingController();

  // Controllers for Rate Card
  final TextEditingController _pruningRateController = TextEditingController();
  final TextEditingController _pastingRateController = TextEditingController();
  final TextEditingController _harvestingRateController = TextEditingController();
  //final TextEditingController _defaultRateController = TextEditingController();

  // Controllers for Location Issues (individual fields, but will be aggregated into an array for API)
  final TextEditingController _issueVillageController = TextEditingController();
  final TextEditingController _issueDistrictController = TextEditingController();
  final TextEditingController _issueReasonController = TextEditingController();
  String? _issueSeverity;
  final List<Map<String, dynamic>> _locationIssues = []; // Placeholder for multiple location issues

  // Controllers for Work Area Preference
  final TextEditingController _homeLocationController = TextEditingController();
  final TextEditingController _preferredWorkLocationsController = TextEditingController();
  final TextEditingController _maxTravelDistanceController = TextEditingController();

  // Change these from Controllers to Lists
  List<Map<String, dynamic>> _preferredWorkLocationsListt = [];
  List<String> _maxTravelDistancesListt = [];




  // Controllers for Transport Details
  String? _transportMode;
  String? _transportArrangedBy;
  final TextEditingController _perKmChargeController = TextEditingController();
  final TextEditingController _dailyRateChargeController = TextEditingController();
  bool _includesFuel = false;

  // Controllers for Payment Details
  String? _paymentMode;
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _ifscCodeController = TextEditingController();
  final TextEditingController _upiIdController = TextEditingController();
  String? _paymentFrequency;
  bool _advanceRequired = false;

  // Controllers for Work Mode
  String? _workMode;
  final TextEditingController _moveInPreferredRegionController = TextEditingController();

  // Controllers for Referral
  final TextEditingController _referralSourceController = TextEditingController();
  final TextEditingController _referredByController = TextEditingController();
  final TextEditingController _referralSourceTextController = TextEditingController();

  // Controllers for Notification Preferences
  bool _whatsappNotifications = false;
  bool _smsNotifications = false;
  bool _callNotifications = false;
  final TextEditingController _preferredTimeController = TextEditingController();
  final TextEditingController _languageController = TextEditingController();

  // Controllers for Other Info
  final TextEditingController _otherCommitmentsController = TextEditingController();

  // Controllers for ID Numbers
  final TextEditingController _aadharNumberController = TextEditingController();
  final TextEditingController _panNumberController = TextEditingController();





  // File paths (will be populated by a file picker, currently placeholders)
  String? _profilePhotoPath;
  String? _aadharCardPath;
  String? _panCardPath;
  String? _bankProofPath;

  bool _isIssueLocationLoading = false;


  @override
  void dispose() {
    _mukkadamNameController.dispose();
    _mobileNumbersController.dispose();
    _villageController.dispose();
    _crewSizeController.dispose();
    _issueTalukaCode.dispose();


    //rate card

    _aprilPruningController.dispose();
    _bagalBaliFutRemovalController.dispose();
    _berryThinningController.dispose();
    _bunchSelectionController.dispose();
    _bunchThinningController.dispose();
    _bunchTyingController.dispose();
    _bunchVariationController.dispose();
    _defaultRateController.dispose();
    _fingerThinningController.dispose();
    _firstDippingController.dispose();
    _firstFailFutRemovalController.dispose();
    _harvestingController.dispose();
    _newPlantationController.dispose();
    _otherRateController.dispose();
    _paperRemovalController.dispose();
    _paperWrappingController.dispose();
    _pastingController.dispose();
    _pruningController.dispose();
    _secondDippingController.dispose();
    _secondFailFutRemovalController.dispose();
    _shendaToppingController.dispose();
    _shootTyingClipsController.dispose();
    _shootTyingStringsController.dispose();
    _thirdDippingController.dispose();

    _bikeBeyondKmController.dispose();
    _freeFromDateController.dispose();
    _bikeChargePerBikeController.dispose();
    _pickupChargeDetailsController.dispose();
    _currentlyStationedAtController.dispose();

    // ADD THESE TWO LINES:
    _issueVillageName.dispose();
    _issueVillageCode.dispose();

    _workTalukaController.dispose();
    _workTalukaCodeController.dispose();

    _mukkadamNameController.dispose();
    _maxCrewCapacityController.dispose();
    _splittingLogicController.dispose();
    _deputyMukkadamNameController.dispose();
    _deputyMukkadamMobileController.dispose();
    _teamMemberNameController.dispose();
    _teamMemberAgeController.dispose();
    _teamMemberMobileController.dispose();
    _teamMemberAadharController.dispose();
    _numberOfChildrenController.dispose();
    _childrenCaretakerController.dispose();
    _startDateTextController.dispose(); // Dispose new controller
    _endDateTextController.dispose();   // Dispose new controller
    _dailyWorkTimingController.dispose();
    _pruningRateController.dispose();
    _pastingRateController.dispose();
    _harvestingRateController.dispose();
    _defaultRateController.dispose();
    _issueVillageController.dispose();
    _issueDistrictController.dispose();
    _issueReasonController.dispose();
    _homeLocationController.dispose();
    _preferredWorkLocationsController.dispose();
    _maxTravelDistanceController.dispose();
    _perKmChargeController.dispose();
    _dailyRateChargeController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ifscCodeController.dispose();
    _upiIdController.dispose();
    _moveInPreferredRegionController.dispose();
    _referralSourceController.dispose();
    _referredByController.dispose();
    _referralSourceTextController.dispose();
    _preferredTimeController.dispose();
    _languageController.dispose();
    _otherCommitmentsController.dispose();
    _aadharNumberController.dispose();
    _panNumberController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  bool _isHomeLocationLoading = false;

  Future<void> _selectFreeFromDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _freeFromDateController.text = picked.toIso8601String().split('T')[0];
      });
    }
  }




  Future<void> _fetchGPSCoordinates() async {
    try {
      // Calling your existing function to determine position
      final position = await determinePosition();
      setState(() {
        _latitudeController.text = position.latitude.toStringAsFixed(6);
        _longitudeController.text = position.longitude.toStringAsFixed(6);
        _capturedLat = position.latitude;
        _capturedLong = position.longitude;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coordinates fetched successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching location: $e')),
      );
    }
  }

  Future<void> _captureLocationPhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.camera);

    if (file != null) {
      setState(() {
        _locationCapturePath = file.path;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location photo captured!')),
      );
    }
  }








  Future<void> _selectDate(BuildContext context, {required bool isStart}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          _startDateTextController.text = '${_startDate!.toLocal()}'.split(' ')[0]; // Update controller text
        } else {
          _endDate = picked;
          _endDateTextController.text = '${_endDate!.toLocal()}'.split(' ')[0];     // Update controller text
        }
      });
    }
  }

  // Modified _pickFile function to use image_picker
  Future<void> _pickFile(String fileType, ImageSource source) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? file = await _picker.pickImage(source: source);

    if (file != null) {
      setState(() {
        if (fileType == 'profile_photo') {
          _profilePhotoPath = file.path;
        } else if (fileType == 'aadhar_card') {
          _aadharCardPath = file.path;
        } else if (fileType == 'pan_card') {
          _panCardPath = file.path;
        } else if (fileType == 'bank_proof') {
          _bankProofPath = file.path;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$fileType ${source == ImageSource.camera ? "captured" : "selected"}: ${file.path.split('/').last}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No $fileType ${source == ImageSource.camera ? "captured" : "selected"}.')),
      );
    }
  }


  // --- CURRENT LOCATION HANDLERS ---
  void _handleStateSelection(Map<String, dynamic>? selection) async {
    if (selection == null) return;
    setState(() {
      _isLocationLoading = true; // Start Loading
      _stateController.text = selection['state_name_english'];
      _stateCodeController.text = selection['state_code'].toString();
      _districtsList = []; _talukasList = []; _villagesList = [];
      _districtController.clear(); _districtCodeController.clear();
      _talukaController.clear(); _talukaCodeController.clear();
      _villageController.clear(); _villageCodeController.clear();
    });
    try {
      final data = await _locationService.getDistricts(_stateCodeController.text);
      setState(() => _districtsList = data);
    } finally {
      setState(() => _isLocationLoading = false); // Stop Loading
    }
  }

  void _handleDistrictSelection(Map<String, dynamic>? selection) async {
    if (selection == null) return;
    setState(() {
      _isLocationLoading = true; // Start Loading
      _districtController.text = selection['districtnameenglish'];
      _districtCodeController.text = selection['districtcode'].toString();
      _talukasList = []; _villagesList = [];
      _talukaController.clear(); _talukaCodeController.clear();
      _villageController.clear(); _villageCodeController.clear();
    });
    try {
      final data = await _locationService.getTalukas(_stateCodeController.text, _districtCodeController.text);
      setState(() => _talukasList = data);
    } finally {
      setState(() => _isLocationLoading = false); // Stop Loading
    }
  }

  void _handleTalukaSelection(Map<String, dynamic>? selection) async {
    if (selection == null) return;
    setState(() {
      _isLocationLoading = true; // Start Loading
      _talukaController.text = selection['subdistrictnameenglish'];
      _talukaCodeController.text = selection['subdistrictcode'].toString();
      _villagesList = [];
      _villageController.clear(); _villageCodeController.clear();
    });
    try {
      final data = await _locationService.getVillages(_stateCodeController.text, _talukaCodeController.text);
      setState(() => _villagesList = data);
    } finally {
      setState(() => _isLocationLoading = false); // Stop Loading
    }
  }


  void _handleVillageSelection(Map<String, dynamic>? selection) {
    if (selection == null) return;
    setState(() {
      _villageController.text = selection['villagenameenglish'] ?? '';
      _villageCodeController.text = selection['villagecode']?.toString() ?? '';
    });
  }







  Future<void> _handleLocationCapture() async {
    try {
      // Get Coordinates
      final position = await determinePosition();

      // Open Camera
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: ImageSource.camera);

      if (file != null) {
        setState(() {
          _locationCapturePath = file.path;
          _latitudeController.text = position.latitude.toStringAsFixed(6);
          _longitudeController.text = position.longitude.toStringAsFixed(6);
          _capturedLat = position.latitude;
          _capturedLong = position.longitude;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo and GPS coordinates captured successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }


  void _handleHomeStateSelection(Map<String, dynamic>? selection) async {
    if (selection == null) return;
    setState(() {
      _isHomeLocationLoading = true; // Start Loading
      _homeStateController.text = selection['state_name_english'];
      _homeStateCodeController.text = selection['state_code'].toString();
      _homeDistrictsList = []; _homeTalukasList = []; _homeVillagesList = [];
      _homeDistrictController.clear(); _homeDistrictCodeController.clear();
      _homeTalukaController.clear(); _homeTalukaCodeController.clear();
      _homeVillageController.clear(); _homeVillageCodeController.clear();
    });
    try {
      final data = await _locationService.getDistricts(_homeStateCodeController.text);
      setState(() => _homeDistrictsList = data);
    } finally {
      setState(() => _isHomeLocationLoading = false); // Stop Loading
    }
  }

  void _handleHomeDistrictSelection(Map<String, dynamic>? selection) async {
    if (selection == null) return;
    setState(() {
      _isHomeLocationLoading = true; // Start Loading
      _homeDistrictController.text = selection['districtnameenglish'];
      _homeDistrictCodeController.text = selection['districtcode'].toString();
      _homeTalukasList = []; _homeVillagesList = [];
      _homeTalukaController.clear(); _homeTalukaCodeController.clear();
      _homeVillageController.clear(); _homeVillageCodeController.clear();
    });
    try {
      final data = await _locationService.getTalukas(_homeStateCodeController.text, _homeDistrictCodeController.text);
      setState(() => _homeTalukasList = data);
    } finally {
      setState(() => _isHomeLocationLoading = false); // Stop Loading
    }
  }

  void _handleHomeTalukaSelection(Map<String, dynamic>? selection) async {
    if (selection == null) return;
    setState(() {
      _isHomeLocationLoading = true; // Start Loading
      _homeTalukaController.text = selection['subdistrictnameenglish'];
      _homeTalukaCodeController.text = selection['subdistrictcode'].toString();
      _homeVillagesList = [];
      _homeVillageController.clear(); _homeVillageCodeController.clear();
    });
    try {
      final data = await _locationService.getVillages(_homeStateCodeController.text, _homeTalukaCodeController.text);
      setState(() => _homeVillagesList = data);
    } finally {
      setState(() => _isHomeLocationLoading = false); // Stop Loading
    }
  }

  void _handleHomeVillageSelection(Map<String, dynamic>? selection) {
    if (selection == null) return;
    setState(() {
      _homeVillageController.text = selection['villagenameenglish'] ?? '';
      _homeVillageCodeController.text = selection['villagecode']?.toString() ?? '';
    });
  }













  // Inside _MukkadamRegistrationScreenState class in lib/main.dart
// This is the modified _submitForm function.






      @override
      Widget build(BuildContext context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Mukkadam Registration'),
            centerTitle: true,
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              children: [
                ExpansionTile(
                  title: const Text('Basic Details', style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
                  children: [
                    BasicDetailsSection(
                      mukkadamNameController: _mukkadamNameController,
                      mobileNumbersController: _mobileNumbersController,
                      villageController: _villageController,
                      crewSizeController: _crewSizeController,
                      isPermanent: _isPermanent,
                      onIsPermanentChanged: (bool? value) {
                        setState(() {
                          _isPermanent = value ?? false;
                        });
                      },
                      hasSmartphone: _hasSmartphone,
                      onHasSmartphoneChanged: (String? value) {
                        setState(() {
                          _hasSmartphone = value;
                        });
                      },
                    ),
                  ],
                ),
                ExpansionTile(
                  title: const Text('Crew Details', style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
                  children: [

                    CrewDetailsSection(
                      maxCrewCapacityController: _maxCrewCapacityController,
                      splittingLogicController: _splittingLogicController,
                      deputyMukkadamNameController: _deputyMukkadamNameController,
                      deputyMukkadamMobileController: _deputyMukkadamMobileController,
                      teamMemberNameController: _teamMemberNameController,
                      teamMemberAgeController: _teamMemberAgeController,
                      teamMemberGender: _teamMemberGender,
                      onTeamMemberGenderChanged: (val) => setState(() => _teamMemberGender = val),
                      teamMemberMobileController: _teamMemberMobileController,
                      teamMemberAadharController: _teamMemberAadharController,
                      teamMembers: _teamMembersList, // Pass the array
                      onAddMember: _addTeamMember,   // Pass the helper
                      onRemoveMember: _removeTeamMember, // Pass the helper
                    ),


                  ],
                ),
                ExpansionTile(
                  title: const Text('Children Details', style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
                  children: [
                    ChildrenDetailsSection(
                      numberOfChildrenController: _numberOfChildrenController,
                      childrenCaretakerController: _childrenCaretakerController,
                    ),
                  ],
                ),
                ExpansionTile(
                  title: const Text('Availability', style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
                  children: [
                    AvailabilitySection(
                      startDateController: _startDateTextController,
                      // Pass the new controller
                      onSelectStartDate: () =>
                          _selectDate(context, isStart: true),
                      endDateController: _endDateTextController,
                      // Pass the new controller
                      onSelectEndDate: () =>
                          _selectDate(context, isStart: false),
                      dailyWorkTimingController: _dailyWorkTimingController,
                    ),
                  ],
                ),

                ExpansionTile(
                  title: const Text('Current Address Details', style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
                  children: [

                    AddressHierarchySection(
                      title: "Current Location",
                      stateName: _stateController,
                      stateCode: _stateCodeController,
                      districtName: _districtController,
                      districtCode: _districtCodeController,
                      talukaName: _talukaController,
                      talukaCode: _talukaCodeController,
                      villageName: _villageController,
                      villageCode: _villageCodeController,
                      states: _statesList,
                      districts: _districtsList,
                      talukas: _talukasList,
                      villages: _villagesList,
                      onStateChanged: _handleStateSelection,
                      onDistrictChanged: _handleDistrictSelection,
                      onTalukaChanged: _handleTalukaSelection,
                      onVillageChanged: _handleVillageSelection,
                      isLoading: _isLocationLoading, // Pass the loading state here
                    ),





                  ],
                ),

                ExpansionTile(
                  title: const Text('Home Address Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  children: [
                    AddressHierarchySection(
                      title: "Permanent Home Location",
                      stateName: _homeStateController,
                      stateCode: _homeStateCodeController,
                      districtName: _homeDistrictController,
                      districtCode: _homeDistrictCodeController,
                      talukaName: _homeTalukaController,
                      talukaCode: _homeTalukaCodeController,
                      villageName: _homeVillageController,
                      villageCode: _homeVillageCodeController,
                      states: _homeStatesList,
                      districts: _homeDistrictsList,
                      talukas: _homeTalukasList,
                      villages: _homeVillagesList,
                      onStateChanged: _handleHomeStateSelection,
                      onDistrictChanged: _handleHomeDistrictSelection,
                      onTalukaChanged: _handleHomeTalukaSelection,
                      onVillageChanged: _handleHomeVillageSelection,
                      isLoading: _isHomeLocationLoading,

                    ),
                  ],
                ),



                ExpansionTile(
                  title: const Text('Rate Card', style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
                  children: [
                    RateCardSection(
                      aprilPruningController: _aprilPruningController,
                      bagalBaliFutRemovalController: _bagalBaliFutRemovalController,
                      berryThinningController: _berryThinningController,
                      bunchSelectionController: _bunchSelectionController,
                      bunchThinningController: _bunchThinningController,
                      bunchTyingController: _bunchTyingController,
                      bunchVariationController: _bunchVariationController,
                      defaultRateController: _defaultRateController,
                      fingerThinningController: _fingerThinningController,
                      firstDippingController: _firstDippingController,
                      firstFailFutRemovalController: _firstFailFutRemovalController,
                      harvestingController: _harvestingController,
                      newPlantationController: _newPlantationController,
                      otherRateController: _otherRateController,
                      paperRemovalController: _paperRemovalController,
                      paperWrappingController: _paperWrappingController,
                      pastingController: _pastingController,
                      pruningController: _pruningController,
                      secondDippingController: _secondDippingController,
                      secondFailFutRemovalController: _secondFailFutRemovalController,
                      shendaToppingController: _shendaToppingController,
                      shootTyingClipsController: _shootTyingClipsController,
                      shootTyingStringsController: _shootTyingStringsController,
                      thirdDippingController: _thirdDippingController,
                    ),
                  ],
                ),


                // Inside your build method's ExpansionTile for Referral Information
                ExpansionTile(
                  title: const Text('Referral Information', style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
                  children: [
                    ReferralSection(
                      // Adding a key based on list length can help force a refresh when data arrives
                      key: ValueKey(_referralOptions.length),
                      referralOptions: _referralOptions,
                      selectedReferral: _selectedReferral,
                      onReferralChanged: (dynamic value) {
                        setState(() {
                          _selectedReferral = value;
                          // Fill the ID into the controller
                          _referredByController.text =
                              value['id']?.toString() ?? '';
                          // Optional: fill the name into the source controller if needed
                          _referralSourceController.text =
                              value['mukkadam_name']?.toString() ?? '';
                        });
                      },
                      referredByController: _referredByController,
                      referralSourceTextController: _referralSourceTextController,
                    ),
                  ],
                ),

                ExpansionTile(
                  title: const Text('Work History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  children: [

                    WorkHistorySection(
                      locationController: _workLocationController,
                      states: _workStatesList,
                      districts: _workDistrictsList,
                      talukas: _workTalukasList, // Pass this
                      villages: _workVillagesList,
                      selectedStateCode: _workStateCodeController.text,
                      selectedDistrictCode: _workDistrictCodeController.text,
                      selectedTalukaCode: _workTalukaCodeController.text, // Pass this
                      selectedVillageCode: _workVillageCodeController.text,
                      onStateChanged: _handleWorkStateSelection,
                      onDistrictChanged: _handleWorkDistrictSelection,
                      onTalukaChanged: _handleWorkTalukaSelection, // Pass this
                      onVillageChanged: _handleWorkVillageSelection,
                      currentList: _workHistoryList,
                      onAdd: _addWorkHistoryEntry,
                      onRemove: _removeWorkHistoryEntry,
                      isLoading: _isWorkLocationLoading, // Pass the loading state
                    ),


                  ],
                ),




                ExpansionTile(
                  title: const Text('Capture Location', style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
                  children: [
                    CaptureLocationSection(
                      latitudeController: _latitudeController,
                      longitudeController: _longitudeController,
                      onFetchLocation: _fetchGPSCoordinates,
                      onCapturePhoto: _captureLocationPhoto,
                      capturedImagePath: _locationCapturePath,
                    ),
                  ],
                ),

                ExpansionTile(
                  title: const Text('Location Issues', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  children: [
                    LocationIssuesSection(
                      states: _issueStatesList,
                      districts: _issueDistrictsList,
                      talukas: _issueTalukasList,
                      villages: _issueVillagesList, // Added
                      selectedStateCode: _issueStateCode.text,
                      selectedDistrictCode: _issueDistrictCode.text,
                      selectedTalukaCode: _issueTalukaCode.text,
                      selectedVillageCode: _issueVillageCode.text, // Added
                      issueSeverity: _issueSeverity,
                      reasonController: _issueReasonController,
                      onStateChanged: _handleIssueStateSelection,
                      onDistrictChanged: _handleIssueDistrictSelection,
                      onTalukaChanged: _handleIssueTalukaSelection,
                      onVillageChanged: _handleIssueVillageSelection, // Added
                      onIssueSeverityChanged: (val) => setState(() => _issueSeverity = val),
                      currentList: _locationIssuesList,
                      onAdd: _addLocationIssue,
                      onRemove: _removeLocationIssue,
                      isLoading: _isIssueLocationLoading, // Added
                    ),

                  ],
                ),

                // 1. Remove the separate ExpansionTiles for "Work History" and "Location Issues"
// 2. Replace the "Work Area Preference" ExpansionTile with this:

                ExpansionTile(
                  title: const Text(
                    'Work Area & Preferences',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  children: [
                    WorkAreaPreferenceSection(
                      homeLocationController: _homeLocationController,
                      preferredWorkLocations: _preferredWorkLocationsListt, // Use the List variable from your state
                      maxTravelDistanceController: _maxTravelDistanceController, // Correct parameter name
                      workHistory: _workHistoryList,
                      locationIssues: _locationIssuesList,
                    ),
                  ],
                ),









                ExpansionTile(
                  title: const Text('Transport Details', style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
                  children: [
                    TransportDetailsSection(
                      transportMode: _transportMode,
                      onTransportModeChanged: (String? value) {
                        setState(() {
                          _transportMode = value;
                        });
                      },
                      perKmChargeController: _perKmChargeController,
                      dailyRateChargeController: _dailyRateChargeController,
                      bikeBeyondKmController: _bikeBeyondKmController,
                      freeFromDateController: _freeFromDateController,
                      bikeChargePerBikeController: _bikeChargePerBikeController,
                      pickupChargeDetailsController: _pickupChargeDetailsController,
                      currentlyStationedAtController: _currentlyStationedAtController,
                      onSelectFreeDate: _selectFreeFromDate,
                      includesFuel: _includesFuel,
                      onIncludesFuelChanged: (bool? value) {
                        setState(() {
                          _includesFuel = value ?? false;
                        });
                      },
                    ),

                  ],
                ),
                ExpansionTile(
                  title: const Text('Payment Details', style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
                  children: [
                    PaymentDetailsSection(
                      paymentModes: _paymentModes,
                      onModeChanged: (String mode, bool value) {
                        setState(() {
                          _paymentModes[mode] = value;
                        });
                      },
                      bankNameController: _bankNameController,
                      accountNumberController: _accountNumberController,
                      ifscCodeController: _ifscCodeController,
                      upiIdController: _upiIdController,
                      paymentFrequency: _paymentFrequency,
                      onPaymentFrequencyChanged: (String? value) {
                        setState(() {
                          _paymentFrequency = value;
                        });
                      },
                      advanceRequired: _advanceRequired,
                      onAdvanceRequiredChanged: (bool? value) {
                        setState(() {
                          _advanceRequired = value ?? false;
                        });
                      },
                    ),
                  ],
                ),
                ExpansionTile(
                  title: const Text('Work Mode', style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
                  children: [
                    WorkModeSection(
                      workMode: _workMode,
                      onWorkModeChanged: (String? value) {
                        setState(() {
                          _workMode = value;
                        });
                      },
                      moveInPreferredRegionController: _moveInPreferredRegionController,
                    ),
                  ],
                ),

                ExpansionTile(
                  title: const Text('Notification Preferences',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  children: [
                    NotificationPreferencesSection(
                      whatsappNotifications: _whatsappNotifications,
                      onWhatsappNotificationsChanged: (bool? value) {
                        setState(() {
                          _whatsappNotifications = value ?? false;
                        });
                      },
                      smsNotifications: _smsNotifications,
                      onSmsNotificationsChanged: (bool? value) {
                        setState(() {
                          _smsNotifications = value ?? false;
                        });
                      },
                      callNotifications: _callNotifications,
                      onCallNotificationsChanged: (bool? value) {
                        setState(() {
                          _callNotifications = value ?? false;
                        });
                      },
                      preferredTimeController: _preferredTimeController,
                      languageController: _languageController,
                    ),
                  ],
                ),
                ExpansionTile(
                  title: const Text('Other Information', style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
                  children: [
                    OtherInfoSection(
                      otherCommitmentsController: _otherCommitmentsController,
                    ),
                  ],
                ),
                ExpansionTile(
                  title: const Text('ID Numbers', style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
                  children: [
                    IDNumbersSection(
                      aadharNumberController: _aadharNumberController,
                      panNumberController: _panNumberController,
                    ),
                  ],
                ),

                ExpansionTile(
                  title: const Text('File Uploads (Optional)', style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
                  children: [
                    FileUploadsSection(
                      onUploadProfilePhoto: () =>
                          _pickFile('profile_photo', ImageSource.gallery),
                      onCaptureProfilePhoto: () =>
                          _pickFile('profile_photo', ImageSource.camera),
                      onUploadAadharCard: () =>
                          _pickFile('aadhar_card', ImageSource.gallery),
                      onCaptureAadharCard: () =>
                          _pickFile('aadhar_card', ImageSource.camera),
                      onUploadPanCard: () =>
                          _pickFile('pan_card', ImageSource.gallery),
                      onCapturePanCard: () =>
                          _pickFile('pan_card', ImageSource.camera),
                      onUploadBankProof: () =>
                          _pickFile('bank_proof', ImageSource.gallery),
                      onCaptureBankProof: () =>
                          _pickFile('bank_proof', ImageSource.camera),
                    ),
                  ],
                ),


                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 18),
                      textStyle: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Register Mukkadam'),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      }
    }



