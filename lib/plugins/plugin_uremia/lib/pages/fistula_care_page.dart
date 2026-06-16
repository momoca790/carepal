import 'package:flutter/material.dart';

/// 瘘管护理页面
///
/// SOP 护理步骤 + 动画 + 进度跟踪
class FistulaCarePage extends StatefulWidget {
  const FistulaCarePage({super.key});

  @override
  State<FistulaCarePage> createState() => _FistulaCarePageState();
}

class _FistulaCarePageState extends State<FistulaCarePage>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  final Set<int> _completedSteps = {};
  late AnimationController _celebrationCtrl;

  bool get _allDone => _completedSteps.length == _steps.length;

  static const _steps = [
    _CareStep(
      number: 1,
      title: '观察外观',
      description: '查看瘘管部位有无红肿、渗血、皮肤破损',
      icon: Icons.visibility,
      detail: '在光线充足下仔细观察动静脉瘘管皮肤表面，确认无异常颜色变化。',
    ),
    _CareStep(
      number: 2,
      title: '触摸震颤',
      description: '用手指轻触瘘管，感受血管震颤感',
      icon: Icons.touch_app,
      detail: '将食指和中指并拢，轻轻放在瘘管上方，感受"嗡嗡"的震颤感（即"猫喘"）。震颤减弱或消失要立即就医。',
    ),
    _CareStep(
      number: 3,
      title: '听诊杂音',
      description: '用听诊器听取瘘管血流杂音',
      icon: Icons.hearing,
      detail: '将听诊器置于瘘管处，正常应有持续的低音调杂音。杂音改变提示可能有血管狭窄。',
    ),
    _CareStep(
      number: 4,
      title: '清洁保护',
      description: '保持瘘管部位清洁干燥，避免压迫',
      icon: Icons.clean_hands,
      detail: '透析前用肥皂水清洗瘘管处，透析后保持穿刺点干燥 24 小时。睡眠时避免瘘管侧手臂受压。',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _celebrationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _celebrationCtrl.dispose();
    super.dispose();
  }

  void _completeStep(int index) {
    setState(() {
      if (_completedSteps.contains(index)) {
        _completedSteps.remove(index);
      } else {
        _completedSteps.add(index);
      }
      if (_completedSteps.length == _steps.length) {
        _celebrationCtrl.forward(from: 0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = const Color(0xFF2196F3);
    final progress = _completedSteps.length / _steps.length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('瘘管护理'),
        backgroundColor: color,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(2)),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 进度提示 ──
          _buildProgressHeader(progress, color),
          const SizedBox(height: 16),

          // ── 护理步骤列表 ──
          ...List.generate(_steps.length, (i) {
            return _buildStepCard(i, color);
          }),

          const SizedBox(height: 16),

          // ── 完成横幅 ──
          _buildCompletionBanner(color),
        ],
      ),
    );
  }

  Widget _buildProgressHeader(double progress, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Text(
                '${_completedSteps.length}/${_steps.length}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('今日瘘管护理',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  _allDone ? '全部完成，做得很好！' : '请按步骤完成今日护理',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(int index, Color color) {
    final step = _steps[index];
    final isCompleted = _completedSteps.contains(index);
    final isCurrent = index == _currentStep && !isCompleted;

    return GestureDetector(
      onTap: () => _completeStep(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isCompleted
              ? Colors.green.withOpacity(0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCompleted
                ? Colors.green.withOpacity(0.3)
                : isCurrent
                    ? color.withOpacity(0.3)
                    : Colors.grey[200]!,
            width: isCurrent ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // 步骤编号圆圈
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? Colors.green
                    : isCurrent
                        ? color
                        : Colors.grey[300],
              ),
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 22)
                  : Text(
                      '${step.number}',
                      style: TextStyle(
                        color: isCurrent ? Colors.white : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(step.icon,
                          color:
                              isCompleted ? Colors.green : color,
                          size: 16),
                      const SizedBox(width: 6),
                      Text(step.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: isCompleted
                                ? Colors.grey
                                : Colors.black87,
                          )),
                    ],
                  ),
                  const SizedBox(height: 4),
                  AnimatedCrossFade(
                    firstChild: Text(
                      step.description,
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 12, height: 1.3),
                    ),
                    secondChild: Text(
                      step.detail,
                      style: TextStyle(
                          color: color, fontSize: 12, height: 1.4),
                    ),
                    crossFadeState: isCurrent
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                  ),
                ],
              ),
            ),
            // 完成勾选框
            Transform.scale(
              scale: 0.9,
              child: Checkbox(
                value: isCompleted,
                onChanged: (_) => _completeStep(index),
                activeColor: Colors.green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionBanner(Color color) {
    return AnimatedBuilder(
      animation: _celebrationCtrl,
      builder: (context, _) {
        final scale = 1.0 + 0.1 * _celebrationCtrl.value;

        return AnimatedOpacity(
          opacity: _allDone ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 400),
          child: Transform.scale(
            scale: _allDone ? scale : 0.8,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.withOpacity(0.15),
                    Colors.green.withOpacity(0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.emoji_events,
                      color: Colors.green, size: 48),
                  const SizedBox(height: 8),
                  const Text('太棒了！',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green)),
                  const SizedBox(height: 4),
                  Text(
                    '今日瘘管护理已全部完成\n动静脉瘘管是透析患者的 "生命线"',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 13,
                        height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CareStep {
  final int number;
  final String title;
  final String description;
  final IconData icon;
  final String detail;

  const _CareStep({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
    required this.detail,
  });
}
