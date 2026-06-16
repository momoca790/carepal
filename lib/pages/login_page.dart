import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/services/user_service.dart';
import '../core/services/notification_service.dart';

/// 简易登录页 —— 模拟用户选择
///
/// 提供几个预设用户，每个用户关联不同的疾病列表：
/// - "钱阿姨" → 糖尿病
/// - "李叔叔" → 糖尿病 + 尿毒症
/// - "王奶奶" → 尿毒症
///
/// 选择后跳转到 HomePage，HomePage 会根据登录用户的疾病列表
/// 动态渲染不同的插件入口卡片。
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _presetUsers = const [
    _PresetUser('钱阿姨', ['diabetes']),
    _PresetUser('李叔叔', ['diabetes', 'uremia']),
    _PresetUser('王奶奶', ['uremia']),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite, size: 64, color: Color(0xFFFF9800)),
              const SizedBox(height: 16),
              Text(
                'CarePal',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFF9800),
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '选择您的身份以继续',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 32),
              ..._presetUsers.map((user) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _loginAs(user),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          '${user.name}（${user.diseases.isEmpty ? "无疾病" : user.diseases.map(_diseaseLabel).join("、")}）',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  )),
              const SizedBox(height: 16),
              Text(
                '提示：不同用户会看到不同的护理模块',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loginAs(_PresetUser user) async {
    await UserService.login(user.name);
    for (final d in user.diseases) {
      await UserService.addDisease(d);
    }

    // 登录后调度通知
    await _scheduleNotifications();

    if (mounted) {
      context.go('/home');
    }
  }

  Future<void> _scheduleNotifications() async {
    // 用药提醒：后续在 Provider 初始化后由个人中心设置触发
    // 这里先调度每日健康打卡提醒
    await NotificationService.scheduleDailyHealthReminder();
  }

  String _diseaseLabel(String id) {
    switch (id) {
      case 'diabetes':
        return '糖尿病护理';
      case 'uremia':
        return '尿毒症护理';
      default:
        return id;
    }
  }
}

class _PresetUser {
  final String name;
  final List<String> diseases;
  const _PresetUser(this.name, this.diseases);
}
