import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/ingredient_item.dart';
import '../models/ingredient_master.dart';
import '../services/ingredient_service.dart';
import '../services/ingredient_master_service.dart';
import '../services/http_client.dart';
import '../services/storage_location_service.dart';
import '../config/api_config.dart';

// --- Theme Constants ---
const Color _oatmeal = Color(0xFFF5F5F0);
const Color _sageGreen = Color(0xFFB2AC88);
const Color _persimmon = Color(0xFFE58A73);
const Color _textPrimary = Color(0xFF4A4F50);
const Color _textSecondary = Color(0xFF8C8F90);

// --- Helper Components ---

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry padding;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.blur = 12,
    this.opacity = 0.6,
    this.padding = EdgeInsets.zero,
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
            color: Colors.white.withValues(alpha: opacity),
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
    this.padding = const EdgeInsets.all(16),
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
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 16,
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
  final ValueChanged<String>? onChanged;
  final int? maxLines;

  const MinimalInput({
    super.key,
    required this.controller,
    required this.hintText,
    this.style,
    this.textAlign = TextAlign.start,
    this.keyboardType,
    this.onChanged,
    this.maxLines = 1,
  });

  @override
  State<MinimalInput> createState() => _MinimalInputState();
}

class _MinimalInputState extends State<MinimalInput> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(
      () => setState(() => _isFocused = _focusNode.hasFocus),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
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
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        style:
            widget.style ?? const TextStyle(fontSize: 15, color: _textPrimary),
        textAlign: widget.textAlign,
        keyboardType: widget.keyboardType,
        onChanged: widget.onChanged,
        maxLines: widget.maxLines,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            fontSize: 14,
            color: _textSecondary.withValues(alpha: 0.4),
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

// --- Main Screen ---

class IngredientEditScreen extends StatefulWidget {
  final IngredientItem? ingredient;
  final String? defaultStorage;

  const IngredientEditScreen({super.key, this.ingredient, this.defaultStorage});

  @override
  State<IngredientEditScreen> createState() => _IngredientEditScreenState();
}

class _IngredientEditScreenState extends State<IngredientEditScreen> {
  final IngredientService _ingredientService = IngredientService();
  final IngredientMasterService _masterService = IngredientMasterService();
  final IngredientCategoryService _categoryService =
      IngredientCategoryService();
  final StorageLocationService _storageService = StorageLocationService();
  final HttpClient _httpClient = HttpClient();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isSaving = false;
  bool _isLoading = true;
  List<IngredientCategory> _categories = [];
  List<StorageLocation> _storages = [];
  List<IngredientMaster> _masterList = [];
  List<IngredientUnitOption> _unitOptions = [];
  IngredientMaster? _selectedMaster;
  String? _selectedUnitId;
  File? _selectedImageFile;
  String? _uploadedImageUrl;

  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _unitController;
  late TextEditingController _noteController;

  /// 图标选项列表（不可用 string[i] 按索引取 emoji，会拆散 UTF-16 代理对导致非法字符）
  static const List<String> _iconOptions = [
    '🥬', '🥕', '🍅', '🥔', '🧅', '🥒', '🌽', '🍆', '🫑', '🥦', '🥗', '🍄',
    '🍎', '🍊', '🍋', '🍇', '🍓', '🫐', '🍌', '🥝', '🍑', '🍒', '🥭', '🍍',
    '🥛', '🧀', '🥚', '🍳', '🥩', '🍗', '🥓', '🦐', '🐟', '🍤', '🥖', '🍞',
    '🥐', '🍚', '🍜', '🥟', '🍲', '🥗', '🧂', '🫙', '🍯', '🥜', '🌰', '🍫',
  ];

  String _selectedStorage = 'fridge';
  String _selectedCategoryId = 'cat_other';
  String _selectedIcon = '🥬';
  DateTime _purchaseDate = DateTime.now();
  int _shelfLifeDays = 7;

  DateTime get _expiryDate => _purchaseDate.add(Duration(days: _shelfLifeDays));

  /// 用于 Text 显示的图标，避免非法 UTF-16（如后端脏数据）导致绘制报错
  String get _displayIcon =>
      _selectedIcon.isNotEmpty && _iconOptions.contains(_selectedIcon)
          ? _selectedIcon
          : '🥬';

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadData();
  }

  void _initControllers() {
    final item = widget.ingredient;
    _nameController = TextEditingController(text: item?.name ?? '');
    _quantityController = TextEditingController(
      text: item?.quantity != null && item!.quantity > 0
          ? item.quantity.toString().replaceAll(RegExp(r'\.0$'), '')
          : '',
    );
    _unitController = TextEditingController(text: item?.unit ?? '个');
    _noteController = TextEditingController(text: item?.note ?? '');

    if (item != null) {
      _selectedStorage = item.storage;
      _selectedCategoryId = item.categoryId.isNotEmpty
          ? item.categoryId
          : 'cat_other';
      _selectedIcon = _iconOptions.contains(item.icon) ? item.icon : '🥬';
      _uploadedImageUrl = item.thumbnail;
      if (item.expiryDate != null && item.purchaseDate != null) {
        final exp = DateTime.tryParse(item.expiryDate!);
        final pur = DateTime.tryParse(item.purchaseDate!);
        if (exp != null && pur != null) {
          _purchaseDate = pur;
          _shelfLifeDays = exp.difference(pur).inDays;
        }
      }
    } else if (widget.defaultStorage != null) {
      _selectedStorage = widget.defaultStorage!;
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([_loadCategories(), _loadStorages(), _loadMasterList()]);
    if (widget.ingredient != null &&
        widget.ingredient!.ingredientId != null &&
        widget.ingredient!.ingredientId!.isNotEmpty) {
      await _loadUnitsFor(widget.ingredient!.ingredientId!);
      try {
        _selectedMaster = _masterList.firstWhere(
          (m) => m.id == widget.ingredient!.ingredientId,
        );
      } catch (_) {}
      _selectedUnitId = widget.ingredient!.unitId;
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadMasterList() async {
    _masterList = await _masterService.search();
  }

  Future<void> _loadUnitsFor(String ingredientId) async {
    _unitOptions = await _masterService.getUnitsForIngredient(ingredientId);
    if (_selectedUnitId != null &&
        !_unitOptions.any((u) => u.unitId == _selectedUnitId)) {
      _selectedUnitId = _unitOptions.isNotEmpty ? _unitOptions.first.unitId : null;
    }
  }

  Future<void> _loadCategories() async {
    _categories = await _categoryService.getCategories();
  }

  Future<void> _loadStorages() async {
    _storages = await _storageService.getStorageLocations();
    if (_storages.isNotEmpty &&
        !_storages.any((s) => s.id == _selectedStorage)) {
      _selectedStorage = _storages.first.id;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1000,
    );
    if (file != null) setState(() => _selectedImageFile = File(file.path));
  }

  Future<void> _save() async {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    if (_selectedMaster == null || _selectedUnitId == null || _selectedUnitId!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请选择食材与单位')),
        );
      }
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      String? thumbnailUrl = _uploadedImageUrl;
      if (_selectedImageFile != null) {
        final res = await _httpClient.uploadFile(
          ApiConfig.uploadImage,
          filePath: _selectedImageFile!.path,
          fieldName: 'file',
        );
        if (res.isSuccess) thumbnailUrl = res.data['url'];
      }

      final res = widget.ingredient != null
          ? await _ingredientService.updateIngredient(
              widget.ingredient!.id,
              ingredientId: _selectedMaster!.id,
              quantity: quantity,
              unitId: _selectedUnitId,
              name: _selectedMaster!.name,
              unit: _unitOptions.where((u) => u.unitId == _selectedUnitId).isNotEmpty
                  ? _unitOptions.firstWhere((u) => u.unitId == _selectedUnitId).displayName
                  : null,
              storage: _selectedStorage,
              categoryId: _selectedCategoryId,
              thumbnail: thumbnailUrl,
              icon: _selectedIcon,
              note: _noteController.text,
              expiryDate: _formatDate(_expiryDate),
              purchaseDate: _formatDate(_purchaseDate),
            )
          : await _ingredientService.createIngredient(
              ingredientId: _selectedMaster!.id,
              quantity: quantity,
              unitId: _selectedUnitId!,
              name: _selectedMaster!.name,
              unit: _unitOptions.where((u) => u.unitId == _selectedUnitId).isNotEmpty
                  ? _unitOptions.firstWhere((u) => u.unitId == _selectedUnitId).displayName
                  : null,
              storage: _selectedStorage,
              categoryId: _selectedCategoryId,
              thumbnail: thumbnailUrl,
              icon: _selectedIcon,
              note: _noteController.text,
              expiryDate: _formatDate(_expiryDate),
              purchaseDate: _formatDate(_purchaseDate),
            );

      if (mounted) {
        if (res != null) {
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('保存失败，请重试')),
          );
        }
      }
    } catch (e) {
      debugPrint("Save error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _formatDate(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: _sageGreen)),
      );
    }

    return Scaffold(
      backgroundColor: _oatmeal,
      body: CustomScrollView(
        slivers: [
          // 1. Hero Header
          SliverToBoxAdapter(
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _selectedImageFile != null
                      ? Image.file(_selectedImageFile!, fit: BoxFit.cover)
                      : (_uploadedImageUrl != null &&
                            _uploadedImageUrl!.isNotEmpty)
                      ? Image.network(
                          _uploadedImageUrl!.startsWith('http')
                              ? _uploadedImageUrl!
                              : ApiConfig.devBaseUrl.replaceAll('/api', '') +
                                    _uploadedImageUrl!,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: Colors.white,
                          child: Center(
                            child: Text(
                              _displayIcon,
                              style: const TextStyle(fontSize: 64),
                            ),
                          ),
                        ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.2),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Floating Actions
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 10,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildRoundButton(
                          Icons.close,
                          () => Navigator.pop(context),
                        ),
                        _buildRoundButton(Icons.camera_alt_rounded, _pickImage),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Form Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListFromGenerator([
                // Info Card
                BouncyCard(
                  child: Column(
                    children: [
                      _buildFormRow(
                        Icons.shopping_basket_rounded,
                        "选择食材",
                        _masterList.isEmpty
                            ? _buildGlassDropdownTrigger(
                                icon: Icons.shopping_basket_rounded,
                                text: "请选择食材",
                              )
                            : PopupMenuButton<IngredientMaster>(
                                padding: EdgeInsets.zero,
                                offset: const Offset(0, 42),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                color: Colors.white,
                                onSelected: (m) async {
                                  setState(() => _selectedMaster = m);
                                  await _loadUnitsFor(m.id);
                                  setState(() {
                                    _selectedUnitId = _unitOptions.isNotEmpty ? _unitOptions.first.unitId : null;
                                  });
                                },
                                itemBuilder: (context) => _masterList.map((m) {
                                  final isActive = _selectedMaster?.id == m.id;
                                  return PopupMenuItem<IngredientMaster>(
                                    value: m,
                                    child: SizedBox(
                                      width: 200,
                                      child: Text(
                                        m.name,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                                          color: _textPrimary,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                child: _buildGlassDropdownTrigger(
                                  icon: Icons.shopping_basket_rounded,
                                  text: _selectedMaster?.name ?? "请选择食材",
                                ),
                              ),
                      ),
                      Divider(
                        height: 24,
                        thickness: 0.5,
                        color: _textSecondary.withValues(alpha: 0.1),
                      ),
                      _buildFormRow(
                        Icons.pin_drop_rounded,
                        "选择图标",
                        GestureDetector(
                          onTap: _showIconPicker,
                          child: Text(
                            _displayIcon,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      Divider(
                        height: 24,
                        thickness: 0.5,
                        color: _textSecondary.withValues(alpha: 0.1),
                      ),
                      _buildFormRow(
                        Icons.format_list_numbered_rounded,
                        "数量与单位",
                        Row(
                          children: [
                            SizedBox(
                              width: 80,
                              child: MinimalInput(
                                controller: _quantityController,
                                hintText: "0",
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _unitOptions.isEmpty
                                  ? _buildGlassDropdownTrigger(
                                      icon: Icons.format_list_numbered_rounded,
                                      text: "单位",
                                    )
                                  : PopupMenuButton<String>(
                                      padding: EdgeInsets.zero,
                                      offset: const Offset(0, 42),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      color: Colors.white,
                                      onSelected: (id) => setState(() => _selectedUnitId = id),
                                      itemBuilder: (context) => _unitOptions.map((u) {
                                        final isActive = _selectedUnitId == u.unitId;
                                        return PopupMenuItem<String>(
                                          value: u.unitId,
                                          child: SizedBox(
                                            width: 160,
                                            child: Text(
                                              u.displayName,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                                                color: _textPrimary,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      child: _buildGlassDropdownTrigger(
                                        icon: Icons.format_list_numbered_rounded,
                                        text: _unitOptions
                                            .where((u) => u.unitId == _selectedUnitId)
                                            .map((u) => u.displayName)
                                            .firstOrNull ?? "单位",
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Storage & Category Card
                BouncyCard(
                  child: Column(
                    children: [
                      _buildFormRow(
                        Icons.kitchen_rounded,
                        "存储位置",
                        _buildStorageDropdown(),
                      ),
                      Divider(
                        height: 24,
                        thickness: 0.5,
                        color: _textSecondary.withValues(alpha: 0.1),
                      ),
                      _buildFormRow(
                        Icons.category_rounded,
                        "分类标签",
                        _buildCategorySelector(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Expiry Card
                BouncyCard(
                  child: Column(
                    children: [
                      _buildFormRow(
                        Icons.today_rounded,
                        "购买日期",
                        GestureDetector(
                          onTap: _selectPurchaseDate,
                          child: Text(
                            _formatDate(_purchaseDate),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _textPrimary,
                            ),
                          ),
                        ),
                      ),
                      Divider(
                        height: 24,
                        thickness: 0.5,
                        color: _textSecondary.withValues(alpha: 0.1),
                      ),
                      _buildFormRow(
                        Icons.timer_rounded,
                        "保质时长",
                        GestureDetector(
                          onTap: _showShelfLifePicker,
                          child: Text(
                            "$_shelfLifeDays 天",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _persimmon,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Note Card
                BouncyCard(
                  child: MinimalInput(
                    controller: _noteController,
                    hintText: "备注信息...",
                    maxLines: 2,
                  ),
                ),
                const SizedBox(height: 120),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildStickyFooter(),
    );
  }

  Widget _buildRoundButton(IconData icon, VoidCallback onTap) {
    return GlassContainer(
      borderRadius: 50,
      padding: const EdgeInsets.all(10),
      child: GestureDetector(
        onTap: onTap,
        child: Icon(icon, size: 20, color: _textPrimary),
      ),
    );
  }

  Widget _buildFormRow(IconData icon, String label, Widget trailing) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: _textSecondary),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: _textSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(child: trailing),
      ],
    );
  }

  /// 与食材管理主界面一致的 Glass 风格下拉触发块
  Widget _buildGlassDropdownTrigger({
    required IconData icon,
    required String text,
  }) {
    return GlassContainer(
      borderRadius: 18,
      opacity: 0.6,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: _textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildStorageDropdown() {
    if (_storages.isEmpty) {
      return GlassContainer(
        borderRadius: 18,
        opacity: 0.6,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: const Text(
          "加载中",
          style: TextStyle(fontSize: 14, color: _textSecondary),
        ),
      );
    }
    final active = _storages.firstWhere(
      (s) => s.id == _selectedStorage,
      orElse: () => _storages.first,
    );
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      offset: const Offset(0, 42),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Colors.white,
      onSelected: (v) => setState(() => _selectedStorage = v),
      itemBuilder: (context) => _storages.map((s) {
        final isActive = s.id == _selectedStorage;
        return PopupMenuItem<String>(
          value: s.id,
          child: SizedBox(
            width: 160,
            child: Text(
              s.name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: _textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
      child: _buildGlassDropdownTrigger(
        icon: Icons.kitchen_rounded,
        text: active.name,
      ),
    );
  }

  Widget _buildCategorySelector() {
    final cat = _categories.firstWhere(
      (c) => c.id == _selectedCategoryId,
      orElse: () => _categories.first,
    );
    return GestureDetector(
      onTap: _showCategoryPicker,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "${cat.icon} ${cat.name}",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildStickyFooter() {
    return Container(
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
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                child: const Text(
                  "取消",
                  style: TextStyle(color: _textSecondary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 6,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _sageGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("保存食材"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Modal Pickers ---

  void _showIconPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => GridView.builder(
        padding: const EdgeInsets.all(24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: _iconOptions.length,
        itemBuilder: (ctx, i) {
          final icon = _iconOptions[i];
          return GestureDetector(
            onTap: () {
              setState(() => _selectedIcon = icon);
              Navigator.pop(ctx);
            },
            child: Container(
              decoration: BoxDecoration(
                color: _oatmeal,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 24)),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _categories.length,
        itemBuilder: (ctx, i) => ListTile(
          leading: Text(_categories[i].icon),
          title: Text(_categories[i].name),
          onTap: () {
            setState(() => _selectedCategoryId = _categories[i].id);
            Navigator.pop(ctx);
          },
        ),
      ),
    );
  }

  Future<void> _selectPurchaseDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _purchaseDate = d);
  }

  void _showShelfLifePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [3, 7, 10, 14, 30, 60]
              .map(
                (d) => GestureDetector(
                  onTap: () {
                    setState(() => _shelfLifeDays = d);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _oatmeal,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text("$d 天"),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

// --- List From Generator Utility ---
class SliverChildListFromGenerator extends SliverChildDelegate {
  final List<Widget> children;
  SliverChildListFromGenerator(this.children);
  @override
  Widget? build(BuildContext context, int index) =>
      index < children.length ? children[index] : null;
  @override
  bool shouldRebuild(covariant SliverChildDelegate oldDelegate) => true;
  @override
  int? get estimatedChildCount => children.length;
}
