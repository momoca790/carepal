import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/di/plugin_registry.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';

// ── 插件导入（唯一一处直接导入具体插件）──
import 'plugins/plugin_diabetes/lib/plugin_diabetes.dart';
import 'plugins/plugin_uremia/lib/plugin_uremia.dart';

void main() async {
  // 确保 binding 初始化（用于通知服务）
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化本地通知服务
  await NotificationService.init();

  // 注册所有插件
  PluginRegistry.init([
    DiabetesPlugin(),
    UremiaPlugin(),
  ]);

  // 创建路由并注入导航 key 到通知服务（用于点击通知跳转）
  final router = AppRouter.create();
  NotificationService.setNavigatorKey(AppRouter.navigatorKey);

  // 启动应用
  runApp(CarePalApp(router: router));
}

/// CarePal 应用根组件
class CarePalApp extends StatelessWidget {
  final GoRouter router;

  const CarePalApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    // 合并所有插件的 Provider
    final providers = PluginRegistry.allProviders();

    return MultiProvider(
      providers: providers,
      child: MaterialApp.router(
        title: 'CarePal',
        theme: AppTheme.light,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
