import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/blood_sugar_provider.dart';
import '../providers/medication_provider.dart';

/// 糖尿病首页看板
///
/// 血糖概况 + 用药进度 + 快捷入口 + 迷你趋势图
class DiabetesDashboard extends StatelessWidget {
  const DiabetesDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final color = const Color(0xFFFF9800);
    final sugar = context.watch<BloodSugarProvider>();
    final meds = context.watch<MedicationProvider>();
    final latest = sugar.records.isNotEmpty ? sugar.records.first : null;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('糖尿病护理'),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 今日血糖概况 ──
          _buildGlucoseCard(context, latest, color),
          const SizedBox(height: 12),

          // ── 用药进度 ──
          _buildMedicationCard(context, meds, color),
          const SizedBox(height: 12),

          // ── 迷你趋势图 ──
          _buildMiniChart(context, sugar, color),
          const SizedBox(height: 20),

          // ── 快捷入口 ──
          _buildQuickActions(context, color),
          const SizedBox(height: 20),

          // ── 护理知识小贴士 ──
          _buildTipCard(context, color),
        ],
      ),
    );
  }

  /// 今日血糖概况卡片
  Widget _buildGlucoseCard(
    BuildContext context,
    dynamic? latest,
    Color color,
  ) {
    final hasData = latest != null;
    final value = hasData ? (latest.value as double) : 0.0;
    final type = hasData ? (latest.type as String) : '-';

    // 血糖状态
    String status;
    Color statusColor;
    IconData statusIcon;
    if (!hasData) {
      status = '暂无记录';
      statusColor = Colors.grey;
      statusIcon = Icons.info_outline;
    } else if (value > 13) {
      status = '偏高 — 请及时就医';
      statusColor = Colors.red;
      statusIcon = Icons.warning_rounded;
    } else if (value >= 7) {
      status = '偏高 — 请注意饮食';
      statusColor = color;
      statusIcon = Icons.info_outline;
    } else {
      status = '状态良好';
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bloodtype, color: color, size: 22),
                const SizedBox(width: 8),
                const Text('今日血糖',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  hasData ? value.toStringAsFixed(1) : '--',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: hasData ? statusColor : Colors.grey,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'mmol/L',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ),
                const Spacer(),
                // 测量类型标签
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    hasData ? type : '未测量',
                    style: TextStyle(color: color, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // 状态行
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
                  Text(
                    status,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 用药进度卡片
  Widget _buildMedicationCard(
    BuildContext context,
    MedicationProvider meds,
    Color color,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/diabetes/medication'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.medication, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('今日用药',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      '${meds.takenCount} / ${meds.totalCount} 次已完成',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: meds.progress,
                        minHeight: 5,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          meds.allDone ? Colors.green : color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  /// 迷你趋势图（最近 7 天）
  Widget _buildMiniChart(
    BuildContext context,
    BloodSugarProvider provider,
    Color color,
  ) {
    final recent = provider.recent7Days;
    if (recent.isEmpty) return const SizedBox.shrink();

    // 按天聚合取均值（简化版：直接按时间倒序排列）
    final sorted = recent.toList();   // 已经是从最新到最旧
    final reversed = sorted.reversed.toList(); // 从最旧到最新
    final spots = reversed.asMap().entries.map((e) =>
        FlSpot(e.key.toDouble(), (e.value as dynamic).value as double),
    ).toList();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: color, size: 20),
                const SizedBox(width: 6),
                const Text('7天血糖趋势',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const Spacer(),
                GestureDetector(
                  onTap: () => context.go('/diabetes/record'),
                  child: Text('查看详情',
                      style: TextStyle(color: color, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 2,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey[200]!,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 2,
                        getTitlesWidget: (v, _) => Text(
                          '${v.toInt()}',
                          style: TextStyle(fontSize: 9, color: Colors.grey[400]),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 20,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < reversed.length) {
                            final d = (reversed[i] as dynamic).time as DateTime;
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${d.month}/${d.day}',
                                style: TextStyle(fontSize: 9, color: Colors.grey[400]),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: color,
                      barWidth: 2.5,
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withOpacity(0.1),
                      ),
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                          radius: 2.5,
                          color: color,
                          strokeWidth: 1,
                          strokeColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                  // 7.0 警示线
                  extraLinesData: ExtraLinesData(horizontalLines: [
                    HorizontalLine(
                      y: 7.0,
                      color: color.withOpacity(0.4),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        show: true,
                        labelResolver: (_) => '7.0',
                        style: TextStyle(
                          color: color.withOpacity(0.7),
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 快捷入口按钮
  Widget _buildQuickActions(BuildContext context, Color color) {
    final actions = [
      _QuickAction(Icons.edit_note, '记录血糖', '/diabetes/record', color),
      _QuickAction(Icons.spa, '足部护理', '/diabetes/footcare', color),
      _QuickAction(Icons.medication, '用药打卡', '/diabetes/medication', color),
      _QuickAction(Icons.restaurant, '饮食管理', '/diabetes/diet', color),
    ];

    return Row(
      children: actions.map((action) {
        return Expanded(
          child: GestureDetector(
            onTap: () => context.go(action.route),
            child: Container(
              margin: EdgeInsets.only(
                right: action != actions.last ? 10 : 0,
              ),
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
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 护理贴士卡片
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
                const Text(
                  '护理小贴士',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '餐后 2 小时是血糖峰值时段，建议饭后散步 15 分钟帮助控制血糖。',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 快捷入口数据
class _QuickAction {
  final IconData icon;
  final String label;
  final String route;
  final Color color;

  const _QuickAction(this.icon, this.label, this.route, this.color);
}
