import { EMAIL, PHONE, IDCARD } from "@/utils/regEx";

/**
 * @description 验证手机号码
 * @param mobile 手机号码
 * @returns 布尔值
 */
export function validateMobile(mobile: string): boolean {
  let regex = /^1[3456789]\d{9}$/;
  return regex.test(mobile);
}

/**
 * 邮箱
 * @param {string} email
 * @returns {Boolean}
 */
export function validEmail(email: string) {
  const reg = EMAIL;
  return reg.test(email);
}

/**
 * 手机
 * @param {string} mobile
 * @returns {Boolean}
 */
export function validMobile(mobile: string) {
  const reg = PHONE;
  if (!reg.test(mobile)) {
    showError("手机号格式不正确");
    return false;
  }
  return true;
}

/**
 * 身份证号
 * @param {string} idcard
 * @returns {Boolean}
 */
export function validIdcard(idcard: string) {
  const reg = IDCARD;
  if (!reg.test(idcard)) {
    showError("证件号格式不正确");
    return false;
  }
  return true;
}

function showError(message: string) {
  uni.showToast({
    title: message,
    icon: "none",
    duration: 2000,
  });
}
