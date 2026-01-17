import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glass/glass.dart';
import 'package:intl/intl.dart';
import 'package:adhan/adhan.dart';
import 'package:hijri/hijri_calendar.dart';
import '../../../core/services/prayer_time_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/models/settings_model.dart';
import 'monthly_calendar_page.dart';
import 'weather_widgets.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:awesome_notifications/awesome_notifications.dart';
import '../../settings/ui/notification_settings_page.dart';
import 'package:disable_battery_optimization/disable_battery_optimization.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final PrayerTimeService _prayerService = PrayerTimeService();
  final LocationService _locationService = LocationService();
  final SettingsService _settingsService = SettingsService();

  late Future<PrayerTimes?> _prayerTimesFuture;
  Map<String, dynamic>? _nextPrayerData;
  Timer? _timer;
  StreamSubscription<SettingsModel>? _settingsSubscription;
  Duration _currentCountdown = Duration.zero;
  String _locationName = 'Loading...';
  String _hijriDateString = '';
  bool _isSystemMuted = false;
  bool _isBatteryOptimized = false; // "true" means BAD (restricted)
  bool _showBatteryBanner = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkBatteryStatus();
    _refreshData();
    _startTimer();
    checkSystemPermission();
    _settingsSubscription = _settingsService.settingsStream.listen((_) {
      if (mounted) {
        setState(() {
          _refreshData();
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-check permission when user returns from settings
      checkSystemPermission();
      _checkBatteryStatus(); // Re-check battery optimization
    }
  }

  /// Public method to check system notification permission
  void checkSystemPermission() {
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (mounted) setState(() => _isSystemMuted = !isAllowed);
    });
  }

  Future<void> _checkBatteryStatus() async {
    final isDisabled = await DisableBatteryOptimization.isBatteryOptimizationDisabled;
    if (mounted) {
      setState(() {
        // if isDisabled is true, then optimization is OFF (Good)
        // if isDisabled is false, then optimization is ON (Bad)
        _isBatteryOptimized = !(isDisabled ?? false);
      });
    }
  }

  void _refreshData() {
    _prayerTimesFuture = _loadPrayerTimes();
  }

  Future<PrayerTimes?> _loadPrayerTimes() async {
    try {
      final coords = await _locationService.getCurrentLocation();
      // Fetch name in parallel or sequence
      _locationService.getLocationName(coords).then((name) {
        if (mounted) setState(() => _locationName = name);
      });

      final settings = _settingsService.getSettings();
      final times = await _prayerService.calculatePrayerTimes(coords, settings);
      
      // Hijri Date
      final hijri = _prayerService.getHijriDate(DateTime.now(), settings.hijriAdjustmentDays);
      if (mounted) {
        setState(() {
           _hijriDateString = "${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear}";
        });
      }

      _nextPrayerData = await _prayerService.getNextPrayer(times);
      _updateCountdown();
      
      return times;
    } catch (e) {
      debugPrint("Error loading times: $e");
      return null;
    }
  }

  void _updateCountdown() {
    if (_nextPrayerData != null) {
      final nextTime = _nextPrayerData!['time'] as DateTime;
      final now = DateTime.now();
      if (nextTime.isAfter(now)) {
        setState(() {
          _currentCountdown = nextTime.difference(now);
        });
      } else {
        // Prayer time has passed - need to recalculate next prayer
        debugPrint('[HomePage] Prayer time passed, refreshing data...');
        _refreshData();
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        // Call _updateCountdown which handles both countdown and refresh logic
        _updateCountdown();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _settingsSubscription?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }


  String _formatInTimezone(DateTime date, String format) {
    final settings = _settingsService.getSettings();
    try {
      final location = tz.getLocation(settings.timezoneId);
      final tzDate = tz.TZDateTime.from(date, location);
      return DateFormat(format).format(tzDate);
    } catch (e) {
      return DateFormat(format).format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<PrayerTimes?>(
        future: _prayerTimesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _nextPrayerData == null) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF5B7FFF)));
          }
           if (snapshot.hasError || !snapshot.hasData) {
            // Simplified error state
             return const Center(child: Text("Loading..."));
           }

          final data = snapshot.data!;
          final nextName = _nextPrayerData?['name'] ?? 'None';
          final nextTime = _nextPrayerData?['time'] as DateTime?;

          // Formats are passed to _formatInTimezone
          const timeFormatStr = 'HH:mm';

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF5B7FFF),
                  Color(0xFF8C9EFF),
                  Color(0xFFE8EAF6),
                ],
                stops: [0.0, 0.4, 1.0],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // 1. Top Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTopButton('Share', Icons.share_rounded),
                          Row(
                            children: [
                              // Muted warning icon
                              if (_isSystemMuted)
                                IconButton(
                                  icon: const Icon(Icons.notifications_off, color: Colors.orange),
                                  onPressed: () => AwesomeNotifications().showNotificationConfigPage(),
                                  tooltip: 'Notifications Muted',
                                ),
                              _buildTopButton('Upgrade', null),
                              const SizedBox(width: 8),
                              _buildCircleButton(Icons.more_horiz),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // 2. Main Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      child: Row( // Changed to Row for side-by-side layout
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Left Side: Text Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Next Prayer in ${_formatDuration(_currentCountdown)}',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '$nextName ',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 42,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  nextTime != null ? _formatInTimezone(nextTime, timeFormatStr) : '--:--',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 42,
                                    height: 0.8, // Tighter height for alignment
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                                  style: GoogleFonts.outfit(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _hijriDateString,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Right Side: Native Weather Animation
                          SizedBox(
                            width: 120, 
                            height: 120,
                            child: Center(
                              child: _buildWeatherWidget(data),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 3. Date Carousel (Static for now)
                    SizedBox(
                      height: 80,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _buildDateItem(DateTime.now(), true),
                          _buildDateItem(DateTime.now().add(const Duration(days: 1)), false),
                          _buildDateItem(DateTime.now().add(const Duration(days: 2)), false),
                          _buildDateItem(DateTime.now().add(const Duration(days: 3)), false),
                          _buildDateItem(DateTime.now().add(const Duration(days: 4)), false),
                        ],
                      ),
                    ),

                    // 4. Location
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Row(
                        children: [
                          Text(
                            'Today',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _locationName,
                            style: GoogleFonts.outfit(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.edit_location_alt_outlined, color: Colors.white, size: 16),
                        ],
                      ),
                    ),

                    // 5. Prayer Grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      childAspectRatio: 1.1, // Decreased height
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      children: [
                        _buildPrayerCard('Fajr', _formatInTimezone(data.fajr, timeFormatStr), isNext: nextName == 'Fajr'),
                        _buildPrayerCard('Sunrise', _formatInTimezone(data.sunrise, timeFormatStr), isNext: nextName == 'Sunrise'),
                        _buildPrayerCard('Dhuhr', _formatInTimezone(data.dhuhr, timeFormatStr), isNext: nextName == 'Dhuhr'),
                        _buildPrayerCard('Asr', _formatInTimezone(data.asr, timeFormatStr), isNext: nextName == 'Asr'),
                        _buildPrayerCard('Maghrib', _formatInTimezone(data.maghrib, timeFormatStr), isNext: nextName == 'Maghrib'),
                        _buildPrayerCard('Isha', _formatInTimezone(data.isha, timeFormatStr), isNext: nextName == 'Isha'),
                      ],
                    ),

                    // 6. Battery Warning Widget (New Position)
                    _buildBatteryWarning(),

                    // 7. Calendar Banner
                   GestureDetector(
                     onTap: () {
                       Navigator.push(
                         context,
                         MaterialPageRoute(builder: (context) => const MonthlyCalendarPage()),
                       );
                     },
                     child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Monthly Calendar',
                              style: GoogleFonts.outfit(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                             const SizedBox(height: 4),
                             Text(
                              'Tap to view full calendar.',
                              style: GoogleFonts.outfit(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                   ),
                    const SizedBox(height: 100), // Bottom padding for nav bar
                  ],
                ),
              ),
            ),
          );
        }
      ),
      // bottomNavigationBar: _buildBatteryBanner(), // Removed
    );
  }
  
  Widget _buildBatteryWarning() {
    if (!_isBatteryOptimized || !_showBatteryBanner) return const SizedBox.shrink();
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5), // White transparent 50%
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
               onTap: () {
                 DisableBatteryOptimization.showDisableBatteryOptimizationSettings();
               },
               child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Adhan is not authorized",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold, 
                      color: Colors.redAccent.shade200, // Light red
                      fontSize: 16
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Tap to fix",
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
          
          // Arrow Button
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.black54),
             onPressed: () {
                DisableBatteryOptimization.showDisableBatteryOptimizationSettings();
             },
             padding: EdgeInsets.zero,
             constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16),
          
          // X Icon (Red)
          IconButton(
            icon: const Icon(Icons.close, size: 20, color: Colors.redAccent),
            onPressed: () => setState(() => _showBatteryBanner = false),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          )
        ],
      ),
    );
  }

  String _getPrayerName(Prayer p) {
      if (p == Prayer.none) return "Fajr"; // Wrapped
      return p.name[0].toUpperCase() + p.name.substring(1);
    }
  
    // ... helper methods _buildTopButton, _buildCircleButton, _buildDateItem remain ...

    Widget _buildTopButton(String label, IconData? icon) {
       return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
               Text(
                label,
                style: GoogleFonts.outfit(color: const Color(0xFF1E1E1E), fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ] else ...[
               Text(
                label,
                style: GoogleFonts.outfit(color: const Color(0xFF1E1E1E), fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ]
          ],
        ).asGlass(tintColor: Colors.white, clipBorderRadius: BorderRadius.circular(20), blurX: 10, blurY: 10),
      );
    }
  
     Widget _buildCircleButton(IconData icon) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), shape: BoxShape.circle),
        child: Icon(icon, color: const Color(0xFF1E1E1E), size: 20),
      ).asGlass(tintColor: Colors.white, clipBorderRadius: BorderRadius.circular(50), blurX: 10, blurY: 10);
    }
  
    Widget _buildDateItem(DateTime date, bool isSelected) {
      return Container(
        margin: const EdgeInsets.only(right: 12),
        width: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
          boxShadow: [if (isSelected) const BoxShadow(color: Colors.black26, blurRadius: 8)],
        ),
        child: Container(
          decoration: BoxDecoration(
             shape: BoxShape.circle,
             gradient: const LinearGradient(
               colors: [Color(0xFFFFD54F), Color(0xFFFF6F00)],
               begin: Alignment.topLeft,
               end: Alignment.bottomRight,
             ),
          ),
          child: Center(
             child: Column(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 Text(
                   date.day.toString(),
                   style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                 ),
                  Text(
                   DateFormat('MMM').format(date),
                   style: GoogleFonts.outfit(color: Colors.white, fontSize: 10),
                 ),
               ],
             ),
          )
        ),
      );
    }

  Widget _buildPrayerCard(String name, String time, {bool isNext = false}) {
    // Get notification setting for this prayer
    final settings = _settingsService.getSettings();
    final notifType = settings.prayerNotificationSettings[name] ?? NotificationType.adhan;
    final isMuted = notifType == NotificationType.silent;
    
    return Container(
      decoration: BoxDecoration(
        color: isNext ? Colors.white : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isNext ? Colors.green.withOpacity(0.5) : Colors.blue.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: isNext ? [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
        ] : null,
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationSettingsPage()),
                  ).then((_) => _refreshData());
                },
                child: Icon(
                  isMuted ? Icons.notifications_off_outlined : Icons.notifications_active_rounded,
                  size: 18,
                  color: isMuted ? Colors.grey[400] : (isNext ? Colors.green : Colors.grey[600]),
                ),
              )
            ],
          ),
          const Spacer(),
          Text(name, style: GoogleFonts.outfit(fontWeight: isNext ? FontWeight.bold : FontWeight.w500, fontSize: 16, color: const Color(0xFF1E1E1E))),
          Text(time, style: GoogleFonts.outfit(fontWeight: isNext ? FontWeight.bold : FontWeight.normal, fontSize: isNext ? 16 : 14, color: isNext ? Colors.green : Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildWeatherWidget(PrayerTimes data) {
    // return const AnimatedAdhan(); // FORCED PREVIEW REMOVED
    final now = DateTime.now();

    // 0. Check for Adhan (Prayer Time) - 15 Minute Window
    // Check if we represent a "Call to Prayer" time
    final prayers = [
      data.fajr,
      // data.sunrise, // Sunrise is not a prayer time (Adhan)
      data.dhuhr,
      data.asr,
      data.maghrib,
      data.isha,
    ];

    for (var prayerTime in prayers) {
      // Show Adhan widget if within 5 minutes AFTER the prayer time
      if (now.isAfter(prayerTime) && now.isBefore(prayerTime.add(const Duration(minutes: 5)))) {
         return const AnimatedAdhan();
      }
    }

    // 1. Night: Before Sunrise OR After Maghrib
    if (now.isBefore(data.sunrise) || now.isAfter(data.maghrib)) {
      return const AnimatedMoon();
    }
    
    // 2. Sunset: Between Asr and Maghrib (Late Afternoon)
    if (now.isAfter(data.asr) && now.isBefore(data.maghrib)) {
        return const AnimatedSunset();
    }

    // 3. Day: Otherwise (Sunrise to Asr)
    return const AnimatedSun();
  }
}
