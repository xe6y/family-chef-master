/// 导航辅助类
/// 用于在深层页面中触发主页面的 tab 切换
class NavigationHelper {
  /// 单例实例
  static final NavigationHelper _instance = NavigationHelper._internal();

  /// 工厂构造函数
  factory NavigationHelper() => _instance;

  /// 私有构造函数
  NavigationHelper._internal();

  /// tab 切换回调
  Function(int)? _onSwitchTab;

  /// 设置 tab 切换回调
  void setOnSwitchTab(Function(int) callback) {
    _onSwitchTab = callback;
  }

  /// 切换到指定的 tab
  void switchToTab(int index) {
    _onSwitchTab?.call(index);
  }
}
