// lib/language_jsons/transport_directory_strings.dart

class TransportDirectoryStrings {
  static const Map<String, Map<String, String>> strings = {
    // Loading / Error / Empty
    'loadingtransporters': {'en': 'Loading transporters...', 'mr': 'वाहतूकदार लोड होत आहेत...'},
    'somethingwentwrong': {'en': 'Something went wrong', 'mr': 'काहीतरी चूक झाली'},
    'retry': {'en': 'Retry', 'mr': 'पुन्हा प्रयत्न करा'},
    'notransporters': {'en': 'No Transporters', 'mr': 'वाहतूकदार नाहीत'},
    'notransportersfound': {'en': 'No transporters found at the moment.', 'mr': 'सध्या वाहतूकदार सापडले नाहीत.'},
    'nomatches': {'en': 'No Matches', 'mr': 'जुळणारे नाहीत'},
    'noverifiedmatch': {'en': 'No verified transporters match your search.', 'mr': 'आपल्या शोधाशी जुळणारे सत्यापित वाहतूकदार नाहीत.'},

    // Card labels
    'fullyverified': {'en': 'Fully Verified', 'mr': 'पूर्ण सत्यापित'},
    'docs': {'en': 'Docs', 'mr': 'कागदपत्रे'},
  };

  static String get(String key, String lang) {
    return strings[key]?[lang] ?? strings[key]?['en'] ?? key;
  }
}
