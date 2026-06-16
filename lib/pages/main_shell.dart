import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/di/plugin_registry.dart';
import '../core/services/user_service.dart';

/// 主界面外壳 —— 含动态底部导航栏
///
/// 配合 GoRouter 的 [StatefulShellRoute.indexedStack] 使用，
/// 所有主页面（首页 / 插件 / 个人中心）共用此壳，
/// 底部导航栏根据用户当前激活的疾病模块动态显示/隐藏 tab。
class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final diseases = UserService.diseases;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _buildBottomNav(context, diseases),
    );
  }

  /// 动态构建底部导航项
  ///
  /// 固定项：首页、AI 护士、个人中心
  /// 动态项：根据 [UserService.diseases] 插入对应插件 tab
  ///
  /// Tab 顺序：首页 → [糖尿病] → [尿毒症] → AI护士 → 我的
  NavigationBar _buildBottomNav(BuildContext context, List<String> diseases) {
    final items = <NavigationDestination>[];
    final branchIndices = <int>[];

    // 首页
    items.add(const NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: '首页',
    ));
    branchIndices.add(0);

    // 糖尿病插件
    if (diseases.contains('diabetes')) {
      final plug = PluginRegistry.get('diabetes');
      items.add(NavigationDestination(
        icon: Icon(plug?.icon ?? Icons.bloodtype),
        selectedIcon: Icon(plug?.icon ?? Icons.bloodtype),
        label: plug?.name ?? '糖尿病',
      ));
      branchIndices.add(1);
    }

    // 尿毒症插件
    if (diseases.contains('uremia')) {
      final plug = PluginRegistry.get('uremia');
      items.add(NavigationDestination(
        icon: Icon(plug?.icon ?? Icons.water_damage),
        selectedIcon: Icon(plug?.icon ?? Icons.water_damage),
        label: plug?.name ?? '尿毒症',
      ));
      branchIndices.add(2);
    }

    // AI 护士（始终显示）
    items.add(const NavigationDestination(
      icon: Icon(Icons.smart_toy_outlined),
      selectedIcon: Icon(Icons.smart_toy_rounded),
      label: 'AI 护士',
    ));
    branchIndices.add(4);

    // 个人中心
    items.add(const NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: '我的',
    ));
    branchIndices.add(3);

    // 计算当前选中索引
    final currentBranch = navigationShell.currentIndex;
    final selectedIndex = _mapBranchToTab(branchIndices, currentBranch);

    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (tabIndex) {
        if (tabIndex < branchIndices.length) {
          navigationShell.goBranch(branchIndices[tabIndex]);
        }
      },
      animationDuration: const Duration(milliseconds: 300),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: items,
    );
  }

  /// 将 StatefulNavigationShell 的 branch index 映射到 tab index
  int _mapBranchToTab(List<int> branchIndices, int branchIndex) {
    final idx = branchIndices.indexOf(branchIndex);
    return idx >= 0 ? idx : 0;
  }
}
