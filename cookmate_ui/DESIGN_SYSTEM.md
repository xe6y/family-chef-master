# BitePal 设计系统

## 一、设计理念

### 核心定位

**温馨、现代、易用的家庭点餐应用**

### 设计原则

1. **简洁优先** - 减少视觉噪音，突出核心功能
2. **温馨友好** - 营造家庭氛围，传递温暖感
3. **现代高效** - 符合当代用户习惯，提升操作效率
4. **一致性** - 统一的视觉语言，降低学习成本

---

## 二、配色方案

### 2.1 主色调选择

#### 推荐方案 A：温暖橙色系（当前）

- **主色 (Primary)**: `#F97316` (Orange 500)
- **特点**: 温暖、活力、食欲感强
- **适用**: 强调美食、家庭温馨感

#### 推荐方案 B：柔和暖橙系（优化版）

- **主色 (Primary)**: `#FF6B35` (Coral Orange)
- **特点**: 更柔和、现代，减少视觉疲劳
- **适用**: 长时间使用，更舒适

#### 推荐方案 C：自然绿色系（备选）

- **主色 (Primary)**: `#10B981` (Emerald 500)
- **特点**: 健康、自然、清新
- **适用**: 强调健康饮食理念

### 2.2 完整配色系统

#### 浅色模式 (Light Mode)

```dart
// 主色调
Primary: #F97316 (Orange 500)
Primary Container: #FFE5D4 (浅橙背景)
On Primary: #FFFFFF
On Primary Container: #7C2D12 (深橙文字)

// 次要色
Secondary: #14B8A6 (Teal 500) - 用于辅助操作
Secondary Container: #CCFBF1
On Secondary: #FFFFFF
On Secondary Container: #134E4A

// 语义色
Success: #10B981 (Green 500) - 成功状态
Warning: #F59E0B (Amber 500) - 警告状态
Error: #EF4444 (Red 500) - 错误状态
Info: #3B82F6 (Blue 500) - 信息提示

// 中性色
Background: #FAFAFA (浅灰背景)
Surface: #FFFFFF (卡片背景)
Surface Container: #F5F5F5 (容器背景)
Surface Container High: #EEEEEE (高对比容器)

// 文字色
On Background: #1F2937 (主文字)
On Surface: #374151 (次要文字)
On Surface Variant: #6B7280 (辅助文字)
Outline: #D1D5DB (边框/分割线)
```

#### 深色模式 (Dark Mode)

```dart
// 主色调
Primary: #FF8A50 (浅橙，提高对比度)
Primary Container: #7C2D12
On Primary: #1F2937
On Primary Container: #FFE5D4

// 次要色
Secondary: #5EEAD4 (浅青)
Secondary Container: #134E4A
On Secondary: #1F2937
On Secondary Container: #CCFBF1

// 语义色
Success: #34D399
Warning: #FBBF24
Error: #F87171
Info: #60A5FA

// 中性色
Background: #121212 (深灰背景)
Surface: #1E1E1E (卡片背景)
Surface Container: #2A2A2A
Surface Container High: #363636

// 文字色
On Background: #F9FAFB (主文字)
On Surface: #E5E7EB (次要文字)
On Surface Variant: #9CA3AF (辅助文字)
Outline: #4B5563 (边框/分割线)
```

### 2.3 配色使用规范

#### 主色使用场景

- ✅ 主要按钮、重要操作
- ✅ 选中状态、激活状态
- ✅ 品牌标识、Logo
- ✅ 关键信息高亮

#### 次要色使用场景

- ✅ 次要按钮、辅助操作
- ✅ 标签、徽章
- ✅ 链接文字

#### 语义色使用场景

- ✅ 成功：添加成功、完成状态
- ✅ 警告：即将过期、提醒信息
- ✅ 错误：删除操作、错误提示
- ✅ 信息：提示信息、说明文字

---

## 三、字体系统

### 3.1 字体层级

```dart
// 标题层级
Display Large: 57px / 64px (行高) / 700 (粗体)
Display Medium: 45px / 52px / 700
Display Small: 36px / 44px / 700

// 标题层级
Headline Large: 32px / 40px / 700
Headline Medium: 28px / 36px / 700
Headline Small: 24px / 32px / 600

// 正文层级
Title Large: 22px / 28px / 600
Title Medium: 16px / 24px / 600
Title Small: 14px / 20px / 600

// 正文层级
Body Large: 16px / 24px / 400
Body Medium: 14px / 20px / 400
Body Small: 12px / 16px / 400

// 标签层级
Label Large: 14px / 20px / 500
Label Medium: 12px / 16px / 500
Label Small: 11px / 16px / 500
```

### 3.2 字体使用规范

- **标题**: 使用 600-700 字重，突出层级
- **正文**: 使用 400 字重，保证可读性
- **标签**: 使用 500 字重，适度强调
- **行高**: 通常为字体大小的 1.2-1.5 倍

---

## 四、间距系统

### 4.1 基础间距单位

```dart
// 基于 4px 网格系统
spacingXS: 2px   // 极小间距（图标与文字）
spacingS: 4px    // 小间距（紧密元素）
spacingM: 8px    // 中等间距（相关元素）
spacingL: 12px   // 大间距（分组元素）
spacingXL: 16px  // 超大间距（区块间距）
spacingXXL: 24px // 极大间距（页面间距）
spacingXXXL: 32px // 超大间距（大区块间距）
```

### 4.2 间距使用规范

- **卡片内边距**: 16px
- **卡片间距**: 16px
- **页面边距**: 16-24px
- **组件内边距**: 12-16px
- **图标与文字**: 4-8px

---

## 五、圆角系统

```dart
// 圆角规范
radiusXS: 4px   // 小标签、徽章
radiusS: 8px     // 小按钮、输入框
radiusM: 12px    // 卡片、中等按钮
radiusL: 16px    // 大卡片、对话框
radiusXL: 20px   // 超大卡片
radiusFull: 999px // 圆形（头像、FAB）
```

---

## 六、阴影系统

```dart
// 浅色模式阴影
shadowS:
  color: rgba(0, 0, 0, 0.05)
  blur: 4px
  offset: (0, 2px)

shadowM:
  color: rgba(0, 0, 0, 0.08)
  blur: 8px
  offset: (0, 4px)

shadowL:
  color: rgba(0, 0, 0, 0.12)
  blur: 16px
  offset: (0, 8px)

// 深色模式阴影（使用主色半透明）
shadowDark:
  color: rgba(249, 115, 22, 0.2)
  blur: 12px
  offset: (0, 4px)
```

---

## 七、组件设计规范

### 7.1 按钮

#### 主要按钮 (Primary Button)

- 背景: 主色
- 文字: 白色，16px，600 字重
- 高度: 48px
- 圆角: 16px
- 内边距: 16px 水平

#### 次要按钮 (Secondary Button)

- 背景: 透明
- 边框: 1px 主色
- 文字: 主色，16px，600 字重
- 高度: 48px
- 圆角: 16px

#### 文本按钮 (Text Button)

- 背景: 透明
- 文字: 主色，14px，500 字重
- 高度: 40px

### 7.2 卡片

- 背景: 白色（浅色）/ 深灰（深色）
- 圆角: 16px
- 阴影: shadowS
- 内边距: 16px
- 间距: 16px

### 7.3 输入框

- 背景: Surface Container
- 边框: 1px Outline（默认）/ 主色（聚焦）
- 圆角: 16px
- 高度: 52px
- 内边距: 16px 水平

### 7.4 标签/徽章

- 背景: Primary Container（选中）/ Surface Container（未选中）
- 文字: On Primary Container（选中）/ On Surface（未选中）
- 圆角: 20px（胶囊形）
- 内边距: 8px 水平，6px 垂直
- 字体: 12px，500 字重

---

## 八、动画规范

### 8.1 动画时长

```dart
durationXS: 100ms  // 微交互
durationS: 200ms  // 快速反馈
durationM: 300ms  // 标准动画
durationL: 500ms  // 页面过渡
```

### 8.2 动画曲线

- **标准**: `Curves.easeInOut`
- **进入**: `Curves.easeOut`
- **退出**: `Curves.easeIn`
- **弹性**: `Curves.elasticOut`（特殊场景）

---

## 九、设计风格关键词

### 视觉风格

- **现代简约** - 扁平化设计，减少装饰
- **温暖友好** - 暖色调，圆润边角
- **清晰易读** - 高对比度，合理留白
- **一致性** - 统一的组件和交互模式

### 交互风格

- **流畅自然** - 平滑动画，即时反馈
- **直观易用** - 符合用户习惯，降低学习成本
- **高效便捷** - 减少操作步骤，提升效率

---

## 十、实施建议

### 10.1 优先级

1. **高优先级**

   - 统一配色系统（移除硬编码颜色）
   - 统一间距系统
   - 统一字体层级

2. **中优先级**

   - 统一圆角和阴影
   - 优化按钮和卡片样式
   - 完善动画效果

3. **低优先级**
   - 微交互优化
   - 细节打磨

### 10.2 实施步骤

1. 更新 `app_theme.dart` 使用完整配色系统
2. 更新 `app_constants.dart` 统一间距和尺寸
3. 逐步替换硬编码颜色
4. 统一组件样式
5. 优化动画和交互

---

## 十一、参考案例

### 类似应用设计参考

- **下厨房** - 温暖色调，美食图片为主
- **日日煮** - 现代简约，清晰层级
- **Kitchen Stories** - 国际化设计，精致细节

### 设计趋势

- Material Design 3
- iOS Human Interface Guidelines
- 现代移动应用设计最佳实践
