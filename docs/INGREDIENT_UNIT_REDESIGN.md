# 食材管理模块：单位统一化设计

## 一、现状与问题

### 1.1 当前数据结构

**菜谱食材（RecipeIngredient）**
- 存储：`recipes` / `my_recipes` / `public_recipes` 表，`ingredients` 字段为 JSONB
- 结构：`{name, amount, available?}` 
- `amount`：**自由文本**，如 `"2个"`, `"300g"`, `"适量"`, `"1勺"`
- 来源：种子数据示例：`"500g"`, `"2个"`, `"适量"`, `"1勺"`

**食材库存（IngredientItem）**
- 存储：`ingredient_items` 表
- 关键字段：`quantity` (float) + `unit` (varchar 自由文本)
- `unit`：用户手填，如 `"个"`, `"克"`, `"斤"`, `"ml"` 等
- 来源：`ingredient_edit_screen.dart` 中 `_unitController` 为文本输入，默认 `"个"`

### 1.2 比对逻辑现状

**recipe_detail_screen.dart** 中的 `_checkIngredientStatus`：
1. 按 `ingredient.name` 调用 `getIngredientBatches(name)`
2. 汇总所有批次的 `quantity` 之和
3. 判断：`totalQuantity > 0` → 充足，否则不足

**问题**：
- 完全**忽略**菜谱所需用量 `amount`
- 菜谱写「需要 500g 鸡胸肉」，库存有 100g，仍显示「充足」
- 单位不统一：「克」vs「g」vs「千克」无法比较
- `"适量"` 无法量化

### 1.3 根本原因

| 维度     | 菜谱食材         | 食材库存           | 结果         |
|----------|------------------|--------------------|--------------|
| 数量     | 混在 amount 文本 | quantity (float)   | 无法解析     |
| 单位     | 混在 amount 文本 | unit 自由文本      | 不统一       |
| 可比较性 | 无结构化         | 有结构化但单位随意 | 无法正确比对 |

---

## 二、设计目标

1. **食材库（主数据）**：独立维护食材种类、常用单位、营养成分、以及**按食材的计量换算**（如「1只鸡腿≈300g」），参考薄荷健康的食物库与热量逻辑。
2. **添加食材时**：从该食材的**常用单位**中选取（如鸡腿可选「只」或「克」），不再使用全局单位列表。
3. **单位换算**：同一食材不同单位可换算到统一基准（如克），用于库存比对与热量计算。
4. **菜谱热量**：基于食材库的每100g（或每基准单位）营养数据，按用量换算后汇总，得到整道菜的热量及三大营养素。

---

## 三、核心设计

### 3.1 单位表（unit）— 全局单位定义

仅定义「单位本身」，不包含与具体食材的换算。

| 字段 | 类型 | 说明 |
|------|------|------|
| id | varchar(20) | 主键，如 `g`, `kg`, `pcs`, `ml`, `tbsp`, `suitable` |
| display_name | varchar(20) | 显示名称，如 `克`, `千克`, `只`, `毫升`, `勺`, `适量` |
| unit_type | varchar(20) | `weight`, `volume`, `count`, `unspecified` |
| sort_order | int | 排序 |

重量/体积单位在「食材-单位」中通过 `factor_to_base` 参与换算；计数类（如「只」「个」）的换算**按食材**在食材库中维护。

### 3.2 食材库（ingredient_master）— 主数据

维护每一种食材的通用信息与营养基准（参考薄荷：以每 100g 为基准）。

| 字段 | 类型 | 说明 |
|------|------|------|
| id | varchar(36) | 主键 |
| name | varchar(100) | 食材名称，如 鸡腿、番茄、鸡蛋 |
| category_id | varchar(36) | 关联食材分类（肉类/蔬菜等），可选 |
| base_unit_id | varchar(20) | 营养数据的基准单位，一般为 `g`（克） |
| calories_per_100 | decimal(8,2) | 每100克/100ml 热量（千卡） |
| protein_per_100 | decimal(8,2) | 每100克 蛋白质（克） |
| fat_per_100 | decimal(8,2) | 每100克 脂肪（克） |
| carb_per_100 | decimal(8,2) | 每100克 碳水化合物（克） |
| sort_order | int | 排序/搜索权重 |

- **热量与营养**：与薄荷一致，以「每 100 基准单位」存储；热量也可用公式校验：`热量 ≈ 蛋白质×4 + 脂肪×9 + 碳水×4`（千卡/克系数）。
- **基准单位**：通常为 `g`，便于与「克」直接对应；若某食材只用体积（如酱油），可用 `ml`。

### 3.3 食材-单位（ingredient_unit）— 常用单位与换算

为每种食材维护「可用单位」及**该食材下**该单位到基准单位的换算（如「1只鸡腿 = 300g」）。

| 字段 | 类型 | 说明 |
|------|------|------|
| ingredient_id | varchar(36) | 食材库 ID |
| unit_id | varchar(20) | 单位 ID |
| factor_to_base | decimal(12,4) | 1 单位 = 多少基准单位。例：鸡腿+「只」→ 300（1只=300g）；鸡腿+「g」→ 1 |
| sort_order | int | 该食材下单位的展示顺序 |

- **添加/编辑库存或菜谱时**：先选食材，单位下拉只展示该食材在 `ingredient_unit` 中配置的单位。
- **换算**：用量（基准单位）= `quantity * factor_to_base`。例如 2只鸡腿 → 600g；再结合 `calories_per_100` 算热量。

示例：

| ingredient_id | unit_id | factor_to_base | 含义 |
|---------------|---------|----------------|------|
| 鸡腿 | g | 1 | 1g = 1g |
| 鸡腿 | kg | 1000 | 1kg = 1000g |
| 鸡腿 | 只 | 300 | 1只 ≈ 300g |
| 鸡蛋 | 个 | 50 | 1个 ≈ 50g |
| 番茄 | 个 | 150 | 1个 ≈ 150g |
| 番茄 | g | 1 | 1g = 1g |

### 3.4 食材库存（ingredient_item）— 用户库存

| 字段 | 类型 | 说明 |
|------|------|------|
| ingredient_id | varchar(36) | 关联食材库，必填 |
| quantity | decimal(10,2) | 数量 |
| unit_id | varchar(20) | 单位，必须属于该食材的 ingredient_unit |
| … |  | 其余字段（存储位置、保质期等）同现有设计 |

- 展示名称：用食材库的 `name`；展示单位：用单位表的 `display_name`。
- 不再使用自由文本的「名称」和「单位」。

### 3.5 菜谱食材（RecipeIngredient）— 菜谱的 ingredients 字段需一并修改

菜谱表（`recipes` / `my_recipes` / `public_recipes`）中的 **ingredients 字段**为 JSONB，存食材数组。需从当前结构改为新结构，否则无法做库存比对与热量计算。

**修改前（当前）**：

```json
"ingredients": [
  { "name": "鸡腿", "amount": "2只", "available": false },
  { "name": "番茄", "amount": "300g" }
]
```

**修改后**：

```json
"ingredients": [
  { "ingredientId": "uuid-鸡腿", "quantity": 2, "unitId": "只" },
  { "ingredientId": "uuid-番茄", "quantity": 300, "unitId": "g" }
]
```

结构定义：

```go
type RecipeIngredient struct {
    IngredientID string   `json:"ingredientId"` // 食材库 ID，必填
    Quantity     *float64 `json:"quantity"`     // 数量（适量时为 nil）
    UnitID       string   `json:"unitId"`       // 单位，须为该食材的常用单位
}
```

- **存储**：上述结构数组仍写入同一列 `ingredients`（JSONB），无需新增列。
- **展示**：用 `ingredientId` 查食材库得 `name`，用 `unitId` 查单位表得 `display_name`，拼成「鸡腿 2只」「番茄 300克」；`unitId == "suitable"` 且 `quantity == nil` 时展示「适量」。

### 3.6 库存与菜谱的比对逻辑

1. **按食材匹配**：菜谱用料 `ingredient_id` 与库存条目的 `ingredient_id` 一致。
2. **统一到基准**：用各自条目的 `quantity * factor_to_base`（从 `ingredient_unit` 取）得到「基准单位数量」。
3. **比较**：菜谱所需基准总量 ≤ 库存基准总量 → 充足；否则不足；无该食材库存 → 未知。
4. **适量**：菜谱侧为「适量」时，仅判断是否有该食材的任意库存。

### 3.7 菜谱热量计算（参考薄荷）

- 对每个菜谱用料：  
  `基准用量 = quantity * factor_to_base`（适量可忽略或按 0 处理）。  
  `该用料热量 = (基准用量 / 100) * calories_per_100`；蛋白质/脂肪/碳水同理。
- **菜谱总热量** = 所有用料热量之和；总蛋白质/脂肪/碳水同理。
- 公式与薄荷一致：**热量（千卡）≈ 蛋白质×4 + 脂肪×9 + 碳水×4**；若只存三大营养素，也可用该式算热量。

### 3.8 新增食材到食材库

若用户添加的食材在库中不存在（如小众或地方食材），需支持**新增到食材库**后再用于库存/菜谱：

- 必填：名称、基准单位（通常 `g`）、每 100 基准单位的热量/蛋白/脂肪/碳水（可先填 0 或估算）。
- 至少配置一个常用单位及换算：如「g → 1」；若常用「只」，则新增一行「只 → 300」等。
- 后续可在管理端或设置中补充/修正营养与换算。

### 3.9 与「薄荷健康」的对应关系

| 薄荷逻辑 | 本设计 |
|----------|--------|
| 食物库：每100g 热量/营养 | 食材库 `calories_per_100`、`protein/fat/carb_per_100`，基准单位一般为 g |
| 多份量：1个苹果≈150g | 食材-单位：该食材 + 单位「个」→ `factor_to_base = 150` |
| 热量 = 单位营养 × 摄入量 | 用料基准量 = quantity × factor_to_base；热量 = (基准量/100) × calories_per_100 |
| 自定义食谱：各食材用量累加 | 菜谱热量 = 各 RecipeIngredient 换算后热量之和 |

---

## 四、实现计划

### 4.1 后端

| 步骤 | 内容 |
|------|------|
| 1 | 新建 `Unit`、`IngredientMaster`、`IngredientUnit` 模型，建表与种子数据 |
| 2 | 食材库存 `IngredientItem`：改为 `ingredient_id` + `quantity` + `unit_id`，去掉 name/unit/amount |
| 3 | 菜谱食材 `RecipeIngredient`：`ingredient_id` + `quantity` + `unit_id` |
| 4 | API：`GET /api/units`；`GET /api/ingredient-master`（搜索/列表）；`GET /api/ingredient-master/:id/units`（某食材的常用单位列表） |
| 5 | 创建/更新库存、菜谱时：校验 `unit_id` 属于该 `ingredient_id` 的 ingredient_unit |
| 6 | 比对逻辑：按 ingredient_id 汇总库存基准量，与菜谱所需基准量比较 |
| 7 | 菜谱详情/汇总 API：返回总热量及三大营养素（按 3.7 计算） |

### 4.2 前端

| 步骤 | 内容 |
|------|------|
| 1 | 食材库模型与 API：搜索/选择食材，获取某食材的常用单位列表 |
| 2 | 添加/编辑库存：先选**食材**（从食材库），再选**单位**（仅该食材常用单位）、填数量 |
| 3 | 菜谱编辑：每行选食材 + 数量 + 单位（单位随食材变化） |
| 4 | 菜谱详情：展示充足/不足/未知；展示整道菜热量及营养（若后端已算则直接展示） |

---

## 五、API 设计

### 5.1 单位与食材库

```
GET /api/units
Response: { list: [{ id, displayName, unitType, sortOrder }] }

GET /api/ingredient-master?q=鸡腿
Response: { list: [{ id, name, categoryId, baseUnitId, caloriesPer100, proteinPer100, fatPer100, carbPer100 }] }

GET /api/ingredient-master/:id/units
Response: { list: [{ unitId, factorToBase, displayName?, sortOrder }] }
```

### 5.2 库存与菜谱

- 创建/更新库存：body 含 `ingredientId`, `quantity`, `unitId`（校验 unitId 属于该 ingredient）。
- 创建/更新菜谱：ingredients 数组项为 `{ ingredientId, quantity?, unitId }`。

### 5.3 菜谱食材检查与热量

```
POST /api/recipes/check-ingredients
Body: { ingredients: [{ ingredientId, quantity?, unitId }] }
Response: { results: [{ ingredientId, name, status, requiredBase, availableBase }] }

GET /api/recipes/:id 或 菜谱汇总
Response: 含 caloriesTotal, proteinTotal, fatTotal, carbTotal（按 3.7 计算）
```

---

## 六、文件变更清单

### 后端

- `models/unit.go`（新建）
- `models/ingredient_master.go`（新建，食材库）
- `models/ingredient_unit.go`（新建，食材-常用单位及换算）
- `models/ingredient.go`（库存：ingredient_id + quantity + unit_id，去掉 name/unit/amount）
- `models/recipe.go`（RecipeIngredient：ingredient_id, quantity, unit_id）
- `handlers/unit.go`、`handlers/ingredient_master.go`（新建）
- `handlers/ingredient.go`（校验单位属于食材、按基准量比对）
- `config/database.go`（迁移与种子：单位、食材库、ingredient_unit）
- `routes/routes.go`（注册 units、ingredient-master 等）

### 前端

- `lib/models/unit.dart`、`lib/models/ingredient_master.dart`（新建）
- `lib/models/ingredient_item.dart`（ingredientId + quantity + unitId）
- `lib/models/recipe.dart`（Ingredient：ingredientId, quantity, unitId）
- `lib/services/unit_service.dart`、`lib/services/ingredient_master_service.dart`（新建）
- `lib/screens/ingredient_edit_screen.dart`（选食材库 → 选该食材常用单位 → 数量）
- `lib/screens/recipe_detail_screen.dart`（食材行选食材+单位+数量；展示热量；比对逻辑用基准量）
