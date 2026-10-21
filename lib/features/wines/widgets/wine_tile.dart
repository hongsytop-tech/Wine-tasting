import 'package:flutter/material.dart';

import '../models/wine.dart';
import 'rating_stars.dart';
import 'wine_thumb.dart';

class WineTile extends StatelessWidget {
  const WineTile({
    super.key,
    required this.wine,
    this.noteCount = 0,
    this.onTap,
    this.onToggleFavorite,
  });

  final Wine wine;
  final int noteCount;
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
    return ListTile(
      onTap: onTap,
      leading: WineThumb(imageUrl: wine.imageUrl, type: wine.type),
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
              if (noteCount > 0) ...[
                const SizedBox(width: 10),
                Icon(Icons.edit_note, size: 16, color: theme.hintColor),
                Text(' $noteCount', style: theme.textTheme.bodySmall),
              ],
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
