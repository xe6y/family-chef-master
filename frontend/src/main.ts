import { createSSRApp } from "vue";
import App from "./App.vue";
import uviewPlus from "uview-plus";

import pinia from "./store/index";

import * as dayjs from "dayjs";
import "dayjs/locale/zh-cn";
dayjs.locale("zh-cn");

export function createApp() {
  const app = createSSRApp(App);
  app.use(pinia);
  app.use(uviewPlus);

  return {
    app,
  };
}
