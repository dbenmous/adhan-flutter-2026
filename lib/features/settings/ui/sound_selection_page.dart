import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/services/notification_service.dart';

class SoundSelectionPage extends StatefulWidget {
  const SoundSelectionPage({super.key});

  @override
  State<SoundSelectionPage> createState() => _SoundSelectionPageState();
}

class _SoundSelectionPageState extends State<SoundSelectionPage> {
  String _selectedSound = 'adhan_mishary';
  final NotificationService _notificationService = NotificationService();

  final List<Map<String, String>> _sounds = [
    {'id': 'adhan_mishary', 'name': 'Mishary Rashid Alafasy'},
    {'id': 'adhan_abdulbasit', 'name': 'Abdulbasit Abdusamad'},
    {'id': 'adhan_ahmed_kourdi', 'name': 'Ahmed El Kourdi'},
    {'id': 'adhan_assem_bukhari', 'name': 'Assem Bukhari'},
    {'id': 'adhan_algeria', 'name': 'Adhan Algeria'},
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentSelection();
  }

  Future<void> _loadCurrentSelection() async {
    final settings = SettingsService().getSettings();
    setState(() {
      _selectedSound = settings.adhanSound;
    });
  }

  Future<void> _selectSound(String soundId) async {
    await SettingsService().setAdhanSound(soundId);
    setState(() {
      _selectedSound = soundId;
    });
    // Trigger a reschedule so next prayer uses this sound
    // (In main.dart we listen to settings changes and reschedule automatically)
  }

  Future<void> _previewSound(String soundId) async {
    // To "preview", we can just schedule a test alarm for 5 seconds from now using THIS sound logic
    // But notification channels are tricky.
    // For now, let's just show a snackbar saying "Preview not implemented yet (requires restart for channel creation)"
    // Wait, we implement dynamic channels in NotificationService next.
    
    // BETTER IDEA: Just play it using audioplayers?
    // Or simpler: Just rely on user Trust for now until we add audioplayers dependency.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Selected. Use "Test Alarm" to hear it.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Adhan Sound',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sounds.length,
        itemBuilder: (context, index) {
          final sound = _sounds[index];
          final isSelected = sound['id'] == _selectedSound;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => _selectSound(sound['id']!),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected 
                        ? Theme.of(context).primaryColor 
                        : (isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0)),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? Theme.of(context).primaryColor.withOpacity(0.15)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSelected ? Icons.volume_up_rounded : Icons.music_note_rounded,
                        color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        sound['name']!,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? Theme.of(context).primaryColor : null,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle_rounded,
                        color: Theme.of(context).primaryColor,
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
