import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nested/nested.dart';
import 'package:provider/provider.dart';

import '../../../../core/di/plugin_registry.dart';
import '../../../../shared/utils/health_check.dart';
import 'pages/glucose_record_page.dart';
import 'pages/foot_care_page.dart';
import 'pages/medication_page.dart';
import 'pages/diet_page.dart';
import 'pages/diabetes_dashboard.dart';
import 'providers/blood_sugar_provider.dart';
import 'providers/medication_provider.dart';
import 'providers/diet_provider.dart';

/// 糖尿病护理插件（增强版）
///
/// 新增：
/// - 首页看板（今日血糖 + 用药进度 + 快捷入口）
/// - 分餐血糖记录（空腹/早餐后/午餐后/晚餐后/睡前多线对比）
/// - 用药提醒（药物列表 + 时段打卡 + 进度反馈）
/// - 饮食管理（碳水计数 + GI值参考 + 每周趋势）
class DiabetesPlugin extends DiseasePlugin {
  // ── 元数据 ──
  @override
  String get id => 'diabetes';

  @override
  String get name => '糖尿病护理';

  @override
  IconData get icon => Icons.bloodtype;

  @override
  Color get color => const Color(0xFFFF9800);

  // ── 路由 ──
  @override
  List<RouteBase> get routes => [
        GoRoute(
          path: '/diabetes',
          builder: (context, state) => const DiabetesDashboard(),
        ),
        GoRoute(
          path: '/diabetes/record',
          builder: (context, state) => const GlucoseRecordPage(),
        ),
        GoRoute(
          path: '/diabetes/footcare',
          builder: (context, state) => const FootCarePage(),
        ),
        GoRoute(
          path: '/diabetes/medication',
          builder: (context, state) => const MedicationPage(),
        ),
        GoRoute(
          path: '/diabetes/diet',
          builder: (context, state) => const DietPage(),
        ),
      ];

  // ── Provider 注入 ──
  @override
  List<SingleChildWidget> providers() => [
        ChangeNotifierProvider<BloodSugarProvider>(
          create: (_) => BloodSugarProvider(),
        ),
        ChangeNotifierProvider<MedicationProvider>(
          create: (_) => MedicationProvider(),
        ),
        ChangeNotifierProvider<DietProvider>(
          create: (_) => DietProvider(),
        ),
      ];

  // ── 首页卡片 ──
  @override
  Widget homeCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/diabetes'),
      child: Card(
        color: const Color(0xFFFFF3E0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bloodtype, size: 40, color: color),
              const SizedBox(height: 8),
              Text(
                '糖尿病护理',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '血糖 · 足部 · 用药 · 饮食',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => context.go('/diabetes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('进入'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── SOP ──
  @override
  List<SopStep> get sopSteps => const [
        SopStep(stepNumber: 1, title: '温水洗脚',
            description: '37℃温水，浸泡不超过10分钟', icon: Icons.water_drop),
        SopStep(stepNumber: 2, title: '擦干趾缝',
            description: '用柔软毛巾轻擦，注意趾缝', icon: Icons.water_drop_outlined),
        SopStep(stepNumber: 3, title: '检查红肿',
            description: '查看有无红肿、破损、水泡', icon: Icons.search),
        SopStep(stepNumber: 4, title: '涂润肤霜',
            description: '适量涂抹，保持湿润不过量', icon: Icons.spa),
      ];

  // ── 健康评估 ──
  @override
  String evaluateHealth(Map<String, double> data) {
    final sugar = data['blood_sugar'] ?? 0;
    return HealthCheck.bloodSugar(sugar);
  }
}
