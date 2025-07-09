# 家庭点菜功能使用说明

## 功能概述

这是一个基于Vue3 + TypeScript + uni-app开发的家庭点菜系统，支持微信小程序、H5等多端运行。主要功能包括：

### 核心功能

1. **用户注册/登录**
   - 微信授权登录
   - 用户信息管理

2. **家庭管理**
   - 一家之主：创建家庭，邀请成员
   - 家庭成员：通过邀请码加入，等待审批
   - 成员身份管理：主厨、美食家、洗碗工等

3. **菜品管理**
   - 主厨拿手菜功能
   - 私家菜谱创建和管理
   - 菜谱库浏览和收藏

4. **点餐系统**
   - 今日菜单管理
   - 快速点菜
   - 大厨选择
   - 备注和期望时间

5. **食材管理**
   - 食材分类和库存管理
   - 保质期提醒
   - 采购清单生成
   - 成本统计

6. **家宴功能**
   - 家宴创建和记录
   - 照片上传和分享
   - 美好回忆保存

7. **智能推荐**
   - 随机菜单生成
   - 基于剩余食材推荐
   - 个性化推荐

## 页面结构

```
pages/order/
├── index.vue          # 主页面 - 家庭点菜首页
├── order.vue          # 点菜页面 - 我要点菜
├── menu.vue           # 菜单管理 - 今日菜单/私家菜谱/菜谱库
├── ingredients.vue    # 食材管理 - 库存管理/采购清单
├── chef.vue           # 大厨专区 - 拿手菜管理
├── party.vue          # 家宴回忆 - 家宴记录
├── party-create.vue   # 创建家宴
├── recipe-create.vue  # 创建私家菜
├── recipe-detail.vue  # 菜谱详情
├── dish-detail.vue    # 菜品详情
├── shopping-list.vue  # 采购清单
└── random-menu.vue    # 随机菜单
```

## 技术栈

- **前端框架**: Vue 3 + TypeScript
- **UI组件库**: uview-plus
- **状态管理**: Pinia
- **HTTP请求**: uni-app原生请求 + 拦截器
- **日期处理**: dayjs
- **多端支持**: uni-app

## 安装和运行

### 1. 安装依赖

```bash
cd frontend
pnpm install
```

### 2. 运行开发服务器

```bash
# H5版本
pnpm dev:h5

# 微信小程序
pnpm dev:mp-weixin

# App版本
pnpm dev:app
```

### 3. 构建生产版本

```bash
# H5版本
pnpm build:h5

# 微信小程序
pnpm build:mp-weixin
```

## 配置说明

### 1. 环境配置

在 `src/utils/env.ts` 中配置API基础URL：

```typescript
export const getBaseUrl = () => {
  // 开发环境
  if (process.env.NODE_ENV === 'development') {
    return 'http://localhost:8080'
  }
  // 生产环境
  return 'https://your-api-domain.com'
}
```

### 2. 微信小程序配置

在 `manifest.json` 中配置微信小程序相关信息：

```json
{
  "mp-weixin": {
    "appid": "your-wechat-appid",
    "setting": {
      "urlCheck": false
    }
  }
}
```

## API接口

### 基础URL
```
开发环境: http://localhost:8080
生产环境: https://your-api-domain.com
```

### 主要接口

#### 菜品相关
- `GET /api/dishes` - 获取菜品列表
- `GET /api/dishes/:id` - 获取菜品详情
- `POST /api/dishes/private` - 创建私家菜
- `PUT /api/dishes/:id` - 更新菜品
- `DELETE /api/dishes/:id` - 删除菜品

#### 点菜相关
- `GET /api/orders` - 获取订单列表
- `POST /api/orders` - 创建订单
- `PUT /api/orders/:id/status` - 更新订单状态
- `POST /api/orders/:id/rate` - 评价订单

#### 菜单相关
- `GET /api/menu/today` - 获取今日菜单
- `POST /api/menu/add` - 添加菜品到菜单
- `DELETE /api/menu/:id` - 从菜单移除菜品

#### 食材相关
- `GET /api/ingredients` - 获取食材列表
- `POST /api/ingredients` - 添加食材
- `PUT /api/ingredients/:id/stock` - 调整库存
- `GET /api/ingredients/shopping-list` - 生成采购清单

#### 家庭相关
- `GET /api/family/info` - 获取家庭信息
- `POST /api/family` - 创建家庭
- `POST /api/family/join` - 加入家庭
- `GET /api/family/members` - 获取家庭成员

## 使用流程

### 1. 首次使用

1. 用户通过微信授权登录
2. 选择角色：一家之主或家庭成员
3. 一家之主创建家庭，获得邀请码
4. 家庭成员通过邀请码加入家庭

### 2. 日常使用

1. **点菜流程**
   - 进入"我要点菜"页面
   - 搜索或浏览菜品
   - 选择大厨和期望时间
   - 添加备注后提交订单

2. **菜单管理**
   - 查看今日菜单
   - 添加/移除菜品
   - 管理私家菜谱
   - 浏览菜谱库

3. **食材管理**
   - 添加食材信息
   - 调整库存数量
   - 查看保质期提醒
   - 生成采购清单

4. **家宴记录**
   - 创建家宴活动
   - 上传照片
   - 记录美好回忆
   - 分享给家人

## 开发指南

### 1. 添加新页面

1. 在 `pages/order/` 目录下创建新的 `.vue` 文件
2. 在 `pages.json` 中添加页面路由配置
3. 在 `src/types/order.d.ts` 中添加相关类型定义
4. 在 `src/api/order.ts` 中添加相关API接口

### 2. 组件开发规范

```vue
<template>
  <!-- 使用uview-plus组件 -->
  <view class="page-container">
    <u-button type="primary" @click="handleClick">按钮</u-button>
  </view>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import type { Dish } from '@/types/order'
import { dishApi } from '@/api/order'

// 响应式数据
const dishes = ref<Dish[]>([])

// 方法
const handleClick = () => {
  // 处理逻辑
}

// 生命周期
onMounted(() => {
  // 初始化数据
})
</script>

<style lang="scss" scoped>
.page-container {
  min-height: 100vh;
  background-color: #f8f9fa;
}
</style>
```

### 3. API调用规范

```typescript
// 使用封装的API方法
import { dishApi } from '@/api/order'

// 获取数据
const getDishes = async () => {
  try {
    const response = await dishApi.getDishes()
    dishes.value = response.data
  } catch (error) {
    console.error('获取菜品失败:', error)
  }
}

// 提交数据
const createDish = async (data: Partial<Dish>) => {
  try {
    const response = await dishApi.createPrivateDish(data)
    uni.showToast({ title: '创建成功', icon: 'success' })
  } catch (error) {
    uni.showToast({ title: '创建失败', icon: 'error' })
  }
}
```

## 注意事项

1. **权限控制**: 不同角色有不同的操作权限，需要在后端进行验证
2. **数据同步**: 家庭成员之间的数据需要实时同步
3. **图片上传**: 支持本地图片上传到服务器
4. **离线支持**: 考虑网络不稳定情况下的用户体验
5. **性能优化**: 大量数据时的分页加载和虚拟滚动

## 常见问题

### Q: 如何修改主题颜色？
A: 在 `src/uni.scss` 中修改CSS变量，或在组件中直接修改样式。

### Q: 如何添加新的菜品分类？
A: 在 `src/types/order.d.ts` 中扩展相关类型，在页面中添加对应的筛选逻辑。

### Q: 如何自定义组件样式？
A: 使用 `scoped` 样式，或通过CSS变量覆盖uview-plus的默认样式。

### Q: 如何处理网络错误？
A: 在HTTP拦截器中统一处理错误，或在具体API调用中使用try-catch。

## 更新日志

### v1.0.0 (2024-01-20)
- 初始版本发布
- 基础点菜功能
- 食材管理功能
- 家宴记录功能

## 联系方式

如有问题或建议，请联系开发团队。 