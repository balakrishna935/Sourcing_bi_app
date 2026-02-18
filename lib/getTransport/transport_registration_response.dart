class TransportRegistrationResponse {
  final Map<String, dynamic> summary;
  final List<Transporter> transporters;

  TransportRegistrationResponse(
      {required this.summary, required this.transporters});

  factory TransportRegistrationResponse.fromJson(Map<String, dynamic> json) {
    return TransportRegistrationResponse(
      summary: json['summary'] ?? {},
      transporters: (json['transporters'] as List?)
          ?.map((i) => Transporter.fromJson(i))
          .toList() ??
          [],
    );
  }
}

class Transporter {
  final int id;
  final String name;
  final String mobile;
  final String village;
  final String registeredAt;

  // ✅ NEW: Marathi translated name
  String? marathiName;

  // ✅ NEW: Bilingual display — "English / मराठी"
  String get displayName {
    if (marathiName != null && marathiName!.isNotEmpty) {
      return '$name / $marathiName';
    }
    return name;
  }

  Transporter({
    required this.id,
    required this.name,
    required this.mobile,
    required this.village,
    required this.registeredAt,
    this.marathiName,
  });

  factory Transporter.fromJson(Map<String, dynamic> json) {
    return Transporter(
      id: json['id'] ?? 0,
      name: json['name'] ?? json['transporter_name'] ?? 'N/A',
      mobile: json['contact_number'] ?? json['mobile_numbers'] ?? 'N/A',
      village: json['village'] ?? 'N/A',
      registeredAt: json['registered_at'] ?? '',
    );
  }
}
