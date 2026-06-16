import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../di/plugin_registry.dart';
import '../services/user_service.dart';
import '../../pages/home_page.dart';
import '../../pages/login_page.dart';
import '../../pages/profile_page.dart';
import '../../pages/main_shell.dart';
import '../../pages/ai_nurse_page.dart';

/// 全局路由配置
///
/// ## 路由结构
///
/// ```
/// GoRouter
/// ├── /login                      (独立页，无底部导航)
/// └── StatefulShellRoute           (主界面壳，含 BottomNavigationBar)
///     ├── Branch 0: /home          (首页)
///     ├── Branch 1: /diabetes/*    (糖尿病插件)
///     ├── Branch 2: /uremia/*      (尿毒症插件)
///     ├── Branch 3: /profile       (个人中心)
///     └── Branch 4: /ai-nurse      (AI 护士顾问)
/// ```
///
/// 底部导航栏在 [MainShell] 中根据用户疾病动态显示/隐藏 tab。
class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static GoRouter create() {
    final plugins = PluginRegistry.all;

    return GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: '/login',
      redirect: (context, state) {
        final loggedIn = UserService.isLoggedIn;
        final goingToLogin = state.matchedLocation == '/login';

        if (!loggedIn && !goingToLogin) return '/login';
        if (loggedIn && goingToLogin) return '/home';
        return null;
      },
      routes: [
        // ── 登录页（无底部导航）──
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginPage(),
        ),

        // ── 主界面壳（含底部导航栏）──
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              MainShell(navigationShell: navigationShell),
          branches: [
            // Branch 0 — 首页
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomePage(),
              ),
            ]),

            // Branch 1 — 糖尿病插件（始终注册，tab 按需显示）
            StatefulShellBranch(
              routes: _pluginRoutes(plugins, 'diabetes'),
            ),

            // Branch 2 — 尿毒症插件
            StatefulShellBranch(
              routes: _pluginRoutes(plugins, 'uremia'),
            ),

            // Branch 3 — 个人中心
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfilePage(),
              ),
            ]),

            // Branch 4 — AI 护士顾问（占位）
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/ai-nurse',
                builder: (context, state) => const AiNursePage(),
              ),
            ]),
          ],
        ),
      ],
    );
  }

  /// 提取指定插件路由；未找到时给一个占位路由
  static List<RouteBase> _pluginRoutes(
    List<DiseasePlugin> plugins,
    String id,
  ) {
    for (final p in plugins) {
      if (p.id == id) return p.routes;
    }
    return [
      GoRoute(
        path: '/$id',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: Text('$id 插件未找到')),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('插件 "$id" 未注册或已卸载',
                    style: TextStyle(
                        fontSize: 16, color: Colors.grey[600])),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('返回首页'),
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }
}
