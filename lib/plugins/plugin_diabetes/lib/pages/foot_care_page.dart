import 'package:flutter/material.dart';

/// 足部护理 SOP 页面
///
/// 展示 4 步标准化护理流程，每步带 Checkbox 和完成反馈。
class FootCarePage extends StatefulWidget {
  const FootCarePage({super.key});

  @override
  State<FootCarePage> createState() => _FootCarePageState();
}

class _FootCarePageState extends State<FootCarePage> {
  final _steps = const [
    _Step('warm_water', 1, '温水洗脚', '37℃温水，浸泡不超过10分钟', Icons.water_drop),
    _Step('dry_toes',  2, '擦干趾缝', '柔软毛巾轻擦，特别注意趾缝间', Icons.water_drop_outlined),
    _Step('check',     3, '检查红肿', '查看足部有无红肿、破损、水泡', Icons.search),
    _Step('lotion',    4, '涂润肤霜', '适量涂抹润肤霜，保持湿润不过量', Icons.spa),
  ];
  final Set<String> _done = {};
  bool _allDoneAnim = false;

  int get _doneCount => _done.length;
  double get _progress => _doneCount / _steps.length;

  @override
  Widget build(BuildContext context) {
    final color = const Color(0xFFFF9800);

    return Scaffold(
      appBar: AppBar(
        title: const Text('足部护理'),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 进度卡片
          _buildProgress(color),
          const SizedBox(height: 16),
          // 步骤列表
          ..._steps.map((s) => _buildStepCard(s, color)),

          // 全部完成横幅
          if (_allDoneAnim)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, v, _) => Opacity(
                opacity: v,
                child: Transform.scale(
                  scale: v,
                  child: Card(
                    color: Colors.green[50],
                    margin: const EdgeInsets.only(top: 20),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 28),
                          const SizedBox(width: 12),
                          Text('全部完成！今天护理得很棒 🎉',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: Colors.green[700])),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgress(Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('护理进度',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 10,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 6),
            Text('$_doneCount / ${_steps.length} 步骤已完成',
                style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard(_Step step, Color color) {
    final isDone = _done.contains(step.id);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDone ? color.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone ? color.withOpacity(0.4) : Colors.grey[200]!,
          width: isDone ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDone
                ? color.withOpacity(0.08)
                : Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // 序号圆圈
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDone ? color : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: isDone
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : Text('${step.num}',
                      style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            // 内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        decoration:
                            isDone ? TextDecoration.lineThrough : null,
                        color: isDone ? Colors.grey : null,
                      )),
                  const SizedBox(height: 2),
                  Text(step.desc,
                      style: TextStyle(
                          color: isDone ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 13)),
                ],
              ),
            ),
            // Checkbox
            SizedBox(
              width: 42,
              height: 42,
              child: Checkbox(
                value: isDone,
                onChanged: (_) => _toggle(step.id),
                activeColor: color,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggle(String id) {
    setState(() {
      if (_done.contains(id)) {
        _done.remove(id);
        _allDoneAnim = false;
      } else {
        _done.add(id);
        if (_done.length == _steps.length) {
          _allDoneAnim = true;
        }
      }
    });
  }
}

class _Step {
  final String id;
  final int num;
  final String title;
  final String desc;
  final IconData icon;
  const _Step(this.id, this.num, this.title, this.desc, this.icon);
}
