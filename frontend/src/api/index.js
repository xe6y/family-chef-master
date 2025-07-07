// API接口管理
import request from '@/utils/request'

// 用户相关API
export const login = (code) => request.post('/auth/login', { code })
export const getUserInfo = () => request.get('/user/profile')
export const updateUserInfo = (data) => request.put('/user/profile', data)

// 家庭相关API
export const createFamily = (data) => request.post('/family/create', data)
export const joinFamily = (code) => request.post('/family/join', { code })
export const getFamilyInfo = () => request.get('/family/info')
export const getFamilyMembers = () => request.get('/family/members')
export const updateMemberRole = (memberId, role) => request.put(`/family/members/${memberId}/role`, { role })

// 菜谱相关API
export const getRecipeList = (params) => request.get('/recipe/list', { params })
export const getRecipeDetail = (id) => request.get(`/recipe/detail/${id}`)
export const createRecipe = (data) => request.post('/recipe/create', data)
export const updateRecipe = (id, data) => request.put(`/recipe/update/${id}`, data)
export const deleteRecipe = (id) => request.delete(`/recipe/delete/${id}`)

// 主厨拿手菜API
export const getChefSkills = () => request.get('/chef/skills')
export const addChefSkill = (data) => request.post('/chef/skills', data)
export const updateChefSkill = (id, data) => request.put(`/chef/skills/${id}`, data)

// 订单相关API
export const createOrder = (data) => request.post('/order/create', data)
export const getOrderList = (params) => request.get('/order/list', { params })
export const getOrderDetail = (id) => request.get(`/order/detail/${id}`)
export const updateOrderStatus = (id, status) => request.put(`/order/status/${id}`, { status })

// 食材相关API
export const getIngredientList = (params) => request.get('/ingredient/list', { params })
export const addIngredient = (data) => request.post('/ingredient/add', data)
export const updateIngredient = (id, data) => request.put(`/ingredient/update/${id}`, data)
export const deleteIngredient = (id) => request.delete(`/ingredient/delete/${id}`)

// 采购清单API
export const getPurchaseList = () => request.get('/purchase/list')
export const updatePurchaseItem = (id, data) => request.put(`/purchase/items/${id}`, data)

// 回忆相关API
export const getMemoryList = (params) => request.get('/memory/list', { params })
export const createMemory = (data) => request.post('/memory/create', data)
export const getMemoryDetail = (id) => request.get(`/memory/detail/${id}`)
export const updateMemory = (id, data) => request.put(`/memory/update/${id}`, data)
export const deleteMemory = (id) => request.delete(`/memory/delete/${id}`)

// 评价相关API
export const createReview = (data) => request.post('/review/create', data)
export const getRecipeReviews = (recipeId) => request.get(`/review/recipe/${recipeId}`)

// 文件上传API
export const uploadFile = (file) => request.upload('/upload/file', file) 