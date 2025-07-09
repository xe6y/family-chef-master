import http from '@/utils/http'
import type { 
  Dish, 
  Order, 
  PrivateRecipe, 
  Ingredient, 
  Family, 
  FamilyMember,
  Chef,
  Party,
  ShoppingItem,
  CostRecord,
  Notification
} from '@/types/order'

// 菜品相关API
export const dishApi = {
  // 获取菜品列表
  getDishes: (params?: any) => {
    return http.get<Dish[]>('/api/dishes', { params })
  },

  // 获取菜品详情
  getDishDetail: (id: number) => {
    return http.get<Dish>(`/api/dishes/${id}`)
  },

  // 创建私家菜
  createPrivateDish: (data: Partial<Dish>) => {
    return http.post<Dish>('/api/dishes/private', data)
  },

  // 更新菜品
  updateDish: (id: number, data: Partial<Dish>) => {
    return http.put<Dish>(`/api/dishes/${id}`, data)
  },

  // 删除菜品
  deleteDish: (id: number) => {
    return http.delete(`/api/dishes/${id}`)
  }
}

// 点菜相关API
export const orderApi = {
  // 获取订单列表
  getOrders: (params?: any) => {
    return http.get<Order[]>('/api/orders', { params })
  },

  // 创建订单
  createOrder: (data: Partial<Order>) => {
    return http.post<Order>('/api/orders', data)
  },

  // 更新订单状态
  updateOrderStatus: (id: number, status: string) => {
    return http.put<Order>(`/api/orders/${id}/status`, { status })
  },

  // 评价订单
  rateOrder: (id: number, rating: number, comment?: string) => {
    return http.post(`/api/orders/${id}/rate`, { rating, comment })
  },

  // 取消订单
  cancelOrder: (id: number) => {
    return http.put(`/api/orders/${id}/cancel`)
  }
}

// 菜单相关API
export const menuApi = {
  // 获取今日菜单
  getTodayMenu: () => {
    return http.get<Dish[]>('/api/menu/today')
  },

  // 添加菜品到菜单
  addToMenu: (data: { dishId: number, chefId: number, remark?: string }) => {
    return http.post('/api/menu/add', data)
  },

  // 从菜单移除菜品
  removeFromMenu: (id: number) => {
    return http.delete(`/api/menu/${id}`)
  },

  // 获取私家菜谱
  getPrivateRecipes: () => {
    return http.get<PrivateRecipe[]>('/api/recipes/private')
  },

  // 创建私家菜谱
  createRecipe: (data: Partial<PrivateRecipe>) => {
    return http.post<PrivateRecipe>('/api/recipes/private', data)
  },

  // 更新私家菜谱
  updateRecipe: (id: number, data: Partial<PrivateRecipe>) => {
    return http.put<PrivateRecipe>(`/api/recipes/private/${id}`, data)
  },

  // 删除私家菜谱
  deleteRecipe: (id: number) => {
    return http.delete(`/api/recipes/private/${id}`)
  }
}

// 食材相关API
export const ingredientApi = {
  // 获取食材列表
  getIngredients: (params?: any) => {
    return http.get<Ingredient[]>('/api/ingredients', { params })
  },

  // 添加食材
  addIngredient: (data: Partial<Ingredient>) => {
    return http.post<Ingredient>('/api/ingredients', data)
  },

  // 更新食材
  updateIngredient: (id: number, data: Partial<Ingredient>) => {
    return http.put<Ingredient>(`/api/ingredients/${id}`, data)
  },

  // 删除食材
  deleteIngredient: (id: number) => {
    return http.delete(`/api/ingredients/${id}`)
  },

  // 调整库存
  adjustStock: (id: number, adjustment: number) => {
    return http.put(`/api/ingredients/${id}/stock`, { adjustment })
  },

  // 生成采购清单
  generateShoppingList: () => {
    return http.get<ShoppingItem[]>('/api/ingredients/shopping-list')
  }
}

// 家庭相关API
export const familyApi = {
  // 获取家庭信息
  getFamilyInfo: () => {
    return http.get<Family>('/api/family/info')
  },

  // 创建家庭
  createFamily: (data: { name: string }) => {
    return http.post<Family>('/api/family', data)
  },

  // 加入家庭
  joinFamily: (inviteCode: string) => {
    return http.post('/api/family/join', { inviteCode })
  },

  // 获取家庭成员
  getFamilyMembers: () => {
    return http.get<FamilyMember[]>('/api/family/members')
  },

  // 更新成员角色
  updateMemberRole: (memberId: number, role: string) => {
    return http.put(`/api/family/members/${memberId}/role`, { role })
  },

  // 移除成员
  removeMember: (memberId: number) => {
    return http.delete(`/api/family/members/${memberId}`)
  }
}

// 大厨相关API
export const chefApi = {
  // 获取大厨列表
  getChefs: () => {
    return http.get<Chef[]>('/api/chefs')
  },

  // 获取大厨详情
  getChefDetail: (id: number) => {
    return http.get<Chef>(`/api/chefs/${id}`)
  },

  // 添加拿手菜
  addSpecialtyDish: (chefId: number, dishId: number) => {
    return http.post(`/api/chefs/${chefId}/specialty`, { dishId })
  },

  // 移除拿手菜
  removeSpecialtyDish: (chefId: number, dishId: number) => {
    return http.delete(`/api/chefs/${chefId}/specialty/${dishId}`)
  }
}

// 家宴相关API
export const partyApi = {
  // 获取家宴列表
  getParties: (params?: any) => {
    return http.get<Party[]>('/api/parties', { params })
  },

  // 创建家宴
  createParty: (data: Partial<Party>) => {
    return http.post<Party>('/api/parties', data)
  },

  // 获取家宴详情
  getPartyDetail: (id: number) => {
    return http.get<Party>(`/api/parties/${id}`)
  },

  // 更新家宴
  updateParty: (id: number, data: Partial<Party>) => {
    return http.put<Party>(`/api/parties/${id}`, data)
  },

  // 删除家宴
  deleteParty: (id: number) => {
    return http.delete(`/api/parties/${id}`)
  },

  // 上传家宴照片
  uploadPartyPhoto: (partyId: number, file: File) => {
    const formData = new FormData()
    formData.append('photo', file)
    return http.post(`/api/parties/${partyId}/photos`, formData)
  },

  // 分享家宴
  shareParty: (partyId: number) => {
    return http.post(`/api/parties/${partyId}/share`)
  }
}

// 成本统计API
export const costApi = {
  // 获取成本记录
  getCostRecords: (params?: any) => {
    return http.get<CostRecord[]>('/api/costs', { params })
  },

  // 添加成本记录
  addCostRecord: (data: Partial<CostRecord>) => {
    return http.post<CostRecord>('/api/costs', data)
  },

  // 更新成本记录
  updateCostRecord: (id: number, data: Partial<CostRecord>) => {
    return http.put<CostRecord>(`/api/costs/${id}`, data)
  },

  // 删除成本记录
  deleteCostRecord: (id: number) => {
    return http.delete(`/api/costs/${id}`)
  },

  // 获取成本统计
  getCostStats: (params?: any) => {
    return http.get('/api/costs/stats', { params })
  }
}

// 通知相关API
export const notificationApi = {
  // 获取通知列表
  getNotifications: (params?: any) => {
    return http.get<Notification[]>('/api/notifications', { params })
  },

  // 标记通知为已读
  markAsRead: (id: number) => {
    return http.put(`/api/notifications/${id}/read`)
  },

  // 标记所有通知为已读
  markAllAsRead: () => {
    return http.put('/api/notifications/read-all')
  },

  // 删除通知
  deleteNotification: (id: number) => {
    return http.delete(`/api/notifications/${id}`)
  }
}

// 随机菜单API
export const randomMenuApi = {
  // 生成随机菜单
  generateRandomMenu: (params: {
    peopleCount: number
    mealType: string
    preferences?: string[]
    excludeIngredients?: string[]
  }) => {
    return http.post<Dish[]>('/api/menu/random', params)
  }
}

// 微信相关API
export const wechatApi = {
  // 微信授权登录
  wxLogin: (code: string) => {
    return http.post('/api/auth/wx-login', { code })
  },

  // 获取用户信息
  getUserInfo: () => {
    return http.get('/api/auth/user-info')
  },

  // 更新用户信息
  updateUserInfo: (data: any) => {
    return http.put('/api/auth/user-info', data)
  }
} 