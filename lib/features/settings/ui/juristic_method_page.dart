import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/models/settings_model.dart';
import '../../../shared/widgets/custom_switch.dart';

class JuristicMethodPage extends StatefulWidget {
  const JuristicMethodPage({super.key});

  @override
  State<JuristicMethodPage> createState() => _JuristicMethodPageState();
}

class _JuristicMethodPageState extends State<JuristicMethodPage> {
  bool _isAuto = true;
  String _selectedMadhab = 'shafi';

  final List<String> _madhabs = [
    'shafi',
    'hanafi',
  ];

  StreamSubscription<SettingsModel>? _subscription;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _subscription = SettingsService().settingsStream.listen((settings) {
      if (mounted) {
        setState(() {
          _isAuto = settings.autoMadhab;
          _selectedMadhab = settings.madhab;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = SettingsService().getSettings();
    setState(() {
      _isAuto = settings.autoMadhab;
      _selectedMadhab = settings.madhab;
    });
  }

  Future<void> _saveSettings(String madhab, bool auto) async {
    await SettingsService().setMadhabOptions(madhab: madhab, auto: auto);
    setState(() {
      _selectedMadhab = madhab;
      _isAuto = auto;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Juristic Method',
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
                    _saveSettings(_selectedMadhab, val);
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
                  children: List.generate(_madhabs.length, (index) {
                    final madhab = _madhabs[index];
                    final isSelected = madhab == _selectedMadhab;
                    // final isDisabled = _isAuto; // Removed to allow implicit switch
                    final isLast = index == _madhabs.length - 1;
                    
                    String displayName = madhab == 'shafi' 
                        ? 'Standard (Shafi, Maliki, Hanbali)' 
                        : 'Hanafi';

                    return Column(
                      children: [
                        InkWell(
                           onTap: () => _saveSettings(madhab, false), // Always set auto to false on tap
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
                                     displayName,
                                     style: GoogleFonts.outfit(
                                       fontSize: 16,
                                       fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                       color: isSelected ? Theme.of(context).primaryColor : null, // Always color selected
                                     ),
                                   ),
                                 ),
                                 if (isSelected) // Always show check if selected, even in Auto (simpler UI)
                                   Icon(
                                     Icons.check_circle_rounded,
                                     color: Theme.of(context).primaryColor,
                                     size: 20,
                                   ),
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
