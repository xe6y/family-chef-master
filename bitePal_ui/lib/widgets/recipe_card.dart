import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../utils/app_constants.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onView;
  final VoidCallback? onAdd;
  final bool isAdded;

  const RecipeCard({
    super.key,
    required this.recipe,
    this.onTap,
    this.onFavorite,
    this.onView,
    this.onAdd,
    this.isAdded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Stack(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image with tags
                Stack(
                  children: [
                    Container(
                      height: AppConstants.cardImageHeight,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: recipe.image != null
                          ? ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              child: Image.network(
                                recipe.image!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildPlaceholder(),
                              ),
                            )
                          : _buildPlaceholder(),
                    ),
                    // Tags
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: recipe.tags.asMap().entries.map((entry) {
                          final index = entry.key;
                          final tag = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getTagColor(recipe.tagColors[index]),
                              borderRadius: BorderRadius.circular(
                                AppConstants.cardBorderRadius,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (tag == "常做")
                                  const Icon(
                                    Icons.star,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                const SizedBox(width: 4),
                                Text(
                                  tag,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                // Info
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppConstants.cardPadding,
                    AppConstants.cardPadding,
                    AppConstants.cardPadding,
                    AppConstants.cardBottomPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        recipe.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            recipe.time,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          Text(
                            recipe.difficulty,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Row(
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 3,
                              runSpacing: 3,
                              children: recipe.categories.take(2).map((
                                category,
                              ) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppConstants.tagBlueBackground,
                                    borderRadius: BorderRadius.circular(
                                      AppConstants.spacingS,
                                    ),
                                  ),
                                  child: Text(
                                    category,
                                    style: TextStyle(
                                      fontSize: AppConstants.textSizeXS,
                                      color: AppConstants.tagBlueText,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          if (onAdd != null) ...[
                            const SizedBox(width: 4),
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: AppConstants.addButtonSize,
                                  height: AppConstants.addButtonSize,
                                  decoration: BoxDecoration(
                                    color: AppConstants.addButtonColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.2,
                                        ),
                                        blurRadius: 3,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: onAdd,
                                      borderRadius: BorderRadius.circular(
                                        AppConstants.addButtonSize / 2,
                                      ),
                                      child: Icon(
                                        isAdded ? Icons.check : Icons.add,
                                        color: Colors.white,
                                        size: AppConstants.addButtonIconSize,
                                      ),
                                    ),
                                  ),
                                ),
                                if (isAdded)
                                  Positioned(
                                    right: -2,
                                    top: -2,
                                    child: Container(
                                      width: AppConstants.addButtonBadgeSize,
                                      height: AppConstants.addButtonBadgeSize,
                                      decoration: BoxDecoration(
                                        color: AppConstants.addedBadgeColor,
                                        shape: BoxShape.circle,
                                        border: Border.fromBorderSide(
                                          BorderSide(
                                            color: Colors.white,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 8,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      if (onFavorite != null || onView != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (onFavorite != null)
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: onFavorite,
                                  icon: Icon(
                                    Icons.star,
                                    size: 16,
                                    color: recipe.favorite
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                                  label: const Text(
                                    "收藏",
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    minimumSize: const Size(0, 32),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppConstants.cardBorderRadius,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            if (onFavorite != null && onView != null)
                              const SizedBox(width: 6),
                            if (onView != null)
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: onView,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    minimumSize: const Size(0, 32),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppConstants.cardBorderRadius,
                                      ),
                                    ),
                                  ),
                                  child: const Text(
                                    "查看",
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300, width: 2),
        ),
      ),
    );
  }

  Color _getTagColor(String colorClass) {
    if (colorClass.contains('blue')) return Colors.blue;
    if (colorClass.contains('green')) return Colors.green;
    if (colorClass.contains('red')) return Colors.red;
    if (colorClass.contains('pink')) return Colors.pink;
    if (colorClass.contains('amber')) return Colors.amber;
    return Colors.grey;
  }
}
