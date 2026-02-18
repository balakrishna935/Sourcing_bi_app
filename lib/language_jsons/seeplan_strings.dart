// lib/language_jsons/seeplan_strings.dart

class SeePlanStrings {
  static const Map<String, Map<String, String>> strings = {
    // ========== VillagePlansDashboard ==========
    'today': {'en': 'Today', 'mr': 'आज'},
    'all': {'en': 'All', 'mr': 'सर्व'},
    'upcoming': {'en': 'Upcoming', 'mr': 'आगामी'},
    'completed': {'en': 'Completed', 'mr': 'पूर्ण'},
    'inprogress': {'en': 'In Progress', 'mr': 'प्रगतीत'},
    'overview': {'en': 'Overview', 'mr': 'आढावा'},
    'filters': {'en': 'Filters', 'mr': 'फिल्टर'},
    'villagevisitplans': {'en': 'Village Visit Plans', 'mr': 'गाव भेट योजना'},
    'plans': {'en': 'Plans', 'mr': 'योजना'},
    'villages': {'en': 'Villages', 'mr': 'गावे'},
    'days': {'en': 'Days', 'mr': 'दिवस'},
    'upcomingplan': {'en': 'Upcoming Plan', 'mr': 'आगामी योजना'},
    'noplansfound': {'en': 'No Plans Found', 'mr': 'कोणत्याही योजना सापडल्या नाहीत'},
    'somethingwentwrong': {'en': 'Something went wrong', 'mr': 'काहीतरी चूक झाली'},
    'tryagain': {'en': 'Try Again', 'mr': 'पुन्हा प्रयत्न करा'},
    'clearfilters': {'en': 'Clear Filters', 'mr': 'फिल्टर साफ करा'},
    'from': {'en': 'From', 'mr': 'पासून'},
    'to': {'en': 'To', 'mr': 'पर्यंत'},
    'selectdate': {'en': 'Select date', 'mr': 'तारीख निवडा'},
    'selectstartdate': {'en': 'Select Start Date', 'mr': 'प्रारंभ तारीख निवडा'},
    'selectenddate': {'en': 'Select End Date', 'mr': 'समाप्ती तारीख निवडा'},
    'ok': {'en': 'OK', 'mr': 'ठीक आहे'},
    'cancel': {'en': 'Cancel', 'mr': 'रद्द करा'},
    'of': {'en': 'of', 'mr': 'पैकी'},
    'novillages': {'en': 'No villages', 'mr': 'गावे नाहीत'},
    'tryadjustingfilters': {'en': 'Try adjusting your filters or come back later', 'mr': 'फिल्टर बदलून पहा किंवा नंतर परत या'},

    // ========== DailyPlansScreen ==========
    'selectday': {'en': 'Select Day', 'mr': 'दिवस निवडा'},
    'villagestovisit': {'en': 'Villages to Visit', 'mr': 'भेट द्यायची गावे'},
    'novillagesscheduled': {'en': 'No villages scheduled', 'mr': 'कोणतीही गावे नियोजित नाहीत'},
    'novisitsplanned': {'en': 'No visits planned for this day', 'mr': 'या दिवसासाठी भेटी नियोजित नाहीत'},
    'planaccessdenied': {'en': 'Plan access Denied', 'mr': 'योजना प्रवेश नाकारला'},
    'cantaccessvillage': {'en': "You can't access that village now", 'mr': 'तुम्ही आता त्या गावात प्रवेश करू शकत नाही'},
    'accessrestricted': {'en': 'Access Restricted', 'mr': 'प्रवेश प्रतिबंधित'},
    'cantaccessnow': {'en': "You can't access that now", 'mr': 'तुम्ही आता त्यात प्रवेश करू शकत नाही'},
    'visitcompleted': {'en': 'Visit Completed', 'mr': 'भेट पूर्ण'},
    'visitcompletedmsg': {'en': 'This village visit has already been completed.', 'mr': 'या गावाची भेट आधीच पूर्ण झाली आहे.'},
    'notyetavailable': {'en': 'Not Yet Available', 'mr': 'अद्याप उपलब्ध नाही'},
    'visitscheduledfor': {'en': 'This visit is scheduled for', 'mr': 'ही भेट यासाठी नियोजित आहे'},
    'startvisitafter': {'en': 'You can start this visit on or after the planned date.', 'mr': 'तुम्ही नियोजित तारखेला किंवा त्यानंतर ही भेट सुरू करू शकता.'},
    'okgotit': {'en': 'OK, Got It', 'mr': 'ठीक आहे, समजले'},
    'nodailyplans': {'en': 'No daily plans available', 'mr': 'दैनिक योजना उपलब्ध नाहीत'},
    'noscheduledvisits': {'en': 'This plan has no scheduled visits yet', 'mr': 'या योजनेत अद्याप कोणत्याही नियोजित भेटी नाहीत'},
    'planned': {'en': 'Planned', 'mr': 'नियोजित'},
    'couldnotopendir': {'en': 'Could not open directions', 'mr': 'दिशा उघडता आल्या नाहीत'},
    'erroropeningdir': {'en': 'Error opening directions', 'mr': 'दिशा उघडताना त्रुटी'},
  };

  static String get(String key, String lang) {
    return strings[key]?[lang] ?? strings[key]?['en'] ?? key;
  }
}
