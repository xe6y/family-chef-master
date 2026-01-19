import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/ingredient_item.dart';
import '../services/ingredient_service.dart';
import '../services/http_client.dart';
import '../services/storage_location_service.dart';
import '../config/api_config.dart';

/// 食材添加/编辑页面 - 全新UI设计
class IngredientEditScreen extends StatefulWidget {
  /// 要编辑的食材（为null时为添加模式）
  final IngredientItem? ingredient;

  /// 默认存储位置
  final String? defaultStorage;

  const IngredientEditScreen({super.key, this.ingredient, this.defaultStorage});

  @override
  State<IngredientEditScreen> createState() => _IngredientEditScreenState();
}

class _IngredientEditScreenState extends State<IngredientEditScreen> {
  /// 食材服务
  final IngredientService _ingredientService = IngredientService();

  /// 分类服务
  final IngredientCategoryService _categoryService =
      IngredientCategoryService();
  
  /// 存储位置服务
  final StorageLocationService _storageService = StorageLocationService();

  /// HTTP客户端
  final HttpClient _httpClient = HttpClient();

  /// 图片选择器
  final ImagePicker _imagePicker = ImagePicker();

  /// 表单键
  final _formKey = GlobalKey<FormState>();

  /// 是否编辑模式
  bool get _isEditMode => widget.ingredient != null;

  /// 是否正在保存
  bool _isSaving = false;

  /// 是否正在加载分类
  bool _isLoadingCategories = true;
  
  /// 是否正在加载位置
  bool _isLoadingStorages = true;

  /// 分类列表
  List<IngredientCategory> _categories = [];
  
  /// 存储位置列表
  List<StorageLocation> _storages = [];

  /// 选中的图片文件
  File? _selectedImageFile;

  /// 上传后的图片URL
  String? _uploadedImageUrl;

  // 表单字段控制器
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _unitController;
  late TextEditingController _noteController;

  // 表单状态
  String _selectedStorage = 'fridge';
  String _selectedCategoryId = 'cat_other';
  String _selectedIcon = '🥬';

  /// 购买日期
  DateTime _purchaseDate = DateTime.now();

  /// 保质期（天数）
  int _shelfLifeDays = 7;

  /// 计算得出的过期日期
  DateTime get _expiryDate => _purchaseDate.add(Duration(days: _shelfLifeDays));

  /// 常用单位列表
  final List<String> _commonUnits = [
    '个',
    '斤',
    '克',
    '千克',
    '毫升',
    '升',
    '包',
    '袋',
    '盒',
    '瓶',
  ];

  /// 常用图标列表
  final List<String> _commonIcons = [
    '🥬',
    '🥕',
    '🍅',
    '🥔',
    '🧅',
    '🥒',
    '🌽',
    '🥦',
    '🥩',
    '🍖',
    '🥓',
    '🍗',
    '🐟',
    '🦐',
    '🦀',
    '🥚',
    '🍎',
    '🍊',
    '🍋',
    '🍇',
    '🍓',
    '🍑',
    '🥝',
    '🍌',
    '🥛',
    '🧀',
    '🍞',
    '🍚',
    '🧂',
    '🫚',
    '🧄',
    '📦',
  ];

  /// 常用保质期选项（天数）
  final List<int> _shelfLifeOptions = [1, 3, 5, 7, 10, 14, 21, 30, 60, 90];

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadCategories(),
      _loadStorageLocations(),
    ]);
  }

  /// 初始化控制器
  void _initControllers() {
    final ingredient = widget.ingredient;
    _nameController = TextEditingController(text: ingredient?.name ?? '');
    _quantityController = TextEditingController(
      text: ingredient?.quantity != null && ingredient!.quantity > 0
          ? (ingredient.quantity == ingredient.quantity.truncateToDouble()
                ? ingredient.quantity.toInt().toString()
                : ingredient.quantity.toString())
          : '',
    );
    _unitController = TextEditingController(text: ingredient?.unit ?? '个');
    _noteController = TextEditingController(text: ingredient?.note ?? '');

    if (ingredient != null) {
      _selectedStorage = ingredient.storage;
      _selectedCategoryId = ingredient.categoryId.isNotEmpty
          ? ingredient.categoryId
          : 'cat_other';
      _selectedIcon = ingredient.icon;
      _uploadedImageUrl = ingredient.thumbnail;

      // 尝试从日期计算保质期
      if (ingredient.expiryDate != null && ingredient.expiryDate!.isNotEmpty) {
        final expiryDate = DateTime.tryParse(ingredient.expiryDate!);
        if (expiryDate != null) {
          if (ingredient.purchaseDate != null &&
              ingredient.purchaseDate!.isNotEmpty) {
            final purchaseDate = DateTime.tryParse(ingredient.purchaseDate!);
            if (purchaseDate != null) {
              final days = expiryDate.difference(purchaseDate).inDays;
              _shelfLifeDays = days > 0 ? days : 7;
              _purchaseDate = purchaseDate;
            }
          }
        }
      }
    } else if (widget.defaultStorage != null && widget.defaultStorage!.isNotEmpty) {
      _selectedStorage = widget.defaultStorage!;
    }
  }

  /// 加载分类列表
  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      _categories = await _categoryService.getCategories();
    } catch (e) {
      debugPrint('加载分类失败: $e');
    }
    if (mounted) setState(() => _isLoadingCategories = false);
  }
  
  /// 加载存储位置
  Future<void> _loadStorageLocations() async {
    setState(() => _isLoadingStorages = true);
    try {
      final locations = await _storageService.getStorageLocations();
      if (mounted) {
        setState(() {
          _storages = locations;
          // 如果当前选中的位置不在列表中（且列表不为空），选中第一个
          // 注意：如果是编辑模式，我们可能希望保留原值（即使它已被删除？或者我们显示为"未知"？）
          // 这里的逻辑是：如果当前选中的位置为空，或者（不在列表中且不是自定义输入），则重置。
          // 但由于 storage 是字符串ID，我们应该尽量匹配。
          if (_storages.isNotEmpty && !_storages.any((s) => s.id == _selectedStorage)) {
             // 如果是新建，且传入的默认值无效，则选中第一个
             if (!_isEditMode) {
               _selectedStorage = _storages.first.id;
             }
             // 如果是编辑，保留原值，UI上可能需要处理"未找到"的情况，或者自动添加到列表显示
          }
          
          // 如果是新建且没有默认值，选中第一个
          if (!_isEditMode && (_selectedStorage.isEmpty || _selectedStorage == 'fridge')) {
             if (_storages.isNotEmpty) {
                // 检查 'fridge' 是否存在，如果存在则保持，否则选第一个
                if (!_storages.any((s) => s.id == _selectedStorage)) {
                  _selectedStorage = _storages.first.id;
                }
             }
          }
        });
      }
    } catch (e) {
      debugPrint('加载存储位置失败: $e');
    }
    if (mounted) setState(() => _isLoadingStorages = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// 选择图片
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('选择图片失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('选择图片失败: $e')));
      }
    }
  }

  /// 显示图片选择对话框
  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('拍照'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('从相册选择'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_selectedImageFile != null ||
                (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty))
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('删除图片', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImageFile = null;
                    _uploadedImageUrl = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  /// 上传图片
  Future<String?> _uploadImage() async {
    if (_selectedImageFile == null) return _uploadedImageUrl;

    try {
      final response = await _httpClient.uploadFile(
        ApiConfig.uploadImage,
        filePath: _selectedImageFile!.path,
        fieldName: 'file',
      );

      if (response.isSuccess && response.data != null) {
        return response.data['url'] as String?;
      }
    } catch (e) {
      debugPrint('上传图片失败: $e');
    }

    return null;
  }

  /// 选择购买日期
  Future<void> _selectPurchaseDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('zh', 'CN'),
    );

    if (pickedDate != null) {
      setState(() {
        _purchaseDate = pickedDate;
      });
    }
  }

  /// 选择保质期
  void _showShelfLifePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: const Text(
                '选择保质期',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 12,
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _shelfLifeOptions.map((days) {
                    final isSelected = days == _shelfLifeDays;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _shelfLifeDays = days);
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 80,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFF6B35)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? null
                              : Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          '$days天',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 选择图标
  void _showIconPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: const Text(
                '选择图标',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _commonIcons.length,
                itemBuilder: (context, index) {
                  final icon = _commonIcons[index];
                  final isSelected = icon == _selectedIcon;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedIcon = icon);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFF6B35).withValues(alpha: 0.15)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected
                            ? Border.all(
                                color: const Color(0xFFFF6B35),
                                width: 2,
                              )
                            : Border.all(color: Colors.grey.shade200),
                      ),
                      child: Center(
                        child: Text(icon, style: const TextStyle(fontSize: 28)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 保存食材
  Future<void> _saveIngredient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // 上传图片（如果有新选择的图片）
      String? thumbnailUrl = _uploadedImageUrl;
      if (_selectedImageFile != null) {
        thumbnailUrl = await _uploadImage();
      }

      final quantity = double.tryParse(_quantityController.text) ?? 0;
      final unit = _unitController.text;
      final expiryDateStr = _formatDate(_expiryDate);
      final purchaseDateStr = _formatDate(_purchaseDate);

      IngredientItem? result;

      if (_isEditMode) {
        result = await _ingredientService.updateIngredient(
          widget.ingredient!.id,
          name: _nameController.text,
          quantity: quantity,
          unit: unit,
          storage: _selectedStorage,
          categoryId: _selectedCategoryId,
          thumbnail: thumbnailUrl,
          icon: _selectedIcon,
          note: _noteController.text,
          expiryDate: expiryDateStr,
          purchaseDate: purchaseDateStr,
        );
      } else {
        result = await _ingredientService.createIngredient(
          name: _nameController.text,
          quantity: quantity,
          unit: unit,
          storage: _selectedStorage,
          categoryId: _selectedCategoryId,
          thumbnail: thumbnailUrl,
          icon: _selectedIcon,
          note: _noteController.text,
          expiryDate: expiryDateStr,
          purchaseDate: purchaseDateStr,
        );
      }

      if (result != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_isEditMode ? '更新成功' : '添加成功')));
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_isEditMode ? '更新失败' : '添加失败')));
      }
    } catch (e) {
      debugPrint('保存失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    }

    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  /// 解析颜色字符串
  Color _parseColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) return Colors.grey;
    try {
      return Color(int.parse(colorStr.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  /// 格式化日期显示
  String _formatDate(DateTime date) {
    final year = date.year.toString();
    final month = date.month < 10 ? '0${date.month}' : date.month.toString();
    final day = date.day < 10 ? '0${date.day}' : date.day.toString();
    return '$year-$month-$day';
  }

  /// 获取过期状态颜色
  Color _getExpiryStatusColor() {
    final daysLeft = _expiryDate.difference(DateTime.now()).inDays;
    if (daysLeft <= 0) return Colors.red;
    if (daysLeft <= 2) return Colors.orange;
    if (daysLeft <= 7) return Colors.yellow.shade700;
    return const Color(0xFF4CAF50);
  }

  /// 获取过期状态文本
  String _getExpiryStatusText() {
    final daysLeft = _expiryDate.difference(DateTime.now()).inDays;
    if (daysLeft <= 0) return '已过期';
    if (daysLeft == 1) return '明天过期';
    return '$daysLeft天后过期';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF2D3436)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditMode ? '编辑食材' : '添加食材',
          style: const TextStyle(
            color: Color(0xFF2D3436),
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveIngredient,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFFF6B35),
                    ),
                  )
                : const Text(
                    '保存',
                    style: TextStyle(
                      color: Color(0xFFFF6B35),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 16),

              // 图片和图标选择区域
              _buildImageIconSection(),

              const SizedBox(height: 16),

              // 基本信息
              _buildBasicInfoCard(),

              const SizedBox(height: 16),

              // 分类和存储
              _buildCategoryCard(),

              const SizedBox(height: 16),

              // 保质期和购买日期
              _buildShelfLifeCard(),

              const SizedBox(height: 16),

              // 备注
              _buildNoteCard(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建图片和图标选择区域
  Widget _buildImageIconSection() {
    final hasImage =
        _selectedImageFile != null ||
        (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 图片预览
          GestureDetector(
            onTap: _showImagePickerDialog,
            child: Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
              ),
              child: hasImage
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _selectedImageFile != null
                          ? Image.file(_selectedImageFile!, fit: BoxFit.cover)
                          : Image.network(
                              _uploadedImageUrl!.startsWith('http')
                                  ? _uploadedImageUrl!
                                  : ApiConfig.devBaseUrl.replaceAll(
                                          '/api',
                                          '',
                                        ) +
                                        _uploadedImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildImagePlaceholder(),
                            ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFFF6B35,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 28,
                            color: Color(0xFFFF6B35),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '添加食材照片',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF868E96),
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 20),

          // 图标选择
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '选择图标',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF868E96),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _showIconPicker,
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE9ECEF),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            Text(
                              _selectedIcon,
                              style: const TextStyle(fontSize: 28),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                '点击更换',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF868E96),
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: Color(0xFF868E96),
                            ),
                            const SizedBox(width: 12),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.add_photo_alternate_outlined,
            size: 28,
            color: Color(0xFFFF6B35),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '添加食材照片',
          style: TextStyle(fontSize: 14, color: Color(0xFF868E96)),
        ),
      ],
    );
  }

  /// 构建基本信息卡片
  Widget _buildBasicInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 名称
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE9ECEF)),
            ),
            child: TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: '输入食材名称',
                hintStyle: TextStyle(color: Color(0xFFADB5BD)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2D3436),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入食材名称';
                }
                return null;
              },
            ),
          ),

          const SizedBox(height: 16),

          // 数量和单位
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE9ECEF)),
                  ),
                  child: TextFormField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      hintText: '数量',
                      hintStyle: TextStyle(color: Color(0xFFADB5BD)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2D3436),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE9ECEF)),
                  ),
                  child: DropdownButtonFormField<String>(
                    initialValue: _commonUnits.contains(_unitController.text)
                        ? _unitController.text
                        : '个',
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Color(0xFF868E96),
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2D3436),
                    ),
                    items: _commonUnits
                        .map(
                          (unit) =>
                              DropdownMenuItem(value: unit, child: Text(unit)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _unitController.text = value;
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建分类卡片
  Widget _buildCategoryCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 存储位置
          const Text(
            '存储位置',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF868E96),
            ),
          ),
          const SizedBox(height: 12),
          _isLoadingStorages 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35)))
          : Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE9ECEF)),
              ),
              child: DropdownButtonFormField<String>(
                value: _storages.any((s) => s.id == _selectedStorage) ? _selectedStorage : (_storages.isNotEmpty ? _storages.first.id : null),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                ),
                icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF868E96)),
                isExpanded: true,
                items: _storages.map((loc) {
                  return DropdownMenuItem<String>(
                    value: loc.id,
                    child: Text(
                      loc.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2D3436),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedStorage = value);
                  }
                },
              ),
            ),

          const SizedBox(height: 20),

          // 食材分类
          const Text(
            '食材分类',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF868E96),
            ),
          ),
          const SizedBox(height: 12),
          _isLoadingCategories
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((cat) {
                    final isSelected = cat.id == _selectedCategoryId;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedCategoryId = cat.id);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _parseColor(cat.color).withValues(alpha: 0.15)
                              : const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? _parseColor(cat.color)
                                : const Color(0xFFE9ECEF),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              cat.icon,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              cat.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isSelected
                                    ? _parseColor(cat.color)
                                    : const Color(0xFF495057),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }
  
  IconData _getIconForStorage(String id, String name) {
    if (id.contains('fridge') || name.contains('冷藏')) return Icons.kitchen_outlined;
    if (id.contains('freezer') || name.contains('冷冻')) return Icons.ac_unit;
    if (id.contains('room') || name.contains('常温')) return Icons.home_outlined;
    return Icons.inventory_2_outlined;
  }

  Widget _buildStorageButton(String value, String label, IconData icon) {
    final isSelected = _selectedStorage == value;
    // 使用 IntrinsicWidth 使得按钮宽度自适应，或者固定宽度
    return GestureDetector(
      onTap: () {
        setState(() => _selectedStorage = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF6B35).withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected 
              ? Border.all(color: const Color(0xFFFF6B35).withValues(alpha: 0.5))
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? const Color(0xFFFF6B35)
                  : const Color(0xFF868E96),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFFFF6B35)
                    : const Color(0xFF868E96),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建保质期卡片
  Widget _buildShelfLifeCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 购买日期
          const Text(
            '购买日期',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF868E96),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _selectPurchaseDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE9ECEF)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 20,
                    color: Color(0xFF868E96),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _formatDate(_purchaseDate),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2D3436),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: Color(0xFF868E96)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 保质期
          const Text(
            '保质期',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF868E96),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _showShelfLifePicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE9ECEF)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time_outlined,
                    size: 20,
                    color: Color(0xFFFF6B35),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$_shelfLifeDays 天',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF6B35),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: Color(0xFF868E96)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 过期日期预览
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _getExpiryStatusColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getExpiryStatusColor().withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _expiryDate.isBefore(DateTime.now())
                      ? Icons.warning_amber_outlined
                      : Icons.event_available_outlined,
                  size: 20,
                  color: _getExpiryStatusColor(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '过期日期: ${_formatDate(_expiryDate)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _getExpiryStatusColor(),
                        ),
                      ),
                      Text(
                        _getExpiryStatusText(),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getExpiryStatusColor().withValues(alpha: 0.8),
                        ),
                      ),
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

  /// 构建备注卡片
  Widget _buildNoteCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '备注',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF868E96),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE9ECEF)),
            ),
            child: TextFormField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '添加备注信息...',
                hintStyle: TextStyle(color: Color(0xFFADB5BD)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              style: const TextStyle(fontSize: 16, color: Color(0xFF2D3436)),
            ),
          ),
        ],
      ),
    );
  }
}