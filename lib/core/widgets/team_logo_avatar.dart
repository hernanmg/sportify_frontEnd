import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/utils/team_colors.dart';
import 'package:sportify_amateur/core/widgets/image_from_url_or_data.dart';

class TeamLogoAvatar extends StatelessWidget {
  final String? logoUrl;
  final String? colorsRaw;
  final double radius;
  final bool highlight;

  const TeamLogoAvatar({
    super.key,
    this.logoUrl,
    this.colorsRaw,
    this.radius = 24,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final pair = parseTeamColors(colorsRaw);
    final bg = pair?.primary ?? (highlight ? Colors.green.shade100 : Colors.grey.shade200);

    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: ClipOval(
        child: logoUrl != null && logoUrl!.isNotEmpty
            ? ImageFromUrlOrData(
                imageUrl: logoUrl,
                width: radius * 2,
                height: radius * 2,
                placeholder: _fallbackIcon(pair),
                errorWidget: _fallbackIcon(pair),
              )
            : _fallbackIcon(pair),
      ),
    );
  }

  Widget _fallbackIcon(TeamColorPair? pair) {
    return Icon(
      Icons.shield,
      color: pair?.secondary ?? Colors.grey.shade700,
      size: radius,
    );
  }
}
