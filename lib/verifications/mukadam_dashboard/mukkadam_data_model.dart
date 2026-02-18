class MukkadamDataModel {
  final int id;
  final String mukkadamName;
  final String village;
  final String taluka;       // ✅ NEW
  final String district;
  final String state;        // ✅ NEW
  final String crewSize;
  final String mobileNumbers;
  final String createdAt;
  final bool isAadharVerified;
  final bool isPanVerified;
  final bool isVoterIdVerified;
  final bool isFaceVerified;
  final bool isFullyVerified;
  String? marathiName;
  String? marathiVillage;    // ✅ NEW
  String? marathiTaluka;     // ✅ NEW
  String? marathiDistrict;   // ✅ NEW
  String? marathiState;      // ✅ NEW

  MukkadamDataModel({
    required this.id,
    required this.mukkadamName,
    required this.village,
    required this.taluka,       // ✅ NEW
    required this.district,
    required this.state,        // ✅ NEW
    required this.crewSize,
    required this.mobileNumbers,
    required this.createdAt,
    required this.isAadharVerified,
    required this.isPanVerified,
    required this.isVoterIdVerified,
    required this.isFaceVerified,
    required this.isFullyVerified,
    this.marathiName,
    this.marathiVillage,
    this.marathiTaluka,
    this.marathiDistrict,
    this.marathiState,
  });

  /// Language-aware name
  String getDisplayName(String lang) {
    if (lang == 'mr' && marathiName != null && marathiName!.isNotEmpty) {
      return marathiName!;
    }
    return mukkadamName;
  }

  /// ✅ NEW — Language-aware full location string
  String getDisplayLocation(String lang) {
    final String v, t, d, s;

    if (lang == 'mr') {
      v = (marathiVillage != null && marathiVillage!.isNotEmpty)
          ? marathiVillage! : village;
      t = (marathiTaluka != null && marathiTaluka!.isNotEmpty)
          ? marathiTaluka! : taluka;
      d = (marathiDistrict != null && marathiDistrict!.isNotEmpty)
          ? marathiDistrict! : district;
      s = (marathiState != null && marathiState!.isNotEmpty)
          ? marathiState! : state;
    } else {
      v = village;
      t = taluka;
      d = district;
      s = state;
    }

    // Build location string from non-empty parts
    final parts = [v, t, d, s].where((p) => p.isNotEmpty).toList();
    return parts.join(', ');
  }

  bool get isAnyVerified =>
      isAadharVerified || isPanVerified || isVoterIdVerified || isFaceVerified;

  bool get isAllVerified =>
      isAadharVerified && isPanVerified && isVoterIdVerified && isFaceVerified;

  int get verifiedCount => [
    isAadharVerified,
    isPanVerified,
    isVoterIdVerified,
    isFaceVerified,
  ].where((v) => v).length;

  factory MukkadamDataModel.fromJson(Map<String, dynamic> json) {
    final entity = json['entity'] ?? {};
    final List<dynamic> verifications = json['verifications'] ?? [];

    bool aadharVerified = verifications.any(
            (v) => v['type'] == 'aadhaar_ocr' && v['status'] == 'completed');
    bool panVerified = verifications.any(
            (v) => v['type'] == 'pan_360' && v['status'] == 'completed');
    bool voterVerified = verifications.any(
            (v) => v['type'] == 'voter_id' && v['status'] == 'completed');
    bool faceVerified = verifications.any(
            (v) => v['type'] == 'face_match' && v['status'] == 'completed');

    aadharVerified = aadharVerified || (entity['is_aadhaar_verified'] == true);
    panVerified = panVerified || (entity['is_pan_verified'] == true);
    voterVerified = voterVerified || (entity['is_voter_verified'] == true);
    faceVerified = faceVerified || (entity['is_face_verified'] == true);

    return MukkadamDataModel(
      id: entity['id'] ?? 0,
      mukkadamName: entity['name'] ?? '',
      village: entity['village'] ?? '',
      taluka: entity['taluka'] ?? '',       // ✅ NEW
      district: entity['district'] ?? '',
      state: entity['state'] ?? '',         // ✅ NEW
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
