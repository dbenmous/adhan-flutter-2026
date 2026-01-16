import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600;
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        // Tablet scaling factors
        final double iconSize = isTablet ? 28 : 24;
        final double textSize = isTablet ? 12 : 10;
        final double verticalPadding = isTablet ? 8 : 6;
        final double containerVerticalPadding = isTablet ? 6 : 2;
        final double marginHorizontal = isTablet ? 80 : 16;

        final items = [
          _NavItem(
            icon: Icons.mosque_rounded,
            label: 'Prayer',
            index: 0,
          ),
          _NavItem(
            icon: Icons.explore_rounded, // Qibla
            label: 'Qibla',
            index: 1,
          ),
          _NavItem(
            icon: Icons.fingerprint_rounded, // Zhikr representation
            label: 'Zhikr',
            index: 2,
          ),
          _NavItem(
            icon: Icons.settings_rounded,
            label: 'Settings',
            index: 3,
          ),
        ];

        return SafeArea(
          child: Container(
            margin: EdgeInsets.fromLTRB(marginHorizontal, 0, marginHorizontal, 24),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E1E1E).withOpacity(0.75)
                  : theme.colorScheme.surface.withOpacity(0.75),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: theme.colorScheme.primary.withAlpha(30),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double totalWidth = constraints.maxWidth;
                // Subtract horizontal padding from the total width available for items
                final double availableWidth = totalWidth - 8; // 4 padding each side from container
                final int itemCount = items.length;
                final double itemWidth = availableWidth / itemCount;

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: containerVerticalPadding),
                  child: Stack(
                    children: [
                      // Layer 1: Sliding Active Indicator
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        left: currentIndex * itemWidth,
                        top: 0,
                        bottom: 0,
                        width: itemWidth,
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(30), // Match bar contour
                          ),
                        ),
                      ),
                      
                      // Layer 2: Icons Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: items.map((item) {
                          final isActive = currentIndex == item.index;
                          return SizedBox(
                             width: itemWidth,
                             child: GestureDetector(
                               onTap: () => onTap(item.index),
                               behavior: HitTestBehavior.opaque,
                               child: _buildNavItem(context, item, isActive, iconSize, textSize, verticalPadding),
                             ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              }
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    _NavItem item,
    bool isActive,
    double iconSize,
    double textSize,
    double verticalPadding,
  ) {
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = Colors.grey.shade600;

    return Container(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      // Background handled by parent Stack
      decoration: const BoxDecoration(
        color: Colors.transparent, 
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            item.icon,
            color: isActive ? activeColor : inactiveColor,
            size: iconSize,
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: GoogleFonts.outfit(
              fontSize: textSize,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: isActive ? activeColor : inactiveColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final int index;

  _NavItem({
    required this.icon,
    required this.label,
    required this.index,
  });
}
