import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 血糖数据提供者（ChangeNotifier）
///
/// 使用 SharedPreferences 持久化血糖记录。
class BloodSugarProvider extends ChangeNotifier {
  static const _key = 'blood_sugar_records';

  List<_BloodSugarRecord> _records = [];
  bool _loaded = false;

  BloodSugarProvider() {
    _load();
  }

  bool get isLoaded => _loaded;

  List<_BloodSugarRecord> get records => List.unmodifiable(_records);

  /// 最近 7 天的记录
  List<_BloodSugarRecord> get recent7Days {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return _records.where((r) => r.time.isAfter(cutoff)).toList();
  }

  /// 今日最新血糖
  double? get latestValue => _records.isNotEmpty ? _records.first.value : null;

  void addRecord(double value, String type) {
    _records.insert(0, _BloodSugarRecord(
      time: DateTime.now(),
      value: value,
      type: type,
    ));
    _save();
    notifyListeners();
  }

  /// 编辑指定记录
  void updateRecord(int index, {double? value, String? type}) {
    if (index >= 0 && index < _records.length) {
      final old = _records[index];
      _records[index] = _BloodSugarRecord(
        time: old.time,
        value: value ?? old.value,
        type: type ?? old.type,
      );
      _save();
      notifyListeners();
    }
  }

  /// 删除指定记录
  void deleteRecord(int index) {
    if (index >= 0 && index < _records.length) {
      _records.removeAt(index);
      _save();
      notifyListeners();
    }
  }

  // ════════════════════════════════════════════════════
  // 持久化
  // ════════════════════════════════════════════════════

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final list = jsonDecode(raw) as List<dynamic>;
        _records = list.map((e) => _BloodSugarRecord.fromJson(e as Map<String, dynamic>)).toList();
        _records.sort((a, b) => b.time.compareTo(a.time)); // 最新在前
      } else {
        // 首次运行：生成示例数据并保存
        _records = _generateDummy();
        _save();
      }
    } catch (_) {
      _records = _generateDummy();
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_records.map((r) => r.toJson()).toList());
      await prefs.setString(_key, json);
    } catch (e) {
      // 保存失败，但不影响主流程
    }
  }

  static List<_BloodSugarRecord> _generateDummy() {
    final now = DateTime.now();
    return [
      _BloodSugarRecord(time: now.subtract(const Duration(hours: 2)),  value: 5.8, type: '空腹'),
      _BloodSugarRecord(time: now.subtract(const Duration(days: 1)),  value: 7.5, type: '早餐后'),
      _BloodSugarRecord(time: now.subtract(const Duration(days: 1)),  value: 6.2, type: '空腹'),
      _BloodSugarRecord(time: now.subtract(const Duration(days: 2)),  value: 8.1, type: '午餐后'),
      _BloodSugarRecord(time: now.subtract(const Duration(days: 2)),  value: 5.5, type: '空腹'),
      _BloodSugarRecord(time: now.subtract(const Duration(days: 3)),  value: 6.9, type: '空腹'),
      _BloodSugarRecord(time: now.subtract(const Duration(days: 4)),  value: 8.4, type: '早餐后'),
      _BloodSugarRecord(time: now.subtract(const Duration(days: 4)),  value: 5.3, type: '空腹'),
      _BloodSugarRecord(time: now.subtract(const Duration(days: 5)),  value: 7.2, type: '晚餐后'),
      _BloodSugarRecord(time: now.subtract(const Duration(days: 5)),  value: 5.1, type: '空腹'),
      _BloodSugarRecord(time: now.subtract(const Duration(days: 6)),  value: 6.0, type: '空腹'),
      _BloodSugarRecord(time: now.subtract(const Duration(days: 6)),  value: 8.9, type: '午餐后'),
    ];
  }
}

class _BloodSugarRecord {
  final DateTime time;
  final double value;  // mmol/L
  final String type;   // 空腹/餐后等

  const _BloodSugarRecord({
    required this.time,
    required this.value,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'time': time.toIso8601String(),
        'value': value,
        'type': type,
      };

  factory _BloodSugarRecord.fromJson(Map<String, dynamic> json) {
    return _BloodSugarRecord(
      time: DateTime.parse(json['time'] as String),
      value: (json['value'] as num).toDouble(),
      type: json['type'] as String,
    );
  }
}
