import 'package:provider/provider.dart';
import '../language_jsons/execution_strings.dart';
import '../provider/language_provider.dart';


/// Helper class for language-aware display names
class OfficialDisplayNames {
  static String getShopownerDisplayName(String official, String lang) {
    final match = RegExp(r'shopowner_(\d+)').firstMatch(official);
    if (match != null) {
      int num = int.tryParse(match.group(1) ?? '1') ?? 1;
      bool isMandatory = official.contains('mandatory');
      String suffix = isMandatory ? ' ⭐' : '';
      String label = VillageExecutionStrings.get('shopowner', lang);
      return '$label $num$suffix';
    }
    return VillageExecutionStrings.get('shopowner', lang);
  }

  static String getHotspotDisplayName(String official, String lang) {
    if (VillageExecutionStrings.get(official, lang) != official) {
      return '${VillageExecutionStrings.get(official, lang)} ⭐';
    }
    return VillageExecutionStrings.get('hotspot', lang);
  }

  static String getGovtOfficialDisplayName(String official, String lang) {
    return VillageExecutionStrings.get(official, lang);
  }

  static String getMukkadamDisplayName(String official, String lang) {
    final match = RegExp(r'mukkadam_(\d+)').firstMatch(official);
    if (match != null) {
      int num = int.tryParse(match.group(1) ?? '1') ?? 1;
      return '${VillageExecutionStrings.get('mukkadam', lang)} $num';
    }
    return VillageExecutionStrings.get('mukkadam', lang);
  }

  static String getInfluentialPersonDisplayName(String official, String lang) {
    final match = RegExp(r'influential_person_(\d+)').firstMatch(official);
    if (match != null) {
      int num = int.tryParse(match.group(1) ?? '1') ?? 1;
      return '${VillageExecutionStrings.get('influential', lang)} $num';
    }
    return VillageExecutionStrings.get('influential', lang);
  }

  static String getOtherPersonDisplayName(String official, String lang) {
    if (official == 'other') {
      return VillageExecutionStrings.get('other_person', lang);
    }
    final match = RegExp(r'other_(\d+)').firstMatch(official);
    if (match != null) {
      int num = int.tryParse(match.group(1) ?? '1') ?? 1;
      String label = lang == 'mr' ? 'इतर' : 'Other';
      return '$label $num';
    }
    return VillageExecutionStrings.get('other_person', lang);
  }

  static String getVillagePocDisplayName(String lang) {
    return '${VillageExecutionStrings.get('village_poc', lang)} ⭐';
  }

  /// Main method — now takes `lang`
  static String getDisplayName(String official, String lang) {
    if (official.startsWith('shopowner_')) return getShopownerDisplayName(official, lang);
    if (official.startsWith('hotspot_')) return getHotspotDisplayName(official, lang);
    if (official.startsWith('mukkadam_')) return getMukkadamDisplayName(official, lang);
    if (official.startsWith('influential_person')) return getInfluentialPersonDisplayName(official, lang);
    if (official.startsWith('other_') || official == 'other') return getOtherPersonDisplayName(official, lang);
    if (official == 'village_poc') return getVillagePocDisplayName(lang);
    if (_isGovtOfficial(official)) return getGovtOfficialDisplayName(official, lang);
    return official.replaceAll('_', ' ').split(' ')
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : '')
        .join(' ');
  }

  static bool _isGovtOfficial(String official) {
    const govtOfficials = [
      'sarpanch', 'secretary', 'talathi', 'postman', 'vdo',
      'principal', 'agriculture_officer', 'anganwadi_worker',
      'asha_worker', 'police_patil', 'krishi_sahayak', 'gram_panchayat_member',
    ];
    return govtOfficials.contains(official);
  }
}
