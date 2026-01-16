
class CalculationMethodUtils {
  static String getAutoCalculationMethod(String countryCode) {
    // Normalize code
    final code = countryCode.toUpperCase();

    // 1. Direct Country Mapping
    if (_countryMethodMap.containsKey(code)) {
      return _countryMethodMap[code]!;
    }

    // 2. Region Fallbacks (Optional, if we had continent data, but country code is mostly enough)
    
    // Default
    return 'muslim_world_league';
  }

  static const Map<String, String> _countryMethodMap = {
    // --- North America (ISNA) ---
    'US': 'north_america', // USA
    'CA': 'north_america', // Canada

    // --- South Asia (Karachi: 18/18) ---
    'PK': 'karachi', // Pakistan
    'IN': 'karachi', // India
    'BD': 'karachi', // Bangladesh
    'AF': 'karachi', // Afghanistan
    'LK': 'karachi', // Sri Lanka
    'MV': 'karachi', // Maldives

    // --- Middle East (Umm Al Qura & Specifics) ---
    'SA': 'umm_al_qura', // Saudi Arabia
    'YE': 'umm_al_qura', // Yemen
    'OM': 'umm_al_qura', // Oman
    'BH': 'umm_al_qura', // Bahrain
    'JO': 'umm_al_qura', // Jordan (Often UAQ or Egyptian)
    'PS': 'egyptian',    // Palestine (Egyptian often used)
    'AE': 'dubai',       // UAE
    'KW': 'kuwait',      // Kuwait
    'QA': 'qatar',       // Qatar
    'IR': 'tehran',      // Iran
    'TR': 'turkey',      // Turkey
    'IQ': 'umm_al_qura', // Iraq (Sunni often UAQ/Karachi, Shia Leva. UAQ is safe default or Karachi) - Let's use UAQ.

    // --- Africa & Levant (Egyptian: 19.5/17.5) ---
    'EG': 'egyptian', // Egypt
    'SD': 'egyptian', // Sudan
    'LY': 'egyptian', // Libya
    'DZ': 'egyptian', // Algeria
    'TN': 'egyptian', // Tunisia
    'MA': 'morocco',  // Morocco (Custom)
    'SY': 'egyptian', // Syria
    'LB': 'egyptian', // Lebanon

    // --- Southeast Asia (Egyptian/Singapore) ---
    'SG': 'singapore', // Singapore
    'MY': 'egyptian',  // Malaysia (Egyptian is common alternative to local JAKIM)
    'ID': 'egyptian',  // Indonesia (Egyptian is common alternative to local Kemenag)
    'BN': 'singapore', // Brunei (Close to SG)

    // --- Europe (Muslim World League: 18/17) ---
    'GB': 'muslim_world_league', 'FR': 'muslim_world_league', 'DE': 'muslim_world_league',
    'IT': 'muslim_world_league', 'ES': 'muslim_world_league', 'NL': 'muslim_world_league',
    'BE': 'muslim_world_league', 'SE': 'muslim_world_league', 'NO': 'muslim_world_league',
    'DK': 'muslim_world_league', 'RU': 'muslim_world_league', 'BA': 'muslim_world_league',
    'AL': 'muslim_world_league', 'XK': 'muslim_world_league',
    
    // --- Rest of World (MWL) ---
    'AU': 'muslim_world_league', // Australia
    'NZ': 'muslim_world_league', // New Zealand
  };
}
