import http from "@/utils/http/index";

// 示例接口
export const myInfoApi = () => {
  return http<any>({
    method: "GET",
    url: `/api/app/info`,
  });
};
