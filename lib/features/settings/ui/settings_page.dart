import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/widgets/custom_switch.dart';
import 'package:adhan/adhan.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/prayer_time_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Temporary state 
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'English';
  String _calculationMethod = 'MuslimWorldLeague';
  String _locationName = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = SettingsService().getSettings();
    String locName = 'Unknown';
    if (settings.latitude != null && settings.longitude != null) {
       locName = await LocationService().getLocationName(
          Coordinates(settings.latitude!, settings.longitude!)
       );
    }

    setState(() {
      _calculationMethod = settings.calculationMethodKey;
      _locationName = locName;
    });
  }

  Future<void> _updateCalculationMethod(String methodKey) async {
    // a) Save new method
    await SettingsService().setCalculationMethod(methodKey);
    
    setState(() {
      _calculationMethod = methodKey;
    });

    // b) Cancel existing
    await NotificationService().cancelAllPrayerNotifications();

    // c) Recalculate
    final locationService = LocationService();
    final prayerService = PrayerTimeService();
    final settingsService = SettingsService();
    // Refresh settings explicitly to get the latest
    final currentSettings = settingsService.getSettings();
    final coords = await locationService.getCurrentLocation();

    // Use the model which now contains the new methodKey we just saved
    final prayerTimes = await prayerService.calculatePrayerTimes(coords, currentSettings);

    // d) Schedule new
    await NotificationService().scheduleAllPrayerNotifications(prayerTimes);

    // e) Show confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Prayer times updated for $methodKey')),
      );
    }
  }

  void _showCalculationMethodDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Select Calculation Method'),
          children: [
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
            'morocco'
          ].map((key) => SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _updateCalculationMethod(key); // Simplified key mapping
            },
            child: Text(key.replaceAll('_', ' ').toUpperCase()),
          )).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // General Section
              _buildSectionHeader('General'),
              const SizedBox(height: 8),
              _buildSettingsTile(
                isDark,
                icon: Icons.language,
                iconColor: Colors.blue,
                title: 'Language',
                value: _selectedLanguage,
                onTap: () {}, // TODO: Show language dialog
              ),
              const SizedBox(height: 12),
              _buildSettingsTile(
                isDark,
                icon: Icons.calculate_outlined,
                iconColor: Colors.orange,
                title: 'Calculation Method',
                value: _calculationMethod.replaceAll('_', ' ').toUpperCase(),
                onTap: _showCalculationMethodDialog,
              ),
              
              const SizedBox(height: 24),
              
              // Preferences Section
              _buildSectionHeader('Preferences'),
              const SizedBox(height: 8),
              _buildSwitchTile(
                isDark,
                title: 'Notifications',
                icon: Icons.notifications_active_rounded,
                iconColor: Colors.amber,
                value: _notificationsEnabled,
                onChanged: (val) {
                  setState(() => _notificationsEnabled = val);
                },
              ),
              const SizedBox(height: 12),
              _buildSettingsTile(
                isDark,
                icon: Icons.location_on_outlined,
                iconColor: Colors.green,
                title: 'Location',
                value: _locationName,
                onTap: () {}, 
              ),
               const SizedBox(height: 12),
              _buildSettingsTile(
                isDark,
                icon: Icons.app_settings_alt_rounded,
                iconColor: Colors.purple,
                title: 'App Icon',
                value: 'Default',
                onTap: () {}, 
              ),

              const SizedBox(height: 24),

              // About Section
              _buildSectionHeader('About'),
              const SizedBox(height: 8),
              _buildLinkTile(
                isDark: isDark,
                icon: Icons.privacy_tip_outlined,
                iconColor: Colors.grey,
                title: 'Privacy Policy',
                onTap: () {}, // TODO: Launch URL
              ),
               const SizedBox(height: 12),
              _buildLinkTile(
                isDark: isDark,
                icon: Icons.star_rate_rounded,
                iconColor: Colors.amber,
                title: 'Rate Us',
                onTap: () async {
                   // Placeholder for rating logic
                }, 
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    bool isDark, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
             Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey[400],
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    bool isDark, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
       decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
          ),
        ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          CustomSwitch(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTile({
    required bool isDark,
    required IconData icon,
    required Color iconColor, 
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.open_in_new,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
