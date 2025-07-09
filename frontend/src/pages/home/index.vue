<template>
  <view class="order-page">
    <!-- 顶部导航栏 -->
    <view class="header">
      <view class="family-info">
        <text class="family-name">{{ familyInfo.name }}</text>
        <text class="member-count">{{ familyInfo.memberCount }}人</text>
      </view>
      <view class="user-role">
        <!-- 添加一个二维码邀请链接 -->
        <u-qrcode :text="userStore.userInfo.inviteCode" :size="100" />
        <u-tag :text="userRole" type="primary" size="mini" />
      </view>
    </view>

    <view class="section">
      <view class="section-header">
        <view class="title-group">
          <text class="section-title">今日菜单</text>
          <text class="menu-count">({{ menus.length }}道菜)</text>
        </view>
      </view>

      <view v-if="menus.length === 0" class="empty-menu">
        <u-icon name="list" size="48" color="#ddd" />
        <text> 今天吃点什么呢~</text>
      </view>

      <view v-else class="menu-list">
        <view class="menu-item" v-for="menu in menus" :key="menu.id">
          <view class="menu-image">
            <image :src="menu.image" mode="aspectFill" />
          </view>
          <view class="menu-content">
            <view class="menu-info">
              <text class="menu-name">{{ menu.name }}</text>
              <view class="menu-details">
                <text class="cook-time">预计 30分钟</text>
                <text class="difficulty">难度: 简单</text>
              </view>
              <view class="menu-status">
                <u-tag
                  v-if="menu.insufficient"
                  text="食材不足"
                  type="error"
                  size="mini"
                />
                <u-tag v-else text="可制作" type="success" size="mini" />
              </view>
            </view>
            <view class="menu-actions">
              <u-button type="primary" size="mini" @click="viewRecipe(menu.id)">
                <u-icon name="eye" size="12" color="#fff" />
                <text>查看</text>
              </u-button>
              <!-- 点击已完成把菜品放到最后，同时修改菜品状态，在菜品图片上添加一个勾，不能再点击制作完成按钮 -->
              <u-button type="success" size="mini" @click="makeDone(menu.id)" :disabled="menu.status === '已完成'">
                <u-icon v-if="menu.status === '已完成'" name="checkmark-circle-fill" size="12" color="#fff" />
                <text>制作完成</text>
              </u-button>
              <u-button
                type="error"
                size="mini"
                @click="removeFromMenu(menu.id)"
              >
                <u-icon name="trash" size="12" color="#fff" />
                <text>删除</text>
              </u-button>
            </view>
          </view>
        </view>
      </view>
    </view>

    <!-- 功能导航 -->
    <view class="nav-grid">
      <view class="nav-item" @click="navigateTo('/pages/order/order')">
        <u-icon name="plus-circle-fill" size="24" color="#FF6B6B" />
        <text>我要点菜</text>
      </view>
      <view class="nav-item" @click="navigateTo('/pages/menu/menu')">
        <u-icon name="list-dot" size="24" color="#5685FF" />
        <text>今日菜单</text>
      </view>
      <view class="nav-item" @click="navigateTo('/pages/order/ingredients')">
        <u-icon name="shopping-cart-fill" size="24" color="#45B7D1" />
        <text>食材管理</text>
      </view>
    </view>

    <!-- 快速点菜 -->
    <view class="section">
      <view class="section-header">
        <text class="section-title">快速点菜</text>
      </view>
      <view class="quick-order">
        <view
          class="order-item"
          v-for="item in quickOrderItems"
          :key="item.id"
          @click="quickOrder(item)"
        >
          <u-icon :name="item.icon" size="20" color="#5685FF" />
          <text>{{ item.name }}</text>
        </view>
      </view>
    </view>

    <!-- 家宴回忆 -->
    <view class="section">
      <view class="section-header">
        <text class="section-title">家宴回忆</text>
        <text class="more" @click="navigateTo('/pages/party/party')">更多</text>
      </view>
      <view class="activity-list">
        <view
          class="activity-item"
          v-for="activity in activities"
          :key="activity.id"
        >
          <view class="activity-avatar">
            <image :src="activity.avatar" mode="aspectFill" />
          </view>
          <view class="activity-photos">
            <image
              v-for="photo in activity.photos"
              :key="photo"
              :src="photo"
              mode="aspectFill"
            />
          </view>
          <view class="activity-content">
            <text class="activity-text">{{ activity.theme }}</text>
            <text class="activity-time">{{ activity.time }}</text>
          </view>
        </view>
      </view>
    </view>

  </view>
</template>

<script setup lang="ts">
import { ref, onMounted } from "vue";
import { useUserInfoStore } from "../../store";

// 用户信息
const userStore = useUserInfoStore();

// 家庭信息
const familyInfo = ref({
  name: "温馨之家",
  memberCount: 5,
});

// 用户角色
const userRole = ref("家庭成员");

// 快速点菜选项
const quickOrderItems = ref([
  { id: 1, name: "我想吃", icon: "heart-fill" },
  { id: 2, name: "今天做", icon: "checkmark-circle-fill" },
]);

const menus = ref([
  {
    id: 1,
    name: "红烧肉",
    image: "/static/image/hamburger.jpg",
    insufficient: false,
    status: "未完成",
  },
  {
    id: 2,
    name: "鱼香肉丝",
    image: "/static/image/dumpling.png",
    insufficient: true,
    status: "未完成",
  },
  {
    id: 3,
    name: "宫保鸡丁",
    image: "/static/image/hamburger.jpg",
    insufficient: false,
    status: "未完成",
  },
]);

// 家庭动态
const activities = ref([
  {
    id: 1,
    avatar: "/static/image/avatar1.jpg",
    theme: "庆功宴",
    photos: [
      "/static/image/hamburger.jpg",
      "/static/image/dumpling.png",
      "/static/image/hamburger.jpg",
    ],
    members: ["张妈妈", "李爸爸", "王奶奶"],
    time: "2025-07-09",
  },
  {
    id: 2,
    avatar: "/static/image/avatar2.jpg",
    theme: "庆功宴",
    photos: [
      "/static/image/hamburger.jpg",
      "/static/image/hamburger.jpg",
      "/static/image/dumpling.png",
    ],
    members: ["张妈妈", "李爸爸", "王奶奶"],
    time: "2025-07-04",
  },
  {
    id: 3,
    avatar: "/static/image/avatar3.jpg",
    theme: "庆功宴",
    photos: [
      "/static/image/hamburger.jpg",
      "/static/image/dumpling.png",
      "/static/image/hamburger.jpg",
    ],
    members: ["张妈妈", "李爸爸", "王奶奶"],
    time: "2025-07-02",
  },
]);

// 页面跳转
const navigateTo = (url: string) => {
  uni.navigateTo({ url });
};

// 查看菜品详情
const viewDish = (dish: any) => {
  uni.navigateTo({
    url: `/pages/order/dish-detail?id=${dish.id}`,
  });
};

// 快速点菜
const quickOrder = (item: any) => {
  switch (item.id) {
    case 1:
      uni.navigateTo({ url: "/pages/order/order" });
      break;
    case 2:
      uni.navigateTo({ url: "/pages/order/cook" });
      break;
    case 3:
      uni.navigateTo({ url: "/pages/order/invite" });
      break;
    case 4:
      uni.navigateTo({ url: "/pages/order/ingredients" });
      break;
  }
};

// 创建家宴
const createParty = () => {
  uni.navigateTo({ url: "/pages/order/party-create" });
};

// 随机菜单
const randomMenu = () => {
  uni.navigateTo({ url: "/pages/order/random-menu" });
};

// 添加到菜单
const addToMenu = () => {
  uni.navigateTo({ url: "/pages/menu/menu" });
};

// 从菜单中删除
const removeFromMenu = (id: number) => {
  const index = menus.value.findIndex((menu) => menu.id === id);
  if (index > -1) {
    menus.value.splice(index, 1);
    uni.showToast({
      title: "已从菜单中删除",
      icon: "success",
    });
  }
};

// 查看菜谱
const viewRecipe = (id: number) => {
  uni.navigateTo({
    url: `/pages/order/recipe-detail?id=${id}`,
  });
};

// 把菜品放到最后
const makeDone = (id: number) => {
  const index = menus.value.findIndex((menu) => menu.id === id);
  menus.value.push(menus.value.splice(index, 1)[0]);
  menus.value[index].status = "已完成";
};

// 页面加载
onMounted(() => {
  // 获取家庭信息
  getFamilyInfo();
  // 获取推荐菜品
  getRecommendDishes();
  // 获取家庭动态
  getActivities();
});

// 获取家庭信息
const getFamilyInfo = () => {
  // TODO: 调用API获取家庭信息
};

// 获取推荐菜品
const getRecommendDishes = () => {
  // TODO: 调用API获取推荐菜品
};

// 获取家庭动态
const getActivities = () => {
  // TODO: 调用API获取家庭动态
};
</script>

<style lang="scss" scoped>
.order-page {
  min-height: 100vh;
  background: linear-gradient(180deg, #fff5f7 0%, #fff 50%, #fef7f8 100%);
  padding-bottom: 120rpx;
  position: relative;
}

.order-page::before {
  content: "";
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: radial-gradient(
      circle at 20% 80%,
      rgba(255, 154, 158, 0.1) 0%,
      transparent 50%
    ),
    radial-gradient(
      circle at 80% 20%,
      rgba(254, 207, 239, 0.1) 0%,
      transparent 50%
    ),
    radial-gradient(
      circle at 40% 40%,
      rgba(255, 107, 157, 0.05) 0%,
      transparent 50%
    );
  pointer-events: none;
  z-index: -1;
}

.header {
  background: linear-gradient(135deg, #ff9a9e 0%, #fecfef 50%, #fecfef 100%);
  padding: 40rpx 30rpx;
  display: flex;
  justify-content: space-between;
  align-items: center;
  color: white;
  position: relative;
  overflow: hidden;
}

.header::before {
  content: "";
  position: absolute;
  top: -50%;
  right: -20%;
  width: 200rpx;
  height: 200rpx;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 50%;
  animation: float 6s ease-in-out infinite;
}

.header::after {
  content: "";
  position: absolute;
  bottom: -30%;
  left: -10%;
  width: 150rpx;
  height: 150rpx;
  background: rgba(255, 255, 255, 0.08);
  border-radius: 50%;
  animation: float 8s ease-in-out infinite reverse;
}

@keyframes float {
  0%,
  100% {
    transform: translateY(0px) rotate(0deg);
  }
  50% {
    transform: translateY(-20px) rotate(180deg);
  }
}

.family-info {
  .family-name {
    font-size: 36rpx;
    font-weight: bold;
    display: block;
  }

  .member-count {
    font-size: 24rpx;
    opacity: 0.8;
  }
}

.nav-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 20rpx;
  padding: 30rpx;
  background: linear-gradient(135deg, #fff5f7 0%, #fff 100%);
  margin: 20rpx;
  border-radius: 24rpx;
  box-shadow: 0 8rpx 32rpx rgba(255, 154, 158, 0.15);
  border: 1rpx solid rgba(255, 154, 158, 0.1);
}

.nav-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 30rpx 20rpx;
  border-radius: 20rpx;
  background: linear-gradient(135deg, #fff 0%, #fef7f8 100%);
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  border: 1rpx solid rgba(255, 154, 158, 0.1);
  position: relative;
  overflow: hidden;

  &::before {
    content: "";
    position: absolute;
    top: 0;
    left: -100%;
    width: 100%;
    height: 100%;
    background: linear-gradient(
      90deg,
      transparent,
      rgba(255, 255, 255, 0.4),
      transparent
    );
    transition: left 0.5s;
  }

  &:active {
    background: linear-gradient(135deg, #ffeef0 0%, #fff 100%);
    transform: scale(0.95) translateY(2rpx);
    box-shadow: 0 4rpx 16rpx rgba(255, 154, 158, 0.2);

    &::before {
      left: 100%;
    }
  }

  text {
    margin-top: 16rpx;
    font-size: 24rpx;
    color: #ff6b9d;
    font-weight: 500;
    transition: color 0.3s;
  }

  &:hover text {
    color: #ff4d8d;
  }
}

.section {
  margin: 20rpx;
  background: linear-gradient(135deg, #fff 0%, #fef7f8 100%);
  border-radius: 24rpx;
  padding: 30rpx;
  box-shadow: 0 8rpx 32rpx rgba(255, 154, 158, 0.1);
  border: 1rpx solid rgba(255, 154, 158, 0.08);
  position: relative;
  overflow: hidden;
}

.section::before {
  content: "";
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 4rpx;
  background: linear-gradient(90deg, #ff9a9e, #fecfef, #ff9a9e);
  background-size: 200% 100%;
  animation: shimmer 3s ease-in-out infinite;
}

@keyframes shimmer {
  0%,
  100% {
    background-position: 0% 50%;
  }
  50% {
    background-position: 100% 50%;
  }
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20rpx;
  position: relative;
  z-index: 1;

  .section-title {
    font-size: 32rpx;
    font-weight: bold;
    background: linear-gradient(135deg, #ff6b9d, #ff9a9e);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
    position: relative;

    &::after {
      content: "";
      position: absolute;
      bottom: -8rpx;
      left: 0;
      width: 40rpx;
      height: 4rpx;
      background: linear-gradient(90deg, #ff9a9e, #fecfef);
      border-radius: 2rpx;
    }
  }

  .more {
    font-size: 24rpx;
    color: #ff9a9e;
    font-weight: 500;
    transition: all 0.3s;

    &:active {
      transform: scale(0.95);
      color: #ff6b9d;
    }
  }
}

.recommend-scroll {
  white-space: nowrap;
}

.dish-card {
  display: inline-block;
  width: 240rpx;
  margin-right: 20rpx;
  border-radius: 12rpx;
  overflow: hidden;
  background: white;
  box-shadow: 0 2rpx 8rpx rgba(0, 0, 0, 0.1);

  .dish-image {
    width: 100%;
    height: 160rpx;
  }

  .dish-info {
    padding: 20rpx;

    .dish-name {
      font-size: 28rpx;
      font-weight: bold;
      color: #212529;
      display: block;
    }

    .dish-chef {
      font-size: 24rpx;
      color: #6c757d;
      margin-top: 8rpx;
      display: block;
    }

    .dish-tags {
      margin-top: 12rpx;
      display: flex;
      gap: 8rpx;
    }
  }
}

.quick-order {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 20rpx;
}

.order-item {
  display: flex;
  align-items: center;
  padding: 30rpx;
  background: linear-gradient(135deg, #fff 0%, #fef7f8 100%);
  border-radius: 20rpx;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  border: 1rpx solid rgba(255, 154, 158, 0.1);
  position: relative;
  overflow: hidden;

  &::before {
    content: "";
    position: absolute;
    top: 0;
    left: -100%;
    width: 100%;
    height: 100%;
    background: linear-gradient(
      90deg,
      transparent,
      rgba(255, 154, 158, 0.1),
      transparent
    );
    transition: left 0.5s;
  }

  &:active {
    background: linear-gradient(135deg, #ffeef0 0%, #fff 100%);
    transform: scale(0.98) translateY(2rpx);
    box-shadow: 0 4rpx 16rpx rgba(255, 154, 158, 0.15);

    &::before {
      left: 100%;
    }
  }

  text {
    margin-left: 16rpx;
    font-size: 28rpx;
    color: #ff6b9d;
    font-weight: 500;
    transition: color 0.3s;
  }

  &:hover text {
    color: #ff4d8d;
  }
}

.activity-list {
  .activity-item {
    display: flex;
    align-items: center;
    padding: 24rpx;
    margin-bottom: 16rpx;
    background: linear-gradient(135deg, #fff 0%, #fef7f8 100%);
    border-radius: 20rpx;
    border: 1rpx solid rgba(255, 154, 158, 0.08);
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    position: relative;
    overflow: hidden;

    &::before {
      content: "";
      position: absolute;
      top: 0;
      left: 0;
      width: 6rpx;
      height: 100%;
      background: linear-gradient(180deg, #ff9a9e, #fecfef);
      border-radius: 3rpx;
    }

    &:active {
      transform: scale(0.98) translateY(2rpx);
      box-shadow: 0 4rpx 16rpx rgba(255, 154, 158, 0.15);
    }

    .activity-avatar {
      width: 80rpx;
      height: 80rpx;
      border-radius: 50%;
      overflow: hidden;
      margin-right: 20rpx;
      border: 3rpx solid rgba(255, 154, 158, 0.2);
      box-shadow: 0 4rpx 12rpx rgba(255, 154, 158, 0.2);

      image {
        width: 100%;
        height: 100%;
      }
    }

    .activity-photos {
      display: flex;
      gap: 8rpx;
      margin-right: 20rpx;

      image {
        width: 60rpx;
        height: 60rpx;
        border-radius: 12rpx;
        border: 2rpx solid rgba(255, 154, 158, 0.1);
      }
    }

    .activity-content {
      flex: 1;

      .activity-text {
        font-size: 28rpx;
        color: #ff6b9d;
        font-weight: 600;
        display: block;
        margin-bottom: 8rpx;
      }

      .activity-time {
        font-size: 24rpx;
        color: #ff9a9e;
        opacity: 0.8;
        display: block;
      }
    }
  }
}

.menu-list {
  display: flex;
  flex-direction: column;
  gap: 18rpx;
  padding: 10rpx 0;

  .menu-item {
    display: flex;
    align-items: center;
    background: linear-gradient(135deg, #fff 0%, #fef7f8 100%);
    border-radius: 18rpx;
    overflow: hidden;
    box-shadow: 0 4rpx 16rpx rgba(255, 154, 158, 0.1);
    border: 1rpx solid rgba(255, 154, 158, 0.08);
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    position: relative;
    padding: 18rpx 0;

    .menu-image {
      width: 96rpx;
      height: 96rpx;
      border-radius: 16rpx;
      overflow: hidden;
      margin: 0 24rpx 0 16rpx;
      position: relative;
      flex-shrink: 0;
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .menu-content {
      flex: 1;
      display: flex;
      flex-direction: column;
      justify-content: center;
      min-width: 0;

      .menu-info {
        .menu-name {
          font-size: 30rpx;
          color: #ff6b9d;
          font-weight: bold;
          margin-bottom: 8rpx;
          overflow: hidden;
          text-overflow: ellipsis;
          white-space: nowrap;
        }
        .menu-details {
          display: flex;
          gap: 18rpx;
          margin-bottom: 8rpx;
          .cook-time,
          .difficulty {
            font-size: 22rpx;
            color: #999;
          }
        }
        .menu-status {
          display: flex;
          gap: 10rpx;
        }
      }

      .menu-actions {
        display: flex;
        gap: 12rpx;
        justify-content: flex-end;
        margin-top: 10rpx;
        .u-button {
          padding: 0 18rpx;
          height: 52rpx;
          font-size: 22rpx;
          border-radius: 10rpx;
          display: flex;
          align-items: center;
          gap: 6rpx;
          text {
            font-size: 22rpx;
          }
        }
      }
    }
  }
}

.empty-menu {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 60rpx 0;
  color: #ccc;

  text {
    font-size: 26rpx;
    margin-top: 20rpx;
    color: #999;
  }
}

.bottom-actions {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  background: linear-gradient(135deg, #fff 0%, #fef7f8 100%);
  padding: 24rpx 30rpx;
  display: flex;
  gap: 20rpx;
  box-shadow: 0 -8rpx 32rpx rgba(255, 154, 158, 0.15);
  border-top: 1rpx solid rgba(255, 154, 158, 0.1);
  backdrop-filter: blur(20rpx);
}
</style>
