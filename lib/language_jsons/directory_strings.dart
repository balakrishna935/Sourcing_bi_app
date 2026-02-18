// lib/language_jsons/directory_strings.dart

class DirectoryStrings {
  static const Map<String, Map<String, String>> strings = {
    // AppBar
    'onboardedmembers': {'en': 'Onboarded Members', 'mr': 'नोंदणीकृत सदस्य'},

    // Search
    'searchbyname': {'en': 'Search by name...', 'mr': 'नावाने शोधा...'},

    // Tabs
    'registrations': {'en': 'Registrations', 'mr': 'नोंदणी'},
    'transport': {'en': 'Transport', 'mr': 'वाहतूक'},

    // Card labels
    'crew': {'en': 'Crew', 'mr': 'टोळी'},
    'fullyverified': {'en': 'Fully Verified', 'mr': 'पूर्ण सत्यापित'},

    // Loading / Error / Empty states
    'loadingdirectory': {'en': 'Loading directory...', 'mr': 'डिरेक्टरी लोड होत आहे...'},
    'somethingwentwrong': {'en': 'Something went wrong', 'mr': 'काहीतरी चूक झाली'},
    'retry': {'en': 'Retry', 'mr': 'पुन्हा प्रयत्न करा'},
    'noregistrations': {'en': 'No Registrations', 'mr': 'नोंदणी नाहीत'},
    'noregistrationsfound': {'en': 'No registrations found.', 'mr': 'नोंदणी सापडल्या नाहीत.'},
    'noverifiedregistrations': {'en': 'No Verified Registrations', 'mr': 'सत्यापित नोंदणी नाहीत'},
    'noverifiedregistrationsfound': {'en': 'No verified registrations found.', 'mr': 'सत्यापित नोंदणी सापडल्या नाहीत.'},
  };

  static String get(String key, String lang) {
    return strings[key]?[lang] ?? strings[key]?['en'] ?? key;
  }
}
