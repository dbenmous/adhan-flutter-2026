import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/models/settings_model.dart';
import '../../settings/ui/location_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  final _settingsService = SettingsService();
  final _locationService = LocationService();
  
  int _currentPage = 0;
  bool _isLoadingLocation = false;
  String? _locationName;
  
  // Per-prayer notification settings
  Map<String, NotificationType> _prayerSettings = {
    'Fajr': NotificationType.adhan,
    'Dhuhr': NotificationType.adhan,
    'Asr': NotificationType.adhan,
    'Maghrib': NotificationType.adhan,
    'Isha': NotificationType.adhan,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5B7FFF), Color(0xFF8C9EFF), Color(0xFFE8EAF6)],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Progress indicator
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    _buildProgressDot(0),
                    const SizedBox(width: 8),
                    _buildProgressDot(1),
                  ],
                ),
              ),
              
              // PageView
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  children: [
                    _buildLocationStep(),
                    _buildNotificationsStep(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressDot(int index) {
    final isActive = _currentPage >= index;
    return Container(
      width: 40,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  // ==================== STEP 1: LOCATION ====================
  Widget _buildLocationStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Icon(Icons.location_on, size: 80, color: Colors.white.withOpacity(0.9)),
          const SizedBox(height: 24),
          Text(
            'Set Your Location',
            style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            'We need your location to calculate accurate prayer times for your area.',
            style: GoogleFonts.outfit(fontSize: 16, color: Colors.white.withOpacity(0.8)),
          ),
          if (_locationName != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.greenAccent, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _locationName!,
                      style: GoogleFonts.outfit(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Spacer(),
          
          // Main Button: Enable Location
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoadingLocation ? null : _handleEnableLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF5B7FFF),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoadingLocation
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_locationName != null ? 'Continue' : 'Enable Location', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          
          // Fallback: Search Manually
          Center(
            child: TextButton(
              onPressed: _handleSearchManually,
              child: Text(
                'Search City Manually',
                style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.9), fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _handleEnableLocation() async {
    if (_locationName != null) {
      // Already have location, proceed to next step
      _goToNextPage();
      return;
    }
    
    setState(() => _isLoadingLocation = true);
    
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationServicesDialog();
        setState(() => _isLoadingLocation = false);
        return;
      }

      // Check/request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showPermissionDeniedDialog();
          setState(() => _isLoadingLocation = false);
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _showPermissionDeniedDialog();
        setState(() => _isLoadingLocation = false);
        return;
      }

      // Get location
      final coords = await _locationService.getCurrentLocation();
      final name = await _locationService.getLocationName(coords);
      
      setState(() {
        _locationName = name;
        _isLoadingLocation = false;
      });
      
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    }
  }

  void _showLocationServicesDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text('Please enable location services to use automatic location.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Geolocator.openLocationSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text('Please grant location permission in app settings.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Geolocator.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSearchManually() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LocationPage()),
    );
    
    // Check if location was set
    final settings = _settingsService.getSettings();
    if (settings.manualLocationName != null) {
      setState(() => _locationName = settings.manualLocationName);
      _goToNextPage();
    }
  }

  // ==================== STEP 2: NOTIFICATIONS ====================
  Widget _buildNotificationsStep() {
    final prayers = ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.notifications_active, size: 60, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(height: 16),
          Text(
            'Notification Sounds',
            style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose how you want to be notified for each prayer.',
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.white.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 24),
          
          // Table layout
          Expanded(
            child: Container(
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
                      const SizedBox(width: 80), // Prayer name column
                      Expanded(
                        child: Center(
                          child: Text('Silent', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text('Beep', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text('Adhan', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
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
                      itemCount: prayers.length,
                      itemBuilder: (context, index) => _buildTableRow(prayers[index]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Finish Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleFinish,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF5B7FFF),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('Finish & Enable Alarms', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTableRow(String prayer) {
    // Ensure prayer exists in settings, default to adhan
    if (!_prayerSettings.containsKey(prayer)) {
      _prayerSettings[prayer] = NotificationType.adhan;
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              prayer,
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
          Expanded(
            child: Center(
              child: Radio<NotificationType>(
                value: NotificationType.silent,
                groupValue: _prayerSettings[prayer],
                onChanged: (value) => setState(() => _prayerSettings[prayer] = value!),
                fillColor: WidgetStateProperty.all(Colors.white),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Radio<NotificationType>(
                value: NotificationType.beep,
                groupValue: _prayerSettings[prayer],
                onChanged: (value) => setState(() => _prayerSettings[prayer] = value!),
                fillColor: WidgetStateProperty.all(Colors.white),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Radio<NotificationType>(
                value: NotificationType.adhan,
                groupValue: _prayerSettings[prayer],
                onChanged: (value) => setState(() => _prayerSettings[prayer] = value!),
                fillColor: WidgetStateProperty.all(Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleFinish() async {
    // 1. Save prayer notification settings
    final current = _settingsService.getSettings();
    await _settingsService.saveSettings(
      current.copyWith(prayerNotificationSettings: _prayerSettings),
    );
    
    // 2. Mark onboarding as complete FIRST (before any navigation or permission dialogs)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    
    // 3. Navigate to main app IMMEDIATELY
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
    
    // 4. Request notification permissions AFTER navigation (fire-and-forget)
    // This way, if user presses back from Android settings, they're already in the app
    NotificationService().requestPermissions();
  }

  void _goToNextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
