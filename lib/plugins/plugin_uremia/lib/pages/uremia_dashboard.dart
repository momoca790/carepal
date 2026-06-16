import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';


import '../providers/uremia_provider.dart';

/// 尿毒症首页看板
///
/// 体重概况 + 饮水进度 + 透析排班 + 饮食趋势 + 快捷入口
class UremiaDashboard extends StatelessWidget {
  const UremiaDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final color = const Color(0xFF2196F3); // 蓝色系
    final provider = context.watch<UremiaProvider>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('尿毒症护理'),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 体重概况 ──
          _buildWeightCard(context, provider, color),
          const SizedBox(height: 12),

          // ── 饮水进度 ──
          _buildWaterCard(context, provider, color),
          const SizedBox(height: 12),

          // ── 透析排班 ──
          _buildDialysisCard(context, provider, color),
          const SizedBox(height: 12),

          // ── 饮食指标（钾 / 磷） ──
          _buildDietCard(context, provider, color),
          const SizedBox(height: 20),

          // ── 快捷入口 ──
          _buildQuickActions(context, color),
          const SizedBox(height: 20),

          // ── 护理贴士 ──
          _buildTipCard(context, color),
        ],
      ),
    );
  }

  // ── 体重概况卡片 ──
  Widget _buildWeightCard(
      BuildContext context, UremiaProvider p, Color color) {
    final deviation = p.weightDeviation;
    final isOver = deviation > 1.5;
    final statusColor = isOver ? Colors.red : (deviation > 0 ? color : Colors.green);
    final statusIcon = isOver
        ? Icons.warning_rounded
        : (deviation > 0 ? Icons.info_outline : Icons.check_circle);
    final statusText = isOver
        ? '体重偏高，请注意控水'
        : (deviation > 0 ? '略高于干体重' : '体重控制良好');

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.monitor_weight, color: color, size: 22),
                const SizedBox(width: 8),
                const Text('今日体重',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  p.todayWeight.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'kg',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ),
                const Spacer(),
                // 干体重
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('干体重',
                          style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                      Text(
                        '${UremiaProvider.dryWeight.toStringAsFixed(1)} kg',
                        style: TextStyle(
                          color: color,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '偏差 ${deviation > 0 ? "+" : ""}${deviation.toStringAsFixed(1)} kg',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 18),
                  const SizedBox(width: 6),
                  Text(statusText,
                      style: TextStyle(
                          color: statusColor, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 饮水进度卡片 ──
  Widget _buildWaterCard(BuildContext context, UremiaProvider p, Color color) {
    final over = p.waterOverLimit;
    final progressColor = over ? Colors.red : color;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/uremia/water'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 进度环
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: CircularProgressIndicator(
                        value: p.waterProgress.clamp(0.0, 1.0),
                        strokeWidth: 5,
                        backgroundColor: Colors.grey[200],
                        valueColor:
                            AlwaysStoppedAnimation<Color>(progressColor),
                      ),
                    ),
                    Icon(
                      over ? Icons.warning_amber_rounded : Icons.water_drop,
                      color: progressColor,
                      size: 24,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('今日饮水',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      '${p.todayWaterIntake.toInt()} / ${UremiaProvider.dailyWaterLimit.toInt()} ml',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: p.waterProgress.clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor: Colors.grey[200],
                        valueColor:
                            AlwaysStoppedAnimation<Color>(progressColor),
                      ),
                    ),
                    if (over)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('已超标！请停止饮水',
                            style: TextStyle(
                                color: Colors.red,
                                fontSize: 11,
                                fontWeight: FontWeight.w500)),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  // ── 透析排班卡片 ──
  Widget _buildDialysisCard(
      BuildContext context, UremiaProvider p, Color color) {
    final latest = p.latestDialysis;
    final hasData = latest != null;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/uremia/dialysis'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.local_hospital, color: color, size: 20),
                  const SizedBox(width: 8),
                  const Text('透析排班',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const Spacer(),
                  Text('查看详情',
                      style: TextStyle(color: color, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),
              hasData
                  ? Row(
                      children: [
                        // 透前体重
                        Expanded(
                          child: _dialysisMetric(
                            '透前体重',
                            '${latest.preWeight.toStringAsFixed(1)} kg',
                            Colors.orange,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey[200],
                        ),
                        // 透后体重
                        Expanded(
                          child: _dialysisMetric(
                            '透后体重',
                            '${latest.postWeight.toStringAsFixed(1)} kg',
                            Colors.green,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey[200],
                        ),
                        // 超滤量
                        Expanded(
                          child: _dialysisMetric(
                            '超滤量',
                            '${latest.ultrafiltration.toStringAsFixed(1)} kg',
                            color,
                          ),
                        ),
                      ],
                    )
                  : const Text('暂无透析记录',
                      style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 10),
              // 下次透析倒计时
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, color: color, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      _nextDialysisText(),
                      style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialysisMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14, color: color)),
      ],
    );
  }

  /// 计算下次透析文案
  String _nextDialysisText() {
    final now = DateTime.now();
    final weekday = now.weekday; // 1=Mon ... 7=Sun
    // 假设 MWF (周一三五) 排班
    const mwf = {1, 3, 5};
    if (mwf.contains(weekday)) {
      return '今天是透析日，请做好准备';
    }
    // 计算距离下一个透析日还有几天
    int daysUntil = 0;
    for (int i = 1; i <= 7; i++) {
      final d = (weekday + i - 1) % 7 + 1;
      if (mwf.contains(d)) {
        daysUntil = i;
        break;
      }
    }
    return '距离下次透析还有 $daysUntil 天';
  }

  // ── 饮食指标（钾 / 磷） ──
  Widget _buildDietCard(BuildContext context, UremiaProvider p, Color color) {
    final latest = p.recentDiet.isNotEmpty ? p.recentDiet.first : null;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/uremia/diet'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.restaurant_menu, color: color, size: 20),
                  const SizedBox(width: 8),
                  const Text('饮食指标',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const Spacer(),
                  Text('查看详情',
                      style: TextStyle(color: color, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // 血钾
                  Expanded(
                    child: _dietIndicator(
                      '血钾',
                      latest?.potassium,
                      3.5,
                      5.5,
                      'mmol/L',
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 血磷
                  Expanded(
                    child: _dietIndicator(
                      '血磷',
                      latest?.phosphorus,
                      0.8,
                      1.6,
                      'mmol/L',
                      Colors.teal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dietIndicator(
    String label,
    double? value,
    double low,
    double high,
    String unit,
    Color indicatorColor,
  ) {
    final hasValue = value != null;
    final inRange = hasValue && value >= low && value <= high;
    final statusColor = !hasValue
        ? Colors.grey
        : (inRange ? Colors.green : Colors.red);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: indicatorColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 6),
          Text(
            hasValue ? value.toStringAsFixed(1) : '--',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: statusColor,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(unit, style: TextStyle(color: Colors.grey[400], fontSize: 10)),
          const SizedBox(height: 6),
          Text(
            hasValue
                ? (inRange ? '正常' : '异常')
                : '暂无数据',
            style: TextStyle(
              color: statusColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── 快捷入口 ──
  Widget _buildQuickActions(BuildContext context, Color color) {
    final actions = [
      _QuickAction(
          Icons.local_hospital, '透析记录', '/uremia/dialysis', color),
      _QuickAction(Icons.water_drop, '控水管理', '/uremia/water', color),
      _QuickAction(Icons.restaurant, '饮食管理', '/uremia/diet', color),
      _QuickAction(Icons.healing, '瘘管护理', '/uremia/fistula', color),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: actions.map((action) {
        return GestureDetector(
          onTap: () => context.go(action.route),
          child: Container(
            width: (MediaQuery.of(context).size.width - 52) / 2,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(action.icon, color: color, size: 28),
                const SizedBox(height: 6),
                Text(
                  action.label,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── 护理贴士 ──
  Widget _buildTipCard(BuildContext context, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.08), color.withOpacity(0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('护理小贴士',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  '每天检查动静脉瘘管：触摸有无震颤、听诊有无杂音。如震颤减弱或消失，请立即就医。',
                  style: TextStyle(
                      color: Colors.grey[600], fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final String route;
  final Color color;

  const _QuickAction(this.icon, this.label, this.route, this.color);
}
