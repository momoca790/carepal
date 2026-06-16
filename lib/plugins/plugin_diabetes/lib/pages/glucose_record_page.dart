import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/blood_sugar_provider.dart';
import '../../../../shared/utils/health_check.dart';

/// 血糖记录页面（增强版）
///
/// - 顶部：输入卡片（类型 + 数值 + 保存）
/// - 中部：分餐多线趋势图（空腹/早餐后/午餐后/晚餐后/睡前各一条线）
/// - 底部：历史记录列表
class GlucoseRecordPage extends StatefulWidget {
  const GlucoseRecordPage({super.key});

  @override
  State<GlucoseRecordPage> createState() => _GlucoseRecordPageState();
}

class _GlucoseRecordPageState extends State<GlucoseRecordPage> {
  final _valueCtrl = TextEditingController();
  String _type = '空腹';
  final _types = ['空腹', '早餐后', '午餐后', '晚餐后', '睡前'];

  /// 每条餐线的可见开关
  final Map<String, bool> _lineVisible = {
    '空腹': true,
    '早餐后': true,
    '午餐后': true,
    '晚餐后': true,
    '睡前': true,
  };

  /// 分餐配色方案（橙色系列不同深浅）
  static const _categoryColors = {
    '空腹': Color(0xFFFF9800),   // 主橙
    '早餐后': Color(0xFFE65100), // 深橙
    '午餐后': Color(0xFFFFB74D), // 浅橙
    '晚餐后': Color(0xFFFF7043), // 珊瑚橙
    '睡前': Color(0xFFFFCC80),   // 淡橙
  };

  @override
  void dispose() {
    _valueCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = const Color(0xFFFF9800);
    final records = context.watch<BloodSugarProvider>().records;
    final recent = context.watch<BloodSugarProvider>().recent7Days;

    return Scaffold(
      appBar: AppBar(
        title: const Text('血糖记录'),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 输入卡片
          _buildInputCard(color),
          const SizedBox(height: 20),

          // 分餐多线趋势图
          if (recent.isNotEmpty) ...[
            _buildMultiLineChart(recent, color),
            const SizedBox(height: 20),
          ],

          // 历史记录
          _buildHistory(records, color),
        ],
      ),
    );
  }

  // ────────────────── 输入卡片 ──────────────────
  Widget _buildInputCard(Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('记录血糖',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 12),
            // 测量类型下拉
            DropdownButtonFormField<String>(
              value: _type,
              decoration: InputDecoration(
                labelText: '测量时段',
                prefixIcon: Icon(Icons.access_time, color: color),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              items: _types.map((t) =>
                  DropdownMenuItem(value: t, child: Text(t)),
              ).toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 12),
            // 数值输入
            TextField(
              controller: _valueCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: '血糖值',
                hintText: '例如 5.2',
                prefixIcon: Icon(Icons.bloodtype, color: color),
                suffixText: 'mmol/L',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save, size: 18),
                label: const Text('保存记录'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────── 分餐多线趋势图 ──────────────────
  Widget _buildMultiLineChart(List<dynamic> recent, Color baseColor) {
    // 按日期（天）聚合，每天一条记录
    final groupedByDay = <String, Map<String, double>>{};
    for (final r in recent) {
      final t = r.time as DateTime;
      final dayKey = '${t.month}/${t.day}';
      final rType = r.type as String;
      final rValue = r.value as double;
      groupedByDay.putIfAbsent(dayKey, () => {});
      groupedByDay[dayKey]![rType] = rValue;
    }

    // 按时间排序（最近7天）
    final sortedDays = groupedByDay.keys.toList();
    sortedDays.sort((a, b) {
      final aParts = a.split('/');
      final bParts = b.split('/');
      final aM = int.parse(aParts[0]);
      final aD = int.parse(aParts[1]);
      final bM = int.parse(bParts[0]);
      final bD = int.parse(bParts[1]);
      return aM != bM ? aM.compareTo(bM) : aD.compareTo(bD);
    });
    // 只保留有效天数（最多7天）
    if (sortedDays.length > 7) {
      sortedDays.removeRange(0, sortedDays.length - 7);
    }

    // 构建每条餐线的数据点
    final lineBars = <LineChartBarData>[];
    for (final catType in _types) {
      if (!(_lineVisible[catType] ?? true)) continue;
      final catColor = _categoryColors[catType]!;
      final spots = <FlSpot>[];
      for (int i = 0; i < sortedDays.length; i++) {
        final day = sortedDays[i];
        final data = groupedByDay[day];
        if (data != null && data.containsKey(catType)) {
          spots.add(FlSpot(i.toDouble(), data[catType]!));
        }
      }
      if (spots.isEmpty) continue;

      lineBars.add(LineChartBarData(
        spots: spots,
        isCurved: true,
        color: catColor,
        barWidth: 2,
        belowBarData: BarAreaData(
          show: true,
          color: catColor.withOpacity(0.06),
        ),
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
            radius: 2.5,
            color: catColor,
            strokeWidth: 1,
            strokeColor: Colors.white,
          ),
        ),
      ));
    }

    // 没有任何可见数据
    if (lineBars.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('没有可见数据')),
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart, color: baseColor, size: 20),
                const SizedBox(width: 6),
                Text('分餐血糖趋势',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),

            // 图例切换开关
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _types.map((cat) {
                final catColor = _categoryColors[cat]!;
                final isOn = _lineVisible[cat] ?? true;
                return FilterChip(
                  selected: isOn,
                  showCheckmark: false,
                  label: Text(cat, style: const TextStyle(fontSize: 11)),
                  selectedColor: catColor.withOpacity(0.18),
                  backgroundColor: Colors.grey[100],
                  side: BorderSide(
                    color: isOn ? catColor : Colors.grey[300]!,
                    width: isOn ? 1.5 : 1,
                  ),
                  onSelected: (v) {
                    setState(() => _lineVisible[cat] = v);
                  },
                  avatar: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: catColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // 折线图
            SizedBox(
              height: 240,
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
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < sortedDays.length) {
                            return Text(sortedDays[i],
                                style: TextStyle(
                                    fontSize: 9, color: Colors.grey[500]));
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 2,
                        getTitlesWidget: (v, _) => Text('${v.toInt()}',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[400])),
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: lineBars,
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((s) {
                          final cat = _types.firstWhere(
                            (t) => _categoryColors[t] == s.bar.color,
                            orElse: () => '',
                          );
                          return LineTooltipItem(
                            '$cat: ${s.y.toStringAsFixed(1)}',
                            TextStyle(
                              color: s.bar.color ?? Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  // 参考线
                  extraLinesData: ExtraLinesData(horizontalLines: [
                    HorizontalLine(
                      y: 7.0,
                      color: baseColor.withOpacity(0.5),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        show: true,
                        labelResolver: (_) => '7.0 警戒线',
                        style: TextStyle(
                          color: baseColor.withOpacity(0.8),
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

  // ────────────────── 历史记录 ──────────────────
  Widget _buildHistory(List<dynamic> records, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('历史记录',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Spacer(),
            Text('最近 20 条',
                style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        ...records.take(20).map((r) {
          final v = r.value as double;
          final cat = r.type as String;
          final catColor = _categoryColors[cat] ?? color;
          final status = HealthCheck.bloodSugar(v);
          final statusColor = v > 13
              ? Colors.red
              : v >= 7
                  ? color
                  : v < 3.9
                      ? Colors.blue
                      : Colors.green;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.bloodtype, color: statusColor, size: 20),
              ),
              title: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: catColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 11,
                        color: catColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${v.toStringAsFixed(1)} mmol/L',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              subtitle: Row(
                children: [
                  Text(
                    _formatTime(r.time as DateTime),
                    style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                  ),
                  const Spacer(),
                  Text(
                    status,
                    style: TextStyle(fontSize: 11, color: statusColor),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ────────────────── 工具方法 ──────────────────
  /// 委托给共享 HealthCheck 工具，统一评估逻辑（含低血糖 <3.9）

  String _formatTime(DateTime t) =>
      '${t.year}-${t.month.toString().padLeft(2, '0')}'
      '-${t.day.toString().padLeft(2, '0')} '
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';

  void _save() {
    final v = double.tryParse(_valueCtrl.text);
    if (v == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效数值')),
      );
      return;
    }
    context.read<BloodSugarProvider>().addRecord(v, _type);
    _valueCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$_type 血糖 ${v.toStringAsFixed(1)} mmol/L 已保存'),
        backgroundColor: const Color(0xFFFF9800),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
