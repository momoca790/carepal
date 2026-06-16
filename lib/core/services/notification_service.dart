import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart' show TimeOfDay, GlobalKey, NavigatorState;
import 'package:go_router/go_router.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/standalone.dart' as tz_standalone;
import 'package:timezone/timezone.dart' as tz;

/// 本地推送通知服务
///
/// 管理：
/// - 用药提醒（根据 `MedicationProvider` 的药物时段）
/// - 透析提醒（透析日前一天 + 当天）
/// - 每日健康打卡提醒
///
/// ## 初始化
/// ```dart
/// await NotificationService.init();
/// ```
///
/// ## 时区
/// 使用 `timezone` 包处理中国时区（Asia/Shanghai）
class NotificationService {
  NotificationService._();

  static FlutterLocalNotificationsPlugin? _plugin;

  /// 全局导航 key，在 AppRouter 创建后注入
  static GlobalKey<NavigatorState>? _navigatorKey;

  /// 设置导航 key（在 GoRouter 创建后调用）
  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  /// 初始化通知服务
  ///
  /// 必须先调用 `await tz.initializeTimeZones()` 和 `setLocalLocation`
  static Future<void> init() async {
    // 1. 初始化时区数据库
    tz.initializeTimeZones();
    try {
      tz_standalone.setLocalLocation(tz.getLocation('Asia/Shanghai'));
    } catch (_) {
      // 如果时区设置失败，使用 UTC（通知时间可能不准）
    }

    // 验证 tz.local 已设置
    try {
      tz.TZDateTime.now(tz.local);
    } catch (_) {
      // fallback: 使用 UTC
      tz_standalone.setLocalLocation(tz.getLocation('UTC'));
    }

    _plugin = FlutterLocalNotificationsPlugin();

    // Android 初始化设置（小图标需用真实 drawable 资源）
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS 初始化设置
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin?.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // 请求权限（Android 13+ / iOS）
    await _requestPermissions();
  }

  /// 请求通知权限
  static Future<void> _requestPermissions() async {
    try {
      await _plugin
          ?.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (_) {
      // Android 13+ 权限请求
    }

    try {
      await _plugin
          ?.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } catch (_) {
      // iOS 权限请求
    }
  }

  /// 点击通知回调（使用 go_router 跳转）
  static void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    final ctx = _navigatorKey?.currentContext;
    if (payload == null || ctx == null) return;

    // 根据 payload 格式导航到对应页面：
    // "medication|{medId}|{slot}"  → 用药页面
    // "dialysis|{type}"            → 透析页面
    // "daily_health"               → 首页
    final parts = payload.split('|');
    final router = GoRouter.of(ctx);
    switch (parts[0]) {
      case 'medication':
        router.go('/diabetes/medication');
        break;
      case 'dialysis':
        router.go('/uremia/dialysis');
        break;
      case 'daily_health':
        router.go('/home');
        break;
      default:
        router.go('/home');
    }
  }

  /// 发送即时通知
  static Future<void> showInstant({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'carepal_channel',
      'CarePal 健康提醒',
      channelDescription: '用药、透析、健康打卡提醒',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin?.show(id, title, body, details, payload: payload);
  }

  /// 安排每日定时通知（使用 zonedSchedule）
  ///
  /// [hour] 小时 (0-23)，[minute] 分钟 (0-59)
  /// 需要 `timezone` 包已初始化
  static Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'carepal_channel',
      'CarePal 健康提醒',
      channelDescription: '用药、透析、健康打卡提醒',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // 使用 timezone 包计算下次触发时间
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin?.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      details,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// 取消指定通知
  static Future<void> cancel(int id) async {
    await _plugin?.cancel(id);
  }

  /// 取消所有通知
  static Future<void> cancelAll() async {
    await _plugin?.cancelAll();
  }

  // ════════════════════════════════════════════════════════
  // 业务快捷方法
  // ════════════════════════════════════════════════════════

  /// 安排用药提醒（根据药物时段）
  ///
  /// 如 "早餐后" → 07:30，"晚餐前" → 17:30
  static Future<void> scheduleMedicationReminder({
    required String medId,
    required String medName,
    required List<String> times,
  }) async {
    final timeMap = _parseTimeSlots(times);

    for (final entry in timeMap.entries) {
      final slot = entry.key;
      final timeOfDay = entry.value;
      final notificationId = '${medId}_$slot'.hashCode;

      await scheduleDaily(
        id: notificationId,
        title: '用药提醒',
        body: '该服用 $medName 了',
        hour: timeOfDay.hour,
        minute: timeOfDay.minute,
        payload: 'medication|$medId|$slot',
      );
    }
  }

  /// 安排透析提醒
  ///
  /// - 透析当天 06:00 提醒
  static Future<void> scheduleDialysisReminder({
    required DateTime dialysisDate,
    required String dialysisType,
  }) async {
    final reminderId = 'dialysis_${dialysisDate.toIso8601String()}'.hashCode;
    await scheduleDaily(
      id: reminderId,
      title: '透析提醒',
      body: '今天 $dialysisType 透析，请注意饮食控水',
      hour: 6,
      minute: 0,
      payload: 'dialysis|$dialysisType',
    );
  }

  /// 安排每日健康打卡提醒（20:00）
  static Future<void> scheduleDailyHealthReminder() async {
    await scheduleDaily(
      id: 'daily_health_reminder'.hashCode,
      title: '健康打卡提醒',
      body: '记得记录今天的血糖、体重和饮水情况哦！',
      hour: 20,
      minute: 0,
      payload: 'daily_health',
    );
  }

  /// 解析中文时段 → TimeOfDay
  static Map<String, TimeOfDay> _parseTimeSlots(List<String> times) {
    final result = <String, TimeOfDay>{};

    for (final t in times) {
      final slot = t;
      int hour;
      int minute = 0;

      if (t.contains('早餐前')) {
        hour = 7;
      } else if (t.contains('早餐后')) {
        hour = 8;
        minute = 30;
      } else if (t.contains('午餐前')) {
        hour = 11;
      } else if (t.contains('午餐后')) {
        hour = 12;
        minute = 30;
      } else if (t.contains('晚餐前')) {
        hour = 17;
        minute = 30;
      } else if (t.contains('晚餐后')) {
        hour = 19;
      } else if (t.contains('睡前')) {
        hour = 21;
        minute = 30;
      } else if (t.contains('起床后')) {
        hour = 7;
      } else {
        hour = 8; // 默认
      }

      result[slot] = TimeOfDay(hour: hour, minute: minute);
    }

    return result;
  }
}
