import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dynamic_icon/flutter_dynamic_icon.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppIconPage extends StatefulWidget {
  const AppIconPage({super.key});

  @override
  State<AppIconPage> createState() => _AppIconPageState();
}

class _AppIconPageState extends State<AppIconPage> {
  String _currentIcon = 'Default';
  bool _isLoading = false;

  final List<_AppIconOption> _icons = [
    _AppIconOption(
      name: 'Default',
      aliasName: null, // Null means default activity
      color: const Color(0xFF5B7FFF),
      icon: Icons.mosque_rounded,
    ),
    _AppIconOption(
      name: 'Gold',
      aliasName: 'MainActivityAliasGold',
      color: const Color(0xFFDAA520),
      icon: Icons.star_rounded,
    ),
    _AppIconOption(
      name: 'Dark',
      aliasName: 'MainActivityAliasDark',
      color: const Color(0xFF1E1E1E),
      icon: Icons.nights_stay_rounded,
    ),
    _AppIconOption(
      name: 'Minimal',
      aliasName: 'MainActivityAliasMinimal',
      color: Colors.white,
      borderColor: Colors.black,
      icon: Icons.circle_outlined,
      textColor: Colors.black,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentIcon();
  }

  Future<void> _loadCurrentIcon() async {
    try {
      String? iconName = await FlutterDynamicIcon.getAlternateIconName();
      
      // On Android, the library returns the alias name (e.g., MainActivityAliasGold)
      // On iOS, it returns the name defined in Info.plist (e.g., Gold)
      
      if (iconName == null) {
        _currentIcon = 'Default';
      } else {
        // Find matching option
        final option = _icons.firstWhere(
          (element) => element.aliasName == iconName || iconName.contains(element.aliasName ?? '###'),
          orElse: () => _icons.first,
        );
        _currentIcon = option.name;
      }
      
      setState(() {});
    } catch (e) {
      debugPrint("Error loading icon: $e");
    }
  }

  Future<void> _changeIcon(String name, String? aliasName) async {
    // Show confirmation dialog first
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Change App Icon?'),
        content: const Text(
          'Changing the icon will restart the app on Android devices. \n\nDo you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Restart'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    
    try {
      // Save preference local (optional, for fast load next time)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_icon_name', name);

      // Change Icon
      await FlutterDynamicIcon.setAlternateIconName(aliasName);
      
      if (mounted) {
        setState(() {
          _currentIcon = name;
          _isLoading = false;
        });
        
        // Show success - though app might kill before this
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("App Icon changed to $name"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to change icon: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'App Icon',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 0.85,
            ),
            itemCount: _icons.length,
            itemBuilder: (context, index) {
              final iconOption = _icons[index];
              final isSelected = _currentIcon == iconOption.name;
              
              return GestureDetector(
                onTap: () => _changeIcon(iconOption.name, iconOption.aliasName),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon Preview Placeholder
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: iconOption.color,
                          borderRadius: BorderRadius.circular(20),
                          border: iconOption.borderColor != null 
                             ? Border.all(color: iconOption.borderColor!, width: 2) 
                             : null,
                          boxShadow: [
                            BoxShadow(
                              color: iconOption.color.withOpacity(0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          iconOption.icon,
                          color: iconOption.textColor ?? Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        iconOption.name,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Theme.of(context).primaryColor : null,
                        ),
                      ),
                      if (isSelected) 
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }
}

class _AppIconOption {
  final String name;
  final String? aliasName;
  final Color color;
  final IconData icon;
  final Color? borderColor;
  final Color? textColor;

  _AppIconOption({
    required this.name,
    required this.aliasName,
    required this.color,
    required this.icon,
    this.borderColor,
    this.textColor,
  });
}
