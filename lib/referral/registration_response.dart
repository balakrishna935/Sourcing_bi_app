class MukkadamDataModell {
  final int id;
  final String mukkadamName;
  final String village;
  final String district;
  final String crewSize;
  final String mobileNumbers;
  final String createdAt;
  final bool isAadharVerified;
  final bool isPanVerified;
  final bool isVoterIdVerified;
  final bool isFaceVerified;
  final bool isFullyVerified;

  String? marathiName;

  // ✅ NEW — shows ONLY the selected language
  String getDisplayName(String lang) {
    if (lang == 'mr' && marathiName != null && marathiName!.isNotEmpty) {
      return marathiName!;       // Marathi ONLY
    }
    return mukkadamName;          // English ONLY
  }




  MukkadamDataModell({
    required this.id,
    required this.mukkadamName,
    required this.village,
    required this.district,
    required this.crewSize,
    required this.mobileNumbers,
    required this.createdAt,
    required this.isAadharVerified,
    required this.isPanVerified,
    required this.isVoterIdVerified,
    required this.isFaceVerified,
    required this.isFullyVerified,
    this.marathiName


  });



  /// At least one verification is done
  bool get isAnyVerified =>
      isAadharVerified || isPanVerified || isVoterIdVerified || isFaceVerified;

  /// ALL verifications are done
  bool get isAllVerified =>
      isAadharVerified && isPanVerified && isVoterIdVerified && isFaceVerified;

  /// Count of verified items
  int get verifiedCount => [
    isAadharVerified,
    isPanVerified,
    isVoterIdVerified,
    isFaceVerified,
  ].where((v) => v).length;

  factory MukkadamDataModell.fromJson(Map<String, dynamic> json) {
    final entity = json['entity'] ?? {};
    final List<dynamic> verifications = json['verifications'] ?? [];

    // Check verification status from verifications array by type + status
    bool aadharVerified = verifications.any(
            (v) => v['type'] == 'aadhaar_ocr' && v['status'] == 'completed');
    bool panVerified = verifications.any(
            (v) => v['type'] == 'pan_360' && v['status'] == 'completed');
    bool voterVerified = verifications.any(
            (v) => v['type'] == 'voter_id' && v['status'] == 'completed');
    bool faceVerified = verifications.any((v) =>
    v['type'] == 'face_match' && v['status'] == 'completed');

    // Also check entity-level flags as fallback
    aadharVerified = aadharVerified || (entity['is_aadhaar_verified'] == true);
    panVerified = panVerified || (entity['is_pan_verified'] == true);

    return MukkadamDataModell(
      id: entity['id'] ?? 0,
      mukkadamName: entity['name'] ?? '',
      village: entity['village'] ?? '',
      district: entity['district'] ?? '',
      crewSize: entity['crew_size']?.toString() ?? '',
      mobileNumbers: entity['mobile'] ?? '',
      createdAt: entity['created_at'] ?? '',
      isAadharVerified: aadharVerified,
      isPanVerified: panVerified,
      isVoterIdVerified: voterVerified,
      isFaceVerified: faceVerified,
      isFullyVerified: entity['is_fully_verified'] ?? false,
    );
  }
}
