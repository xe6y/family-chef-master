import { useUserInfoStore } from "@/store";
import { checkStatus } from "./checkStatus";
import { getBaseUrl } from "../../utils/env";

const baseURL = getBaseUrl();

const timeStamp = Math.ceil(Date.now() / 1000);

// 拦截器配置
const httpInterceptor = {
  // 拦截前触发
  invoke(options: UniApp.RequestOptions) {
    // 1. 非 http 开头需拼接地址
    if (!options.url.startsWith("http")) {
      options.url = baseURL + options.url;
    }
    // 2. 请求超时
    options.timeout = 10000;
    // 3. 添加小程序端请求头标识
    options.header = {
      "source-client": "miniapp",
      ...options.header,
    };

    if (options.url?.indexOf("?") !== -1) {
      options.url += `&n=${timeStamp}`;
    } else {
      options.url += `?n=${timeStamp}`;
    }

    // 4. 添加 token 请求头标识
    const userInfoStore = useUserInfoStore();
    const token = userInfoStore.token;

    if (token) {
      options.header.Authorization = "Bearer " + token;
    }
  },
};

// 拦截 request 请求
uni.addInterceptor("request", httpInterceptor);
// 拦截 uploadFile 文件上传
uni.addInterceptor("uploadFile", httpInterceptor);

/**
 * 请求函数
 * @param  UniApp.RequestOptions
 * @returns Promise
 */
type Data<T> = {
  code: number;
  msg: string;
  data: T;
  extras: string | null;
  timestamp: number;
  succeeded?: boolean;
  [name: string]: any;
};
// 2.2 添加类型，支持泛型
const http = <T>(options: UniApp.RequestOptions) => {
  uni.showLoading({
    title: "加载中",
  });
  // 1. 返回 Promise 对象
  return new Promise<Data<T>>((resolve, reject) => {
    uni.request({
      ...options,
      // 响应成功
      success(res: any) {
        setTimeout(() => {
          uni.hideLoading();
        }, 200);
        // 状态码 2xx
        if (res.statusCode >= 200 && res.statusCode < 300) {
          // 2.1 提取核心数据 res.data
          resolve(res.data as Data<T>);
          if (res.data.code === 401) {
            uni.navigateTo({ url: "/pages/login/index" });
          }
        } else if (res.statusCode === 401) {
          // 401错误  -> 跳转到登录页
          uni.navigateTo({ url: "/pages/login/index" });
          reject(res);
        } else {
          // 其他错误 -> 根据后端错误信息轻提示
          uni.showToast({
            icon: "none",
            title: (res.data as Data<T>).msg || checkStatus(res.statusCode),
          });
          reject(res);
        }
      },
      // 响应失败
      fail(err) {
        uni.showLoading({
          title: "网络开小差了",
        });
        setTimeout(() => {
          uni.hideLoading();
        }, 1000);
        reject(err);
      },
    });
  });
};
// 封装常用请求方法
const httpClient = {
  get<T>(url: string, options?: any) {
    return http<T>({
      url,
      method: 'GET',
      ...options
    })
  },
  
  post<T>(url: string, data?: any, options?: any) {
    return http<T>({
      url,
      method: 'POST',
      data,
      ...options
    })
  },
  
  put<T>(url: string, data?: any, options?: any) {
    return http<T>({
      url,
      method: 'PUT',
      data,
      ...options
    })
  },
  
  delete<T>(url: string, options?: any) {
    return http<T>({
      url,
      method: 'DELETE',
      ...options
    })
  }
}

export default httpClient;
