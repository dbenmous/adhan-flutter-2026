import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/services/prayer_time_service.dart';
import 'package:adhan/adhan.dart'; // Ensure we have access to adhan if needed, mostly for types but here we use core services
import 'package:hijri/hijri_calendar.dart';

class HijriAdjustmentTile extends StatefulWidget {
  final int currentAdjustment; // We pass this in usually, or fetch it
  
  const HijriAdjustmentTile({
    super.key,
    required this.currentAdjustment,
  });

  @override
  State<HijriAdjustmentTile> createState() => _HijriAdjustmentTileState();
}

class _HijriAdjustmentTileState extends State<HijriAdjustmentTile> {
  late int _adjustment;

  @override
  void initState() {
    super.initState();
    _adjustment = widget.currentAdjustment;
  }
  
  @override
  void didUpdateWidget(HijriAdjustmentTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentAdjustment != widget.currentAdjustment) {
      _adjustment = widget.currentAdjustment;
    }
  }

  void _updateAdjustment(int delta) {
    final newValue = (_adjustment + delta).clamp(-2, 2);
    if (newValue != _adjustment) {
      setState(() {
        _adjustment = newValue;
      });
      // Save to SettingsService
      SettingsService().setHijriAdjustment(newValue);
    }
  }

  String _getHijriPreview() {
    // Calculate Hijri date for TODAY with the pending adjustment
    final now = DateTime.now();
    // Using existing service method if available or direct
    // PrayerTimeService() instance might need to be created or use direct logic
    
    // Using the helper from PrayerTimeService to ensure consistency with Home Page
    // Assuming PrayerTimeService().getHijriDate(date, adjustment) exists as seen in planning
    final hijri = PrayerTimeService().getHijriDate(now, _adjustment);
    return "${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear}";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = Colors.indigoAccent;

    return Container( // Use same container style as existing settings tiles
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      // We will wrap this in the existing _buildGroupTile or similar structure in the parent,
      // BUT the requirement was a custom tile.
      // If we look at SettingsPage structure, it builds "Groups" of tiles. 
      // This widget effectively replaces the content of a tile or is a standalone tile.
      // To match exactly, let's just build the 'Row' content if we want to reuse the container,
      // OR build the whole container if we want it to be standalone.
      // Given the custom controls, let's make it a standalone Container matching the style.
      
      // WAIT: SettingsPage uses `_buildGroupTile` which takes title/value/icon. 
      // This needs custom interactive controls (buttons).
      // So we will replicate the styling of `_buildSettingsTile` / `_buildGroupTile` here.
      
      // Actually, looking at `settings_page.dart` line 665 `_buildSettingsGroup`, it takes a list of widgets.
      // `_buildGroupTile` returns a Column (Inkwell + Divider).
      // So this widget should behave like `_buildGroupTile`.
        
      child: Column(
        children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.nightlight_round, color: iconColor, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hijri Date Correction',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                       Text(
                        'Today: ${_getHijriPreview()}',
                        style: GoogleFonts.outfit(
                          fontSize: 12, // Subtitle size
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Controls
                Row(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     _buildCtrlBtn(Icons.remove, () => _updateAdjustment(-1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          _adjustment > 0 ? '+${_adjustment}' : '${_adjustment}',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                     _buildCtrlBtn(Icons.add, () => _updateAdjustment(1)),
                   ],
                )
              ],
            ),
             // No divider needed if it's the last item, but if not we might need one.
             // Ideally the parent handles the divider or we accept a 'showDivider' param.
             // For now, let's assume we might need one. 
             // We'll leave it out for now and let the parent group handle spacing or we create a transparent one.
        ],
      ),
    );
  }

  Widget _buildCtrlBtn(IconData icon, VoidCallback onTap) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: Colors.grey),
        ),
      );
  }
}
