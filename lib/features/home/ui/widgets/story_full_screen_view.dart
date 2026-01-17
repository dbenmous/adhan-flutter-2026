import 'package:flutter/material.dart';
import 'package:story_view/story_view.dart';
import '../../../../core/services/daily_content_service.dart';
import 'package:google_fonts/google_fonts.dart';

class StoryFullScreenView extends StatefulWidget {
  final DailyContent content;
  final String initialStoryType; // 'Ayah', 'Hadith', 'Dua', 'Name'

  const StoryFullScreenView({
    super.key,
    required this.content,
    required this.initialStoryType,
  });

  @override
  State<StoryFullScreenView> createState() => _StoryFullScreenViewState();
}

class _StoryFullScreenViewState extends State<StoryFullScreenView> {
  final StoryController _storyController = StoryController();
  
  @override
  void dispose() {
    _storyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine which Item to show based on type
    // We could show all in a sequence, but user tapped a specific circle.
    // Let's just show that specific content item for now to keep it focused.
    
    ContentItem itemToShow;
    Color color;
    
    switch (widget.initialStoryType) {
      case 'Hadith':
        itemToShow = widget.content.hadith;
        color = const Color(0xFF2E7D32);
        break;
      case 'Dua':
        itemToShow = widget.content.dua;
        color = const Color(0xFF1565C0);
        break;
      case 'Name':
        itemToShow = widget.content.allahName;
        color = const Color(0xFF8E24AA);
        break;
      case 'Ayah':
      default:
        itemToShow = widget.content.ayah;
        color = const Color(0xFFD4AF37);
        break;
    }

    // Build the View for the StoryItem
    // Since StoryItem.text is limited, we use a custom widget wrapper if needed, 
    // or just format the text. But StoryView 0.16.6 supports `StoryItem.text` nicely.
    // For rich layout (Arabic big, Translation small), we really need a custom view.
    // StoryItem( view: ... ) is the best way for custom layouts.

    final storyItem = StoryItem(
        Container(
          color: color,
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title / Arabic
                 Text(
                   itemToShow.name ?? itemToShow.text, // Use name for AllahName, text for others
                   textAlign: TextAlign.center,
                   style: GoogleFonts.amiri(
                     fontSize: 32,
                     height: 1.6,
                     fontWeight: FontWeight.bold,
                     color: Colors.white,
                   ),
                 ),
                 const SizedBox(height: 40),
                 
                 // Translation / Meaning
                 if (itemToShow.translation != null || itemToShow.meaning != null)
                   Text(
                     itemToShow.translation ?? itemToShow.meaning ?? '',
                     textAlign: TextAlign.center,
                     style: GoogleFonts.outfit(
                       fontSize: 18,
                       color: Colors.white.withOpacity(0.9),
                     ),
                   ),

                 const SizedBox(height: 20),
                 
                 // Source / Reference
                 if (itemToShow.surah != null || itemToShow.source != null)
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                     decoration: BoxDecoration(
                       border: Border.all(color: Colors.white54),
                       borderRadius: BorderRadius.circular(20),
                     ),
                     child: Text(
                       itemToShow.surah ?? itemToShow.source ?? '',
                       style: GoogleFonts.outfit(
                         fontSize: 12,
                         color: Colors.white70,
                         fontWeight: FontWeight.w500,
                       ),
                     ),
                   ),
              ],
            ),
          ),
        ),
        duration: const Duration(seconds: 10), // Give enough time to read
    );

    return Scaffold(
      body: StoryView(
        storyItems: [storyItem],
        controller: _storyController,
        onStoryShow: (s, index) {
            // Mark as read could happen here too, but we did it on tap.
        },
        onComplete: () {
          Navigator.pop(context);
        },
        progressPosition: ProgressPosition.top,
        repeat: false,
        inline: false,
      ),
    );
  }
}
