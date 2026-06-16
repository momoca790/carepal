import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/di/plugin_registry.dart';
import '../core/services/user_service.dart';
import '../plugins/plugin_diabetes/lib/providers/blood_sugar_provider.dart';
import '../plugins/plugin_diabetes/lib/providers/medication_provider.dart';
import '../plugins/plugin_uremia/lib/providers/uremia_provider.dart';

/// 首页 —— 动态渲染活跃插件卡片
///
/// ## 核心逻辑
///
/// 1. 从 [UserService.diseases] 获取当前用户的疾病 ID 列表
/// 2. 调用 [PluginRegistry.activePlugins] 筛选出活跃插件
/// 3. 顶部展示健康概览横幅（跨插件汇总关键指标）
/// 4. 用 GridView 渲染每个活跃插件的 [homeCard]
///
/// ## 隔离保证
///
/// `PluginRegistry.activePlugins` 在内部使用 `.where()` 过滤，
/// 只有用户拥有的疾病对应的插件才会被选入结果列表。
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final diseases = UserService.diseases;
    final active = PluginRegistry.activePlugins(userDiseases: diseases);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CarePal'),
        centerTitle: false,
        actions: [
          // 退出（切换用户）
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '切换用户',
            onPressed: () async {
              await UserService.logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: active.isEmpty
          ? _buildEmptyState(context)
          : Column(
              children: [
                // ── 健康概览横幅 ──
                _buildHealthBanner(context, diseases),
                // ── 插件卡片网格 ──
                Expanded(
                  child: _buildPluginGrid(context, active),
                ),
              ],
            ),
    );
  }

  /// 无插件时的空状态
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.medical_services_outlined, size: 80,
                color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              '暂未添加疾病模块',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '请退出并重新选择身份',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  /// 健康概览横幅 —— 汇总所有活跃插件的关键指标
  Widget _buildHealthBanner(BuildContext context, List<String> diseases) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFFF6D00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9800).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '健康概览',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${diseases.length} 个模块',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 指标行
          Row(
            children: [
              if (diseases.contains('diabetes')) ...[
                _buildHealthMetric(context, '血糖', _glucoseSummary(context), Colors.white),
                _buildMetricDivider(),
                _buildHealthMetric(context, '用药', _medSummary(context), Colors.white),
              ],
              if (diseases.contains('diabetes') && diseases.contains('uremia'))
                _buildMetricDivider(),
              if (diseases.contains('uremia')) ...[
                _buildHealthMetric(context, '体重', _weightSummary(context), Colors.white),
                _buildMetricDivider(),
                _buildHealthMetric(context, '饮水', _waterSummary(context), Colors.white),
              ],
            ].expand((w) => [w]).toList()
              ..removeWhere((w) => w is SizedBox && (w.width ?? 0) <= 0),
          ),
        ],
      ),
    );
  }

  /// 单个健康指标
  Widget _buildHealthMetric(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(color: color.withOpacity(0.7), fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricDivider() {
    return Container(
      width: 1,
      height: 32,
      color: Colors.white.withOpacity(0.2),
    );
  }

  /// 血糖摘要
  String _glucoseSummary(BuildContext context) {
    try {
      final p = context.watch<BloodSugarProvider>();
      final v = p.latestValue;
      return v != null ? v.toStringAsFixed(1) : '--';
    } catch (_) {
      return '--';
    }
  }

  /// 用药摘要
  String _medSummary(BuildContext context) {
    try {
      final p = context.watch<MedicationProvider>();
      return '${p.takenCount}/${p.totalCount}';
    } catch (_) {
      return '--';
    }
  }

  /// 体重摘要
  String _weightSummary(BuildContext context) {
    try {
      final p = context.watch<UremiaProvider>();
      return '${p.todayWeight.toStringAsFixed(1)}kg';
    } catch (_) {
      return '--';
    }
  }

  /// 饮水摘要
  String _waterSummary(BuildContext context) {
    try {
      final p = context.watch<UremiaProvider>();
      return '${p.todayWaterIntake.toInt()}ml';
    } catch (_) {
      return '--';
    }
  }

  /// 活跃插件卡片网格
  Widget _buildPluginGrid(BuildContext context, List<DiseasePlugin> plugins) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.0,
        ),
        itemCount: plugins.length,
        itemBuilder: (context, index) {
          return plugins[index].homeCard(context);
        },
      ),
    );
  }
}
