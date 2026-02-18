// lib/seeplan/plan_service_model.dart

import 'dart:convert';

class VillageVisitPlan {
  final String id;
  final String planName;
  final String startDate;
  final String endDate;
  final List<DailyPlan> dailyPlans;
  final String status;
  final String statusDisplay;
  final String purpose;
  String? marathiPlanName;

  VillageVisitPlan({
    required this.id,
    required this.planName,
    required this.startDate,
    required this.endDate,
    required this.dailyPlans,
    required this.status,
    required this.statusDisplay,
    required this.purpose,
    this.marathiPlanName,
  });

  String getDisplayName(String lang) {
    if (lang == 'mr' && marathiPlanName != null && marathiPlanName!.isNotEmpty) {
      return marathiPlanName!;       // Marathi only
    }
    return planName;                  // English only
  }

  // Keep old getter for backward compat if needed elsewhere
  String get displayName => planName;


  factory VillageVisitPlan.fromJson(Map<String, dynamic> json) {
    return VillageVisitPlan(
      id: json['id']?.toString() ?? '',
      purpose: json['"purpose"']?.toString() ?? '',
      planName: json['plan_name']?.toString() ?? '',
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      statusDisplay: json['status_display']?.toString() ??
          (json['status']?.toString() ?? ''),
      dailyPlans: json['daily_plans'] != null
          ? (json['daily_plans'] as List)
          .map((i) => DailyPlan.fromJson(i))
          .toList()
          : [],
    );
  }
}

class DailyPlan {
  final String id;
  final String visitDate;
  final String purpose;
  final String status;
  final String statusDisplay;
  final List<VillageVisit> villageVisits;

  DailyPlan({
    required this.id,
    required this.visitDate,
    required this.purpose,
    required this.status,
    required this.statusDisplay,
    required this.villageVisits,
  });

  factory DailyPlan.fromJson(Map<String, dynamic> json) {
    String visitDateStr = json['visit_date']?.toString() ?? '';

    return DailyPlan(
      id: json['id']?.toString() ?? '',
      visitDate: json['visit_date']?.toString() ?? '',
      purpose: json['purpose']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      statusDisplay: json['status_display']?.toString() ?? '',
      villageVisits: json['village_visits'] != null
          ? (json['village_visits'] as List)
          .map((i) => VillageVisit.fromJson(i, visitDateStr))
          .toList()
          : [],
    );
  }
}

class VillageVisit {
  final String id;
  final String village;
  final String villageCode;
  final String taluka;
  final String talukaCode;
  final String district;
  final String districtCode;
  final String state;
  final String stateCode;
  final String status;
  final String statusDisplay;
  final int expectedRegistrations;
  final List<String> officialsToMeet;
  final String notes;
  final bool canExecute;
  final double? villageLatitude;
  final double? villageLongitude;
  final String? startedAt;
  final String? completedAt;
  final VillageExecution? execution;
  final DateTime plannedDate;

  // ✅ NEW: Marathi translation fields
  String? marathiVillage;
  String? marathiTaluka;
  String? marathiDistrict;
  String? marathiState;

  VillageVisit({
    required this.id,
    required this.village,
    this.villageCode = '',
    required this.taluka,
    this.talukaCode = '',
    required this.district,
    this.districtCode = '',
    required this.state,
    this.stateCode = '',
    required this.status,
    required this.statusDisplay,
    required this.expectedRegistrations,
    required this.officialsToMeet,
    required this.notes,
    required this.canExecute,
    this.villageLatitude,
    this.villageLongitude,
    this.startedAt,
    this.completedAt,
    this.execution,
    required this.plannedDate,
    this.marathiVillage,
    this.marathiTaluka,
    this.marathiDistrict,
    this.marathiState,
  });

  // ✅ NEW: Display getters for English / Marathi
  String getDisplayVillage(String lang) {
    if (lang == 'mr' && marathiVillage != null && marathiVillage!.isNotEmpty) {
      return marathiVillage!;
    }
    return village;
  }

  String getDisplayTaluka(String lang) {
    if (lang == 'mr' && marathiTaluka != null && marathiTaluka!.isNotEmpty) {
      return marathiTaluka!;
    }
    return taluka;
  }

  String getDisplayDistrict(String lang) {
    if (lang == 'mr' && marathiDistrict != null && marathiDistrict!.isNotEmpty) {
      return marathiDistrict!;
    }
    return district;
  }

  String getDisplayState(String lang) {
    if (lang == 'mr' && marathiState != null && marathiState!.isNotEmpty) {
      return marathiState!;
    }
    return state;
  }

  String get displayVillage => village;
  String get displayTaluka => taluka;
  String get displayDistrict => district;
  String get displayState => state;





  factory VillageVisit.fromJson(Map<String, dynamic> json,
      [String? visitDate]) {
    DateTime parsedPlannedDate;
    try {
      String dateStr = visitDate ??
          json['visit_date']?.toString() ??
          json['planned_date']?.toString() ??
          '';
      if (dateStr.isNotEmpty) {
        parsedPlannedDate = DateTime.parse(dateStr);
      } else {
        parsedPlannedDate = DateTime.now();
      }
    } catch (e) {
      parsedPlannedDate = DateTime.now();
    }

    return VillageVisit(
      id: json['id']?.toString() ?? '',
      village: json['village']?.toString() ?? '',
      villageCode: json['village_code']?.toString() ?? '',
      taluka: json['taluka']?.toString() ?? '',
      talukaCode: json['taluka_code']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      districtCode: json['district_code']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      stateCode: json['state_code']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      statusDisplay: json['status_display']?.toString() ?? '',
      expectedRegistrations: json['expected_registrations'] ?? 0,
      officialsToMeet: json['officials_to_meet'] != null
          ? List<String>.from(json['officials_to_meet'])
          : [],
      notes: json['notes']?.toString() ?? '',
      canExecute: json['can_execute'] ?? true,
      villageLatitude: json['village_latitude'] != null
          ? double.tryParse(json['village_latitude'].toString())
          : null,
      villageLongitude: json['village_longitude'] != null
          ? double.tryParse(json['village_longitude'].toString())
          : null,
      startedAt: json['started_at']?.toString(),
      completedAt: json['completed_at']?.toString(),
      execution: json['execution'] != null
          ? VillageExecution.fromJson(json['execution'])
          : null,
      plannedDate: parsedPlannedDate,
    );
  }
}

class VillageExecution {
  final String id;
  final String startedAt;
  final String? completedAt;
  final String startLatitude;
  final String startLongitude;
  final String? completionLatitude;
  final String? completionLongitude;
  final String villageFeedback;
  final int totalRegistrations;
  final List<Meeting> meetings;
  final List<ProofImage> proofImages;
  final MeetingSummary meetingSummary;

  VillageExecution({
    required this.id,
    required this.startedAt,
    this.completedAt,
    required this.startLatitude,
    required this.startLongitude,
    this.completionLatitude,
    this.completionLongitude,
    required this.villageFeedback,
    required this.totalRegistrations,
    required this.meetings,
    required this.proofImages,
    required this.meetingSummary,
  });

  factory VillageExecution.fromJson(Map<String, dynamic> json) {
    return VillageExecution(
      id: json['id']?.toString() ?? '',
      startedAt: json['started_at']?.toString() ?? '',
      completedAt: json['completed_at']?.toString(),
      startLatitude: json['start_latitude']?.toString() ?? '',
      startLongitude: json['start_longitude']?.toString() ?? '',
      completionLatitude: json['completion_latitude']?.toString(),
      completionLongitude: json['completion_longitude']?.toString(),
      villageFeedback: json['village_feedback']?.toString() ?? '',
      totalRegistrations: json['total_registrations'] ?? 0,
      meetings: json['meetings'] != null
          ? (json['meetings'] as List)
          .map((i) => Meeting.fromJson(i))
          .toList()
          : [],
      proofImages: json['proof_images'] != null
          ? (json['proof_images'] as List)
          .map((i) => ProofImage.fromJson(i))
          .toList()
          : [],
      meetingSummary: json['meeting_summary'] != null
          ? MeetingSummary.fromJson(json['meeting_summary'])
          : MeetingSummary(total: 0, completed: 0, notFound: 0, withProof: 0),
    );
  }
}

class Meeting {
  final String id;
  final String personType;
  final String personTypeDisplay;
  final String? personName;
  final String? personPhone;
  final String personDesignation;
  final bool personMet;
  final String? meetingNotes;
  final String? reasonNotMet;
  final double? meetingLatitude;
  final double? meetingLongitude;
  final List<ProofImage> proofImages;
  final String createdAt;

  Meeting({
    required this.id,
    required this.personType,
    required this.personTypeDisplay,
    this.personName,
    this.personPhone,
    required this.personDesignation,
    required this.personMet,
    this.meetingNotes,
    this.reasonNotMet,
    this.meetingLatitude,
    this.meetingLongitude,
    required this.proofImages,
    required this.createdAt,
  });

  factory Meeting.fromJson(Map<String, dynamic> json) {
    return Meeting(
      id: json['id']?.toString() ?? '',
      personType: json['person_type']?.toString() ?? '',
      personTypeDisplay: json['person_type_display']?.toString() ?? '',
      personName: json['person_name']?.toString(),
      personPhone: json['person_phone']?.toString(),
      personDesignation: json['person_designation']?.toString() ?? '',
      personMet: json['person_met'] ?? false,
      meetingNotes: json['meeting_notes']?.toString(),
      reasonNotMet: json['reason_not_met']?.toString(),
      meetingLatitude: json['meeting_latitude'] != null
          ? double.tryParse(json['meeting_latitude'].toString())
          : null,
      meetingLongitude: json['meeting_longitude'] != null
          ? double.tryParse(json['meeting_longitude'].toString())
          : null,
      proofImages: json['proof_images'] != null
          ? (json['proof_images'] as List)
          .map((i) => ProofImage.fromJson(i))
          .toList()
          : [],
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class ProofImage {
  final String id;
  final String? imageType;
  final String s3Key;
  final String imageUrl;
  final String? caption;
  final String? latitude;
  final String? longitude;
  final String uploadedAt;

  ProofImage({
    required this.id,
    this.imageType,
    required this.s3Key,
    required this.imageUrl,
    this.caption,
    this.latitude,
    this.longitude,
    required this.uploadedAt,
  });

  factory ProofImage.fromJson(Map<String, dynamic> json) {
    return ProofImage(
      id: json['id']?.toString() ?? '',
      imageType: json['image_type']?.toString(),
      s3Key: json['s3_key']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
      caption: json['caption']?.toString(),
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      uploadedAt: json['uploaded_at']?.toString() ?? '',
    );
  }
}

class MeetingSummary {
  final int total;
  final int completed;
  final int notFound;
  final int withProof;

  MeetingSummary({
    required this.total,
    required this.completed,
    required this.notFound,
    required this.withProof,
  });

  factory MeetingSummary.fromJson(Map<String, dynamic> json) {
    return MeetingSummary(
      total: json['total'] ?? 0,
      completed: json['completed'] ?? 0,
      notFound: json['not_found'] ?? 0,
      withProof: json['with_proof'] ?? 0,
    );
  }
}

class OfficialCategory {
  static const List<String> mandatory = [
    'shopowner_1_mandatory',
    'shopowner_2_mandatory',
    'hotspot_pickup_dropoff',
    'hotspot_banner_spot',
    'hotspot_wall_painting',
    'village_poc',
  ];

  static const List<String> conditional = [
    'sarpanch',
    'secretary',
    'talathi',
    'postman',
  ];

  static bool isMandatory(String official) => mandatory.contains(official);
  static bool isConditional(String official) => conditional.contains(official);
  static bool isShopowner(String official) => official.startsWith('shopowner_');
  static bool isMukkadam(String official) => official.startsWith('mukkadam_');
  static bool isInfluentialPerson(String official) =>
      official.startsWith('influential_person');

  static int getShopownerNumber(String official) {
    if (!isShopowner(official)) return 0;
    final match = RegExp(r'shopowner_(\d+)').firstMatch(official);
    return match != null ? int.tryParse(match.group(1) ?? '0') ?? 0 : 0;
  }

  static int getMukkadamNumber(String official) {
    if (!isMukkadam(official)) return 0;
    final match = RegExp(r'mukkadam_(\d+)').firstMatch(official);
    return match != null ? int.tryParse(match.group(1) ?? '0') ?? 0 : 0;
  }

  static int getInfluentialPersonNumber(String official) {
    if (!isInfluentialPerson(official)) return 0;
    final match = RegExp(r'influential_person_(\d+)').firstMatch(official);
    return match != null ? int.tryParse(match.group(1) ?? '0') ?? 0 : 0;
  }
}
