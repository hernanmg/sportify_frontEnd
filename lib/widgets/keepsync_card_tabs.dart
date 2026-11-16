import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/theme/keepsync_colors.dart';

class KeepSyncTabItem {
  final IconData icon;
  final String label;
  final String? subtitle;

  const KeepSyncTabItem({
    required this.icon,
    required this.label,
    this.subtitle,
  });
}

/// Tabs tipo card (Ink/Volt) para hubs: Finanzas, Equipos, Gestión deportiva.
class KeepSyncCardTabs extends StatelessWidget {
  final List<KeepSyncTabItem> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final EdgeInsetsGeometry padding;

  const KeepSyncCardTabs({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
    this.padding = const EdgeInsets.fromLTRB(12, 10, 12, 8),
  });

  /// Variante sincronizada con [TabController].
  static Widget fromController({
    Key? key,
    required TabController controller,
    required List<KeepSyncTabItem> items,
    EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(12, 10, 12, 8),
  }) {
    return AnimatedBuilder(
      key: key,
      animation: controller,
      builder: (context, _) {
        return KeepSyncCardTabs(
          items: items,
          selectedIndex: controller.index,
          padding: padding,
          onChanged: (i) {
            if (controller.index != i) controller.animateTo(i);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: padding,
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              _KeepSyncTabCard(
                item: items[i],
                selected: selectedIndex == i,
                isDark: isDark,
                onTap: () => onChanged(i),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _KeepSyncTabCard extends StatelessWidget {
  final KeepSyncTabItem item;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _KeepSyncTabCard({
    required this.item,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? (isDark ? KeepSyncColors.ink2 : KeepSyncColors.white)
        : (isDark
            ? KeepSyncColors.ink.withValues(alpha: 0.35)
            : KeepSyncColors.paper);
    final border = selected
        ? KeepSyncColors.volt
        : (isDark ? KeepSyncColors.borderDark : KeepSyncColors.borderLight);
    final titleColor = selected
        ? (isDark ? KeepSyncColors.paper : KeepSyncColors.ink)
        : (isDark ? KeepSyncColors.mutedDark : KeepSyncColors.mutedLight);
    final iconBg =
        selected ? KeepSyncColors.volt : border.withValues(alpha: 0.35);
    final iconColor =
        selected ? KeepSyncColors.onVolt : titleColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minWidth: 118),
          padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: selected ? 1.6 : 1),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: KeepSyncColors.volt.withValues(alpha: 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(item.icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: titleColor,
                      height: 1.15,
                    ),
                  ),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle!,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? KeepSyncColors.mutedDark
                            : KeepSyncColors.mutedLight,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
