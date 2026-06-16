import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/uremia_provider.dart';

/// 饮食管理页面
///
/// 血钾 / 血磷监测 + 趋势图 + 饮食建议
class DietPage extends StatefulWidget {
  const DietPage({super.key});

  @override
  State<DietPage> createState() => _DietPageState();
}

class _DietPageState extends State<DietPage> {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<UremiaProvider>();
    final color = const Color(0xFF2196F3);
    final latest =
        p.recentDiet.isNotEmpty ? p.recentDiet.first : null;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('饮食管理'),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 当前指标概览 ──
          _buildCurrentIndicators(latest, color),
          const SizedBox(height: 12),

          // ── 食物禁忌参考 ──
          _buildFoodGuide(color),
          const SizedBox(height: 16),

          // ── 历史趋势 ──
          _buildTrendChart(p, color),
          const SizedBox(height: 16),

          // ── 饮食记录列表 ──
          const Text('饮食指标记录',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ...p.recentDiet.map((r) => _buildDietRecord(r, color)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDietDialog(context, color),
        backgroundColor: color,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('记录指标'),
      ),
    );
  }

  /// 当前指标概览
  Widget _buildCurrentIndicators(dynamic latest, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.biotech, color: color, size: 22),
                const SizedBox(width: 8),
                const Text('当前指标',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // 血钾
                Expanded(
                  child: _indicatorGauge(
                    '血钾 K⁺',
                    latest?.potassium,
                    3.5,
                    5.5,
                    'mmol/L',
                    Colors.orange,
                    '低钾风险',
                    '正常',
                    '高钾危险',
                  ),
                ),
                const SizedBox(width: 12),
                // 血磷
                Expanded(
                  child: _indicatorGauge(
                    '血磷 P',
                    latest?.phosphorus,
                    0.8,
                    1.6,
                    'mmol/L',
                    Colors.teal,
                    '偏低',
                    '正常',
                    '偏高',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _indicatorGauge(
    String label,
    double? value,
    double low,
    double high,
    String unit,
    Color indicatorColor,
    String lowText,
    String normalText,
    String highText,
  ) {
    final hasValue = value != null;

    String status;
    Color statusColor;
    String statusIcon;
    if (!hasValue) {
      status = '暂无';
      statusColor = Colors.grey;
      statusIcon = '--';
    } else if (value < low) {
      status = lowText;
      statusColor = Colors.blue;
      statusIcon = '↓';
    } else if (value > high) {
      status = highText;
      statusColor = Colors.red;
      statusIcon = '↑';
    } else {
      status = normalText;
      statusColor = Colors.green;
      statusIcon = '✓';
    }

    // 计算指针位置 (0~1)
    final range = 7.0;
    final position = hasValue ? ((value - 1.0) / range).clamp(0.04, 0.96) : 0.5;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: indicatorColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: indicatorColor.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
          const SizedBox(height: 10),
          // 简易仪表盘
          Stack(
            alignment: Alignment.center,
            children: [
              // 色带背景
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 12,
                  child: Row(
                    children: [
                      Expanded(
                          flex: 3,
                          child: Container(color: Colors.blue.withOpacity(0.2))),
                      Expanded(
                          flex: 3,
                          child: Container(color: Colors.green.withOpacity(0.2))),
                      Expanded(
                          flex: 4,
                          child: Container(color: Colors.red.withOpacity(0.2))),
                    ],
                  ),
                ),
              ),
              // 指针
              Positioned(
                left: 4 + (MediaQuery.of(context).size.width - 92) * position,
                child: Container(
                  width: 8,
                  height: 20,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            hasValue ? '${value.toStringAsFixed(1)} $unit' : '-- $unit',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: statusColor,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$statusIcon $status',
              style: TextStyle(
                  color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// 食物禁忌参考
  Widget _buildFoodGuide(Color color) {
    final guides = [
      _FoodGuide('高钾食物', '香蕉、橙子、土豆、菠菜', Colors.orange, Icons.warning_amber),
      _FoodGuide('高磷食物', '坚果、奶酪、动物内脏、可乐', Colors.teal, Icons.warning_amber),
      _FoodGuide('推荐食物', '苹果、黄瓜、米饭、蛋白', Colors.green, Icons.check_circle),
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.menu_book, color: color, size: 20),
                const SizedBox(width: 8),
                const Text('饮食参考',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 12),
            ...guides.map((g) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(g.icon, color: g.color, size: 18),
                      const SizedBox(width: 8),
                      Text('${g.category}：',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: g.color)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(g.foods,
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12)),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  /// 趋势图
  Widget _buildTrendChart(UremiaProvider p, Color color) {
    if (p.recentDiet.isEmpty) return const SizedBox.shrink();

    final reversed = p.recentDiet.reversed.toList();

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
                const SizedBox(width: 8),
                const Text('指标趋势',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 130,
              child: CustomPaint(
                size: Size.infinite,
                painter: _DietTrendPainter(
                  records: reversed,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendDot2(Colors.orange, '血钾'),
                const SizedBox(width: 16),
                _legendDot2(Colors.teal, '血磷'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot2(Color dotColor, String label) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 3,
            decoration: BoxDecoration(
                color: dotColor, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  /// 饮食记录
  Widget _buildDietRecord(dynamic record, Color color) {
    final k = record.potassium as double;
    final p = record.phosphorus as double;
    final kOk = k >= 3.5 && k <= 5.5;
    final pOk = p >= 0.8 && p <= 1.6;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: (kOk && pOk)
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                (kOk && pOk) ? Icons.check_circle : Icons.warning_amber,
                color: (kOk && pOk) ? Colors.green : Colors.red,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${record.date.month}月${record.date.day}日',
                    style:
                        const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _inlineMetric('K⁺', k, 3.5, 5.5, Colors.orange),
                      const SizedBox(width: 16),
                      _inlineMetric('P', p, 0.8, 1.6, Colors.teal),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }

  Widget _inlineMetric(
      String label, double v, double lo, double hi, Color col) {
    final ok = v >= lo && v <= hi;
    return Row(
      children: [
        Text('$label ',
            style: TextStyle(
                color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w600)),
        Text('${v.toStringAsFixed(1)}',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: ok ? Colors.green : Colors.red)),
      ],
    );
  }

  /// 添加饮食记录对话框
  void _showAddDietDialog(BuildContext context, Color color) {
    final kCtrl = TextEditingController(text: '4.5');
    final pCtrl = TextEditingController(text: '1.5');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('记录饮食指标'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: kCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '血钾 K⁺ (mmol/L)',
                hintText: '正常范围 3.5-5.5',
                prefixIcon: Icon(Icons.science),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '血磷 P (mmol/L)',
                hintText: '正常范围 0.8-1.6',
                prefixIcon: Icon(Icons.science_outlined),
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
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final k = double.tryParse(kCtrl.text) ?? 0;
              final ph = double.tryParse(pCtrl.text) ?? 0;
              if (k > 0 && ph > 0) {
                context.read<UremiaProvider>().addDiet(
                      date: DateTime.now(),
                      potassium: k,
                      phosphorus: ph,
                    );
                Navigator.pop(ctx);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

class _FoodGuide {
  final String category;
  final String foods;
  final Color color;
  final IconData icon;

  const _FoodGuide(this.category, this.foods, this.color, this.icon);
}

/// 饮食趋势自定义绘制
class _DietTrendPainter extends CustomPainter {
  final List<dynamic> records;
  final Color color;

  _DietTrendPainter({required this.records, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (records.isEmpty) return;

    final kPaint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final pPaint = Paint()
      ..color = Colors.teal
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

    final dotPaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.fill;

    final stepX = size.width / (records.length - 1);
    const maxK = 6.5, minK = 2.5;
    const maxP = 2.2, minP = 0.5;

    void drawLine(List<Offset> points, Paint paint, {bool showDots = false}) {
      final path = Path();
      path.moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        final midX = (points[i - 1].dx + points[i].dx) / 2;
        path.cubicTo(
            midX, points[i - 1].dy, midX, points[i].dy, points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, paint);

      if (showDots) {
        for (final p in points) {
          canvas.drawCircle(p, 3, dotPaint);
        }
      }
    }

    final kPoints = <Offset>[];
    final pPoints = <Offset>[];

    for (var i = 0; i < records.length; i++) {
      final r = records[i];
      final k = (r.potassium as double).clamp(minK, maxK);
      final ph = (r.phosphorus as double).clamp(minP, maxP);
      kPoints.add(Offset(
          i * stepX, size.height - (k - minK) / (maxK - minK) * size.height));
      pPoints.add(Offset(
          i * stepX, size.height - (ph - minP) / (maxP - minP) * size.height));
    }

    drawLine(pPoints, pPaint);
    drawLine(kPoints, kPaint, showDots: true);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
