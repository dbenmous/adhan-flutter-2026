import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/models/settings_model.dart';

/// Shared notification settings page used by:
/// - Onboarding (Step 2)
/// - SettingsPage (Notification tile tap)
/// - HomePage (Prayer bell tap)
class NotificationSettingsPage extends StatefulWidget {
  /// If true, shows as a full page with back button. If false, embedded mode.
  final bool showAppBar;
  
  /// Callback when settings are saved (for onboarding flow)
  final VoidCallback? onComplete;
  
  const NotificationSettingsPage({
    super.key,
    this.showAppBar = true,
    this.onComplete,
  });

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> with WidgetsBindingObserver {
  final _settingsService = SettingsService();
  bool _isSystemAllowed = true;
  
  // Per-prayer notification settings
  late Map<String, NotificationType> _prayerSettings;
  
  // Prayers list - Sunrise has no Adhan option
  final List<String> _prayers = ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
    _checkSystemPermission();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-check permission when returning from system settings
      _checkSystemPermission();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _loadSettings() {
    final settings = _settingsService.getSettings();
    _prayerSettings = Map.from(settings.prayerNotificationSettings);
    
    // Ensure all prayers have a default
    for (final prayer in _prayers) {
      _prayerSettings.putIfAbsent(prayer, () => NotificationType.adhan);
    }
    // Sunrise cannot have Adhan - force to beep if set to adhan
    if (_prayerSettings['Sunrise'] == NotificationType.adhan) {
      _prayerSettings['Sunrise'] = NotificationType.beep;
    }
  }

  void _checkSystemPermission() {
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (mounted) setState(() => _isSystemAllowed = isAllowed);
    });
  }

  Future<void> _requestPermission() async {
    await NotificationService().requestPermissions();
    _checkSystemPermission();
  }

  Future<void> _saveSettings() async {
    final current = _settingsService.getSettings();
    await _settingsService.saveSettings(
      current.copyWith(prayerNotificationSettings: _prayerSettings),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Widget content = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF5B7FFF),
            const Color(0xFF8C9EFF),
            isDark ? Colors.grey[900]! : const Color(0xFFE8EAF6),
          ],
          stops: const [0.0, 0.3, 1.0],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Icon(Icons.notifications_active, size: 48, color: Colors.white.withValues(alpha: 0.9)),
              const SizedBox(height: 12),
              Text(
                'Notification Settings',
                style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose how you want to be notified for each prayer.',
                style: GoogleFonts.outfit(fontSize: 14, color: Colors.white.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 20),
              
              // System permission section
              _buildSystemPermissionCard(),
              
              const SizedBox(height: 16),
              
              // Per-prayer table
              Expanded(
                child: _buildPrayerTable(),
              ),
              
              const SizedBox(height: 16),
              
              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _saveSettings();
                    if (widget.onComplete != null) {
                      widget.onComplete!();
                    } else if (widget.showAppBar && mounted) {
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF5B7FFF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('Save Settings', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.showAppBar) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: content,
      );
    }
    
    return content;
  }

  Widget _buildSystemPermissionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            _isSystemAllowed ? Icons.check_circle : Icons.warning_amber_rounded,
            color: _isSystemAllowed ? Colors.greenAccent : Colors.orange,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'System Notifications',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                Text(
                  _isSystemAllowed ? 'Enabled' : 'Tap to enable',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: _isSystemAllowed ? Colors.white70 : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          if (!_isSystemAllowed)
            ElevatedButton(
              onPressed: _requestPermission,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF5B7FFF),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Enable', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildPrayerTable() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Header row
          Row(
            children: [
              const SizedBox(width: 80),
              Expanded(
                child: Center(
                  child: Text('Silent', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text('Beep', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text('Adhan', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(height: 8),
          
          // Prayer rows
          Expanded(
            child: ListView.builder(
              itemCount: _prayers.length,
              itemBuilder: (context, index) => _buildPrayerRow(_prayers[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerRow(String prayer) {
    final isSunrise = prayer == 'Sunrise';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              prayer,
              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
          // Silent
          Expanded(
            child: Center(
              child: Radio<NotificationType>(
                value: NotificationType.silent,
                groupValue: _prayerSettings[prayer],
                onChanged: (value) {
                  setState(() => _prayerSettings[prayer] = value!);
                },
                fillColor: WidgetStateProperty.all(Colors.white),
              ),
            ),
          ),
          // Beep
          Expanded(
            child: Center(
              child: Radio<NotificationType>(
                value: NotificationType.beep,
                groupValue: _prayerSettings[prayer],
                onChanged: (value) {
                  setState(() => _prayerSettings[prayer] = value!);
                },
                fillColor: WidgetStateProperty.all(Colors.white),
              ),
            ),
          ),
          // Adhan (disabled for Sunrise)
          Expanded(
            child: Center(
              child: isSunrise
                  ? Icon(Icons.block, color: Colors.white.withValues(alpha: 0.3), size: 20)
                  : Radio<NotificationType>(
                      value: NotificationType.adhan,
                      groupValue: _prayerSettings[prayer],
                      onChanged: (value) {
                        setState(() => _prayerSettings[prayer] = value!);
                      },
                      fillColor: WidgetStateProperty.all(Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
