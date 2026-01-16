import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import 'package:timezone/data/latest.dart' as tz;

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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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

class _AdhanAppState extends State<AdhanApp> with WidgetsBindingObserver {
  
  StreamSubscription<SettingsModel>? _settingsSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    await notificationService.cancelAllPrayerNotifications();
    
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
       _checkUpdatesOnResume();
    }
  }

  Future<void> _checkUpdatesOnResume() async {
     // Ideally check for date/timezone change or significant location change
     // simplified: just refresh 
     await _refreshPrayerTimes();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
