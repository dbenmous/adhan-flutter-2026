import 'package:flutter/foundation.dart';

class CalculationMethodResolver {
  static String resolve(String? countryCode) {
    if (countryCode == null) return 'muslim_world_league';
    
    final code = countryCode.toUpperCase();
    
    if (_mapping.containsKey(code)) {
      return _mapping[code]!;
    }
    
    return 'muslim_world_league';
  }

  static bool hasSpecificMapping(String? countryCode) {
    if (countryCode == null) return false;
    return _mapping.containsKey(countryCode.toUpperCase());
  }

  static const Map<String, String> _mapping = {
    // North America (ISNA)
    'US': 'north_america', 'CA': 'north_america', 'MX': 'north_america',

    // South Asia (Karachi)
    'PK': 'karachi', 'IN': 'karachi', 'BD': 'karachi', 
    'AF': 'karachi', 'NP': 'karachi', 'LK': 'karachi',

    // Gulf (Umm Al Qura)
    'SA': 'umm_al_qura', 'YE': 'umm_al_qura', 'BH': 'umm_al_qura', 'OM': 'umm_al_qura',

    // UAE
    'AE': 'dubai',

    // Kuwait
    'KW': 'kuwait',

    // Qatar
    'QA': 'qatar',

    // Turkey, Azerbaijan
    'TR': 'turkey', 'AZ': 'turkey',

    // Iran
    'IR': 'tehran',

    // Levant & Iraq (Umm Al Qura per user req)
    'IQ': 'umm_al_qura', 'JO': 'umm_al_qura', 'PS': 'umm_al_qura', 
    'LB': 'umm_al_qura', 'SY': 'umm_al_qura',

    // Egypt & East Africa (Egyptian)
    'EG': 'egyptian', 'SD': 'egyptian', 'LY': 'egyptian', 
    'ET': 'egyptian', 'ER': 'egyptian', 'SO': 'egyptian', 'DJ': 'egyptian',

    // Morocco (Custom)
    'MA': 'morocco_custom',

    // Maghreb others (MWL per user req)
    'DZ': 'muslim_world_league', 'TN': 'muslim_world_league', 'MR': 'muslim_world_league',

    // Southeast Asia (Singapore)
    'SG': 'singapore', 'MY': 'singapore', 'ID': 'singapore', 
    'BN': 'singapore', 'PH': 'singapore', 'TH': 'singapore',

    // Central Asia (Hanafi -> Karachi)
    'UZ': 'karachi', 'TJ': 'karachi', 'TM': 'karachi',

    // Central Asia (others -> MWL)
    'KZ': 'muslim_world_league', 'KG': 'muslim_world_league',

    // Europe (MWL, except UK/Ireland)
    'GB': 'london_unified', 'IE': 'london_unified',
    'DE': 'muslim_world_league', 'FR': 'muslim_world_league',
    'NL': 'muslim_world_league', 'BE': 'muslim_world_league', 'ES': 'muslim_world_league',
    'IT': 'muslim_world_league', 'SE': 'muslim_world_league', 'NO': 'muslim_world_league',
    'DK': 'muslim_world_league', 'AT': 'muslim_world_league', 'CH': 'muslim_world_league',
    'PL': 'muslim_world_league', 'RU': 'muslim_world_league',
    'PT': 'muslim_world_league', 'GR': 'muslim_world_league', 'CZ': 'muslim_world_league',
    'HU': 'muslim_world_league', 'RO': 'muslim_world_league', 'BG': 'muslim_world_league',
    'UA': 'muslim_world_league', 'BY': 'muslim_world_league',

    // Australia & Oceania (MWL)
    'AU': 'muslim_world_league', 'NZ': 'muslim_world_league', 'FJ': 'muslim_world_league',

    // Sub-Saharan (Egyptian)
    'NG': 'egyptian', 'KE': 'egyptian', 'TZ': 'egyptian', 
    'GH': 'egyptian', 'CM': 'egyptian', 'TD': 'egyptian',

    // Sub-Saharan (MWL)
    'ZA': 'muslim_world_league', 'SN': 'muslim_world_league', 
    'ML': 'muslim_world_league', 'NE': 'muslim_world_league',

    // South America (MWL)
    'BR': 'muslim_world_league', 'AR': 'muslim_world_league', 'CL': 'muslim_world_league',
    'CO': 'muslim_world_league', 'VE': 'muslim_world_league', 'PE': 'muslim_world_league',

    // East Asia (MWL)
    'CN': 'muslim_world_league', 'JP': 'muslim_world_league', 'KR': 'muslim_world_league',
  };
}
