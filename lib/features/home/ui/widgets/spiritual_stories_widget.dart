import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/daily_content_service.dart';
import 'story_full_screen_view.dart';

class SpiritualStoriesWidget extends StatefulWidget {
  const SpiritualStoriesWidget({super.key});

  @override
  State<SpiritualStoriesWidget> createState() => _SpiritualStoriesWidgetState();
}

class _SpiritualStoriesWidgetState extends State<SpiritualStoriesWidget> {
  // Store read state locally to update UI immediately
  Map<String, bool> _readStates = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() async {
    // 1. Load Content if not loaded
    await DailyContentService().loadContent();
    
    // 2. Load Read States
    _loadReadStates();
  }

  void _loadReadStates() async {
    final service = DailyContentService();
    final ayahRead = await service.isRead('Ayah');
    final hadithRead = await service.isRead('Hadith');
    final duaRead = await service.isRead('Dua');
    final nameRead = await service.isRead('Name'); // New
    
    if (mounted) {
      setState(() {
        _readStates = {
          'Ayah': ayahRead,
          'Hadith': hadithRead,
          'Dua': duaRead,
          'Name': nameRead,
        };
        _isLoading = false;
      });
    }
  }
  
  void _markAsRead(String type) async {
    await DailyContentService().markAsRead(type);
    if (mounted) {
      setState(() {
        _readStates[type] = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox(height: 105); // Placeholder

    // Items to display - Added "Names"
    final items = [
      {'label': 'Ayah', 'type': 'Ayah', 'color': const Color(0xFFD4AF37), 'asset': 'aya.png'}, // Gold
      {'label': 'Hadith', 'type': 'Hadith', 'color': const Color(0xFF2E7D32), 'asset': 'hadith.png'}, // Green
      {'label': 'Dua', 'type': 'Dua', 'color': const Color(0xFF1565C0), 'asset': 'dua.png'}, // Blue
      {'label': 'Names', 'type': 'Name', 'color': const Color(0xFF8E24AA), 'asset': 'Allah.png'}, // Purple
    ];

    return SizedBox(
      height: 105, 
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
          crossAxisAlignment: CrossAxisAlignment.center,    
          children: items.map((item) {
            final type = item['type'] as String;
            final isRead = _readStates[type] ?? false;
            
            return _StoryAvatar(
              label: item['label'] as String,
              assetName: item['asset'] as String,
              color: item['color'] as Color,
              isRead: isRead, 
              onTap: () async {
                 _markAsRead(type); 
                 
                 // Get content to pass
                 final content = DailyContentService().getDailyContent();
                 if (content != null) {
                   await Navigator.of(context).push(
                     MaterialPageRoute(
                       builder: (context) => StoryFullScreenView(
                         content: content,
                         initialStoryType: type,
                       ),
                     ),
                   );
                 }
                 _loadReadStates(); // Refresh on return
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _StoryAvatar extends StatelessWidget {
  final String label;
  final String assetName; // New
  final Color color;
  final bool isRead;
  final VoidCallback onTap;

  const _StoryAvatar({
    required this.label,
    required this.assetName,
    required this.color,
    this.isRead = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Gradient: Grey if read, Color if unread
    final gradientColors = isRead 
        ? [Colors.grey.shade300, Colors.grey.shade400] 
        : [color, color.withOpacity(0.4)];
    
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(3), 
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(3), // White gap
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: color.withOpacity(0.1), // Always keep background color
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset(
                    'assets/stories/$assetName',
                    color: color, // Tint the icon with the type color
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87, // Always black
            ),
          )
        ],
      ),
    );
  }
}
