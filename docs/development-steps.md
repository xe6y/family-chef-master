# 家庭厨师微信小程序开发步骤

## 第一阶段：环境准备

### 1.1 开发环境要求
- **Go 1.21+** - 后端开发语言
- **Node.js 18+** - 前端开发环境
- **MySQL 8.0+** - 数据库
- **Redis 6.0+** - 缓存服务
- **微信开发者工具** - 小程序开发工具
- **HBuilderX** - uni-app开发工具（推荐）

### 1.2 安装依赖
```bash
# 后端依赖安装
cd backend
go mod tidy

# 前端依赖安装
cd frontend
npm install
```

### 1.3 配置数据库
1. 创建MySQL数据库
2. 执行 `database/init.sql` 脚本
3. 修改 `backend/configs/config.yaml` 中的数据库配置

## 第二阶段：后端开发

### 2.1 完善中间件模块
创建以下文件：
- `backend/internal/middleware/cors.go` - 跨域处理
- `backend/internal/middleware/logger.go` - 日志中间件
- `backend/internal/middleware/recovery.go` - 错误恢复
- `backend/internal/middleware/auth.go` - JWT认证

### 2.2 创建路由模块
创建 `backend/internal/routes/routes.go`，定义API路由：
```go
// 用户相关路由
POST /api/auth/login - 微信登录
GET /api/user/profile - 获取用户信息
PUT /api/user/profile - 更新用户信息

// 家庭相关路由
POST /api/family/create - 创建家庭
POST /api/family/join - 加入家庭
GET /api/family/info - 获取家庭信息
GET /api/family/members - 获取家庭成员

// 菜谱相关路由
GET /api/recipe/list - 获取菜谱列表
GET /api/recipe/detail/:id - 获取菜谱详情
POST /api/recipe/create - 创建菜谱
PUT /api/recipe/update/:id - 更新菜谱

// 点餐相关路由
POST /api/order/create - 创建订单
GET /api/order/list - 获取订单列表
PUT /api/order/status/:id - 更新订单状态

// 食材相关路由
GET /api/ingredient/list - 获取食材列表
POST /api/ingredient/add - 添加食材
PUT /api/ingredient/update/:id - 更新食材

// 回忆相关路由
GET /api/memory/list - 获取回忆列表
POST /api/memory/create - 创建回忆
GET /api/memory/detail/:id - 获取回忆详情
```

### 2.3 创建处理器模块
创建以下处理器：
- `backend/internal/handlers/auth.go` - 认证相关
- `backend/internal/handlers/user.go` - 用户相关
- `backend/internal/handlers/family.go` - 家庭相关
- `backend/internal/handlers/recipe.go` - 菜谱相关
- `backend/internal/handlers/order.go` - 订单相关
- `backend/internal/handlers/ingredient.go` - 食材相关
- `backend/internal/handlers/memory.go` - 回忆相关

### 2.4 创建服务层
创建以下服务：
- `backend/internal/services/wechat.go` - 微信服务
- `backend/internal/services/jwt.go` - JWT服务
- `backend/internal/services/upload.go` - 文件上传服务
- `backend/internal/services/notification.go` - 消息通知服务

### 2.5 创建工具函数
创建以下工具：
- `backend/pkg/utils/response.go` - 响应工具
- `backend/pkg/utils/validator.go` - 验证工具
- `backend/pkg/utils/helper.go` - 辅助函数

## 第三阶段：前端开发

### 3.1 创建页面组件
按照 `pages.json` 配置创建以下页面：
- `frontend/pages/index/index.vue` - 首页
- `frontend/pages/login/login.vue` - 登录页
- `frontend/pages/family/create.vue` - 创建家庭
- `frontend/pages/family/join.vue` - 加入家庭
- `frontend/pages/recipe/list.vue` - 菜谱列表
- `frontend/pages/recipe/detail.vue` - 菜谱详情
- `frontend/pages/order/create.vue` - 点餐页面
- `frontend/pages/ingredient/list.vue` - 食材管理
- `frontend/pages/memory/list.vue` - 回忆列表

### 3.2 创建公共组件
创建以下组件：
- `frontend/components/RecipeCard.vue` - 菜谱卡片
- `frontend/components/OrderCard.vue` - 订单卡片
- `frontend/components/IngredientItem.vue` - 食材项
- `frontend/components/MemoryCard.vue` - 回忆卡片
- `frontend/components/ChefAvatar.vue` - 厨师头像

### 3.3 创建API服务
创建 `frontend/api/index.js`，封装所有API调用：
```javascript
// 用户相关API
export const login = (code) => request.post('/auth/login', { code })
export const getUserInfo = () => request.get('/user/profile')

// 家庭相关API
export const createFamily = (data) => request.post('/family/create', data)
export const joinFamily = (code) => request.post('/family/join', { code })

// 菜谱相关API
export const getRecipeList = (params) => request.get('/recipe/list', { params })
export const getRecipeDetail = (id) => request.get(`/recipe/detail/${id}`)

// 订单相关API
export const createOrder = (data) => request.post('/order/create', data)
export const getOrderList = (params) => request.get('/order/list', { params })
```

### 3.4 创建状态管理
创建 `frontend/store/index.js`，使用Vuex管理状态：
```javascript
export default new Vuex.Store({
  state: {
    user: null,
    family: null,
    token: null
  },
  mutations: {
    SET_USER(state, user) {
      state.user = user
    },
    SET_FAMILY(state, family) {
      state.family = family
    },
    SET_TOKEN(state, token) {
      state.token = token
    }
  },
  actions: {
    async login({ commit }, code) {
      const res = await login(code)
      commit('SET_USER', res.data.user)
      commit('SET_TOKEN', res.data.token)
    }
  }
})
```

### 3.5 创建工具函数
创建以下工具：
- `frontend/utils/request.js` - HTTP请求封装
- `frontend/utils/storage.js` - 本地存储工具
- `frontend/utils/validate.js` - 验证工具
- `frontend/utils/format.js` - 格式化工具

## 第四阶段：功能实现

### 4.1 用户认证模块
1. 实现微信授权登录
2. 实现JWT token管理
3. 实现用户信息管理

### 4.2 家庭管理模块
1. 实现家庭创建功能
2. 实现邀请码生成和验证
3. 实现成员管理功能
4. 实现角色权限控制

### 4.3 菜谱管理模块
1. 实现菜谱CRUD操作
2. 实现菜谱分类和标签
3. 实现私家菜谱功能
4. 实现菜谱分享功能

### 4.4 点餐系统模块
1. 实现点餐下单功能
2. 实现订单状态管理
3. 实现厨师选择功能
4. 实现订单评价功能

### 4.5 食材管理模块
1. 实现食材CRUD操作
2. 实现库存管理
3. 实现采购清单生成
4. 实现保质期提醒

### 4.6 回忆功能模块
1. 实现回忆创建和编辑
2. 实现照片上传功能
3. 实现回忆分享功能
4. 实现回忆导出功能

## 第五阶段：测试和优化

### 5.1 单元测试
为后端创建单元测试：
```bash
cd backend
go test ./...
```

### 5.2 集成测试
测试API接口功能：
```bash
# 使用Postman或其他工具测试API
```

### 5.3 性能优化
1. 数据库查询优化
2. 缓存策略优化
3. 前端性能优化
4. 图片压缩和CDN

### 5.4 安全加固
1. 输入验证和过滤
2. SQL注入防护
3. XSS攻击防护
4. 敏感信息加密

## 第六阶段：部署上线

### 6.1 后端部署
1. 配置生产环境
2. 部署到服务器
3. 配置域名和SSL
4. 配置监控和日志

### 6.2 前端部署
1. 构建生产版本
2. 上传到微信小程序
3. 配置CDN加速
4. 测试线上功能

### 6.3 数据库部署
1. 配置生产数据库
2. 数据迁移
3. 备份策略
4. 性能监控

## 开发注意事项

1. **代码规范**：遵循Go和Vue.js的代码规范
2. **错误处理**：完善的错误处理和日志记录
3. **用户体验**：注重界面美观和操作流畅
4. **安全性**：重视数据安全和用户隐私
5. **可扩展性**：考虑未来功能扩展的需求

## 开发时间估算

- **第一阶段**：1-2天（环境准备）
- **第二阶段**：5-7天（后端开发）
- **第三阶段**：7-10天（前端开发）
- **第四阶段**：10-15天（功能实现）
- **第五阶段**：3-5天（测试优化）
- **第六阶段**：2-3天（部署上线）

**总计**：28-42天（约1-1.5个月）

## 下一步行动

1. 按照步骤逐步实现各个模块
2. 每完成一个模块进行测试
3. 及时记录开发过程中的问题和解决方案
4. 定期与团队成员沟通进度
5. 保持代码的版本控制和备份 