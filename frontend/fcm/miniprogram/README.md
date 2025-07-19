# Family Chef Master 小程序前端

## 项目概述

这是Family Chef Master小程序的微信小程序前端代码，已经与后端API进行了完整的对接。

## 项目结构

```
miniprogram/
├── config/           # 配置文件
│   └── api.js       # API配置
├── services/         # 服务层
│   ├── user.js      # 用户服务
│   ├── menu.js      # 菜谱服务
│   ├── order.js     # 订单服务
│   ├── family.js    # 家庭服务
│   └── ingredient.js # 食材服务
├── utils/           # 工具类
│   └── request.js   # 请求工具
├── pages/           # 页面
│   ├── login/       # 登录页面
│   ├── order/       # 点餐页面
│   ├── ingredients/ # 食材管理页面
│   └── ...
└── ...
```

## 后端接口对接

### 1. 用户管理
- **登录**: `POST /api/v1/users` - 创建用户
- **获取用户**: `GET /api/v1/users/:id` - 获取用户信息
- **根据OpenID获取用户**: `GET /api/v1/users/openid` - 微信登录
- **更新用户**: `PUT /api/v1/users/:id` - 更新用户信息
- **更新用户基本信息**: `PUT /api/v1/users/:id/profile` - 更新用户基本信息

### 2. 菜谱管理
- **获取公共菜谱**: `GET /api/v1/menus/public` - 获取公共菜谱列表
- **获取家庭菜谱**: `GET /api/v1/menus/family` - 获取家庭菜谱列表
- **搜索菜谱**: `GET /api/v1/menus/search` - 搜索菜谱
- **按分类获取菜谱**: `GET /api/v1/menus/category` - 按分类获取菜谱

### 3. 订单管理
- **创建订单**: `POST /api/v1/orders` - 创建新订单
- **获取订单列表**: `GET /api/v1/orders` - 获取订单列表
- **获取订单详情**: `GET /api/v1/orders/:id` - 获取订单详情
- **更新订单状态**: `PUT /api/v1/orders/:id/status` - 更新订单状态
- **取消订单**: `PUT /api/v1/orders/:id/cancel` - 取消订单
- **完成订单**: `PUT /api/v1/orders/:id/complete` - 完成订单

### 4. 家庭管理
- **创建家庭**: `POST /api/v1/families` - 创建家庭
- **获取家庭信息**: `GET /api/v1/families/:id` - 获取家庭信息
- **获取家庭成员**: `GET /api/v1/families/:id/members` - 获取家庭成员
- **添加家庭成员**: `POST /api/v1/families/:id/members` - 添加家庭成员
- **移除家庭成员**: `DELETE /api/v1/families/:id/members/:memberId` - 移除家庭成员

### 5. 食材管理
- **获取食材列表**: `GET /api/v1/ingredients` - 获取食材列表
- **获取食材详情**: `GET /api/v1/ingredients/:id` - 获取食材详情
- **创建食材**: `POST /api/v1/ingredients` - 创建食材
- **更新食材**: `PUT /api/v1/ingredients/:id` - 更新食材
- **删除食材**: `DELETE /api/v1/ingredients/:id` - 删除食材
- **搜索食材**: `GET /api/v1/ingredients/search` - 搜索食材
- **更新库存**: `PUT /api/v1/ingredients/:id/stock` - 更新库存

## 数据格式

### 用户数据格式
```javascript
{
  id: 1,
  open_id: "wx_openid_123",
  nickname: "用户昵称",
  avatar: "头像URL",
  phone: "手机号",
  family_id: 1,
  family_role: "owner",
  create_time: "2025-01-01T00:00:00Z"
}
```

### 菜谱数据格式
```javascript
{
  id: 1,
  name: "红烧肉",
  description: "经典家常菜",
  image: "图片URL",
  cuisine: "中餐",
  difficulty: 2,
  price: 25.0,
  chef_name: "张三",
  chef_avatar: "厨师头像URL"
}
```

### 订单数据格式
```javascript
{
  id: 1,
  user_id: 1,
  family_id: 1,
  chef_name: "张三",
  expected_time: "12:30",
  remark: "备注信息",
  total_price: 50.0,
  status: 0,
  items: [
    {
      menu_id: 1,
      quantity: 2,
      price: 25.0
    }
  ]
}
```

### 食材数据格式
```javascript
{
  id: 1,
  name: "土豆",
  description: "新鲜土豆",
  image: "图片URL",
  category: "蔬菜",
  stock: 50,
  price: 3.5,
  unit: "斤",
  nutrition: [
    { name: "热量", value: "77千卡" }
  ],
  storage: "存储建议",
  usage: "使用建议"
}
```

## 环境配置

### 开发环境
- API地址: `http://localhost:8080/api/v1`
- 上传地址: `http://localhost:8080/api/v1/upload`

### 生产环境
- API地址: `https://your-production-domain.com/api/v1`
- 上传地址: `https://your-production-domain.com/api/v1/upload`

## 功能特性

### 1. 用户认证
- 微信登录集成
- Token管理
- 自动登录状态检查

### 2. 点餐功能
- 菜谱浏览和搜索
- 购物车管理
- 订单提交
- 实时价格计算

### 3. 食材管理
- 食材CRUD操作
- 库存管理
- 营养成分管理
- 分类筛选

### 4. 错误处理
- 网络错误处理
- 接口错误处理
- 用户友好的错误提示

### 5. 数据缓存
- 本地数据缓存
- 离线数据支持
- 数据同步机制

## 开发说明

### 1. 启动项目
1. 确保后端服务已启动（默认端口8080）
2. 在微信开发者工具中导入项目
3. 配置小程序AppID
4. 开始开发

### 2. 接口调试
- 使用微信开发者工具的网络面板查看请求
- 检查后端服务是否正常运行
- 验证API地址配置是否正确

### 3. 数据模拟
- 当后端接口不可用时，前端会使用模拟数据
- 模拟数据在对应的页面JS文件中定义
- 可以通过修改模拟数据来测试不同场景

### 4. 错误处理
- 所有API请求都有完整的错误处理
- 网络错误会显示友好的提示信息
- 401错误会自动跳转到登录页面

## 注意事项

1. **跨域问题**: 开发环境需要配置后端CORS
2. **HTTPS要求**: 生产环境必须使用HTTPS
3. **文件上传**: 图片上传需要后端支持文件上传接口
4. **数据格式**: 确保前后端数据格式一致
5. **错误码**: 统一使用后端定义的错误码

## 更新日志

### v1.0.0 (2025-01-01)
- 完成基础功能开发
- 实现前后端完整对接
- 支持用户、菜谱、订单、食材管理
- 添加错误处理和离线支持 