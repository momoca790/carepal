import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nested/nested.dart';
import 'package:provider/provider.dart';

import '../../../../core/di/plugin_registry.dart';
import 'pages/uremia_dashboard.dart';
import 'pages/dialysis_record_page.dart';
import 'pages/water_control_page.dart';
import 'pages/diet_page.dart';
import 'pages/fistula_care_page.dart';
import 'providers/uremia_provider.dart';

/// 尿毒症护理插件（完整版）
///
/// 功能：透析管理 / 控水提醒 / 饮食管理 / 瘘管护理
/// 完全独立，与糖尿病插件零耦合。
class UremiaPlugin extends DiseasePlugin {
  // ── 插件标识 ──────────────────────────────────────────────
  @override
  String get id => 'uremia';

  @override
  String get name => '尿毒症护理';

  @override
  IconData get icon => Icons.water_damage;

  @override
  Color get color => const Color(0xFF2196F3);

  // ── 路由注册 ──────────────────────────────────────────────
  @override
  List<RouteBase> get routes => [
        GoRoute(
          path: '/uremia',
          builder: (context, state) => const UremiaDashboard(),
        ),
        GoRoute(
          path: '/uremia/dialysis',
          builder: (context, state) => const DialysisRecordPage(),
        ),
        GoRoute(
          path: '/uremia/water',
          builder: (context, state) => const WaterControlPage(),
        ),
        GoRoute(
          path: '/uremia/diet',
          builder: (context, state) => const DietPage(),
        ),
        GoRoute(
          path: '/uremia/fistula',
          builder: (context, state) => const FistulaCarePage(),
        ),
      ];

  // ── Provider 注册 ─────────────────────────────────────────
  @override
  List<SingleChildWidget> providers() => [
        ChangeNotifierProvider<UremiaProvider>(
          create: (_) => UremiaProvider(),
        ),
      ];

  // ── 首页卡片 ──────────────────────────────────────────────
  @override
  Widget homeCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/uremia'),
      child: Card(
        color: const Color(0xFFE3F2FD),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.water_damage, size: 40, color: color),
              const SizedBox(height: 8),
              Text(
                '尿毒症护理',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '透析管理 · 控水提醒',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => context.go('/uremia'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 36),
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

  // ── SOP 护理步骤 ──────────────────────────────────────────
  @override
  List<SopStep> get sopSteps => const [
        SopStep(
          stepNumber: 1,
          title: '称量体重',
          description: '透析前后各称一次，记录体重变化，超滤量控制在干体重±3%',
          icon: Icons.monitor_weight,
        ),
        SopStep(
          stepNumber: 2,
          title: '控制饮水',
          description: '每日饮水量不超过前日尿量+500ml，含汤、粥等含水食物',
          icon: Icons.water_drop,
        ),
        SopStep(
          stepNumber: 3,
          title: '检查瘘管',
          description: '触摸瘘管有无震颤感，听诊有无杂音，避免压迫、测血压、抽血',
          icon: Icons.hearing,
        ),
        SopStep(
          stepNumber: 4,
          title: '低盐低钾饮食',
          description: '每日盐摄入≤3g，避免橙子、香蕉、土豆等高钾食物',
          icon: Icons.restaurant,
        ),
      ];

  // ── 健康评估 ──────────────────────────────────────────────
  @override
  String evaluateHealth(Map<String, double> data) {
    final urine = data['urine_output'] ?? 0;
    final weight = data['weight_deviation'] ?? 0;
    if (urine < 100 || weight > 3) return '请及时就医';
    if (urine < 400 || weight > 1.5) return '请注意控水';
    return '状态良好';
  }
}
