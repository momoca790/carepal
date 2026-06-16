import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/services/user_service.dart';
import '../core/services/notification_service.dart';
import '../plugins/plugin_diabetes/lib/providers/blood_sugar_provider.dart';
import '../plugins/plugin_diabetes/lib/providers/medication_provider.dart';
import '../plugins/plugin_uremia/lib/providers/uremia_provider.dart';

/// 个人中心页面
///
/// 功能：
/// - 用户信息展示（用户名、头像）
/// - 疾病模块展示
/// - 设置入口（用药提醒 / 数据同步 / 导出报告）
/// - 关于信息
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _reminderEnabled = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadReminderPref();
  }

  Future<void> _loadReminderPref() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _reminderEnabled = prefs.getBool('medication_reminder') ?? true;
      _loaded = true;
    });
  }

  Future<void> _setReminderPref(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('medication_reminder', value);

    if (value) {
      // 重新调度通知
      try {
        final medProvider = context.read<MedicationProvider>();
        for (final med in medProvider.medications) {
          await NotificationService.scheduleMedicationReminder(
            medId: med.id,
            medName: med.name,
            times: med.times,
          );
        }
      } catch (_) {
        // 用户可能没有糖尿病插件
      }

      try {
        final uremia = context.read<UremiaProvider>();
        if (uremia.dialysisRecords.isNotEmpty) {
          await NotificationService.scheduleDialysisReminder(
            dialysisDate: DateTime.now().add(const Duration(days: 1)),
            dialysisType: 'HD',
          );
        }
      } catch (_) {
        // 用户可能没有尿毒症插件
      }

      await NotificationService.scheduleDailyHealthReminder();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('用药提醒已开启'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      await NotificationService.cancelAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已关闭所有推送通知'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }

    setState(() => _reminderEnabled = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diseases = UserService.diseases;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('个人中心'),
        backgroundColor: const Color(0xFFFF9800),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildUserCard(context, theme),
          const SizedBox(height: 16),
          _buildDiseaseSection(context, theme, diseases),
          const SizedBox(height: 16),
          _buildSettingsSection(context, theme),
          const SizedBox(height: 16),
          _buildAboutSection(context, theme),
          const SizedBox(height: 24),
          _buildLogoutButton(context, theme),
        ],
      ),
    );
  }

  /// 用户信息卡片
  Widget _buildUserCard(BuildContext context, ThemeData theme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: const Color(0xFFFF9800).withOpacity(0.1),
              child: Text(
                (UserService.userName ?? '?')[0],
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF9800),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    UserService.userName ?? '未登录',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'CarePal 用户',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  /// 疾病模块管理
  Widget _buildDiseaseSection(
      BuildContext context, ThemeData theme, List<String> diseases) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medical_services, color: Colors.blue[700], size: 22),
                const SizedBox(width: 8),
                const Text(
                  '我的疾病模块',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (diseases.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  '暂未添加疾病模块，请退出后重新登录选择',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              )
            else
              ...diseases.map((id) => _buildDiseaseChip(id)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '疾病模块在登录时由系统根据您的身份自动分配',
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontSize: 12,
                        height: 1.4,
                      ),
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

  Widget _buildDiseaseChip(String id) {
    final String name;
    final IconData icon;
    final Color color;
    switch (id) {
      case 'diabetes':
        name = '糖尿病护理';
        icon = Icons.bloodtype;
        color = const Color(0xFFFF9800);
        break;
      case 'uremia':
        name = '尿毒症护理';
        icon = Icons.water_damage;
        color = const Color(0xFF2196F3);
        break;
      default:
        name = id;
        icon = Icons.medical_services;
        color = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(
            name,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              '已激活',
              style: TextStyle(color: Colors.green, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  /// 设置项
  Widget _buildSettingsSection(BuildContext context, ThemeData theme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _settingsTile(
            icon: Icons.notifications_outlined,
            color: Colors.orange,
            title: '用药提醒设置',
            subtitle: _loaded
                ? (_reminderEnabled ? '已开启每日用药推送' : '已关闭推送通知')
                : '管理每日用药推送通知',
            trailing: _loaded
                ? Switch(
                    value: _reminderEnabled,
                    onChanged: _setReminderPref,
                    activeColor: Colors.orange,
                  )
                : null,
            onTap: _loaded
                ? () => _setReminderPref(!_reminderEnabled)
                : null,
          ),
          const Divider(height: 1, indent: 56),
          _settingsTile(
            icon: Icons.cloud_sync_outlined,
            color: Colors.blue,
            title: '数据同步',
            subtitle: '跨设备同步健康数据',
            onTap: () => _showDataSyncDialog(context),
          ),
          const Divider(height: 1, indent: 56),
          _settingsTile(
            icon: Icons.download_outlined,
            color: Colors.green,
            title: '导出健康报告',
            subtitle: '生成文本格式健康摘要',
            onTap: () => _showExportReportDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: trailing ?? Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
    );
  }

  /// 数据同步对话框
  void _showDataSyncDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cloud_sync_outlined, color: Colors.blue),
            SizedBox(width: 8),
            Text('数据同步'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '云同步功能正在开发中',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            SizedBox(height: 12),
            Text(
              '未来版本将支持：',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 8),
            _SyncFeatureItem(icon: Icons.phone_android, text: '手机 / 平板间数据自动同步'),
            _SyncFeatureItem(icon: Icons.security, text: '端到端加密传输'),
            _SyncFeatureItem(icon: Icons.history, text: '7 天历史数据回溯'),
            _SyncFeatureItem(icon: Icons.people, text: '家庭成员共享看护'),
            SizedBox(height: 12),
            Text(
              '当前版本数据存储在本地，无需担心隐私泄露。',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  /// 导出健康报告对话框
  void _showExportReportDialog(BuildContext context) {
    final report = _generateReport(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.assessment, color: Colors.green),
            SizedBox(width: 8),
            Text('健康报告'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              report,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: report));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('报告已复制到剪贴板'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('复制全部'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  String _generateReport(BuildContext context) {
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final buffer = StringBuffer();

    buffer.writeln('═══════════════════════════════════');
    buffer.writeln('  CarePal 健康报告');
    buffer.writeln('  用户：${UserService.userName ?? "未知"}');
    buffer.writeln('  生成时间：$dateStr');
    buffer.writeln('═══════════════════════════════════');
    buffer.writeln();

    // 糖尿病数据
    final diseases = UserService.diseases;
    if (diseases.contains('diabetes')) {
      buffer.writeln('【糖尿病护理】');
      try {
        final bs = context.read<BloodSugarProvider>();
        buffer.writeln('  最新血糖：${bs.latestValue ?? "无数据"} mmol/L');
        buffer.writeln('  近 7 天记录数：${bs.recent7Days.length}');
        buffer.writeln('  总记录数：${bs.records.length}');
      } catch (_) {
        buffer.writeln('  （数据暂不可用）');
      }

      try {
        final med = context.read<MedicationProvider>();
        buffer.writeln('  用药完成度：${(med.progress * 100).toStringAsFixed(0)}%');
        buffer.writeln('  药物数量：${med.medications.length}');
      } catch (_) {
        buffer.writeln('  （用药数据暂不可用）');
      }
      buffer.writeln();
    }

    // 尿毒症数据
    if (diseases.contains('uremia')) {
      buffer.writeln('【尿毒症护理】');
      try {
        final ur = context.read<UremiaProvider>();
        buffer.writeln('  当前体重：${ur.todayWeight.toStringAsFixed(1)} kg');
        buffer.writeln('  干体重偏差：${ur.weightDeviation.toStringAsFixed(2)} kg');
        buffer.writeln('  今日饮水：${ur.todayWaterIntake.toStringAsFixed(0)} ml');
        buffer.writeln('  饮水进度：${(ur.waterProgress * 100).toStringAsFixed(0)}%');
        buffer.writeln('  透析记录数：${ur.dialysisRecords.length}');
        if (ur.latestDialysis != null) {
          buffer.writeln('  最近透析：${ur.latestDialysis!.date.toString().substring(0, 10)}');
        }
      } catch (_) {
        buffer.writeln('  （数据暂不可用）');
      }
      buffer.writeln();
    }

    buffer.writeln('═══════════════════════════════════');
    buffer.writeln('  报告由 CarePal 自动生成');
    buffer.writeln('  版本 1.0.0');
    buffer.writeln('═══════════════════════════════════');

    return buffer.toString();
  }

  /// 关于
  Widget _buildAboutSection(BuildContext context, ThemeData theme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[600], size: 22),
                const SizedBox(width: 8),
                const Text(
                  '关于 CarePal',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _aboutRow('版本', '1.0.0'),
            _aboutRow('架构', 'Core + Plugin 插件化'),
            _aboutRow('技术栈', 'Flutter 3.x / Provider / go_router'),
            _aboutRow('运行环境', 'iOS 14+ / Android 8.0+'),
            const SizedBox(height: 8),
            Text(
              'CarePal 是一款面向慢性病患者的护理管理应用，采用插件架构支持多种疾病模块的灵活组合。',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _aboutRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ),
          Text(value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  /// 退出登录
  Widget _buildLogoutButton(BuildContext context, ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('确认退出'),
              content: const Text('退出后需要重新登录，确定吗？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('确定退出', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            await NotificationService.cancelAll();
            await UserService.logout();
            if (context.mounted) context.go('/login');
          }
        },
        icon: const Icon(Icons.logout, color: Colors.red),
        label: const Text('退出登录', style: TextStyle(color: Colors.red)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

/// 数据同步功能特性项
class _SyncFeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SyncFeatureItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
