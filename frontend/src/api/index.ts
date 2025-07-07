import { request } from '@/utils/request'

// 用户相关API
export const login = (code: string) => request.post('/auth/login', { code })
export const getUserInfo = () => request.get('/user/profile')
export const updateUserInfo = (data: any) => request.put('/user/profile', data)

// 家庭相关API
export const createFamily = (data: any) => request.post('/family/create', data)
export const joinFamily = (code: string) => request.post('/family/join', { code })
export const getFamilyInfo = () => request.get('/family/info')
export const getFamilyMembers = () => request.get('/family/members')
export const updateFamilyInfo = (data: any) => request.put('/family/update', data)

// 菜谱相关API
export const getRecipeList = (params?: any) => request.get('/recipe/list', { params })
export const getRecipeDetail = (id: number) => request.get(`/recipe/detail/${id}`)
export const createRecipe = (data: any) => request.post('/recipe/create', data)
export const updateRecipe = (id: number, data: any) => request.put(`/recipe/update/${id}`, data)
export const deleteRecipe = (id: number) => request.delete(`/recipe/delete/${id}`)

// 订单相关API
export const createOrder = (data: any) => request.post('/order/create', data)
export const getOrderList = (params?: any) => request.get('/order/list', { params })
export const getOrderDetail = (id: number) => request.get(`/order/detail/${id}`)
export const updateOrderStatus = (id: number, status: number) => request.put(`/order/status/${id}`, { status })

// 食材相关API
export const getIngredientList = (params?: any) => request.get('/ingredient/list', { params })
export const createIngredient = (data: any) => request.post('/ingredient/add', data)
export const updateIngredient = (id: number, data: any) => request.put(`/ingredient/update/${id}`, data)
export const deleteIngredient = (id: number) => request.delete(`/ingredient/delete/${id}`)

// 回忆相关API
export const getMemoryList = (params?: any) => request.get('/memory/list', { params })
export const createMemory = (data: any) => request.post('/memory/create', data)
export const getMemoryDetail = (id: number) => request.get(`/memory/detail/${id}`)
export const updateMemory = (id: number, data: any) => request.put(`/memory/update/${id}`, data)
export const deleteMemory = (id: number) => request.delete(`/memory/delete/${id}`)

// 评价相关API
export const createReview = (data: any) => request.post('/review/create', data)
export const getReviewList = (params?: any) => request.get('/review/list', { params })

// 文件上传API
export const uploadFile = (file: File) => {
  const formData = new FormData()
  formData.append('file', file)
  return request.post('/upload/file', formData, {
    headers: {
      'Content-Type': 'multipart/form-data'
    }
  })
} 