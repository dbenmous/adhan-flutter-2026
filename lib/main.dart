import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import 'package:timezone/data/latest.dart' as tz;
import 'package:workmanager/workmanager.dart';
import 'package:flutter/foundation.dart'; // for kDebugMode

import 'features/home/ui/home_page.dart';
import 'features/qibla/ui/qibla_page.dart';
import 'features/zhikr/ui/zhikr_page.dart';
import 'features/settings/ui/settings_page.dart';
import 'features/onboarding/ui/onboarding_page.dart';
import 'shared/widgets/custom_bottom_nav.dart';
import 'core/services/settings_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/location_service.dart';
import 'core/services/prayer_time_service.dart';
import 'core/models/settings_model.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint("Native called background task: $task");
    
    // Services Initialization for Background Isolate
    WidgetsFlutterBinding.ensureInitialized();
    tz.initializeTimeZones();
    await SettingsService().init();
    await NotificationService().init();
    
    try {
      final locationService = LocationService();
      final prayerService = PrayerTimeService();
      final settingsService = SettingsService();
      final notificationService = NotificationService();
      
      // We need to init location service too but it might fail in background if permission missing
      // However, we cached coordinates in Settings usually? 
      // LocationService usually needs to fetch fresh location.
      // If we are in background, better use CACHED location or SettingsService default.
      // But LocationService.getCurrentLocation() handles permission checks.
      
      // NOTE: Location updates in background might be tricky. 
      // Safe bet: Use last known location from SharedPreferences if available, or just call getCurrentLocation()
      // which returns cached if fresh enough.
      
      final coords = await locationService.getCurrentLocation();
      final settings = settingsService.getSettings();
      
      // Schedule 30 Days from NOW
      // We do NOT cancel all. We just overwrite/append for the next 30 days.
      // The IDs overlap (101-150 range usually? No, we use offset).
      // Wait, schedulePrayerTimes uses idOffset.
      // logic in main (lines 92-101) uses offset i*10.
      
      final now = DateTime.now();
      for (int i = 0; i < 30; i++) {
        final date = now.add(Duration(days: i));
        // Recalculate for that day
        final times = await prayerService.calculatePrayerTimes(
          coords,
          settings,
          date: date,
        );
        // Schedule (upsert)
        await notificationService.schedulePrayerTimes(times, idOffset: i * 10);
      }
      
      debugPrint("[Background] Successfully refreshed 30 days of prayers.");
      
    } catch (e) {
      debugPrint("[Background] Error refreshing prayers: $e");
      return Future.value(false);
    }

    return Future.value(true);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init Workmanager
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: kDebugMode, // logs to console
  );
  
  // Register Periodic Task (Once a day)
  Workmanager().registerPeriodicTask(
    "daily_prayer_refresh", 
    "simplePeriodicTask", 
    frequency: const Duration(hours: 24),
    constraints: Constraints(
      networkType: NetworkType.connected, // Only if internet available (optional)
    ),
  );
  
  // Init Services
  tz.initializeTimeZones();
  await SettingsService().init();
  await NotificationService().init();
  await LocationService().init();

  // Check if onboarding is complete
  final prefs = await SharedPreferences.getInstance();
  final bool onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
  
  // Determine initial screen
  final Widget initialScreen = onboardingComplete 
      ? const MainScaffold() 
      : const OnboardingPage();

  runApp(AdhanApp(initialScreen: initialScreen));
}

class AdhanApp extends StatefulWidget {
  final Widget initialScreen;
  
  const AdhanApp({super.key, required this.initialScreen});

  @override
  State<AdhanApp> createState() => _AdhanAppState();
}

class _AdhanAppState extends State<AdhanApp> {
  
  StreamSubscription<SettingsModel>? _settingsSubscription;

  @override
  void initState() {
    super.initState();
    _initialSetup();
    
    // Listen for settings changes to reschedule notifications immediately
    _settingsSubscription = SettingsService().settingsStream.listen((_) {
       debugPrint("Settings changed: Rescheduling notifications...");
       _refreshPrayerTimes();
    });
  }

  Future<void> _initialSetup() async {
    // Request Permissions only if onboarding is already done
    // (OnboardingPage handles its own permission requests)
    final prefs = await SharedPreferences.getInstance();
    final bool onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
    
    if (onboardingComplete) {
      await NotificationService().requestPermissions();
      await _refreshPrayerTimes();
    }
  }

  Future<void> _refreshPrayerTimes() async {
    final locationService = LocationService();
    final prayerService = PrayerTimeService();
    final settingsService = SettingsService();
    final notificationService = NotificationService();

    final coords = await locationService.getCurrentLocation();
    
    // Get Settings
    final settings = settingsService.getSettings();

    // Schedule 30 Days of Notifications for reliability
    
    final now = DateTime.now();
    for (int i = 0; i < 30; i++) {
      final date = now.add(Duration(days: i));
      final times = await prayerService.calculatePrayerTimes(
        coords, 
        settings, 
        date: date
      );
      
      await notificationService.schedulePrayerTimes(times, idOffset: i * 10);
    }
    
    debugPrint("Scheduled 30 days of notifications for $coords");
  }



  @override
  void dispose() {
    _settingsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Adhan App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5B7FFF)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        textTheme: GoogleFonts.outfitTextTheme(),
      ),
      routes: {
        '/home': (context) => const MainScaffold(),
        '/onboarding': (context) => const OnboardingPage(),
      },
      home: widget.initialScreen,
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  
  // GlobalKey to access HomePage state for permission refresh
  final GlobalKey<HomePageState> _homePageKey = GlobalKey<HomePageState>();

  late final List<Widget> _pages;
  
  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(key: _homePageKey),
      const QiblaPage(),
      const ZhikrPage(),
      const SettingsPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _pages[_currentIndex],
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          final wasOnSettings = _currentIndex == 3; // Settings is index 3
          setState(() {
            _currentIndex = index;
          });
          // If switching TO home tab (especially from settings), refresh permission
          if (index == 0) {
            _homePageKey.currentState?.checkSystemPermission();
          }
        },
      ),
    );
  }
}
