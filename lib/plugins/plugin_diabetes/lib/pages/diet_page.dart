import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/diet_provider.dart';

/// 糖尿病饮食管理页面
///
/// - 每日碳水摄入概览（今日总量 + 目标对比）
/// - GI 值食物参考指南（低/中/高 GI）
/// - 每周碳水趋势图
/// - 饮食记录列表 + 添加/删除
class DietPage extends StatefulWidget {
  const DietPage({super.key});

  @override
  State<DietPage> createState() => _DietPageState();
}

class _DietPageState extends State<DietPage> {
  static const _color = Color(0xFFFF9800);

  /// 各餐建议碳水范围（克）
  static const _targetCarbs = {
    '早餐': 45,
    '午餐': 60,
    '晚餐': 60,
    '加餐': 15,
  };

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<DietProvider>().load());
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<DietProvider>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('饮食管理'),
        backgroundColor: _color,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 今日碳水概览 ──
          _buildTodayCard(p),
          const SizedBox(height: 16),

          // ── GI 食物参考指南 ──
          _buildGiGuide(),
          const SizedBox(height: 16),

          // ── 每周趋势 ──
          _buildWeeklyTrend(p),
          const SizedBox(height: 16),

          // ── 历史记录 ──
          const Text('饮食记录',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          if (p.records.isEmpty)
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text('还没有饮食记录\n点击右下角 + 开始记录',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[500])),
                ),
              ),
            )
          else
            ...p.records.map((r) => _buildRecordItem(r, p)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        backgroundColor: _color,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('记录饮食'),
      ),
    );
  }

  // ────────────────── 今日碳水卡 ──────────────────
  Widget _buildTodayCard(DietProvider p) {
    final today = p.todayCarbs;
    final dailyTarget = 180.0; // 一般建议每日 150-200g
    final ratio = (today / dailyTarget).clamp(0.0, 1.2);
    final statusColor = today > dailyTarget * 1.1
        ? Colors.red
        : today > dailyTarget
            ? _color
            : Colors.green;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.restaurant, color: _color, size: 22),
                const SizedBox(width: 8),
                const Text('今日碳水摄入',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            // 环形进度指示
            Center(
              child: SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: CircularProgressIndicator(
                        value: ratio > 1 ? 1 : ratio,
                        strokeWidth: 12,
                        backgroundColor: Colors.grey[200],
                        valueColor:
                            AlwaysStoppedAnimation<Color>(statusColor),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${today.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                        Text(
                          '克碳水',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _mealTypeBadge('早', p, '早餐'),
                const SizedBox(width: 12),
                _mealTypeBadge('午', p, '午餐'),
                const SizedBox(width: 12),
                _mealTypeBadge('晚', p, '晚餐'),
                const SizedBox(width: 12),
                _mealTypeBadge('加', p, '加餐'),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                '每日建议 ${dailyTarget.toInt()}g 碳水',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 分餐碳水小标签
  Widget _mealTypeBadge(String label, DietProvider p, String mealType) {
    final now = DateTime.now();
    final carbs = p.records
        .where((r) =>
            r.date.year == now.year &&
            r.date.month == now.month &&
            r.date.day == now.day &&
            (r.mealType as String) == mealType)
        .fold<double>(0, (sum, r) => sum + (r.carbs as double));
    final target = _targetCarbs[mealType] ?? 40;
    final ok = carbs <= target;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ok ? Colors.green.withOpacity(0.08) : _color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ok ? Colors.green.withOpacity(0.2) : _color.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: ok ? Colors.green : _color,
                  fontSize: 13)),
          Text('${carbs.toStringAsFixed(0)}g',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: ok ? Colors.green : _color)),
        ],
      ),
    );
  }

  // ────────────────── GI 食物指南 ──────────────────
  Widget _buildGiGuide() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.menu_book, color: _color, size: 20),
                const SizedBox(width: 8),
                const Text('GI 值食物参考',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 14),
            // 低 GI
            _giCategory(
              '低 GI (≤55) — 推荐',
              '全麦面包、燕麦、豆类、苹果、梨、牛奶、番茄',
              Colors.green,
              Icons.check_circle,
            ),
            const SizedBox(height: 10),
            // 中 GI
            _giCategory(
              '中 GI (56-69) — 适量',
              '米饭、面条、玉米、菠萝、葡萄、红薯',
              Colors.orange,
              Icons.remove_circle_outline,
            ),
            const SizedBox(height: 10),
            // 高 GI
            _giCategory(
              '高 GI (≥70) — 限制',
              '白面包、糯米、西瓜、荔枝、薯片、含糖饮料',
              Colors.red,
              Icons.warning_amber,
            ),
          ],
        ),
      ),
    );
  }

  Widget _giCategory(String title, String foods, Color catColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: catColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: catColor.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: catColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: catColor)),
                const SizedBox(height: 4),
                Text(foods,
                    style:
                        TextStyle(color: Colors.grey[600], fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────── 每周趋势图 ──────────────────
  Widget _buildWeeklyTrend(DietProvider p) {
    final weekly = p.weeklySummary;
    if (weekly.isEmpty || weekly.every((e) => (e['carbs'] as double) == 0)) {
      return const SizedBox.shrink();
    }

    final spots = <FlSpot>[];
    for (var i = 0; i < weekly.length; i++) {
      final carbs = weekly[i]['carbs'] as double;
      if (carbs > 0) {
        spots.add(FlSpot(i.toDouble(), carbs));
      }
    }

    if (spots.isEmpty) return const SizedBox.shrink();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart, color: _color, size: 20),
                const SizedBox(width: 8),
                const Text('近 7 天碳水趋势',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 50,
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
                        reservedSize: 28,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i >= 0 && i < weekly.length) {
                            return Text(
                              weekly[i]['day'] as String,
                              style: TextStyle(
                                  fontSize: 9, color: Colors.grey[500]),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        interval: 50,
                        getTitlesWidget: (v, _) => Text(
                          '${v.toInt()}g',
                          style:
                              TextStyle(fontSize: 10, color: Colors.grey[400]),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  barGroups: [
                    for (var i = 0; i < weekly.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: (weekly[i]['carbs'] as double).clamp(0, 300),
                            color: _color.withOpacity(0.7),
                            width: 20,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6)),
                          ),
                        ],
                      ),
                  ],
                  // 240g 参考线
                  extraLinesData: ExtraLinesData(horizontalLines: [
                    HorizontalLine(
                      y: 180,
                      color: _color.withOpacity(0.4),
                      strokeWidth: 1,
                      dashArray: [6, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        labelResolver: (_) => '建议 180g',
                        style: TextStyle(
                          color: _color.withOpacity(0.7),
                          fontSize: 10,
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

  // ────────────────── 饮食记录项 ──────────────────
  Widget _buildRecordItem(dynamic record, DietProvider p) {
    final carbs = record.carbs as double;
    final mealType = record.mealType as String;
    final target = _targetCarbs[mealType] ?? 40;
    final over = carbs > target;

    final index = p.records.indexOf(record);

    return Dismissible(
      key: Key('diet_${record.date.toIso8601String()}_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      confirmDismiss: (_) async {
        p.deleteRecord(index);
        return false; // 手动处理删除
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // 餐别标签
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: over
                      ? _color.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    mealType,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: over ? _color : Colors.green,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 碳水数值
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${carbs.toStringAsFixed(0)}g 碳水',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: over ? _color : Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(建议 ≤${target}g)',
                          style: TextStyle(
                              color: Colors.grey[400], fontSize: 11),
                        ),
                      ],
                    ),
                    if (record.notes != null && (record.notes as String).isNotEmpty)
                      Text(
                        record.notes as String,
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // 时间
              Text(
                '${record.date.hour.toString().padLeft(2, '0')}:${record.date.minute.toString().padLeft(2, '0')}',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────── 添加饮食记录对话框 ──────────────────
  void _showAddDialog(BuildContext context) {
    String mealType = '午餐';
    final carbsCtrl = TextEditingController(text: '60');
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('记录饮食'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 餐别选择
              DropdownButtonFormField<String>(
                value: mealType,
                decoration: InputDecoration(
                  labelText: '餐别',
                  prefixIcon: Icon(Icons.restaurant_menu, color: _color),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                items: ['早餐', '午餐', '晚餐', '加餐']
                    .map((t) =>
                        DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setDialogState(() => mealType = v!),
              ),
              const SizedBox(height: 16),
              // 碳水输入
              TextField(
                controller: carbsCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: '碳水化合物（克）',
                  hintText: '例如 60',
                  prefixIcon: Icon(Icons.grain, color: _color),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              // 备注
              TextField(
                controller: notesCtrl,
                decoration: InputDecoration(
                  labelText: '备注（选填）',
                  hintText: '吃了什么',
                  prefixIcon: Icon(Icons.notes, color: _color),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final carbs = double.tryParse(carbsCtrl.text);
                if (carbs == null || carbs <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请输入有效的碳水量')),
                  );
                  return;
                }
                context.read<DietProvider>().addRecord(
                      mealType: mealType,
                      carbs: carbs,
                      notes: notesCtrl.text.isNotEmpty
                          ? notesCtrl.text
                          : null,
                    );
                Navigator.pop(ctx);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}
