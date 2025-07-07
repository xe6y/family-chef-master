// HTTP请求工具类
class Request {
  constructor() {
    this.baseURL = 'http://localhost:8080/api' // 开发环境API地址
    this.timeout = 10000
    this.header = {
      'Content-Type': 'application/json'
    }
  }

  // 设置请求头
  setHeader(key, value) {
    this.header[key] = value
  }

  // 获取token
  getToken() {
    return uni.getStorageSync('token') || ''
  }

  // 请求拦截器
  requestInterceptor(config) {
    // 添加token
    const token = this.getToken()
    if (token) {
      config.header.Authorization = `Bearer ${token}`
    }
    return config
  }

  // 响应拦截器
  responseInterceptor(response) {
    const { statusCode, data } = response
    
    if (statusCode === 200) {
      if (data.code === 0) {
        return data.data
      } else {
        // 业务错误
        uni.showToast({
          title: data.message || '请求失败',
          icon: 'none'
        })
        return Promise.reject(data)
      }
    } else if (statusCode === 401) {
      // 未授权，跳转登录
      uni.removeStorageSync('token')
      uni.removeStorageSync('userInfo')
      uni.reLaunch({
        url: '/pages/login/login'
      })
      return Promise.reject(response)
    } else {
      // 网络错误
      uni.showToast({
        title: '网络错误',
        icon: 'none'
      })
      return Promise.reject(response)
    }
  }

  // 通用请求方法
  request(options) {
    const config = {
      url: this.baseURL + options.url,
      method: options.method || 'GET',
      data: options.data || {},
      header: { ...this.header, ...options.header },
      timeout: this.timeout
    }

    // 请求拦截
    const interceptedConfig = this.requestInterceptor(config)

    return new Promise((resolve, reject) => {
      uni.request({
        ...interceptedConfig,
        success: (response) => {
          try {
            const result = this.responseInterceptor(response)
            resolve(result)
          } catch (error) {
            reject(error)
          }
        },
        fail: (error) => {
          uni.showToast({
            title: '网络请求失败',
            icon: 'none'
          })
          reject(error)
        }
      })
    })
  }

  // GET请求
  get(url, options = {}) {
    return this.request({
      url,
      method: 'GET',
      ...options
    })
  }

  // POST请求
  post(url, data, options = {}) {
    return this.request({
      url,
      method: 'POST',
      data,
      ...options
    })
  }

  // PUT请求
  put(url, data, options = {}) {
    return this.request({
      url,
      method: 'PUT',
      data,
      ...options
    })
  }

  // DELETE请求
  delete(url, options = {}) {
    return this.request({
      url,
      method: 'DELETE',
      ...options
    })
  }

  // 文件上传
  upload(url, filePath, options = {}) {
    const config = {
      url: this.baseURL + url,
      filePath,
      name: 'file',
      header: { ...this.header, ...options.header },
      timeout: this.timeout
    }

    // 添加token
    const token = this.getToken()
    if (token) {
      config.header.Authorization = `Bearer ${token}`
    }

    return new Promise((resolve, reject) => {
      uni.uploadFile({
        ...config,
        success: (response) => {
          try {
            const data = JSON.parse(response.data)
            if (data.code === 0) {
              resolve(data.data)
            } else {
              uni.showToast({
                title: data.message || '上传失败',
                icon: 'none'
              })
              reject(data)
            }
          } catch (error) {
            uni.showToast({
              title: '上传失败',
              icon: 'none'
            })
            reject(error)
          }
        },
        fail: (error) => {
          uni.showToast({
            title: '上传失败',
            icon: 'none'
          })
          reject(error)
        }
      })
    })
  }
}

export default new Request() 