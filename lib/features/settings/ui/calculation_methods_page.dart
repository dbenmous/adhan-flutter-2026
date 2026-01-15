import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/settings_service.dart';
import '../../../shared/widgets/custom_switch.dart';

class CalculationMethodsPage extends StatefulWidget {
  const CalculationMethodsPage({super.key});

  @override
  State<CalculationMethodsPage> createState() => _CalculationMethodsPageState();
}

class _CalculationMethodsPageState extends State<CalculationMethodsPage> {
  bool _isAuto = true;
  String _selectedMethod = 'muslim_world_league';

  final List<String> _methods = [
    'muslim_world_league',
    'egyptian',
    'karachi',
    'umm_al_qura',
    'dubai',
    'moonsighting_committee',
    'north_america',
    'kuwait',
    'qatar',
    'singapore',
    'tehran',
    'turkey',
    'morocco',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = SettingsService().getSettings();
    setState(() {
      _isAuto = settings.autoCalculationMethod;
      _selectedMethod = settings.calculationMethodKey;
    });
  }

  Future<void> _saveSettings(String method, bool auto) async {
    await SettingsService().setCalculationMethodOptions(methodKey: method, auto: auto);
    setState(() {
      _selectedMethod = method;
      _isAuto = auto;
    });
    
    // Trigger update in previous screen if needed or just rely on service stream/rebuild
    // For now, simpler is fine.
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Calculation Methods',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Auto Toggle
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Automatic',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Auto-detect based on location',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                CustomSwitch(
                  value: _isAuto,
                  onChanged: (val) {
                    _saveSettings(_selectedMethod, val);
                  },
                  activeColor: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
              child: Container(
                 decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                child: Column(
                  children: List.generate(_methods.length, (index) {
                    final method = _methods[index];
                    final isSelected = method == _selectedMethod;
                    final isDisabled = _isAuto;
                    final isLast = index == _methods.length - 1;

                    return Column(
                      children: [
                        InkWell(
                           onTap: isDisabled 
                              ? null 
                              : () => _saveSettings(method, false),
                           borderRadius: BorderRadius.only(
                             topLeft: index == 0 ? const Radius.circular(30) : Radius.zero,
                             topRight: index == 0 ? const Radius.circular(30) : Radius.zero,
                             bottomLeft: isLast ? const Radius.circular(30) : Radius.zero,
                             bottomRight: isLast ? const Radius.circular(30) : Radius.zero,
                           ),
                           child: Padding(
                             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                             child: Row(
                               children: [
                                 Expanded(
                                   child: Text(
                                     method.replaceAll('_', ' ').toUpperCase(),
                                     style: GoogleFonts.outfit(
                                       fontSize: 16,
                                       fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                       color: isDisabled ? Colors.grey : (isSelected ? Theme.of(context).primaryColor : null),
                                     ),
                                   ),
                                 ),
                                 if (isSelected && !isDisabled)
                                   Icon(
                                     Icons.check_circle_rounded,
                                     color: Theme.of(context).primaryColor,
                                     size: 20,
                                   ),
                                 if (isSelected && isDisabled)
                                    Container(
                                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                       decoration: BoxDecoration(
                                         color: Colors.grey[300],
                                         borderRadius: BorderRadius.circular(8),
                                       ),
                                       child: Text(
                                         'AUTO',
                                         style: GoogleFonts.outfit(
                                           fontSize: 10, 
                                           fontWeight: FontWeight.bold,
                                           color: Colors.black54
                                         ),
                                       ),
                                     )
                               ],
                             ),
                           ),
                        ),
                        if (!isLast)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Divider(
                              height: 1,
                              thickness: 0.5,
                              color: isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
                            ),
                          ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
