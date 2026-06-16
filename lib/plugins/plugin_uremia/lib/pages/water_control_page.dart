import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/uremia_provider.dart';

/// 控水管理页面
///
/// 每日饮水量追踪 + 进度环 + 饮水记录列表 + 快速添加
class WaterControlPage extends StatefulWidget {
  const WaterControlPage({super.key});

  @override
  State<WaterControlPage> createState() => _WaterControlPageState();
}

class _WaterControlPageState extends State<WaterControlPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _rippleCtrl;

  @override
  void initState() {
    super.initState();
    _rippleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
  }

  @override
  void dispose() {
    _rippleCtrl.dispose();
    super.dispose();
  }

  void _triggerRipple() {
    _rippleCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<UremiaProvider>();
    final color = const Color(0xFF2196F3);
    final progress = p.waterProgress.clamp(0.0, 1.0);
    final over = p.waterOverLimit;
    final progressColor = over ? Colors.red : color;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('控水管理'),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 大进度环 ──
          _buildProgressRing(p, progressColor, color),
          const SizedBox(height: 12),

          // ── 统计信息 ──
          _buildStatsCard(p, color),
          const SizedBox(height: 16),

          // ── 饮水记录 ──
          const Text('今日饮水记录',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ..._buildWaterList(p, color),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddWaterDialog(context, color),
        backgroundColor: color,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('记录饮水'),
      ),
    );
  }

  /// 大进度环
  Widget _buildProgressRing(UremiaProvider p, Color progressColor, Color color) {
    final intake = p.todayWaterIntake;
    final limit = UremiaProvider.dailyWaterLimit;
    final progress = p.waterProgress.clamp(0.0, 1.0);
    final remaining = (limit - intake).clamp(0, limit);

    return AnimatedBuilder(
      animation: _rippleCtrl,
      builder: (context, _) {
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            child: Column(
              children: [
                // 环形进度
                SizedBox(
                  width: 180,
                  height: 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 180,
                        height: 180,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 12,
                          strokeCap: StrokeCap.round,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progress >= 1.0 ? Colors.red : color,
                          ),
                        ),
                      ),
                      // 水波涟漪效果
                      if (_rippleCtrl.isAnimating)
                        ...List.generate(3, (i) {
                          final delay = i * 0.3;
                          final anim = (_rippleCtrl.value - delay).clamp(0.0, 1.0);
                          return SizedBox(
                            width: 180 + 40 * anim,
                            height: 180 + 40 * anim,
                            child: CircularProgressIndicator(
                              value: 1,
                              strokeWidth: 1.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                color.withOpacity(0.3 * (1 - anim)),
                              ),
                            ),
                          );
                        }),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${intake.toInt()}',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: progressColor,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '/ $limit ml',
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // 剩余量
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: progress >= 0.9
                        ? Colors.red.withOpacity(0.08)
                        : Colors.green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    progress >= 1.0
                        ? '⚠️ 已超标，请立即停止饮水'
                        : '还可饮用 ${remaining.toInt()} ml',
                    style: TextStyle(
                      color: progress >= 0.9 ? Colors.red : Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 统计卡片
  Widget _buildStatsCard(UremiaProvider p, Color color) {
    final records = p.waterRecords.where((r) {
      final today = DateTime.now();
      return r.time.year == today.year &&
          r.time.month == today.month &&
          r.time.day == today.day;
    }).toList();

    final avg = records.isNotEmpty
        ? records.map((r) => r.amount).reduce((a, b) => a + b) / records.length
        : 0.0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _statItem('记录次数', '${records.length} 次', Icons.repeat, color),
            Container(width: 1, height: 40, color: Colors.grey[200]),
            _statItem('平均每次', '${avg.toInt()} ml', Icons.water_drop, color),
            Container(width: 1, height: 40, color: Colors.grey[200]),
            _statItem('距上限', '${(UremiaProvider.dailyWaterLimit - p.todayWaterIntake).clamp(0, 9999).toInt()} ml',
                Icons.speed, color),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color.withOpacity(0.5), size: 18),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(label,
              style: TextStyle(color: Colors.grey[500], fontSize: 10)),
        ],
      ),
    );
  }

  /// 饮水记录列表
  List<Widget> _buildWaterList(UremiaProvider p, Color color) {
    final today = DateTime.now();
    final todayRecords = p.waterRecords.where((r) {
      return r.time.year == today.year &&
          r.time.month == today.month &&
          r.time.day == today.day;
    }).toList();

    if (todayRecords.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child:
                Text('今天还没有饮水记录', style: TextStyle(color: Colors.grey)),
          ),
        ),
      ];
    }

    return todayRecords.map((r) {
      final hour = '${r.time.hour.toString().padLeft(2, '0')}:${r.time.minute.toString().padLeft(2, '0')}';
      return Card(
        margin: const EdgeInsets.only(bottom: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.water_drop, color: color, size: 22),
          ),
          title: Text('${r.amount.toInt()} ml',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(hour,
              style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        ),
      );
    }).toList();
  }

  /// 添加饮水对话框
  void _showAddWaterDialog(BuildContext context, Color color) {
    final ctrl = TextEditingController(text: '200');
    final amounts = [50, 100, 150, 200, 250, 300];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('记录饮水'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 快捷选择
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: amounts.map((a) {
                return ChoiceChip(
                  label: Text('$a ml'),
                  selected: ctrl.text == '$a',
                  selectedColor: color.withOpacity(0.15),
                  onSelected: (_) {
                    ctrl.text = '$a';
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '饮水量 (ml)',
                prefixIcon: Icon(Icons.water_drop),
                border: OutlineInputBorder(),
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
              final amount = double.tryParse(ctrl.text) ?? 0;
              if (amount > 0) {
                context.read<UremiaProvider>().addWater(amount);
                _triggerRipple();
                Navigator.pop(ctx);
              }
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }
}
