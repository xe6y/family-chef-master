# 项目迁移指南

## 概述

本指南将帮助你将在HBuilderX中创建的uni-app项目与我们设计的家庭厨师项目配置进行整合。

## 第一步：复制配置文件

### 1. 复制pages.json
将我们项目中的 `pages.json` 复制到你的HBuilderX项目中，替换原有的配置。

### 2. 复制项目结构
在你的HBuilderX项目中创建以下目录结构：

```
src/
├── api/              # API接口管理
├── components/       # 公共组件
├── pages/           # 页面文件
├── static/          # 静态资源
├── store/           # Vuex状态管理
├── utils/           # 工具函数
├── App.vue          # 应用根组件
└── main.js          # 应用入口
```

## 第二步：复制核心文件

### 1. 复制API文件
将以下文件复制到你的项目中：
- `src/api/index.js` - API接口管理
- `src/utils/request.js` - HTTP请求工具

### 2. 复制状态管理
将以下文件复制到你的项目中：
- `src/store/index.js` - Vuex状态管理

### 3. 复制页面组件
将以下页面复制到你的项目中：
- `src/pages/index/index.vue` - 首页
- `src/pages/login/login.vue` - 登录页

### 4. 复制应用文件
将以下文件复制到你的项目中：
- `src/App.vue` - 应用根组件
- `src/main.js` - 应用入口

## 第三步：安装依赖

在你的HBuilderX项目中安装必要的依赖：

```bash
# 进入项目目录
cd your-project-path

# 安装依赖
npm install vuex@4 dayjs lodash-es
```

## 第四步：配置HBuilderX

### 1. 配置微信小程序
1. 在HBuilderX中打开项目
2. 点击"运行" -> "运行到小程序模拟器" -> "微信开发者工具"
3. 配置微信开发者工具路径
4. 配置小程序的AppID

### 2. 配置manifest.json
确保 `manifest.json` 中包含微信小程序的配置：

```json
{
  "mp-weixin": {
    "appid": "你的小程序AppID",
    "setting": {
      "urlCheck": false,
      "es6": true,
      "enhance": true,
      "postcss": true,
      "preloadBackgroundData": false,
      "minified": true,
      "newFeature": true,
      "coverView": true,
      "nodeModules": false,
      "autoAudits": false,
      "showShadowRootInWxmlPanel": true,
      "scopeDataCheck": false,
      "uglifyFileName": false,
      "checkInvalidKey": true,
      "checkSiteMap": true,
      "uploadWithSourceMap": true,
      "compileHotReLoad": false,
      "lazyloadPlaceholderEnable": false,
      "useMultiFrameRuntime": true,
      "useApiHook": true,
      "useApiHostProcess": true,
      "babelSetting": {
        "ignore": [],
        "disablePlugins": [],
        "outputPath": ""
      },
      "enableEngineNative": false,
      "useIsolateContext": true,
      "userConfirmedBundleSwitch": false,
      "packNpmManually": false,
      "packNpmRelationList": [],
      "minifyWXSS": true,
      "disableUseStrict": false,
      "minifyWXML": true,
      "showES6CompileOption": false,
      "useCompilerPlugins": false
    },
    "usingComponents": true,
    "permission": {
      "scope.userLocation": {
        "desc": "你的位置信息将用于小程序位置接口的效果展示"
      }
    }
  }
}
```

## 第五步：创建静态资源

### 1. 创建图片目录
在 `src/static/images/` 目录下创建以下图片：
- `logo.png` - 应用Logo
- `wechat-icon.png` - 微信图标
- `default-avatar.png` - 默认头像
- `default-recipe.png` - 默认菜谱图片

### 2. 创建TabBar图标
在 `src/static/images/tabbar/` 目录下创建TabBar图标：
- `home.png` 和 `home-active.png` - 首页图标
- `recipe.png` 和 `recipe-active.png` - 菜谱图标
- `order.png` 和 `order-active.png` - 点餐图标
- `memory.png` 和 `memory-active.png` - 回忆图标
- `profile.png` 和 `profile-active.png` - 我的图标

## 第六步：配置开发环境

### 1. 配置后端API地址
在 `src/utils/request.js` 中修改API地址：

```javascript
this.baseURL = 'http://localhost:8080/api' // 开发环境
// 或者
this.baseURL = 'https://your-domain.com/api' // 生产环境
```

### 2. 配置微信小程序AppID
在 `manifest.json` 中配置你的小程序AppID。

## 第七步：测试项目

### 1. 运行项目
在HBuilderX中点击"运行" -> "运行到小程序模拟器" -> "微信开发者工具"

### 2. 检查功能
- 检查页面路由是否正常
- 检查登录功能是否正常
- 检查API请求是否正常

## 第八步：继续开发

### 1. 创建其他页面
按照 `pages.json` 中的配置，继续创建其他页面：
- 家庭管理页面
- 菜谱相关页面
- 点餐相关页面
- 食材管理页面
- 回忆相关页面

### 2. 创建公共组件
创建可复用的组件：
- 菜谱卡片组件
- 订单卡片组件
- 食材项组件
- 回忆卡片组件

### 3. 完善功能
根据需求文档，逐步完善各个功能模块。

## 常见问题

### 1. 页面路由不生效
- 检查 `pages.json` 配置是否正确
- 确保页面文件路径正确
- 重启HBuilderX和微信开发者工具

### 2. API请求失败
- 检查后端服务是否启动
- 检查API地址配置是否正确
- 检查网络连接是否正常

### 3. 样式不生效
- 检查SCSS是否正确编译
- 检查样式文件路径是否正确
- 清除缓存并重新编译

### 4. 微信登录失败
- 检查小程序AppID配置
- 检查微信开发者工具配置
- 检查后端微信服务配置

## 下一步

完成迁移后，你可以：

1. 继续开发其他页面和功能
2. 完善用户体验和界面设计
3. 进行功能测试和优化
4. 准备上线发布

如果在迁移过程中遇到任何问题，请参考HBuilderX官方文档或联系技术支持。 