import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nested/nested.dart';

/// 插件注册表 —— 管理所有疾病插件
///
/// ## 隔离原理
///
/// 用户只能看到 `activePlugins` 返回的插件，其路由和 UI 代码也仅对
/// 活跃插件生效。非活跃插件的代码虽然在工程中存在，但 **永远不会被
/// Core 层引用或实例化**，因此不会产生任何运行时副作用，路由器中也
/// 不会暴露未激活插件的路由。
///
/// ## 使用方式
///
/// ```dart
/// void main() {
///   PluginRegistry.init([DiabetesPlugin(), UremiaPlugin()]);
///   runApp(const App());
/// }
///
/// // 首页动态渲染
/// final active = PluginRegistry.activePlugins(userDiseases: ['diabetes']);
/// // -> 只有 diabetes 插件
/// ```
class PluginRegistry {
  PluginRegistry._();

  /// 所有已开发的插件（编译时就存在）
  static final List<DiseasePlugin> _allPlugins = [];

  /// 初始化：注册所有可用插件
  ///
  /// 在 `main.dart` 中调用一次，将插件列表注入
  static void init(List<DiseasePlugin> plugins) {
    _allPlugins.clear();
    _allPlugins.addAll(plugins);
  }

  /// 根据用户疾病列表筛选活跃插件
  ///
  /// [userDiseases] — 用户已添加的疾病 ID 列表（如 `['diabetes']`）
  ///
  /// 返回的列表中，每个插件都恰好在用户的疾病范围内，
  /// 非用户疾病对应的插件**完全不会**被触及。
  static List<DiseasePlugin> activePlugins({
    required List<String> userDiseases,
  }) {
    final List<DiseasePlugin> result = <DiseasePlugin>[];
    for (int i = 0; i < _allPlugins.length; i++) {
      final DiseasePlugin p = _allPlugins[i];
      if (userDiseases.contains(p.id)) {
        result.add(p);
      }
    }
    return result;
  }

  /// 获取所有插件的路由（合并供 go_router 使用）
  ///
  /// Core 层不关心路由细节，只负责汇总。
  /// 使用普通 for 循环避免 Web 编译器 expand 泛型推断 bug。
  static List<RouteBase> allRoutes() {
    final List<RouteBase> result = <RouteBase>[];
    for (int i = 0; i < _allPlugins.length; i++) {
      final DiseasePlugin p = _allPlugins[i];
      final List<RouteBase> routes = p.routes;
      for (int j = 0; j < routes.length; j++) {
        result.add(routes[j]);
      }
    }
    return result;
  }

  /// 收集所有插件的 Provider（供 MultiProvider 使用）
  ///
  /// 每个插件通过 [providers] 暴露自己的 ChangeNotifierProvider，
  /// 此处用 [SingleChildWidget] 保留具体泛型类型
  static List<SingleChildWidget> allProviders() {
    final List<SingleChildWidget> result = <SingleChildWidget>[];
    for (int i = 0; i < _allPlugins.length; i++) {
      final DiseasePlugin p = _allPlugins[i];
      final List<SingleChildWidget> providers = p.providers();
      for (int j = 0; j < providers.length; j++) {
        result.add(providers[j]);
      }
    }
    return result;
  }

  /// 按 ID 查找插件
  static DiseasePlugin? get(String id) {
    for (int i = 0; i < _allPlugins.length; i++) {
      if (_allPlugins[i].id == id) return _allPlugins[i];
    }
    return null;
  }

  /// 获取全部插件（供调试用）
  static List<DiseasePlugin> get all {
    return List<DiseasePlugin>.from(_allPlugins, growable: false);
  }
}

// =============================================================================
// DiseasePlugin 抽象接口
// =============================================================================

/// 疾病插件抽象基类
///
/// Core 层只依赖这个接口，绝不直接 import 具体插件代码。
/// 新疾病只需实现此接口并通过 [PluginRegistry.init] 注册即可。
abstract class DiseasePlugin {
  // ── 元数据 ──
  String get id;
  String get name;
  IconData get icon;
  Color get color;

  // ── 路由注入 ──
  /// 插件内部路由，Core 层只负责合并
  List<RouteBase> get routes;

  // ── Provider 注入 ──
  /// 插件需要的 Provider 列表，使用 [SingleChildWidget] 保留具体类型
  /// 避免类型擦除导致 context.watch<T>() 找不到 Provider
  List<SingleChildWidget> providers() => [];

  // ── 首页卡片 ──
  /// 展示在 HomePage 的入口卡片
  Widget homeCard(BuildContext context);

  // ── 底部导航（可选） ──
  BottomNavigationBarItem? get bottomNavItem => null;

  // ── SOP 步骤 ──
  List<SopStep> get sopSteps;

  // ── 健康评估 ──
  /// 根据健康数据返回评估文本
  String evaluateHealth(Map<String, double> data);
}

// =============================================================================
// 共享数据模型
// =============================================================================

/// SOP 护理步骤
class SopStep {
  final int stepNumber;
  final String title;
  final String description;
  final IconData icon;

  const SopStep({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.icon,
  });
}
