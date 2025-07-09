import { defineConfig } from "vite";
import uni from "@dcloudio/vite-plugin-uni";
import AutoImport from "unplugin-auto-import/vite";
import { ConfigEnv, loadEnv, UserConfig } from "vite";
import TransformPages from "uni-read-pages-vite"; // vite.config.ts

export default defineConfig(({ mode }: ConfigEnv): UserConfig => {
  const root = process.cwd();
  const env = loadEnv(mode, root);
  return {
    // 自定义全局变量
    define: {
      "process.env": {},
      ROUTES: new TransformPages().routes,
    },
    // 开发服务器配置
    server: {
      host: true,
      // open: true,
      port: env.VITE_PORT as any,
      proxy: {
        "/api": {
          target: env.VITE_BASE_URL,
          changeOrigin: true,
          rewrite: (path) => path.replace(/^\/api/, ""),
        },
        "/upload": {
          target: env.VITE_BASE_URL,
          changeOrigin: true,
          rewrite: (path) => path.replace(/^\/upload/, ""),
        },
      },
    },
    build: {
      sourcemap: process.env.NODE_ENV === "development",
      outDir: "dist",
      chunkSizeWarningLimit: 1500,
      rollupOptions: {
        output: {
          entryFileNames: `assets/[name].${new Date().getTime()}.js`,
          chunkFileNames: `assets/[name].${new Date().getTime()}.js`,
          assetFileNames: `assets/[name].${new Date().getTime()}.[ext]`,
          compact: true,
          // manualChunks: {
          //     vue: ['vue', 'vue-router', 'vuex'],
          //     echarts: ['echarts'],
          // },
        },
        external: ["@tencentcloud/tuiroom-engine-wx"],
      },
    },
    base: "./",
    plugins: [
      uni(),
      AutoImport({
        imports: ["vue"],
        dts: "src/auto-import.d.ts",
      }),
    ],
  };
});
