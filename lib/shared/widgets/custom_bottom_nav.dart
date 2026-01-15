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
        final double verticalPadding = isTablet ? 10 : 8;
        final double containerVerticalPadding = isTablet ? 10 : 6;
        final double marginHorizontal = isTablet ? 80 : 16;

        final items = [
          _NavItem(
            icon: Icons.home_rounded,
            label: 'Home',
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
            margin: EdgeInsets.fromLTRB(marginHorizontal, 0, marginHorizontal, 12),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E1E1E).withAlpha(242)
                  : theme.colorScheme.surface.withAlpha(240), // Slightly opaque
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
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: containerVerticalPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: items.map((item) {
                  final isActive = currentIndex == item.index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTap(item.index),
                      behavior: HitTestBehavior.opaque,
                      child: _buildNavItem(context, item, isActive, iconSize, textSize, verticalPadding),
                    ),
                  );
                }).toList(),
              ),
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      decoration: BoxDecoration(
        color: isActive
            ? activeColor.withAlpha(25)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
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
