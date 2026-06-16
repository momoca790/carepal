import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/medication_provider.dart';

/// 用药提醒页面
///
/// - 展示所有药物，每种药物下拆分服药时段
/// - 每剂次带 Checkbox，点击打卡
/// - 顶部展示每日进度环
/// - 全部完成时有弹性动画横幅
class MedicationPage extends StatefulWidget {
  const MedicationPage({super.key});

  @override
  State<MedicationPage> createState() => _MedicationPageState();
}

class _MedicationPageState extends State<MedicationPage> {
  bool _showBanner = false;

  @override
  Widget build(BuildContext context) {
    final color = const Color(0xFFFF9800);
    final provider = context.watch<MedicationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('用药提醒'),
        backgroundColor: color,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '重置今日打卡',
            onPressed: () {
              provider.resetDaily();
              setState(() => _showBanner = false);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 进度环 ──
          _buildProgressRing(context, provider, color),
          const SizedBox(height: 20),

          // ── 药物列表 ──
          ...provider.medications.map((med) {
            // 药物是私有的 _Medication，这里用动态访问
            return _buildMedicationCard(context, provider, med, color);
          }),

          // ── 全部完成横幅 ──
          if (_showBanner || provider.allDone)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 700),
              curve: Curves.elasticOut,
              builder: (_, v, __) => Opacity(
                opacity: v,
                child: Transform.scale(
                  scale: v,
                  child: Container(
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green[400]!, Colors.green[600]!],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.verified, color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        const Text(
                          '今日用药全部完成！身体棒棒 🎉',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 顶部进度环
  Widget _buildProgressRing(
    BuildContext context,
    MedicationProvider provider,
    Color color,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // 环形进度
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: CircularProgressIndicator(
                      value: provider.progress,
                      strokeWidth: 6,
                      backgroundColor: Colors.grey[200],
                      valueColor:
                          AlwaysStoppedAnimation<Color>(provider.allDone ? Colors.green : color),
                    ),
                  ),
                  Text(
                    '${provider.takenCount}/${provider.totalCount}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: provider.allDone ? Colors.green : color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            // 文字说明
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '今日用药进度',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    provider.allDone
                        ? '全部已完成 ✓'
                        : '还有 ${provider.totalCount - provider.takenCount} 次待服用',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 单种药物的卡片
  Widget _buildMedicationCard(
    BuildContext context,
    MedicationProvider provider,
    dynamic med,
    Color accent,
  ) {
    final medId = med.id as String;
    final name = med.name as String;
    final dosage = med.dosage as String;
    final times = med.times as List<String>;
    final icon = med.icon as IconData;
    final medColor = med.color as Color;

    // 该药物已打卡次数
    int medTaken = 0;
    for (int i = 0; i < times.length; i++) {
      if (provider.isTaken(medId, i)) medTaken++;
    }
    final medDone = medTaken == times.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: medDone ? medColor.withOpacity(0.4) : Colors.grey[200]!,
            width: medDone ? 1.5 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 药物标题行
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: medColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: medColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          dosage,
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (medDone)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '已完成',
                        style: TextStyle(color: Colors.green[700], fontSize: 12),
                      ),
                    ),
                ],
              ),
              const Divider(height: 20),

              // 各服药时段
              ...List.generate(times.length, (i) {
                final taken = provider.isTaken(medId, i);
                return InkWell(
                  onTap: () {
                    provider.toggle(medId, i);
                    if (provider.allDone) {
                      setState(() => _showBanner = true);
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    margin: EdgeInsets.only(bottom: i < times.length - 1 ? 4 : 0),
                    decoration: BoxDecoration(
                      color: taken ? medColor.withOpacity(0.06) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: taken ? medColor : Colors.grey[300],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: taken
                              ? const Icon(Icons.check, color: Colors.white, size: 14)
                              : Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          times[i],
                          style: TextStyle(
                            fontSize: 14,
                            decoration: taken ? TextDecoration.lineThrough : null,
                            color: taken ? Colors.grey : null,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          taken ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: taken ? medColor : Colors.grey[300],
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
