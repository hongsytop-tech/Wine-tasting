import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../tasting/providers/tasting_providers.dart';
import '../../tasting/widgets/taste_profile_view.dart';
import '../models/wine.dart';
import 'rating_stars.dart';
import 'wine_avatar.dart';

class WineTile extends StatelessWidget {
  const WineTile({
    super.key,
    required this.wine,
    this.tasting,
    this.onTap,
    this.onToggleFavorite,
  });

  final Wine wine;

  /// 마신 와인이면 시음 요약 (마신 날·횟수·특징 점수 평균).
  final WineTastingSummary? tasting;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sub = [
      if (wine.producer.isNotEmpty) wine.producer,
      wine.vintageLabel,
      wine.type.label,
      if (wine.originLabel.isNotEmpty) wine.originLabel,
    ].join(' · ');
    final t = tasting;
    final tastedLine = t == null
        ? null
        : [
            '${DateFormat('yy.MM.dd').format(t.lastTastedAt)} 마심'
                '${t.count > 1 ? ' (${t.count}회)' : ''}',
            if (t.profile.isNotEmpty) profileSummary(t.profile, max: 3),
          ].join(' · ');
    return ListTile(
      onTap: onTap,
      leading: WineAvatar(wine: wine),
      title: Text(wine.name, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Row(
            children: [
              RatingStars(value: wine.myRating, size: 16),
              const SizedBox(width: 6),
              Text(ratingText(wine.myRating), style: theme.textTheme.bodySmall),
              if (wine.vivinoRating != null) ...[
                const SizedBox(width: 10),
                Text(
                  'Vivino ${wine.vivinoRating!.toStringAsFixed(1)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
          if (tastedLine != null)
            Row(
              children: [
                Icon(Icons.local_bar,
                    size: 14, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    tastedLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
        ],
      ),
      trailing: IconButton(
        tooltip: wine.isFavorite ? '즐겨찾기 해제' : '즐겨찾기',
        icon: Icon(
          wine.isFavorite ? Icons.favorite : Icons.favorite_border,
          color: wine.isFavorite ? theme.colorScheme.primary : null,
        ),
        onPressed: onToggleFavorite,
      ),
    );
  }
}
