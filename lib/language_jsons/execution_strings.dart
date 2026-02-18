// lib/language_jsons/village_execution_strings.dart

class VillageExecutionStrings {
  static const Map<String, Map<String, String>> _strings = {
    // --- Official Display Names ---
    'shopowner': {'en': 'Shopowner', 'mr': 'दुकानदार'},
    'hotspot': {'en': 'Hotspot', 'mr': 'हॉटस्पॉट'},
    'mukkadam': {'en': 'Mukkadam', 'mr': 'मुकादम'},
    'influential': {'en': 'Influential', 'mr': 'प्रभावशाली'},
    'other_person': {'en': 'Other', 'mr': 'इतर व्यक्ती'},
    'village_poc': {'en': 'Village POC', 'mr': 'गाव संपर्क'},

    // Hotspot types
    'hotspot_pickup_dropoff': {'en': 'Pickup/Dropoff Point', 'mr': 'पिकअप/ड्रॉपऑफ'},
    'hotspot_banner_spot': {'en': 'Banner Spot', 'mr': 'बॅनर स्पॉट'},
    'hotspot_wall_painting': {'en': 'Wall Painting', 'mr': 'वॉल पेंटिंग'},

    // Government officials
    'sarpanch': {'en': 'Sarpanch', 'mr': 'सरपंच'},
    'secretary': {'en': 'Secretary', 'mr': 'सचिव'},
    'talathi': {'en': 'Talathi', 'mr': 'तलाठी'},
    'postman': {'en': 'Postman', 'mr': 'पोस्टमन'},
    'vdo': {'en': 'VDO', 'mr': 'ग्रामसेवक'},
    'principal': {'en': 'Principal', 'mr': 'मुख्याध्यापक'},
    'agriculture_officer': {'en': 'Agri Officer', 'mr': 'कृषी अधिकारी'},
    'anganwadi_worker': {'en': 'Anganwadi', 'mr': 'अंगणवाडी सेविका'},
    'asha_worker': {'en': 'ASHA Worker', 'mr': 'आशा वर्कर'},
    'police_patil': {'en': 'Police Patil', 'mr': 'पोलीस पाटील'},
    'krishi_sahayak': {'en': 'Krishi Sahayak', 'mr': 'कृषी सहायक'},
    'gram_panchayat_member': {'en': 'GP Member', 'mr': 'ग्रा.पं. सदस्य'},

    // --- Shopowner Designations (dropdown) ---
    'chai_wala': {'en': 'Chai Wala', 'mr': 'चहावाला'},
    'pan_wala': {'en': 'Pan Wala', 'mr': 'पानवाला'},
    'kirana_store': {'en': 'Kirana Store', 'mr': 'किराणा'},
    'medical_store': {'en': 'Medical Store', 'mr': 'मेडिकल'},
    'hardware_store': {'en': 'Hardware Store', 'mr': 'हार्डवेअर'},
    'stationary_shop': {'en': 'Stationary Shop', 'mr': 'स्टेशनरी'},
    'mobile_shop': {'en': 'Mobile Shop', 'mr': 'मोबाईल'},
    'barber_shop': {'en': 'Barber Shop', 'mr': 'सलून'},
    'tailor_shop': {'en': 'Tailor Shop', 'mr': 'टेलर'},
    'other': {'en': 'Other', 'mr': 'इतर'},

    // --- Pickup Location Types (dropdown) ---
    'bus_stand': {'en': 'Bus Stand', 'mr': 'बस स्टँड'},
    'railway_station': {'en': 'Railway Station', 'mr': 'रेल्वे'},
    'market_area': {'en': 'Market Area', 'mr': 'बाजार'},
    'main_chowk': {'en': 'Main Chowk', 'mr': 'मुख्य चौक'},
    'temple': {'en': 'Temple', 'mr': 'मंदिर'},
    'school': {'en': 'School', 'mr': 'शाळा'},
    'hospital': {'en': 'Hospital', 'mr': 'रुग्णालय'},
    'post_office': {'en': 'Post Office', 'mr': 'पोस्ट ऑफिस'},
    'panchayat': {'en': 'Panchayat', 'mr': 'पंचायत'},

    // --- UI Labels ---
    'start': {'en': 'Start', 'mr': 'सुरू करा'},
    'cancel': {'en': 'Cancel', 'mr': 'रद्द'},
    'complete': {'en': 'Complete', 'mr': 'पूर्ण करा'},
    'submit': {'en': 'Submit', 'mr': 'सबमिट'},
    'saving': {'en': 'Saving...', 'mr': 'सेव्ह होत आहे...'},
    'settings': {'en': 'Settings', 'mr': 'सेटिंग्ज'},
    'complete_visit': {'en': 'Complete Visit', 'mr': 'भेट पूर्ण करा'},
    'start_visit_for': {'en': 'Start visit for', 'mr': 'ला भेट सुरू करायची?'},
    'gps_will_be_captured': {'en': 'GPS will be captured', 'mr': 'GPS घेतले जाईल'},
    'gps_on_submit': {'en': 'GPS will be captured on submit', 'mr': 'GPS सबमिट वर घेतले जाईल'},
    'ready': {'en': 'Ready?', 'mr': 'तयार?'},
    'not_available': {'en': 'Not Available', 'mr': 'उपलब्ध नाही'},
    'start_on_planned_date': {'en': 'Start on planned date', 'mr': 'नियोजित तारखेला सुरू करा'},
    'registrations': {'en': 'Registrations', 'mr': 'नोंदणी'},
    'feedback': {'en': 'Feedback', 'mr': 'अभिप्राय'},
    'enter_feedback': {'en': 'Enter feedback', 'mr': 'अभिप्राय टाका'},
    'no_officials': {'en': 'No officials', 'mr': 'कोणी नाही'},
    'none_added': {'en': 'None added', 'mr': 'काहीही नाही'},
    'met': {'en': 'Met?', 'mr': 'भेटला?'},
    'name': {'en': 'Name', 'mr': 'नाव'},
    'phone': {'en': 'Phone', 'mr': 'फोन'},
    'designation': {'en': 'Designation', 'mr': 'पदनाम'},
    'shop_type': {'en': 'Shop Type', 'mr': 'दुकान'},
    'location': {'en': 'Location', 'mr': 'लोकेशन'},
    'custom': {'en': 'Custom', 'mr': 'इतर'},
    'notes': {'en': 'Notes', 'mr': 'नोट्स'},
    'reason': {'en': 'Reason', 'mr': 'कारण'},
    'capture_photo': {'en': 'Capture *', 'mr': 'फोटो *'},
    'captured': {'en': 'Captured ✓', 'mr': 'फोटो घेतला ✓'},
    'submitted': {'en': 'Submitted', 'mr': 'सबमिट'},
    'tap_to_view': {'en': 'Tap to view', 'mr': 'पाहण्यासाठी टॅप करा'},
    'view_only': {'en': 'View Only', 'mr': 'केवळ पाहण्यासाठी'},
    'not_captured': {'en': 'Not captured', 'mr': 'कॅप्चर नाही'},
    'expected': {'en': 'Expected', 'mr': 'अपेक्षित'},
    'officials': {'en': 'Officials', 'mr': 'अधिकारी'},
    'progress': {'en': 'Progress', 'mr': 'प्रगती'},
    'mukkadams_today': {'en': 'Mukkadams\n(Today)', 'mr': 'मुकादम\n(आज)'},

    // Tab names
    'tab_shops_spots': {'en': 'Shops & Spots', 'mr': 'दुकान व स्पॉट'},
    'tab_officials': {'en': 'Officials', 'mr': 'अधिकारी'},
    'tab_others': {'en': 'Others', 'mr': 'इतर'},

    // Category titles
    'shopowners': {'en': 'Shopowners', 'mr': 'दुकानदार'},
    'influential_persons': {'en': 'Influential Persons', 'mr': 'प्रभावशाली'},
    'mukkadams': {'en': 'Mukkadams', 'mr': 'मुकादम'},
    'other_persons': {'en': 'Other Persons', 'mr': 'इतर व्यक्ती'},

    // Add buttons
    'add_shop': {'en': 'Add Shop +', 'mr': 'दुकान +'},
    'add_influential': {'en': 'Add Influential +', 'mr': 'प्रभावशाली +'},
    'add_mukkadam': {'en': 'Add Mukkadam +', 'mr': 'मुकादम +'},
    'add_other': {'en': 'Add Other +', 'mr': 'इतर +'},

    // Snackbar messages
    'started': {'en': 'Started!', 'mr': 'सुरू झाली!'},
    'completed_msg': {'en': 'Completed!', 'mr': 'पूर्ण झाले!'},
    'submitted_msg': {'en': 'Submitted!', 'mr': 'सबमिट झाले!'},
    'photo_captured': {'en': 'Captured!', 'mr': 'फोटो घेतला!'},
    'capture_gps': {'en': 'Capture GPS', 'mr': 'GPS घ्या'},
    'select_location': {'en': 'Select location', 'mr': 'लोकेशन निवडा'},
    'select_shop_type': {'en': 'Select shop type', 'mr': 'दुकान निवडा'},
    'enter_name': {'en': 'Enter name', 'mr': 'नाव टाका'},
    'enter_phone': {'en': 'Enter phone number', 'mr': 'फोन नंबर टाका'},
    'enter_valid_phone': {'en': 'Enter valid 10-digit phone', 'mr': '10 अंकी फोन नंबर टाका'},
    'enter_reason': {'en': 'Enter reason', 'mr': 'कारण टाका'},
    'enter_designation': {'en': 'Enter designation', 'mr': 'पदनाम टाका'},
    'enter_feedback_msg': {'en': 'Please enter feedback', 'mr': 'कृपया अभिप्राय टाका'},
    'permissions_required': {'en': 'Permissions required', 'mr': 'परवानग्या आवश्यक'},
    'could_not_get_gps': {'en': 'Could not get GPS', 'mr': 'GPS मिळाले नाही'},
    'location_denied': {'en': 'Location denied', 'mr': 'परवानगी नाकारली'},
    'location_disabled': {'en': 'Location Disabled', 'mr': 'लोकेशन बंद'},
    'enable_location': {'en': 'Please enable location services.', 'mr': 'कृपया लोकेशन सुरू करा.'},
    'permission_required': {'en': 'Permission Required', 'mr': 'परवानगी आवश्यक'},
    'enable_location_settings': {'en': 'Please enable location from settings.', 'mr': 'सेटिंग्जमधून लोकेशन सुरू करा.'},
    'cannot_remove_submitted': {'en': 'Cannot remove submitted', 'mr': 'सबमिट केलेले काढता येत नाही'},
    'submit_previous_first': {'en': 'Submit previous', 'mr': 'आधी मागील'},
    'first': {'en': 'first', 'mr': 'सबमिट करा'},

    // Unfilled dialog
    'incomplete_form': {'en': 'Incomplete Form', 'mr': 'अपूर्ण फॉर्म'},
    'items_need_filled': {'en': 'items need to be filled', 'mr': 'आयटम भरणे आवश्यक'},
    'go_back_fill': {'en': 'Go Back & Fill', 'mr': 'परत जा आणि भरा'},
  };

  static String get(String key, String lang) {
    return _strings[key]?[lang] ?? _strings[key]?['en'] ?? key;
  }
}
