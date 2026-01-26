import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';
import '../services/category_service.dart';
import '../services/user_tag_service.dart';
import '../services/ingredient_service.dart';
import '../services/today_menu_state.dart';
import '../services/http_client.dart';
import '../config/api_config.dart';

// --- Theme Colors ---
const Color _oatmeal = Color(0xFFF5F5F0);
const Color _sageGreen = Color(0xFFB2AC88);
const Color _textPrimary = Color(0xFF4A4F50);
const Color _textSecondary = Color(0xFF8C8F90);

// --- Helper Components ---

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry padding;
  final Color? color;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 12, // Reduced radius for refined look
    this.blur = 12,
    this.opacity = 0.6, // Increased opacity for better legibility
    this.padding = EdgeInsets.zero,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: (color ?? Theme.of(context).colorScheme.surface).withValues(
              alpha: opacity,
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class BouncyCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const BouncyCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12), // Reduced padding
    this.onTap,
  });

  @override
  State<BouncyCard> createState() => _BouncyCardState();
}

class _BouncyCardState extends State<BouncyCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => _controller.forward() : null,
      onTapUp: widget.onTap != null ? (_) => _controller.reverse() : null,
      onTapCancel: widget.onTap != null ? () => _controller.reverse() : null,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                16,
              ), // Slightly smaller radius
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03), // Softer shadow
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class MinimalInput extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final TextStyle? style;
  final TextAlign textAlign;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;

  const MinimalInput({
    super.key,
    required this.controller,
    required this.hintText,
    this.style,
    this.textAlign = TextAlign.start,
    this.keyboardType,
    this.onSubmitted,
    this.onChanged,
    this.focusNode,
  });

  @override
  State<MinimalInput> createState() => _MinimalInputState();
}

class _MinimalInputState extends State<MinimalInput> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _isFocused
            ? _sageGreen.withValues(alpha: 0.05)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        style:
            widget.style ?? const TextStyle(fontSize: 14, color: _textPrimary),
        textAlign: widget.textAlign,
        keyboardType: widget.keyboardType,
        onSubmitted: widget.onSubmitted,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            fontSize: 13,
            color: _textSecondary.withValues(alpha: 0.3), // More transparent
            fontWeight: FontWeight.normal,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }
}

// --- Main Screen ---

class RecipeDetailScreen extends StatefulWidget {
  final String? recipeId;
  final bool isFromMyRecipes;
  final bool isCreateMode;

  const RecipeDetailScreen({
    super.key,
    this.recipeId,
    this.isFromMyRecipes = false,
    this.isCreateMode = false,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen>
    with SingleTickerProviderStateMixin {
  final RecipeService _recipeService = RecipeService();
  final CategoryService _categoryService = CategoryService();
  final UserTagService _userTagService = UserTagService();
  final IngredientService _ingredientService = IngredientService();
  final TodayMenuState _todayMenuState = TodayMenuState();

  // State
  Recipe? _recipe;
  bool _isLoading = true;
  bool _isEditing = false;
  late AnimationController _rotateController;

  // 图片上传相关
  File? _selectedImageFile;
  String? _uploadedImageUrl;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploadingImage = false;

  // 食材充足状态缓存 (食材名称 -> 充足状态)
  final Map<String, String> _ingredientStatusCache = {};

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _timeController;
  String _difficulty = "简单";
  List<String> _difficultyOptions = []; // Changed to dynamic list

  List<Ingredient> _ingredients = [];
  List<String> _steps = [];
  List<String> _tags = [];
  List<String> _tagColors = [];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.isCreateMode;
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadDifficultyOptions(),
      if (!widget.isCreateMode) _loadRecipeDetail(),
    ]);

    if (widget.isCreateMode) {
      _initCreateMode();
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadDifficultyOptions() async {
    try {
      final categories = await _categoryService.getCategoriesByType(
        'difficulty',
      );
      if (categories != null && categories.isNotEmpty) {
        setState(() {
          _difficultyOptions = categories.map((e) => e.name).toList();
          // Ensure default value is valid
          if (!_difficultyOptions.contains(_difficulty) &&
              _difficultyOptions.isNotEmpty) {
            _difficulty = _difficultyOptions.first;
          }
        });
      } else {
        // Fallback if DB is empty
        _difficultyOptions = ["有手就行", "家常便饭", "餐厅招牌", "硬核挑战", "专业厨师"];
      }
    } catch (e) {
      _difficultyOptions = ["有手就行", "家常便饭", "餐厅招牌", "硬核挑战", "专业厨师"];
    }
  }

  void _initCreateMode() {
    _nameController = TextEditingController();
    _timeController = TextEditingController();
    _ingredients = [Ingredient(name: "", amount: "")];
    _steps = [""];
  }

  Future<void> _loadRecipeDetail() async {
    if (widget.recipeId == null) return;

    try {
      final recipe = await _recipeService.getRecipeDetail(widget.recipeId!);
      if (recipe != null) {
        setState(() {
          _recipe = recipe;
          _nameController = TextEditingController(text: recipe.name);
          _timeController = TextEditingController(
            text: recipe.time.replaceAll(RegExp(r'[^0-9]'), ''),
          );
          _difficulty = recipe.difficulty;
          _ingredients = List.from(recipe.ingredients ?? []);
          _steps = List.from(recipe.steps ?? []);
          _tags = List.from(recipe.tags);
          _tagColors = List.from(recipe.tagColors);
        });

        // 加载完成后检查所有食材状态
        _checkAllIngredientsStatus();
      }
    } catch (e) {
      debugPrint('加载详情失败: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _timeController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  // --- Ingredient Status Check ---

  /// 检查食材充足状态
  /// 返回: 'sufficient' (充足) / 'insufficient' (不足) / 'unknown' (未知)
  Future<String> _checkIngredientStatus(String ingredientName) async {
    // 如果已有缓存，直接返回
    if (_ingredientStatusCache.containsKey(ingredientName)) {
      return _ingredientStatusCache[ingredientName]!;
    }

    try {
      // 查询库存中是否有该食材
      final batches = await _ingredientService.getIngredientBatches(
        ingredientName,
      );

      String status;
      if (batches.isEmpty) {
        status = 'unknown'; // 未知（库存中没有该食材）
      } else {
        // 计算总数量
        final totalQuantity = batches.fold<double>(
          0,
          (sum, item) => sum + item.quantity,
        );

        // 简单判断：数量大于0则充足
        status = totalQuantity > 0 ? 'sufficient' : 'insufficient';
      }

      // 缓存结果
      _ingredientStatusCache[ingredientName] = status;
      return status;
    } catch (e) {
      debugPrint('检查食材状态失败: $e');
      return 'unknown';
    }
  }

  /// 批量检查所有食材状态
  Future<void> _checkAllIngredientsStatus() async {
    if (_ingredients.isEmpty) return;

    // 并发检查所有食材状态
    await Future.wait(
      _ingredients.map((ingredient) => _checkIngredientStatus(ingredient.name)),
    );

    // 刷新UI
    if (mounted) setState(() {});
  }

  // --- Actions ---

  /// 尝试做做 - 将菜谱加入今日点餐列表
  Future<void> _tryThisRecipe() async {
    if (_recipe == null) return;

    _todayMenuState.addToSelected(_recipe!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('已加入今日点餐列表'),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: '查看',
            onPressed: () {
              // 可以导航到今日菜单页面
            },
          ),
        ),
      );
    }
  }

  /// 显示更多选项菜单
  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              _buildMoreOptionItem(
                icon: Icons.share_rounded,
                title: '分享至网络',
                onTap: () {
                  Navigator.pop(context);
                  _shareToNetwork();
                },
              ),
              if (!widget.isFromMyRecipes) ...[
                Divider(height: 1, thickness: 0.5, color: Colors.grey.withValues(alpha: 0.1)),
                _buildMoreOptionItem(
                  icon: Icons.edit_note_rounded,
                  title: '申请编辑菜谱',
                  onTap: () {
                    Navigator.pop(context);
                    _requestEditPermission();
                  },
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建更多选项菜单项
  Widget _buildMoreOptionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: _textPrimary, size: 24),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: _textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 分享至网络
  void _shareToNetwork() {
    // TODO: 实现分享至网络功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('分享功能开发中...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// 申请编辑菜谱权限
  void _requestEditPermission() {
    // TODO: 实现申请编辑权限功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已提交编辑申请'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// 选择图片
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImageFile = File(image.path);
        });
        // 自动上传图片
        await _uploadImage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败: $e')),
        );
      }
    }
  }

  /// 上传图片到服务器
  Future<void> _uploadImage() async {
    if (_selectedImageFile == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final httpClient = HttpClient();
      final response = await httpClient.uploadFile(
        ApiConfig.uploadImage,
        filePath: _selectedImageFile!.path,
        fieldName: 'file',
      );

      if (response.isSuccess && response.data != null) {
        setState(() {
          _uploadedImageUrl = response.data['url'];
          _isUploadingImage = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('图片上传成功')),
          );
        }
      } else {
        throw Exception('上传失败');
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('图片上传失败: $e')),
        );
      }
    }
  }

  void _addIngredient() {
    _rotateController.forward(from: 0.0);
    setState(() {
      _ingredients.add(Ingredient(name: "", amount: ""));
    });
  }

  void _addStep() {
    _rotateController.forward(from: 0.0);
    setState(() {
      _steps.add("");
    });
  }

  Future<void> _saveRecipe() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入菜谱名称'),
          duration: Duration(seconds: 1),
        ),
      );

      return;
    }

    // 显示加载状态

    showDialog(
      context: context,

      barrierDismissible: false,

      builder: (_) =>
          Center(child: CircularProgressIndicator(color: _sageGreen)),
    );

    // 构建菜谱数据

    final recipeData = Recipe(
      id: widget.isCreateMode ? '' : (widget.recipeId ?? ''),

      name: _nameController.text.trim(),

      time: "${_timeController.text.trim()}分钟", // 格式化时间

      difficulty: _difficulty,

      tags: _tags, // 使用标签数据

      tagColors: _tagColors,

      categories: [],

      ingredients: _ingredients,

      steps: _steps.where((s) => s.trim().isNotEmpty).toList(), // 过滤空步骤

      favorite: false,
    );

    try {
      Recipe? result;

      if (widget.isCreateMode) {
        result = await _recipeService.createRecipe(recipeData);
      } else if (widget.recipeId != null) {
        result = await _recipeService.updateRecipe(
          widget.recipeId!,
          recipeData,
        );
      }

      if (mounted) {
        Navigator.pop(context); // 关闭加载弹窗

        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('保存成功'),
              duration: Duration(seconds: 1),
            ),
          );

          Navigator.pop(context, true); // 返回上一页并通知刷新
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('保存失败，请重试'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发生错误: $e'), duration: Duration(seconds: 1)),
        );
      }
    }
  }

  // --- Tag Management Methods ---

  void _addTag(String tagName, String tagColor) {
    if (tagName.trim().isEmpty) return;
    setState(() {
      _tags.add(tagName.trim());
      _tagColors.add(tagColor);
    });
  }

  void _removeTag(int index) {
    setState(() {
      _tags.removeAt(index);
      _tagColors.removeAt(index);
    });
  }

  Future<void> _showAddTagDialog() async {
    String selectedColor = '#B2AC88'; // Default sage green
    List<UserTag> userTags = [];

    // Load user tags
    try {
      final tags = await _userTagService.getUserTags();
      if (tags != null) {
        userTags = tags;
      }
    } catch (e) {
      debugPrint('加载用户标签失败: $e');
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => _AddTagDialog(
        selectedColor: selectedColor,
        userTags: userTags,
        onAddTag: (name, color) => _addTag(name, color),
      ),
    );
  }

  // --- Helper Methods ---

  /// 构建食材状态指示器
  Widget _buildIngredientStatusIndicator(String ingredientName) {
    final status = _ingredientStatusCache[ingredientName] ?? 'unknown';

    IconData icon;
    Color color;

    switch (status) {
      case 'sufficient':
        icon = Icons.check_circle;
        color = const Color(0xFF43A047); // 绿色
        break;
      case 'insufficient':
        icon = Icons.warning;
        color = const Color(0xFFFF9800); // 橙色
        break;
      case 'unknown':
      default:
        icon = Icons.remove_circle_outline;
        color = const Color(0xFFBDBDBD); // 灰色
        break;
    }

    return Icon(icon, size: 16, color: color);
  }

  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(
          int.parse(colorString.substring(1), radix: 16) + 0xFF000000,
        );
      }
      return _sageGreen;
    } catch (e) {
      return _sageGreen;
    }
  }

  /// 构建"暂无图片"占位符
  Widget _buildNoImagePlaceholder() {
    return Container(
      color: _oatmeal,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 64,
              color: _textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              '暂无图片',
              style: TextStyle(
                fontSize: 16,
                color: _textSecondary.withValues(alpha: 0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem(int index) {
    return Column(
      key: ValueKey("step_$index"),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.center, // Perfect vertical alignment
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _sageGreen.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  "${index + 1}",
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _sageGreen,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _isEditing
                    ? MinimalInput(
                        controller: TextEditingController(text: _steps[index]),
                        hintText: "描述这个步骤...",
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: _textPrimary,
                        ),
                        onChanged: (val) => _steps[index] = val,
                      )
                    : Text(
                        _steps[index],
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: _textPrimary,
                        ),
                      ),
              ),
              if (_isEditing) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.drag_handle,
                  color: Color(0xFFE0E0E0),
                  size: 18,
                ),
              ],
            ],
          ),
        ),
        if (index < _steps.length - 1)
          Divider(height: 1, indent: 50, thickness: 0.5, color: Colors.grey.withValues(alpha: 0.05)),
      ],
    );
  }

  // --- UI Builders ---

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: _oatmeal,
      body: CustomScrollView(
        slivers: [
          // 1. Hero Image Section
          SliverToBoxAdapter(
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Builder(
                    builder: (context) {
                      // 优先显示已选择的本地图片
                      if (_selectedImageFile != null) {
                        return Image.file(
                          _selectedImageFile!,
                          fit: BoxFit.cover,
                        );
                      }

                      // 显示已上传的图片
                      if (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty) {
                        return Image.network(
                          _uploadedImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildNoImagePlaceholder();
                          },
                        );
                      }

                      // 显示菜谱原有的图片
                      final imagePath = _recipe?.image;
                      if (imagePath != null && imagePath.isNotEmpty) {
                        if (imagePath.startsWith('http://') ||
                            imagePath.startsWith('https://')) {
                          return Image.network(
                            imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildNoImagePlaceholder();
                            },
                          );
                        } else if (imagePath.startsWith('assets/')) {
                          return Image.asset(
                            imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildNoImagePlaceholder();
                            },
                          );
                        }
                      }

                      // 默认显示"暂无图片"
                      return _buildNoImagePlaceholder();
                    },
                  ),
                  // 渐变遮罩（不拦截点击事件）
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.4),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // 编辑模式下：点击整个图片区域上传
                  if (_isEditing)
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: _isUploadingImage ? null : _pickImage,
                        child: Container(
                          color: Colors.transparent,
                          child: _isUploadingImage
                              ? Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                        SizedBox(height: 12),
                                        Text(
                                          '上传中...',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 10,
                    left: 16,
                    child: GlassContainer(
                      borderRadius: 50,
                      padding: const EdgeInsets.all(8),
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  // 右上角更多选项按钮（仅在非编辑模式显示）
                  if (!_isEditing)
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 10,
                      right: 16,
                      child: GlassContainer(
                        borderRadius: 50,
                        padding: const EdgeInsets.all(8),
                        child: GestureDetector(
                          onTap: _showMoreOptions,
                          child: const Icon(
                            Icons.more_vert,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: GlassContainer(
                      opacity: 0.6,
                      blur: 16,
                      borderRadius: 12,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: _isEditing
                          ? TextField(
                              controller: _nameController,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: _textPrimary,
                                height: 1.2,
                              ),
                              decoration: const InputDecoration(
                                hintText: "输入菜谱名称...",
                                hintStyle: TextStyle(color: _textSecondary),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            )
                          : Text(
                              _nameController.text,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: _textPrimary,
                                height: 1.2,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Basic Info (Time & Difficulty) - Compact Layout
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: BouncyCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Time Input
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 18,
                          color: _textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "烹饪时长",
                          style: const TextStyle(
                            fontSize: 14,
                            color: _textSecondary,
                          ),
                        ),
                        const Spacer(),
                        _isEditing
                            ? SizedBox(
                                width: 80,
                                child: MinimalInput(
                                  controller: _timeController,
                                  hintText: "0",
                                  textAlign: TextAlign.end,
                                  keyboardType: TextInputType.number,
                                  style: GoogleFonts.nunito(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _textPrimary,
                                  ),
                                ),
                              )
                            : Text(
                                _timeController.text,
                                style: GoogleFonts.nunito(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _textPrimary,
                                ),
                              ),
                        const SizedBox(width: 4),
                        Text(
                          "分钟",
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(
                        height: 1,
                        thickness: 0.5,
                        color: Colors.grey.withValues(alpha: 0.05),
                      ),
                    ),

                    // Row 2: Difficulty Chips
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.bar_chart_rounded,
                              size: 18,
                              color: _textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "难度等级",
                              style: const TextStyle(
                                fontSize: 14,
                                color: _textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _difficultyOptions.map((option) {
                            final isSelected = _difficulty == option;
                            if (!_isEditing && !isSelected) {
                              return const SizedBox.shrink();
                            }
                            return GestureDetector(
                              onTap: _isEditing
                                  ? () => setState(() => _difficulty = option)
                                  : null,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected ? _sageGreen : _oatmeal,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.transparent
                                        : Colors.grey.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Colors.white
                                        : _textPrimary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Tags Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: BouncyCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.local_offer_rounded,
                          size: 18,
                          color: _textSecondary,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "菜品标签",
                          style: TextStyle(fontSize: 14, color: _textSecondary),
                        ),
                        const Spacer(),
                        if (_isEditing)
                          GestureDetector(
                            onTap: _showAddTagDialog,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _sageGreen.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add, size: 14, color: _sageGreen),
                                  const SizedBox(width: 4),
                                  Text(
                                    "添加",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _sageGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (_tags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(_tags.length, (index) {
                          final tagColor = _tagColors.length > index
                              ? _parseColor(_tagColors[index])
                              : _sageGreen;
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: _isEditing ? 8 : 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: tagColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: tagColor.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _tags[index],
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: tagColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (_isEditing) ...[
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () => _removeTag(index),
                                    child: Icon(
                                      Icons.close,
                                      size: 14,
                                      color: tagColor.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                      ),
                    ] else if (!_isEditing)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          "暂无标签",
                          style: TextStyle(fontSize: 13, color: _textSecondary),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // 4. Ingredients Section - Dense List
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "食材清单",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                  if (_isEditing)
                    RotationTransition(
                      turns: Tween(begin: 0.0, end: 0.25).animate(
                        CurvedAnimation(
                          parent: _rotateController,
                          curve: Curves.elasticOut,
                        ),
                      ),
                      child: GestureDetector(
                        onTap: _addIngredient,
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.add_circle,
                            color: _sageGreen,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: BouncyCard(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: List.generate(_ingredients.length, (index) {
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              // Ingredient Name (60%)
                              Expanded(
                                flex: 6,
                                child: _isEditing
                                    ? MinimalInput(
                                        controller:
                                            TextEditingController(
                                                text: _ingredients[index].name,
                                              )
                                              ..selection =
                                                  TextSelection.collapsed(
                                                    offset: _ingredients[index]
                                                        .name
                                                        .length,
                                                  ),
                                        hintText: "食材名称",
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: _textPrimary,
                                        ),
                                        onChanged: (val) =>
                                            _ingredients[index] = Ingredient(
                                              name: val,
                                              amount:
                                                  _ingredients[index].amount,
                                            ),
                                      )
                                    : Text(
                                        _ingredients[index].name,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: _textPrimary,
                                        ),
                                      ),
                              ),
                              // Status Indicator (只在非编辑模式显示)
                              if (!_isEditing) ...[
                                const SizedBox(width: 8),
                                _buildIngredientStatusIndicator(
                                  _ingredients[index].name,
                                ),
                              ],
                              // Vertical Divider
                              Container(
                                height: 16,
                                width: 1,
                                color: Colors.grey.withValues(alpha: 0.2),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                              // Amount (30%)
                              Expanded(
                                flex: 3,
                                child: _isEditing
                                    ? MinimalInput(
                                        controller: TextEditingController(
                                          text: _ingredients[index].amount,
                                        ),
                                        hintText: "用量",
                                        textAlign: TextAlign.end,
                                        style: GoogleFonts.nunito(
                                          fontSize: 15,
                                          color: _textSecondary,
                                        ),
                                        onChanged: (val) =>
                                            _ingredients[index] = Ingredient(
                                              name: _ingredients[index].name,
                                              amount: val,
                                            ),
                                      )
                                    : Text(
                                        _ingredients[index].amount,
                                        textAlign: TextAlign.end,
                                        style: GoogleFonts.nunito(
                                          fontSize: 15,
                                          color: _textSecondary,
                                        ),
                                      ),
                              ),
                              if (_isEditing) ...[
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => setState(
                                    () => _ingredients.removeAt(index),
                                  ),
                                  child: Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.grey.withValues(alpha: 0.4),
                                    size: 18,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (index < _ingredients.length - 1)
                          Divider(
                            height: 1,
                            indent: 16,
                            thickness: 0.5,
                            color: Colors.grey.withValues(alpha: 0.05),
                          ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),

          // 4. Steps Section - Reorderable
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "烹饪步骤",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                  if (_isEditing)
                    GestureDetector(
                      onTap: _addStep,
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.add_circle,
                          color: _sageGreen,
                          size: 24,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverToBoxAdapter(
              child: BouncyCard(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: _isEditing
                    ? ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero, // Remove default list padding
                        itemCount: _steps.length,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) newIndex -= 1;
                            final item = _steps.removeAt(oldIndex);
                            _steps.insert(newIndex, item);
                          });
                        },
                        itemBuilder: (context, index) => _buildStepItem(index),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero, // Remove default list padding
                        itemCount: _steps.length,
                        itemBuilder: (context, index) => _buildStepItem(index),
                      ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: OutlinedButton(
                  onPressed: () {
                    if (_isEditing && !widget.isCreateMode) {
                      setState(() => _isEditing = false);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFE0E0E0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    foregroundColor: _textSecondary,
                  ),
                  child: Text(
                    _isEditing && !widget.isCreateMode ? "取消" : "返回",
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 6,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    if (_isEditing) {
                      _saveRecipe();
                    } else {
                      // 根据来源显示不同功能
                      if (widget.isFromMyRecipes) {
                        // 我的私房：编辑菜谱
                        setState(() => _isEditing = true);
                      } else {
                        // 探索发现：尝试做做
                        _tryThisRecipe();
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _sageGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _isEditing
                        ? "保存菜谱"
                        : (widget.isFromMyRecipes ? "编辑菜谱" : "尝试做做"),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Add Tag Dialog Component ---

class _AddTagDialog extends StatefulWidget {
  final String selectedColor;
  final List<UserTag> userTags;
  final Function(String, String) onAddTag;

  const _AddTagDialog({
    required this.selectedColor,
    required this.userTags,
    required this.onAddTag,
  });

  @override
  State<_AddTagDialog> createState() => _AddTagDialogState();
}

class _AddTagDialogState extends State<_AddTagDialog> {
  late String _selectedColor;
  late TextEditingController _tagController;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.selectedColor;
    _tagController = TextEditingController();
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  // Predefined color options
  final List<Map<String, dynamic>> _colorOptions = [
    {'name': '鼠尾草绿', 'value': '#B2AC88'},
    {'name': '番茄红', 'value': '#E74C3C'},
    {'name': '南瓜橙', 'value': '#E67E22'},
    {'name': '柠檬黄', 'value': '#F39C12'},
    {'name': '薄荷绿', 'value': '#2ECC71'},
    {'name': '天空蓝', 'value': '#3498DB'},
    {'name': '薰衣草紫', 'value': '#9B59B6'},
    {'name': '玫瑰粉', 'value': '#E91E63'},
  ];

  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(
          int.parse(colorString.substring(1), radix: 16) + 0xFF000000,
        );
      }
      return _sageGreen;
    } catch (e) {
      return _sageGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [_buildHeader(), _buildContent(), _buildActions()],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _oatmeal,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_offer_rounded, color: _sageGreen, size: 24),
          const SizedBox(width: 12),
          const Text(
            '添加标签',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.close, color: _textSecondary, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCustomTagInput(),
          const SizedBox(height: 20),
          _buildColorPicker(),
          if (widget.userTags.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildCommonTags(),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomTagInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '自定义标签',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _tagController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '输入标签名称...',
            hintStyle: const TextStyle(color: _textSecondary, fontSize: 14),
            filled: true,
            fillColor: _oatmeal,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '选择颜色',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _colorOptions.map((colorOption) {
            final isSelected = _selectedColor == colorOption['value'];
            final color = _parseColor(colorOption['value']);
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColor = colorOption['value'];
                });
              },
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? color : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCommonTags() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '常用标签',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.userTags.map((tag) {
            final tagColor = _parseColor(tag.color);
            return GestureDetector(
              onTap: () {
                widget.onAddTag(tag.name, tag.color);
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: tagColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: tagColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tag.name,
                      style: TextStyle(
                        fontSize: 13,
                        color: tagColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${tag.useCount}',
                      style: TextStyle(
                        fontSize: 11,
                        color: tagColor.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: Color(0xFFE0E0E0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                foregroundColor: _textSecondary,
              ),
              child: const Text('取消'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (_tagController.text.trim().isNotEmpty) {
                  widget.onAddTag(_tagController.text.trim(), _selectedColor);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _sageGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text('添加'),
            ),
          ),
        ],
      ),
    );
  }
}
