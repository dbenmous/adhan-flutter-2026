import 'package:adhan/adhan.dart';

class MadhabResolver {
  static Madhab resolve(String? countryCode) {
    if (countryCode == null) return Madhab.shafi;
    return resolveToKey(countryCode) == 'hanafi' ? Madhab.hanafi : Madhab.shafi;
  }

  static String resolveToKey(String? countryCode) {
    if (countryCode == null) return 'shafi';
    
    final code = countryCode.toUpperCase();
    
    if (_hanafiCountries.contains(code)) {
      return 'hanafi';
    }
    
    return 'shafi';
  }

  static const Set<String> _hanafiCountries = {
    // South Asia
    'PK', 'IN', 'BD', 'AF', 'NP',
    
    // Turkey & Balkans
    'TR', 'BA', 'XK', 'AL', 'MK',
    
    // Central Asia
    'UZ', 'TJ', 'TM', 'KZ', 'KG', 'AZ',
    
    // Middle East (Levant & Iraq)
    'IQ', 'SY', 'JO', 'PS', 'LB',
    
    // Egypt
    'EG',
    
    // China
    'CN',
    
    // Russia
    'RU',
  };
}
