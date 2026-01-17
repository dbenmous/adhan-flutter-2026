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
import 'package:shared_preferences/shared_preferences.dart'; // Added import for SharedPreferences

import 'calculation_methods_page.dart';
import 'manual_corrections_page.dart';
import 'manual_corrections_page.dart';
import 'location_page.dart';
import 'juristic_method_page.dart';
import 'app_icon_page.dart'; // Add import
import 'notification_settings_page.dart';
import 'sound_selection_page.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:disable_battery_optimization/disable_battery_optimization.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Temporary state 
  bool _notificationsEnabled = true;
  bool _isSystemNotifAllowed = true; // Track actual system permission
  String _selectedLanguage = 'English';
  String _calculationMethod = 'MuslimWorldLeague';
  String _locationName = 'Loading...';
  
  // New State variables for UI preview
  String _madhab = 'Shafi';
  String _highLatitude = 'Middle of Night';
  String _dstMode = 'Auto';
  String _adhanSoundName = 'Default';
  bool? _isBatteryOptimized; // null=loading, true=unrestricted(good), false=restricted(bad)
  String _appIconName = 'Default'; // Add state variable

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkSystemPermission();
  }

  void _checkSystemPermission() {
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (mounted) setState(() => _isSystemNotifAllowed = isAllowed);
    });
  }

  Future<void> _loadSettings() async {
    final settings = SettingsService().getSettings();
    final prefs = await SharedPreferences.getInstance(); // Get prefs
    
    // Check battery optimization status
    _isBatteryOptimized = await DisableBatteryOptimization.isBatteryOptimizationDisabled;
    
    String locName = 'Unknown';
    if (settings.latitude != null && settings.longitude != null) {
       locName = await LocationService().getLocationName(
          Coordinates(settings.latitude!, settings.longitude!)
       );
    }

    setState(() {
      _calculationMethod = settings.autoCalculationMethod ? 'Auto' : settings.calculationMethodKey;
      _locationName = locName;
      final madhabName = settings.madhab == 'hanafi' ? 'Hanafi' : 'Shafi';
      _madhab = settings.autoMadhab ? 'Auto ($madhabName)' : madhabName;
      _highLatitude = settings.highLatitudeRule.replaceAll('_', ' ').toUpperCase(); // basic formatting
      _dstMode = settings.dstMode.toUpperCase();
      _dstMode = settings.dstMode.toUpperCase();
      _notificationsEnabled = settings.areNotificationsEnabled;
      // Basic formatting for display
      _adhanSoundName = settings.adhanSound.replaceAll('adhan_', '').replaceAll('_', ' ').toUpperCase();
      _appIconName = prefs.getString('app_icon_name') ?? 'Default'; // Load icon name
    });
  }

  // Helper to refresh and trigger recalculations
  Future<void> _refreshSettings() async {
    await _loadSettings();
    // In a real app, logic to reschedule notifications would go here or triggered by service listener
    // For now, let's just reload UI state
  }

  void _showJuristicDialog() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        title: const Text('Juristic Method'),
        children: [
          SimpleDialogOption(
            onPressed: () async {
               await SettingsService().setMadhab('shafi');
               Navigator.pop(context);
               _refreshSettings();
            },
            child: const Text('Standard (Shafi, Maliki, Hanbali)'),
          ),
          SimpleDialogOption(
             onPressed: () async { 
               await SettingsService().setMadhab('hanafi'); 
               Navigator.pop(context);
               _refreshSettings();
             },
             child: const Text('Hanafi'),
          ),
        ],
      ),
    );
  }

  void _showHighLatitudeDialog() {
     showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        title: const Text('High Latitude Rule'),
        children: [
          SimpleDialogOption(
             onPressed: () async {
               await SettingsService().setHighLatitudeRule('middle_of_night');
               Navigator.pop(context);
               _refreshSettings();
             },
             child: const Text('Middle of the Night'),
          ),
          SimpleDialogOption(
             onPressed: () async {
               await SettingsService().setHighLatitudeRule('seventh_of_night');
               Navigator.pop(context);
               _refreshSettings();
             },
             child: const Text('One Seventh of the Night'),
          ),
           SimpleDialogOption(
             onPressed: () async {
               await SettingsService().setHighLatitudeRule('twilight_angle');
               Navigator.pop(context);
               _refreshSettings();
             },
             child: const Text('Twilight Angle'),
          ),
        ],
      ),
    );   
  }

  void _showDstDialog() {
      showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        title: const Text('Daylight Saving'),
        children: [
          SimpleDialogOption(
             onPressed: () async {
               await SettingsService().setDstSettings(mode: 'auto', offset: 0);
               Navigator.pop(context);
               _refreshSettings();
             },
             child: const Text('Automatic'),
          ),
          SimpleDialogOption(
             onPressed: () async {
               // Manual 1 hour
               await SettingsService().setDstSettings(mode: 'manual', offset: 60);
               Navigator.pop(context);
               _refreshSettings();
             },
             child: const Text('Manual (+1 Hour)'),
          ),
           SimpleDialogOption(
             onPressed: () async {
               // Manual 0
               await SettingsService().setDstSettings(mode: 'manual', offset: 0);
               Navigator.pop(context);
               _refreshSettings();
             },
             child: const Text('Manual (Off)'),
          ),
        ],
      ),
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
              _buildSettingsGroup(isDark, [
                _buildGroupTile(
                  isDark,
                  icon: Icons.language,
                  iconColor: Colors.blue,
                  title: 'Language',
                  value: _selectedLanguage,
                  onTap: () {}, // TODO: Show language dialog
                  showDivider: false,
                ),
              ]),
              
              const SizedBox(height: 24),

              // Calculation Section
              _buildSectionHeader('Calculation'),
              const SizedBox(height: 8),
              _buildSettingsGroup(isDark, [
                _buildGroupTile(
                  isDark,
                  icon: Icons.calculate_outlined,
                  iconColor: Colors.orange,
                  title: 'Calculation Methods',
                  value: _calculationMethod.replaceAll('_', ' ').toUpperCase(),
                  onTap: () => Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => const CalculationMethodsPage())
                  ),
                ),
                _buildGroupTile(
                  isDark,
                  icon: Icons.balance_outlined,
                  iconColor: Colors.teal,
                  title: 'Juristic',
                  value: _madhab,
                  onTap: () => Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => const JuristicMethodPage())
                  ),
                ),
                _buildGroupTile(
                  isDark,
                  icon: Icons.public,
                  iconColor: Colors.indigo,
                  title: 'Higher Latitudes',
                  value: _highLatitude,
                  onTap: _showHighLatitudeDialog,
                ),
                _buildGroupTile(
                  isDark,
                  icon: Icons.tune,
                  iconColor: Colors.brown,
                  title: 'Manual Corrections',
                  value: 'Adjust',
                  onTap: () => Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => const ManualCorrectionsPage())
                  ),
                ),
                _buildGroupTile(
                  isDark,
                  icon: Icons.schedule,
                  iconColor: Colors.redAccent,
                  title: 'Daylight Saving',
                  value: _dstMode,
                  onTap: _showDstDialog,
                  showDivider: false, // Last item
                ),
              ]),

              const SizedBox(height: 24),
              
              // Preferences Section
              _buildSectionHeader('Preferences'),
              const SizedBox(height: 8),
              _buildSettingsGroup(isDark, [
                _buildGroupTile(
                  isDark,
                  icon: Icons.notifications_active_rounded,
                  iconColor: Colors.amber,
                  title: 'Notifications',
                  value: !_isSystemNotifAllowed 
                      ? 'System permission denied: tap to enable' 
                      : 'Configure alerts',
                  valueColor: !_isSystemNotifAllowed ? Colors.orange : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NotificationSettingsPage()),
                    ).then((_) {
                      _loadSettings();
                      _checkSystemPermission();
                    });
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(
                    height: 1, 
                    thickness: 0.5,
                    color: isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0)
                  ),
                ),
                _buildGroupTile(
                  isDark,
                  icon: Icons.location_on_outlined,
                  iconColor: Colors.green,
                  title: 'Location',
                  value: _locationName,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LocationPage()),
                    ).then((_) => _loadSettings());
                  }, 
                ),
                _buildGroupTile(
                  isDark,
                   icon: Icons.music_note_rounded,
                  iconColor: Colors.deepOrange,
                  title: 'Adhan Sound',
                  value: _adhanSoundName,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SoundSelectionPage()),
                    ).then((_) => _loadSettings());
                  }, 
                ),
                 _buildGroupTile(
                  isDark,
                  icon: Icons.app_settings_alt_rounded,
                  iconColor: Colors.purple,
                  title: 'App Icon',
                  value: _appIconName,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AppIconPage()),
                    ).then((_) => _loadSettings());
                  }, 
                  showDivider: false
                ),
              ]),

              const SizedBox(height: 24),

              // About Section
              _buildSectionHeader('About'),
              const SizedBox(height: 8),
              _buildSettingsGroup(isDark, [
                _buildGroupTile(
                  isDark,
                  icon: Icons.privacy_tip_outlined,
                  iconColor: Colors.grey,
                  title: 'Privacy Policy',
                  value: '',
                  onTap: () {}, 
                ),
                _buildGroupTile(
                  isDark,
                   icon: Icons.star_rate_rounded,
                  iconColor: Colors.amber,
                  title: 'Rate Us',
                  value: '',
                  onTap: () {}, 
                  showDivider: false
                ),
              ]),

              const SizedBox(height: 24),

              // Debug / Tests Section
              _buildSectionHeader('Debug / Tests'),
              const SizedBox(height: 8),
              _buildSettingsGroup(isDark, [
                 _buildGroupTile(
                  isDark,
                  icon: Icons.battery_alert_rounded,
                  iconColor: (_isBatteryOptimized == true) ? Colors.green : Colors.red,
                  title: 'Battery Optimization',
                  value: (_isBatteryOptimized == true) 
                      ? 'Unrestricted (Good)' 
                      : 'Restricted (Tap to Fix)',
                  valueColor: (_isBatteryOptimized == true) ? Colors.green : Colors.red,
                  onTap: () async {
                    if (_isBatteryOptimized == true) {
                       if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Battery is already unrestricted. Great!')),
                        );
                      }
                    } else {
                      await DisableBatteryOptimization.showDisableBatteryOptimizationSettings();
                      // Refresh after coming back
                      await Future.delayed(const Duration(seconds: 1)); // small delay
                      _loadSettings();
                    }
                  },
                ),
                 _buildGroupTile(
                  isDark,
                  icon: Icons.timer_outlined,
                  iconColor: Colors.orange,
                  title: 'Test Alarm (15s)',
                  value: 'Tap then LOCK screen',
                  valueColor: Colors.orange,
                  onTap: () async {
                    await NotificationService().scheduleTestAlarm(seconds: 15);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Alarm set for 15 seconds! Lock your screen NOW.')),
                      );
                    }
                  },
                ),
                 _buildGroupTile(
                  isDark,
                  icon: Icons.timer_10_outlined,
                  iconColor: Colors.deepOrange,
                  title: 'Test Alarm (10min)',
                  value: 'Lock screen and wait',
                  onTap: () async {
                    await NotificationService().scheduleTestAlarm(seconds: 600);
                     if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Alarm set for 10 minutes.')),
                      );
                    }
                  },
                ),
                 _buildGroupTile(
                  isDark,
                  icon: Icons.hourglass_bottom_rounded,
                  iconColor: Colors.redAccent,
                  title: 'Test Alarm (60min)',
                  value: 'Deep Doze test',
                  onTap: () async {
                    await NotificationService().scheduleTestAlarm(seconds: 3600);
                     if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Alarm set for 60 minutes.')),
                      );
                    }
                  },
                  showDivider: false
                ),
              ]),

              const SizedBox(height: 100),
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

  Widget _buildSettingsGroup(bool isDark, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildGroupTile(
    bool isDark, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required VoidCallback onTap,
    bool showDivider = true,
    Color? valueColor,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30), // Match group radius for ripple
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    shape: BoxShape.circle, // Circular shape
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
                Flexible(
                  child: Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: valueColor ?? Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
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
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16), // Padding from edges
            child: Divider(
              height: 1,
              thickness: 0.5, // Thin line
              color: isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
            ),
          ),
      ],
    );
  }
}
