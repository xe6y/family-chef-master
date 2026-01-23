import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../utils/app_theme.dart';

const Map<String, Color> _difficultyBackgrounds = {
  '有手就行': Color(0xFFD4EDDA),
  '家常便饭': Color(0xFFCCE5FF),
  '餐厅招牌': Color(0xFFFFF4CC),
  '硬核挑战': Color(0xFFFFE0B2),
  '专业厨师': Color(0xFFFFDADA),
};

const Map<String, Color> _difficultyTextColors = {
  '有手就行': Color(0xFF2E7D32),
  '家常便饭': Color(0xFF1565C0),
  '餐厅招牌': Color(0xFFF57F17),
  '硬核挑战': Color(0xFFE65100),
  '专业厨师': Color(0xFFC62828),
};

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onAdd;
  final bool isAdded;

  const RecipeCard({
    super.key,
    required this.recipe,
    this.onTap,
    this.onFavorite,
    this.onAdd,
    this.isAdded = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 图片区域
            Stack(
              children: [
                Container(
                  height: 110,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: recipe.image != null && recipe.image!.isNotEmpty
                        ? Image.network(
                            recipe.image!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildPlaceholder(),
                          )
                        : Image.asset(
                            'assets/chinese-potato-strips.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildPlaceholder(),
                          ),
                  ),
                ),
                // 收藏按钮
                if (onFavorite != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          onFavorite?.call();
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            recipe.favorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: recipe.favorite
                                ? Colors.red
                                : colorScheme.onSurface.withValues(alpha: 0.6),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // 信息区域
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 标签（移到第一行）
                  if (recipe.tags.isNotEmpty) ...[
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: _buildTags(colorScheme),
                    ),
                    const SizedBox(height: 8),
                  ],
                  // 菜名
                  Text(
                    recipe.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                      inherit: false,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // 难度和时间
                  Row(
                    children: [
                      if (recipe.difficulty.isNotEmpty) ...[
                        _buildDifficultyBadge(recipe.difficulty, colorScheme),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 13,
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                recipe.time,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                                  inherit: false,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 添加按钮（移到右侧）
                      if (onAdd != null) ...[
                        const SizedBox(width: 6),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              onAdd?.call();
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: isAdded
                                    ? colorScheme.primary
                                    : colorScheme.error,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        (isAdded
                                                ? colorScheme.primary
                                                : colorScheme.error)
                                            .withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                isAdded ? Icons.check : Icons.add,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建难度标识
  Widget _buildDifficultyBadge(String difficulty, ColorScheme colorScheme) {
    final background =
        _difficultyBackgrounds[difficulty] ??
        colorScheme.surfaceContainerHighest.withValues(alpha: 0.15);
    final textColor =
        _difficultyTextColors[difficulty] ?? colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        difficulty,
        style: TextStyle(
          fontSize: 10,
          color: textColor,
          fontWeight: FontWeight.w600,
          inherit: false,
        ),
      ),
    );
  }

  /// 构建标签列表
  List<Widget> _buildTags(ColorScheme colorScheme) {
    if (recipe.tags.isEmpty) {
      return [];
    }

    // 动态计算可以显示的标签数量
    // 根据标签长度决定显示数量：如果标签都很短，可以显示3个；如果有长标签，显示2个
    int maxTags = 3;
    if (recipe.tags.isNotEmpty) {
      final avgLength = recipe.tags.take(3).fold<int>(
            0,
            (sum, tag) => sum + (tag.length > 4 ? 4 : tag.length),
          ) /
          recipe.tags.take(3).length;
      // 如果平均长度大于3，只显示2个标签
      if (avgLength > 3) {
        maxTags = 2;
      }
    }

    final displayTags = recipe.tags.take(maxTags).toList();

    return displayTags.asMap().entries.map((entry) {
      final index = entry.key;
      final tag = entry.value;
      // 限制标签长度为4个字符
      final displayTag = tag.length > 4 ? tag.substring(0, 4) : tag;
      final tagColorClass = index < recipe.tagColors.length
          ? recipe.tagColors[index]
          : null;
      final tagColor = TagColorUtils.parseColor(tagColorClass);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          displayTag,
          style: TextStyle(
            fontSize: 9,
            color: tagColor,
            fontWeight: FontWeight.w500,
            inherit: false,
            height: 1.2,
          ),
        ),
      );
    }).toList();
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
}
