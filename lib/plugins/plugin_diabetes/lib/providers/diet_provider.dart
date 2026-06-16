import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 糖尿病饮食记录
class _DietRecord {
  final DateTime date;
  final String mealType; // 早餐 / 午餐 / 晚餐 / 加餐
  final double carbs; // 碳水化合物（克）
  final String? notes;

  const _DietRecord({
    required this.date,
    required this.mealType,
    required this.carbs,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'mealType': mealType,
        'carbs': carbs,
        'notes': notes,
      };

  factory _DietRecord.fromJson(Map<String, dynamic> json) => _DietRecord(
        date: DateTime.parse(json['date'] as String),
        mealType: json['mealType'] as String,
        carbs: (json['carbs'] as num).toDouble(),
        notes: json['notes'] as String?,
      );
}

/// 糖尿病饮食数据管理
///
/// 追踪每餐碳水化合物摄入量 + 每日总碳水趋势
class DietProvider extends ChangeNotifier {
  static const _key = 'diabetes_diet_records';

  final List<_DietRecord> _records = [];

  List<dynamic> get records => List.unmodifiable(_records);

  /// 今日总碳水（克）
  double get todayCarbs {
    final now = DateTime.now();
    return _records
        .where((r) =>
            r.date.year == now.year &&
            r.date.month == now.month &&
            r.date.day == now.day)
        .fold<double>(0, (sum, r) => sum + r.carbs);
  }

  /// 近 7 天每日碳水汇总（最新在前）
  List<Map<String, dynamic>> get weeklySummary {
    final map = <String, double>{};
    final now = DateTime.now();
    for (var i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: i));
      final key = '${day.month}/${day.day}';
      map[key] = 0;
    }
    for (final r in _records) {
      final key = '${r.date.month}/${r.date.day}';
      map.update(key, (v) => v + r.carbs, ifAbsent: () => r.carbs);
    }
    return map.entries
        .map((e) => {'day': e.key, 'carbs': e.value})
        .toList()
        .reversed
        .toList();
  }

  /// 加载持久化数据
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      final list = json.decode(raw) as List<dynamic>;
      _records.clear();
      _records.addAll(
        list.map((e) => _DietRecord.fromJson(e as Map<String, dynamic>)),
      );
      _records.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
    } catch (_) {
      // 数据损坏，忽略
    }
  }

  /// 添加一条饮食记录
  Future<void> addRecord({
    required String mealType,
    required double carbs,
    String? notes,
  }) async {
    final record = _DietRecord(
      date: DateTime.now(),
      mealType: mealType,
      carbs: carbs,
      notes: notes,
    );
    _records.insert(0, record);
    await _save();
    notifyListeners();
  }

  /// 删除记录
  Future<void> deleteRecord(int index) async {
    if (index < 0 || index >= _records.length) return;
    _records.removeAt(index);
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      json.encode(_records.map((r) => r.toJson()).toList()),
    );
  }
}
