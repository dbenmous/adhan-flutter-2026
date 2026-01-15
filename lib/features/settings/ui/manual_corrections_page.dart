import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/settings_service.dart';

class ManualCorrectionsPage extends StatefulWidget {
  const ManualCorrectionsPage({super.key});

  @override
  State<ManualCorrectionsPage> createState() => _ManualCorrectionsPageState();
}

class _ManualCorrectionsPageState extends State<ManualCorrectionsPage> {
  Map<String, int> _corrections = {
    'fajr': 0,
    'sunrise': 0,
    'dhuhr': 0,
    'asr': 0,
    'maghrib': 0,
    'isha': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = SettingsService().getSettings();
    setState(() {
      _corrections = Map.from(settings.manualCorrectionsMinutes);
      // Ensure all keys exist
      for (var key in ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha']) {
        if (!_corrections.containsKey(key)) {
          _corrections[key] = 0;
        }
      }
    });
  }

  Future<void> _updateCorrection(String prayer, int delta) async {
    setState(() {
      _corrections[prayer] = (_corrections[prayer] ?? 0) + delta;
    });
    await SettingsService().setManualCorrections(_corrections);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manual Corrections',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF1E1E1E) 
                : Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            children: List.generate(_corrections.length, (index) {
              final entry = _corrections.entries.elementAt(index);
              final prayer = entry.key;
              final minutes = entry.value;
              final isLast = index == _corrections.length - 1;
              final isDark = Theme.of(context).brightness == Brightness.dark;
              
              return Column(
                children: [
                   Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            prayer[0].toUpperCase() + prayer.substring(1),
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _updateCorrection(prayer, -1),
                          icon: Icon(Icons.remove_circle_outline, color: Theme.of(context).primaryColor),
                        ),
                        SizedBox(
                          width: 40,
                          child: Text(
                            '$minutes',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _updateCorrection(prayer, 1),
                          icon: Icon(Icons.add_circle_outline, color: Theme.of(context).primaryColor),
                        ),
                        Text(
                          'min',
                           style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                        ),
                      ],
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
    );
  }
}
