import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';
import '../../../core/services/prayer_time_service.dart';
import '../../../core/services/settings_service.dart';

class DailyPrayer {
  final DateTime date;
  final PrayerTimes times;
  DailyPrayer(this.date, this.times);
}

class MonthlyCalendarPage extends StatefulWidget {
  const MonthlyCalendarPage({super.key});

  @override
  State<MonthlyCalendarPage> createState() => _MonthlyCalendarPageState();
}

class _MonthlyCalendarPageState extends State<MonthlyCalendarPage> {
  final _prayerService = PrayerTimeService();
  final _settingsService = SettingsService();
  
  late Future<List<DailyPrayer>> _monthPrayerTimes;
  final DateTime _now = DateTime.now();
  
  // Keys to auto-scroll to specific days
  final Map<int, GlobalKey> _dayKeys = {};

  @override
  void initState() {
    super.initState();
    _monthPrayerTimes = _loadMonthData();
  }

  Future<List<DailyPrayer>> _loadMonthData() async {
    // Optimization: Use saved settings directly. Do NOT await GPS.
    // If user is here, they likely have a location set (automatic or manual).
    final settings = _settingsService.getSettings();
    final lat = settings.latitude ?? 21.4225; // Default Mecca if null
    final lng = settings.longitude ?? 39.8262;
    final coords = Coordinates(lat, lng);

    final monthTimes = await _prayerService.getMonthlyPrayerTimes(coords, settings, _now);
    
    // Convert to DailyPrayer list
    return monthTimes.map((times) {
      final components = times.dateComponents;
      final date = DateTime(components.year, components.month, components.day);
      return DailyPrayer(date, times);
    }).toList();
  }

  /// Auto-scroll to today after layout is built
  void _scrollToToday() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_dayKeys.containsKey(_now.day)) {
        Scrollable.ensureVisible(
          _dayKeys[_now.day]!.currentContext!,
          alignment: 0.5, // Center the item
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          DateFormat('MMMM yyyy').format(DateTime.now()), // Simpler Title
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<List<DailyPrayer>>(
        future: _monthPrayerTimes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text('Failed to load calendar', style: GoogleFonts.outfit()));
          }

          final monthData = snapshot.data!;
          final timeFormat = DateFormat('HH:mm');
          
          // Trigger scroll if it's the first build with data
          if (_dayKeys.isEmpty) {
             // Initialize keys for scroll targets
             for (var daily in monthData) {
               _dayKeys[daily.date.day] = GlobalKey();
             }
             _scrollToToday();
          }

          final columnWidths = const {
            0: FlexColumnWidth(1.2), // Date
            1: FlexColumnWidth(1), // Fajr
            2: FlexColumnWidth(1), // Sunrise
            3: FlexColumnWidth(1), // Dhuhr
            4: FlexColumnWidth(1), // Asr
            5: FlexColumnWidth(1), // Maghrib
            6: FlexColumnWidth(1), // Isha
          };

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Fixed Header Row
                Table(
                  columnWidths: columnWidths,
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    TableRow(
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      children: [
                        _buildHeaderCell('Day'),
                        _buildHeaderCell('Fajr'),
                        _buildHeaderCell('Sun'),
                        _buildHeaderCell('Dhuhr'),
                        _buildHeaderCell('Asr'),
                        _buildHeaderCell('Mag'),
                        _buildHeaderCell('Isha'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Scrollable Data Rows
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        ...monthData.map((daily) {
                          final dayDate = daily.date;
                          final times = daily.times;
                          final isToday = dayDate.day == _now.day && dayDate.month == _now.month;

                          return Container(
                            key: isToday ? _dayKeys[dayDate.day] : null, // Assign key to today
                            child: Table(
                              columnWidths: columnWidths,
                              border: TableBorder(
                                bottom: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
                              ),
                              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                              children: [
                                TableRow(
                                  decoration: isToday ? BoxDecoration(
                                    color: Theme.of(context).primaryColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ) : null,
                                  children: [
                                    _buildDataCell(dayDate.day.toString(), isToday, isBold: true),
                                    _buildDataCell(timeFormat.format(times.fajr), isToday),
                                    _buildDataCell(timeFormat.format(times.sunrise), isToday, color: Colors.grey),
                                    _buildDataCell(timeFormat.format(times.dhuhr), isToday),
                                    _buildDataCell(timeFormat.format(times.asr), isToday),
                                    _buildDataCell(timeFormat.format(times.maghrib), isToday),
                                    _buildDataCell(timeFormat.format(times.isha), isToday),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 100), // Bottom padding
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildDataCell(String text, bool isToday, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(
          fontWeight: isBold || isToday ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
          color: isToday ? Theme.of(context).primaryColor : (color ?? const Color(0xFF1E1E1E)),
        ),
      ),
    );
  }
}
