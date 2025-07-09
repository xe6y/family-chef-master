/**
 * @description: 开发模式
 */
export const devMode = "development";

/**
 * @description: 生产模式
 */
export const prodMode = "production";

/**
 * @description: 获取环境模式
 * @returns:
 * @example:
 */
export function getEnvMode(): string {
  return getEnvValue("VITE_ENV");
}

/**
 * @description: 获取环境变量
 * @returns:
 * @example:
 */
export function getEnvValue<T = string>(key: keyof ImportMetaEnv): T {
  const envValue = import.meta.env[key];
  return (envValue === "true"
    ? true
    : envValue === "false"
    ? false
    : envValue) as unknown as T;
}

/**
 * @description: 获取环境VITE_BASE_URL值
 * @returns:
 * @example:
 */
export function getBaseUrl(): string {
  return getEnvValue<string>("VITE_BASE_URL");
}
