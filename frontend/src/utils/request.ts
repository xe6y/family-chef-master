interface RequestOptions {
  method?: 'GET' | 'POST' | 'PUT' | 'DELETE'
  data?: any
  params?: any
  headers?: Record<string, string>
}

interface ResponseData<T = any> {
  code: number
  message: string
  data: T
}

class Request {
  private baseURL: string
  private timeout: number

  constructor() {
    this.baseURL = 'http://localhost:8080/api' // 开发环境
    this.timeout = 10000
  }

  private getToken(): string | null {
    return uni.getStorageSync('token')
  }

  private setToken(token: string): void {
    uni.setStorageSync('token', token)
  }

  private removeToken(): void {
    uni.removeStorageSync('token')
  }

  private async request<T>(url: string, options: RequestOptions = {}): Promise<ResponseData<T>> {
    const { method = 'GET', data, params, headers = {} } = options

    // 构建完整URL
    let fullURL = this.baseURL + url
    if (params) {
      const queryString = Object.keys(params)
        .map(key => `${encodeURIComponent(key)}=${encodeURIComponent(params[key])}`)
        .join('&')
      fullURL += `?${queryString}`
    }

    // 设置请求头
    const requestHeaders: Record<string, string> = {
      'Content-Type': 'application/json',
      ...headers
    }

    const token = this.getToken()
    if (token) {
      requestHeaders.Authorization = `Bearer ${token}`
    }

    return new Promise((resolve, reject) => {
      uni.request({
        url: fullURL,
        method,
        data,
        header: requestHeaders,
        timeout: this.timeout,
        success: (res: any) => {
          const { statusCode, data: responseData } = res
          
          if (statusCode === 200) {
            const { code, message, data: resultData } = responseData
            
            if (code === 0) {
              resolve(responseData)
            } else if (code === 401) {
              // Token过期，清除本地token
              this.removeToken()
              uni.showToast({
                title: '登录已过期，请重新登录',
                icon: 'none'
              })
              // 跳转到登录页
              uni.reLaunch({
                url: '/pages/login/login'
              })
              reject(new Error(message))
            } else {
              uni.showToast({
                title: message || '请求失败',
                icon: 'none'
              })
              reject(new Error(message))
            }
          } else {
            uni.showToast({
              title: `网络错误: ${statusCode}`,
              icon: 'none'
            })
            reject(new Error(`HTTP ${statusCode}`))
          }
        },
        fail: (err: any) => {
          uni.showToast({
            title: '网络连接失败',
            icon: 'none'
          })
          reject(err)
        }
      })
    })
  }

  get<T = any>(url: string, options?: Omit<RequestOptions, 'method'>): Promise<ResponseData<T>> {
    return this.request<T>(url, { ...options, method: 'GET' })
  }

  post<T = any>(url: string, options?: Omit<RequestOptions, 'method'>): Promise<ResponseData<T>> {
    return this.request<T>(url, { ...options, method: 'POST' })
  }

  put<T = any>(url: string, options?: Omit<RequestOptions, 'method'>): Promise<ResponseData<T>> {
    return this.request<T>(url, { ...options, method: 'PUT' })
  }

  delete<T = any>(url: string, options?: Omit<RequestOptions, 'method'>): Promise<ResponseData<T>> {
    return this.request<T>(url, { ...options, method: 'DELETE' })
  }
}

export const request = new Request() 