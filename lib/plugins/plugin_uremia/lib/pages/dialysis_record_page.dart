import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/uremia_provider.dart';

/// 透析管理页面
///
/// 展示透析记录列表 + 排班信息 + 添加新记录
class DialysisRecordPage extends StatefulWidget {
  const DialysisRecordPage({super.key});

  @override
  State<DialysisRecordPage> createState() => _DialysisRecordPageState();
}

class _DialysisRecordPageState extends State<DialysisRecordPage> {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<UremiaProvider>();
    final color = const Color(0xFF2196F3);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('透析管理'),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 排班信息 ──
          _buildScheduleCard(color),
          const SizedBox(height: 16),

          // ── 最近透析趋势图（体重） ──
          _buildWeightTrendCard(p, color),
          const SizedBox(height: 16),

          // ── 记录列表 ──
          const Text('透析记录',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ...p.recentDialysis.map((r) => _buildDialysisRecord(r, color)),

          if (p.recentDialysis.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('暂无透析记录',
                    style: TextStyle(color: Colors.grey)),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, color),
        backgroundColor: color,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('记录透析'),
      ),
    );
  }

  /// 排班卡片
  Widget _buildScheduleCard(Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_month, color: color, size: 20),
                const SizedBox(width: 8),
                const Text('透析排班',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 12),
            // 周一、三、五
            _buildScheduleRow('周一', DateTime.now().weekday == 1, color),
            _buildScheduleRow('周三', DateTime.now().weekday == 3, color),
            _buildScheduleRow('周五', DateTime.now().weekday == 5, color),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleRow(String day, bool isToday, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isToday ? color : Colors.grey[300],
            ),
          ),
          const SizedBox(width: 10),
          Text(day,
              style: TextStyle(
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday ? color : Colors.grey[700],
              )),
          const Spacer(),
          Text(
            isToday ? '今天' : '08:00 - 12:00',
            style: TextStyle(
                color: isToday ? color : Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }

  /// 体重趋势卡片
  Widget _buildWeightTrendCard(UremiaProvider p, Color color) {
    if (p.recentDialysis.isEmpty) return const SizedBox.shrink();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_down, color: color, size: 20),
                const SizedBox(width: 8),
                const Text('体重趋势',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 16),
            // 简单柱状对比
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: p.recentDialysis.reversed.map((r) {
                  final maxWeight = 70.0;
                  final preH = (r.preWeight / maxWeight * 100).clamp(10.0, 100.0);
                  final postH = (r.postWeight / maxWeight * 100).clamp(10.0, 100.0);

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // 透前
                          Container(
                            height: preH,
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.7),
                              borderRadius:
                                  const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ),
                          const SizedBox(height: 2),
                          // 透后
                          Container(
                            height: postH,
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.7),
                              borderRadius:
                                  const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${r.date.month}/${r.date.day}',
                            style:
                                TextStyle(fontSize: 9, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendDot(Colors.orange, '透前'),
                const SizedBox(width: 16),
                _legendDot(Colors.green, '透后'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  /// 单条透析记录
  Widget _buildDialysisRecord(dynamic record, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    record.type,
                    style: TextStyle(
                        color: color, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${record.date.month}月${record.date.day}日',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const Spacer(),
                Text(
                  '${record.durationMinutes} 分钟',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _recordMetric('透前', '${record.preWeight.toStringAsFixed(1)} kg',
                    Colors.orange),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                _recordMetric('透后', '${record.postWeight.toStringAsFixed(1)} kg',
                    Colors.green),
                const Spacer(),
                _recordMetric(
                    '超滤', '${record.ultrafiltration.toStringAsFixed(1)} kg', color),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _recordMetric(String label, String value, Color col) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 10)),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14, color: col)),
      ],
    );
  }

  /// 添加透析记录对话框
  void _showAddDialog(BuildContext context, Color color) {
    final preCtrl = TextEditingController(text: '67.0');
    final postCtrl = TextEditingController(text: '64.5');
    final durCtrl = TextEditingController(text: '240');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('记录透析'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: preCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '透前体重 (kg)',
                prefixIcon: Icon(Icons.monitor_weight),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: postCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '透后体重 (kg)',
                prefixIcon: Icon(Icons.monitor_weight_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: durCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '透析时长 (分钟)',
                prefixIcon: Icon(Icons.timer),
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
              final pre = double.tryParse(preCtrl.text) ?? 0;
              final post = double.tryParse(postCtrl.text) ?? 0;
              final dur = int.tryParse(durCtrl.text) ?? 0;
              if (pre > 0 && post > 0 && dur > 0) {
                context.read<UremiaProvider>().addDialysis(
                      date: DateTime.now(),
                      preWeight: pre,
                      postWeight: post,
                      durationMinutes: dur,
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
