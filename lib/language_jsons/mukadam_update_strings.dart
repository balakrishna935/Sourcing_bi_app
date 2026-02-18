class MukadamUpdateStrings {
  static const Map<String, Map<String, String>> _strings = {
    // AppBar
    'update_details': {'en': 'Update Details', 'mr': 'तपशील अपडेट करा'},
    'verification_details': {'en': 'Verification Details', 'mr': 'पडताळणी तपशील'},

    // Image Picker
    'select_image_source': {'en': 'Select Image Source', 'mr': 'प्रतिमा स्रोत निवडा'},
    'gallery': {'en': 'Gallery', 'mr': 'गॅलरी'},
    'camera': {'en': 'Camera', 'mr': 'कॅमेरा'},

    // Sections
    'profile_photo': {'en': 'Profile Photo', 'mr': 'प्रोफाइल फोटो'},
    'pan_card': {'en': 'PAN Card', 'mr': 'पॅन कार्ड'},
    'aadhar_card': {'en': 'Aadhar Card', 'mr': 'आधार कार्ड'},
    'voter_id': {'en': 'Voter ID', 'mr': 'मतदार ओळखपत्र'},

    // Common
    'verified': {'en': 'Verified', 'mr': 'सत्यापित'},
    'number': {'en': 'Number', 'mr': 'क्रमांक'},
    'enter': {'en': 'Enter', 'mr': 'प्रविष्ट करा'},
    'upload_document': {'en': 'Upload Document', 'mr': 'कागदपत्र अपलोड करा'},
    'save_update': {'en': 'Save & Update Details', 'mr': 'जतन करा आणि अपडेट करा'},
    'error': {'en': 'Error', 'mr': 'त्रुटी'},

    // Snackbar messages
    'updated_successfully': {'en': 'Updated Successfully', 'mr': 'यशस्वीरित्या अपडेट केले'},
    'failed_to_update': {'en': 'Failed to update details', 'mr': 'तपशील अपडेट करण्यात अयशस्वी'},
    'fix_errors': {'en': 'Please fix the errors before submitting', 'mr': 'कृपया सबमिट करण्यापूर्वी त्रुटी दुरुस्त करा'},

    // PAN validation
    'pan_length_error': {'en': 'PAN must be exactly 10 characters', 'mr': 'पॅन अचूक 10 अक्षरांचा असावा'},
    'pan_format_error': {'en': 'Invalid PAN format (e.g. ABCDE1234F)', 'mr': 'अवैध पॅन स्वरूप (उदा. ABCDE1234F)'},

    // Aadhar validation
    'aadhar_length_error': {'en': 'Aadhaar must be exactly 12 digits', 'mr': 'आधार अचूक 12 अंकांचा असावा'},
    'aadhar_format_error': {'en': 'Invalid Aadhaar (12 digits, cannot start with 0 or 1)', 'mr': 'अवैध आधार (12 अंक, 0 किंवा 1 ने सुरू होऊ शकत नाही)'},

    // Voter ID validation
    'voter_length_error': {'en': 'Voter ID must be exactly 10 characters', 'mr': 'मतदार ओळखपत्र अचूक 10 अक्षरांचे असावे'},
    'voter_format_error': {'en': 'Invalid Voter ID format (e.g. ABC1234567)', 'mr': 'अवैध मतदार ओळखपत्र स्वरूप (उदा. ABC1234567)'},

    // Helper texts
    'pan_helper': {'en': 'Format: ABCDE1234F (5 letters + 4 digits + 1 letter)', 'mr': 'स्वरूप: ABCDE1234F (5 अक्षरे + 4 अंक + 1 अक्षर)'},
    'aadhar_helper': {'en': '12-digit number (cannot start with 0 or 1)', 'mr': '12-अंकी क्रमांक (0 किंवा 1 ने सुरू होऊ शकत नाही)'},
    'voter_helper': {'en': 'Format: ABC1234567 (3 letters + 7 digits)', 'mr': 'स्वरूप: ABC1234567 (3 अक्षरे + 7 अंक)'},
  };

  static String get(String key, String lang) {
    return _strings[key]?[lang] ?? _strings[key]?['en'] ?? key;
  }
}
