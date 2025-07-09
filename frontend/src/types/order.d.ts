// 菜品类型
export interface Dish {
  id: number
  name: string
  chef: string
  image: string
  tags: string[]
  isSpecialty?: boolean
  category: string
  description?: string
  ingredients?: Ingredient[]
  steps?: string[]
  rating?: number
  cookCount?: number
}

// 食材类型
export interface Ingredient {
  id: number
  name: string
  category: string
  stock: number
  unit: string
  location: string
  expiryDate: string
  price: number
  isExpiring: boolean
}

// 点菜订单类型
export interface Order {
  id: number
  dishId: number
  dishName: string
  chefId: number
  chefName: string
  remark: string
  expectedTime: string
  orderTime: string
  status: OrderStatus
  rating?: number
  comment?: string
}

// 订单状态
export enum OrderStatus {
  PENDING = 'pending',
  COOKING = 'cooking',
  COMPLETED = 'completed',
  CANCELLED = 'cancelled'
}

// 私家菜谱类型
export interface PrivateRecipe {
  id: number
  name: string
  description: string
  image: string
  tags: string[]
  cookCount: number
  lastCookDate: string
  ingredients: RecipeIngredient[]
  steps: string[]
  tutorialUrl?: string
}

// 菜谱食材类型
export interface RecipeIngredient {
  name: string
  amount: string
  unit: string
}

// 家庭信息类型
export interface Family {
  id: number
  name: string
  memberCount: number
  ownerId: number
  inviteCode: string
}

// 家庭成员类型
export interface FamilyMember {
  id: number
  name: string
  avatar: string
  role: MemberRole
  joinDate: string
}

// 成员角色
export enum MemberRole {
  OWNER = 'owner',
  CHEF = 'chef',
  FOODIE = 'foodie',
  DISHWASHER = 'dishwasher',
  MEMBER = 'member'
}

// 大厨信息类型
export interface Chef {
  id: number
  name: string
  specialty: string
  specialtyDishes: number[]
  rating: number
  cookCount: number
}

// 家宴类型
export interface Party {
  id: number
  name: string
  date: string
  host: string
  guests: string[]
  dishes: PartyDish[]
  photos: string[]
  memories: string
  totalCost: number
}

// 家宴菜品类型
export interface PartyDish {
  id: number
  name: string
  chef: string
  rating: number
  comment: string
  photo: string
}

// 采购清单类型
export interface ShoppingItem {
  name: string
  category: string
  suggestedAmount: number
  unit: string
  estimatedPrice: number
  actualAmount?: number
  actualPrice?: number
  purchased: boolean
}

// 成本统计类型
export interface CostRecord {
  id: number
  date: string
  category: string
  amount: number
  description: string
  type: 'income' | 'expense'
}

// 消息通知类型
export interface Notification {
  id: number
  type: NotificationType
  title: string
  content: string
  timestamp: string
  read: boolean
  data?: any
}

// 通知类型
export enum NotificationType {
  ORDER = 'order',
  PARTY = 'party',
  INGREDIENT = 'ingredient',
  SYSTEM = 'system'
} 