### uniapp 项目模版，开箱即用

该项目用 uniapp+vue3+vite+ts+uview-plus 等技术栈，通过 `vue-cli` 创建 `uni-app` 项目，可以在 vscode 等编辑器进行运行，也可以将项目导入到 HBuilderX 进行运行；

### 使用方法

1. 下载项目代码后，需要先安装依赖包 ;

   ```
   npm i
   ```

2. 在.env.development 和.env.production 文件中分配配置开发模式与生产模式中的 api 域名；

   ```
   VITE_BASE_URL =''
   ```

3. 运行项目：

- 运行 H5：npm run dev:h5 ，通过浏览器打开运行的网址即可；
- 运行小程序（如微信小程序）：npm run dev:mp-weixin，运行完成后会在项目生成 dist 文件夹，其中有 dev 与 build 文件夹，分别代表开发环境与生成环境的打包的文件，打开微信开发者工具，引入 dev 或 build 文件夹中的 mp-weixin 文件即可；

### 支持作者

如果这个项目模版 可以帮助到你快速开发, 你也可以请作者吃一包辣条。( 头顶有点凉, 众筹植发!)

![1743233275150](image/README/1743233275150.png)
