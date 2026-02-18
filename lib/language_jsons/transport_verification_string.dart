// lib/language_jsons/transport_verification_strings.dart

class TransportVerificationStrings {
  static const Map<String, Map<String, String>> strings = {
    // AppBar
    'transportverification': {'en': 'Transport Verification', 'mr': 'वाहतूक पडताळणी'},

    // Search
    'searchbyname': {'en': 'Search by name...', 'mr': 'नावाने शोधा...'},

    // Status
    'pending': {'en': 'Pending', 'mr': 'प्रलंबित'},
    'notverified': {'en': 'Not Verified', 'mr': 'सत्यापित नाही'},
    'transporter': {'en': 'Transporter', 'mr': 'वाहतूकदार'},

    // Results header
    'result': {'en': 'result', 'mr': 'निकाल'},
    'results': {'en': 'results', 'mr': 'निकाल'},

    // Verification chips
    'aadhaar': {'en': 'Aadhaar', 'mr': 'आधार'},
    'pan': {'en': 'PAN', 'mr': 'पॅन'},
    'rc': {'en': 'RC', 'mr': 'आरसी'},
    'dl': {'en': 'DL', 'mr': 'डीएल'},
    'voterid': {'en': 'Voter ID', 'mr': 'मतदार ओळखपत्र'},

    // Error / Empty states
    'somethingwentwrong': {'en': 'Something went wrong', 'mr': 'काहीतरी चूक झाली'},
    'tryagain': {'en': 'Try Again', 'mr': 'पुन्हा प्रयत्न करा'},
    'noverificationsfound': {'en': 'No Verifications Found', 'mr': 'पडताळणी सापडल्या नाहीत'},
    'nomatchingpending': {'en': 'No matching pending verifications found.', 'mr': 'जुळणाऱ्या प्रलंबित पडताळणी सापडल्या नाहीत.'},
    'refresh': {'en': 'Refresh', 'mr': 'रिफ्रेश'},
  };

  static String get(String key, String lang) {
    return strings[key]?[lang] ?? strings[key]?['en'] ?? key;
  }
}
