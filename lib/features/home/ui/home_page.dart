import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glass/glass.dart';
import 'package:intl/intl.dart';
import 'package:adhan/adhan.dart';
import '../../../core/services/prayer_time_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/settings_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PrayerTimeService _prayerService = PrayerTimeService();
  final LocationService _locationService = LocationService();
  final SettingsService _settingsService = SettingsService();

  late Future<PrayerTimes?> _prayerTimesFuture;
  Map<String, dynamic>? _nextPrayerData;
  Timer? _timer;
  Duration _currentCountdown = Duration.zero;
  String _locationName = 'Loading...';

  @override
  void initState() {
    super.initState();
    _refreshData();
    _startTimer();
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
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_currentCountdown.inSeconds > 0) {
            _currentCountdown = _currentCountdown - const Duration(seconds: 1);
          } else {
            // Refresh when countdown hits zero
             _refreshData();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
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

          final dateFormat = DateFormat('dd/MM/yyyy');
          final timeFormat = DateFormat('HH:mm');

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
                              TextSpan(
                                text: nextTime != null ? timeFormat.format(nextTime) : '--:--',
                                style: GoogleFonts.outfit(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 42,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                          style: GoogleFonts.outfit(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
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
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 3,
                      childAspectRatio: 0.85,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      children: [
                        _buildPrayerCard('Fajr', timeFormat.format(data.fajr), false, false, isNext: nextName == 'Fajr'),
                        _buildPrayerCard('Sunrise', timeFormat.format(data.sunrise), false, true, isNext: nextName == 'Sunrise'),
                        _buildPrayerCard('Dhuhr', timeFormat.format(data.dhuhr), true, false, isNext: nextName == 'Dhuhr'),
                        _buildPrayerCard('Asr', timeFormat.format(data.asr), true, false, isNext: nextName == 'Asr'),
                        _buildPrayerCard('Maghrib', timeFormat.format(data.maghrib), false, true, isNext: nextName == 'Maghrib'),
                        _buildPrayerCard('Isha', timeFormat.format(data.isha), true, false, isNext: nextName == 'Isha'),
                      ],
                    ),
                  ),

                  // 6. Calendar Banner
                 Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
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
                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  String _getPrayerName(Prayer p) {
    if (p == Prayer.none) return "Fajr"; // Wrapped
    return p.name[0].toUpperCase() + p.name.substring(1);
  }

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

  Widget _buildPrayerCard(String name, String time, bool isSoundOn, bool isMuted, {bool isNext = false}) {
     return Container(
      decoration: isNext
          ? BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
              ],
            )
          : null,
          padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(
                isMuted ? Icons.notifications_off_outlined : Icons.notifications_active_rounded,
                size: 18,
                color: isNext ? Colors.green : Colors.grey[600],
              )
            ],
          ),
          const Spacer(),
          Text(name, style: GoogleFonts.outfit(fontWeight: isNext ? FontWeight.bold : FontWeight.w500, fontSize: 16, color: const Color(0xFF1E1E1E))),
          Text(time, style: GoogleFonts.outfit(fontWeight: isNext ? FontWeight.bold : FontWeight.normal, fontSize: isNext ? 16 : 14, color: isNext ? Colors.green : Colors.grey[700])),
        ],
      ),
    ).asGlass(tintColor: Colors.white, clipBorderRadius: BorderRadius.circular(16), enabled: !isNext);
  }
}
