import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';
import '../services/category_service.dart';

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
            color: (color ?? Theme.of(context).colorScheme.surface).withOpacity(
              opacity,
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
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
                  color: Colors.black.withOpacity(0.03), // Softer shadow
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
        color: _isFocused ? _sageGreen.withOpacity(0.05) : Colors.transparent,
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
            color: _textSecondary.withOpacity(0.3), // More transparent
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

  // State
  Recipe? _recipe;
  bool _isLoading = true;
  bool _isEditing = false;
  late AnimationController _rotateController;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _timeController;
  String _difficulty = "简单";
  List<String> _difficultyOptions = []; // Changed to dynamic list

  List<Ingredient> _ingredients = [];
  List<String> _steps = [];

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
        _difficultyOptions = ["简单", "中等", "困难"];
      }
    } catch (e) {
      _difficultyOptions = ["简单", "中等", "困难"];
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
        });
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

  // --- Actions ---

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

      tags: [], // 可以在后续需求中补齐标签编辑

      tagColors: [],

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

  Widget _buildStepItem(int index) {
    return Column(
      key: ValueKey("step_$index"),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.center, // Perfect vertical alignment
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _sageGreen.withOpacity(0.15),
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
          const Divider(height: 1, indent: 50, color: Color(0xFFFAFAFA)),
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
                      final imagePath = _recipe?.image;
                      final isValidAsset =
                          imagePath != null &&
                          imagePath.isNotEmpty &&
                          imagePath.startsWith('assets/');
                      return Image.asset(
                        isValidAsset
                            ? imagePath
                            : 'assets/chinese-potato-strips.jpg',
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.4),
                          ],
                        ),
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

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(
                        height: 1,
                        thickness: 0.5,
                        color: Color(0xFFEEEEEE),
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
                                        : Colors.grey.withOpacity(0.1),
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

          // 3. Ingredients Section - Dense List
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
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: List.generate(_ingredients.length, (index) {
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              // Ingredient Name (70%)
                              Expanded(
                                flex: 7,
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
                              // Vertical Divider
                              Container(
                                height: 16,
                                width: 1,
                                color: Colors.grey.withOpacity(0.2),
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
                                    color: Colors.grey.withOpacity(0.4),
                                    size: 18,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (index < _ingredients.length - 1)
                          const Divider(
                            height: 1,
                            indent: 16,
                            color: Color(0xFFFAFAFA),
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
                padding: EdgeInsets.zero,
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
              color: Colors.black.withOpacity(0.03),
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
                      setState(() => _isEditing = true);
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
                    _isEditing ? "保存菜谱" : "编辑菜谱",
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
