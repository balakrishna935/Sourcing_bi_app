// lib/language_jsons/mukadam_verification_strings.dart

class MukadamVerificationStrings {
  static const Map<String, Map<String, String>> strings = {
    // AppBar & Title
    'mukadamverification': {'en': 'Mukadam Verification', 'mr': 'मुकदम पडताळणी'},

    // Search
    'searchbyname': {'en': 'Search by name...', 'mr': 'नावाने शोधा...'},

    // Status
    'pending': {'en': 'Pending', 'mr': 'प्रलंबित'},
    'notverified': {'en': 'Not Verified', 'mr': 'सत्यापित नाही'},

    // Empty / Error states
    'somethingwentwrong': {'en': 'Something went wrong', 'mr': 'काहीतरी चूक झाली'},
    'tryagain': {'en': 'Try Again', 'mr': 'पुन्हा प्रयत्न करा'},
    'nomukkadamsfound': {'en': 'No Mukkadams Found', 'mr': 'मुक्कदाम सापडले नाहीत'},
    'nounverifiedprofiles': {'en': 'There are no unverified profiles to display at the moment.', 'mr': 'सध्या प्रदर्शित करण्यासाठी असत्यापित प्रोफाइल नाहीत.'},
    'nomatchingresults': {'en': 'No Matching Results', 'mr': 'जुळणारे निकाल नाहीत'},
    'tryadjustingsearch': {'en': 'Try adjusting your search.', 'mr': 'शोध बदलून पहा.'},

    // Count label
    'unverifiedprofile': {'en': 'unverified profile', 'mr': 'असत्यापित प्रोफाइल'},
    'plural_s': {'en': 's', 'mr': ''},

    // Verification dots
    'aadhaar': {'en': 'Aadhaar', 'mr': 'आधार'},
    'pan': {'en': 'PAN', 'mr': 'पॅन'},
    'voter': {'en': 'Voter', 'mr': 'मतदार'},
    'face': {'en': 'Face', 'mr': 'चेहरा'},
  };

  static String get(String key, String lang) {
    return strings[key]?[lang] ?? strings[key]?['en'] ?? key;
  }
}
