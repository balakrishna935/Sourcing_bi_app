class PendingVerificationResponse {
  final int totalEntities;
  final List<VerificationEntity> entities;

  PendingVerificationResponse({
    required this.totalEntities,
    required this.entities,
  });

  factory PendingVerificationResponse.fromJson(Map<String, dynamic> json) {
    return PendingVerificationResponse(
      totalEntities: json['total_entities'] ?? 0,
      entities: (json['entities'] as List)
          .map((e) => VerificationEntity.fromJson(e))
          .toList(),
    );
  }
}

class VerificationEntity {
  final String entityType;
  final EntityDetails entity;
  final List<VerificationStatus> verifications;

  VerificationEntity({
    required this.entityType,
    required this.entity,
    required this.verifications,
  });

  factory VerificationEntity.fromJson(Map<String, dynamic> json) {
    return VerificationEntity(
      entityType: json['entity_type'],
      entity: EntityDetails.fromJson(json['entity']),
      verifications: (json['verifications'] as List)
          .map((v) => VerificationStatus.fromJson(v))
          .toList(),
    );
  }
}

class EntityDetails {
  final int id;
  final String name;
  final String contactNumber;
  final String baseLocation;
  final String? vehicleType;

  final bool isFullyVerified;
  final bool isAadhaarVerified;
  final bool isPanVerified;
  final bool isRcVerified;
  final bool isDlVerified;
  final bool isVoterIdVerified;

  // ✅ NEW: Marathi translated name (set after fetch)
  String? marathiName;

  // ✅ NEW: Bilingual display — "English / मराठी"
  String get displayName {
    if (marathiName != null && marathiName!.isNotEmpty) {
      return '$name / $marathiName';
    }
    return name;
  }

  EntityDetails({
    required this.id,
    required this.name,
    required this.contactNumber,
    required this.baseLocation,
    this.vehicleType,
    required this.isFullyVerified,
    required this.isAadhaarVerified,
    required this.isPanVerified,
    required this.isRcVerified,
    required this.isDlVerified,
    required this.isVoterIdVerified,
    this.marathiName,
  });

  factory EntityDetails.fromJson(Map<String, dynamic> json) {
    return EntityDetails(
      id: json['id'],
      name: json['name'],
      contactNumber: json['contact_number'] ?? '',
      baseLocation: json['base_location'] ?? '',
      vehicleType: json['vehicle_type'],
      isFullyVerified: json['is_fully_verified'] ?? false,
      isAadhaarVerified: json['is_aadhaar_verified'] ?? false,
      isPanVerified: json['is_pan_verified'] ?? false,
      isRcVerified: json['is_rc_verified'] ?? false,
      isDlVerified: json['is_dl_verified'] ?? false,
      isVoterIdVerified: json['is_voter_id_verified'] ?? false,
    );
  }
}

class VerificationStatus {
  final String type;
  final String typeDisplay;
  final String status;

  VerificationStatus({
    required this.type,
    required this.typeDisplay,
    required this.status,
  });

  factory VerificationStatus.fromJson(Map<String, dynamic> json) {
    return VerificationStatus(
      type: json['type'] ?? '',
      typeDisplay: json['type_display'] ?? '',
      status: json['status'] ?? '',
    );
  }
}
