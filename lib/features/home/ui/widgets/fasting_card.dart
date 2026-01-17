import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:percent_indicator/percent_indicator.dart';
import '../../../../core/services/fasting_service.dart';
import '../../../../core/models/settings_model.dart';
import '../../../../core/services/prayer_time_service.dart';

class FastingCard extends StatefulWidget {
  final PrayerTimes? prayerTimes;
  final DateTime date;
  final SettingsModel settings;
  final Coordinates? coordinates;

  const FastingCard({
    super.key, 
    this.prayerTimes,
    required this.date,
    required this.settings,
    this.coordinates,
  });

  @override
  State<FastingCard> createState() => _FastingCardState();
}

class _FastingCardState extends State<FastingCard> with SingleTickerProviderStateMixin {
  final _fastingService = FastingService();
  final _prayerTimeService = PrayerTimeService();
  
  bool _isLoading = true;
  bool _isIntentionSet = false;
  bool _isFastingToday = false; // "Active Mode" vs "Planning Mode"
  DateTime? _nextSunnahDate;
  
  Timer? _ticker;
  Duration _timeLeft = Duration.zero; // For Active Mode
  double _progress = 0.0;
  
  // Shawwal State
  List<String> _shawwalDays = [];
  
  // Expanded/Collapsed state for Du'a
  bool _showDua = false;

  @override
  void initState() {
    super.initState();
    _loadState();
    _startTimer();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
         // Should update for Ramadan mode too even if intent logic isn't standard
         _updateCountdown();
      }
    });
  }

  Future<void> _loadState() async {
    final nextDate = _fastingService.getNextSunnahFast();
    final isIntentionSet = await _fastingService.isIntentionSetFor(nextDate);
    final isFastingToday = await _fastingService.isFastingToday();
    final shawwalDays = await _fastingService.getShawwalFastedDays();

    if (mounted) {
      setState(() {
        _nextSunnahDate = nextDate;
        _isIntentionSet = isIntentionSet;
        _isFastingToday = isFastingToday;
        _shawwalDays = shawwalDays;
        _isLoading = false;
      });
      
      _updateCountdown();
    }
  }

  void _updateCountdown() {
    if (widget.prayerTimes == null) return;
    
    final now = DateTime.now();
    final maghrib = widget.prayerTimes!.maghrib;
    final fajr = widget.prayerTimes!.fajr;
    
    // Logic: If active or ramadan
    
    if (now.isAfter(maghrib)) {
      // Fast completed
      if (_timeLeft != Duration.zero) {
        setState(() {
          _timeLeft = Duration.zero;
          _progress = 1.0;
        });
      }
      return;
    }
    
    if (now.isBefore(fajr)) {
      // Fast hasn't started
       if (_timeLeft != maghrib.difference(now)) {
         setState(() {
           _timeLeft = maghrib.difference(now);
           _progress = 0.0;
        });
       }
      return;
    }
    
    final totalDuration = maghrib.difference(fajr).inSeconds;
    final elapsed = now.difference(fajr).inSeconds;
    
    setState(() {
      _timeLeft = maghrib.difference(now);
      _progress = (elapsed / totalDuration).clamp(0.0, 1.0);
    });
  }

  Future<void> _toggleIntention() async {
    if (_nextSunnahDate == null) return;
    
    final newState = !_isIntentionSet;
    DateTime? fajrToSchedule;
    
    // Logic to determine accurate Fajr time for notification
    if (newState) {
      // 1. If date matches current prayerTimes date, use that
      if (widget.prayerTimes != null) {
        final ptDate = widget.prayerTimes!.dateComponents;
        if (ptDate.year == _nextSunnahDate!.year && 
            ptDate.month == _nextSunnahDate!.month && 
            ptDate.day == _nextSunnahDate!.day) {
           fajrToSchedule = widget.prayerTimes!.fajr;
        }
      }
      
      // 2. If not found or date mismatch, recalculate if we have coordinates
      if (fajrToSchedule == null && widget.coordinates != null) {
         try {
           final times = await _prayerTimeService.calculatePrayerTimes(
             widget.coordinates!, 
             widget.settings, 
             date: _nextSunnahDate!
           );
           fajrToSchedule = times.fajr;
         } catch (e) {
           debugPrint("Error calculating future prayer times: $e");
         }
      }
    }

    await _fastingService.setIntention(newState, _nextSunnahDate!, fajrToSchedule);
    
    setState(() {
      _isIntentionSet = newState;
    });
  }
  
  Future<void> _toggleShawwalDay(bool value) async {
     final today = DateTime.now();
     // Determine date string
     final dateStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
     
     await _fastingService.toggleShawwalDay(dateStr);
     final days = await _fastingService.getShawwalFastedDays();
     setState(() {
       _shawwalDays = days;
     });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();

    // Determine Mode
    final currentType = _fastingService.getFastType(DateTime.now());
    
    Widget content;
    if (currentType == FastType.ramadan) {
       content = _buildActiveMode(overrideTitle: "Ramadan Mubarak");
    } else if (currentType == FastType.shawwal) {
       content = _buildShawwalMode();
    } else {
       content = _isFastingToday ? _buildActiveMode() : _buildPlanningMode();
    }

    // Container Styling
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFE1F5FE), // Very light blue
            const Color(0xFFF0F7FF), // Subtle fade
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE0E0E0), 
          width: 1
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: content,
    );
  }

  // 1. Shawwal Mode
  Widget _buildShawwalMode() {
      final fastedCount = _shawwalDays.length;
      final progress = (fastedCount / 6).clamp(0.0, 1.0);
      final todayStr = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
      final isFastedToday = _shawwalDays.contains(todayStr);

      return Column(
          children: [
            Text(
              "Shawwal Challenge",
              style: GoogleFonts.outfit(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E1E1E)
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "$fastedCount / 6 Days Completed",
              style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 16),
            LinearPercentIndicator(
              lineHeight: 12.0,
              percent: progress,
              backgroundColor: Colors.grey[300],
              progressColor: Colors.orange,
              barRadius: const Radius.circular(10),
              animation: true,
            ),
            const SizedBox(height: 20),
            
            // Toggle Button
            InkWell(
                onTap: () => _toggleShawwalDay(!isFastedToday),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                        color: isFastedToday ? Colors.green.withOpacity(0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isFastedToday ? Colors.green : Colors.grey[300]!)
                    ),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            Icon(
                                isFastedToday ? Icons.check_circle : Icons.circle_outlined,
                                color: isFastedToday ? Colors.green : Colors.grey
                            ),
                            const SizedBox(width: 8),
                            Text(
                                isFastedToday ? "Fasted Today" : "Mark as Fasted Today",
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    color: isFastedToday ? Colors.green[800] : Colors.grey[700]
                                )
                            )
                        ],
                    ),
                ),
            ),
          ],
      );
  }

  // 2. Planning Mode (Standard)
  Widget _buildPlanningMode() {
    final nextType = _nextSunnahDate != null ? _fastingService.getFastType(_nextSunnahDate!) : FastType.none;
    final typeTitle = _fastingService.getFastTitle(nextType);
    
    final dateStr = _nextSunnahDate != null 
        ? DateFormat('EEEE, MMM d').format(_nextSunnahDate!) 
        : 'Unknown';
    
    // Hijri Badge
    final hijriStr = _nextSunnahDate != null 
        ? _fastingService.getHijriDateString(
            _nextSunnahDate!, 
            adjustment: widget.settings.hijriAdjustmentDays
          )
        : '--';

    // Mock calculations used for planning preview (using today's times for simplicity)
    final fajr = widget.prayerTimes?.fajr ?? DateTime.now();
    final maghrib = widget.prayerTimes?.maghrib ?? DateTime.now();
    final suhoorEnds = fajr.subtract(const Duration(minutes: 10));
    final duration = _fastingService.getFastDuration(fajr, maghrib);

    final durationStr = "${duration.inHours}h ${duration.inMinutes % 60}m";
    final suhoorStr = DateFormat.jm().format(suhoorEnds);
    final maghribStr = DateFormat.jm().format(maghrib);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next Opportunity: $typeTitle',
                  style: GoogleFonts.outfit(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1E1E1E),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EAF6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                hijriStr,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF3F51B5),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Info Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildInfoColumn(Icons.soup_kitchen_rounded, 'Suhoor Ends', suhoorStr, Colors.orange),
            _buildInfoColumn(Icons.timer_outlined, 'Duration', durationStr, Colors.blue),
            _buildInfoColumn(Icons.nights_stay_rounded, 'Maghrib', maghribStr, Colors.indigo),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Action Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _toggleIntention,
            icon: Icon(
              _isIntentionSet ? Icons.alarm_on_rounded : Icons.alarm_add_rounded,
              color: Colors.white,
            ),
            label: Text(
               _isIntentionSet 
                   ? 'Alarm Set for ${DateFormat.jm().format(fajr.subtract(const Duration(minutes: 45)))}'
                   : 'Set Suhoor Alarm',
               style: GoogleFonts.outfit(
                 fontWeight: FontWeight.bold,
                 color: Colors.white, // FORCE WHITE TEXT
               ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isIntentionSet ? Colors.green : const Color(0xFF3F51B5),
              foregroundColor: Colors.white, // Ensure ripple/icon is white too
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  // State C: Active Mode (Or Ramadan)
  Widget _buildActiveMode({String? overrideTitle}) {
    final hours = _timeLeft.inHours.toString().padLeft(2, '0');
    final minutes = (_timeLeft.inMinutes % 60).toString().padLeft(2, '0');
    
    // Fast Type (e.g., Sunnah, White Day)
    // If overrideTitle is passed (e.g. Ramadan), use it.
    final type = _fastingService.getFastType(DateTime.now());
    final title = overrideTitle ?? "${_fastingService.getFastTitle(type)} Fasting";

    return Column(
      children: [
         // Header Badge
         Container(
           margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Text(
              title,
              style: GoogleFonts.outfit(
                color: Colors.deepOrange,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
         ),
         
        // Circular Indicator
        CircularPercentIndicator(
          radius: 80.0,
          lineWidth: 10.0,
          percent: _progress,
          center: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Iftar in",
                style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                 "${hours}h ${minutes}m",
                 style: GoogleFonts.outfit(
                   fontWeight: FontWeight.bold, 
                   fontSize: 24,
                   color: const Color(0xFF1E1E1E)
                 ),
              ),
            ],
          ),
          progressColor: const Color(0xFF3F51B5),
          backgroundColor: const Color(0xFFE0E0E0),
          circularStrokeCap: CircularStrokeCap.round,
          animation: true,
          animateFromLastPercent: true,
        ),
        
        const SizedBox(height: 20),
        
        // Dua Expander
        InkWell(
          onTap: () => setState(() => _showDua = !_showDua),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
             duration: const Duration(milliseconds: 300),
             width: double.infinity,
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(
               color: const Color(0xFFE8EAF6),
               borderRadius: BorderRadius.circular(12),
             ),
             child: Column(
               children: [
                 Row(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     const Icon(Icons.menu_book_rounded, size: 16, color: Color(0xFF3F51B5)),
                     const SizedBox(width: 8),
                     Text(
                       "Show Iftar Du'a",
                       style: GoogleFonts.outfit(
                         color: const Color(0xFF3F51B5), 
                         fontWeight: FontWeight.bold
                       ),
                     ),
                     Icon(
                       _showDua ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                       color: const Color(0xFF3F51B5),
                     )
                   ],
                 ),
                 if (_showDua) ...[
                   const SizedBox(height: 12),
                   Text(
                     "ذَهَبَ الظَّمَأُ وَابْتَلَّتِ الْعُرُوقُ وَثَبَتَ الْأَجْرُ إِنْ شَاءَ اللَّهُ",
                     textAlign: TextAlign.center,
                     style: GoogleFonts.amiri(
                       fontSize: 18, 
                       height: 1.8,
                       fontWeight: FontWeight.bold
                     ),
                     textDirection: TextDirection.rtl,
                   ),
                   const SizedBox(height: 8),
                   Text(
                     "Dhahaba adh-dhama'u wabtallat al-'uruq wa thabata al-ajru insha'Allah.",
                     textAlign: TextAlign.center,
                     style: GoogleFonts.outfit(
                       fontSize: 12, 
                       color: Colors.grey[700],
                       fontStyle: FontStyle.italic
                     ),
                   ),
                   const SizedBox(height: 4),
                   Text(
                     "The thirst is gone, the veins are moistened and the reward is confirmed, if Allah wills.",
                     textAlign: TextAlign.center,
                     style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
                   ),
                 ]
               ],
             ),
          ),
        )
      ],
    );
  }

  Widget _buildInfoColumn(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E1E1E),
          ),
        ),
      ],
    );
  }
}
