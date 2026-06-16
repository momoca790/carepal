import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 尿毒症数据提供者（ChangeNotifier）
///
/// 管理透析记录、体重、饮水量、饮食等核心数据。
/// 使用 SharedPreferences 持久化所有数据。
class UremiaProvider extends ChangeNotifier {
  // ── 透析记录 ──
  List<_DialysisRecord> _dialysisRecords = [];

  // ── 饮水管理 ──
  List<_WaterRecord> _waterRecords = [];

  // ── 饮食（钾 / 磷） ──
  List<_DietRecord> _dietRecords = [];

  bool _loaded = false;

  UremiaProvider() {
    _load();
  }

  bool get isLoaded => _loaded;

  // ═══════════════════════════════════════════════════
  // 透析记录
  // ═══════════════════════════════════════════════════

  List<_DialysisRecord> get dialysisRecords =>
      List.unmodifiable(_dialysisRecords);

  List<_DialysisRecord> get recentDialysis {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return _dialysisRecords.where((r) => r.date.isAfter(cutoff)).toList();
  }

  _DialysisRecord? get latestDialysis =>
      _dialysisRecords.isNotEmpty ? _dialysisRecords.first : null;

  void addDialysis({
    required DateTime date,
    required double preWeight,
    required double postWeight,
    required int durationMinutes,
    String type = 'HD',
  }) {
    _dialysisRecords.insert(
      0,
      _DialysisRecord(
        date: date,
        preWeight: preWeight,
        postWeight: postWeight,
        durationMinutes: durationMinutes,
        type: type,
      ),
    );
    _save();
    notifyListeners();
  }

  void updateDialysis(int index, {
    DateTime? date,
    double? preWeight,
    double? postWeight,
    int? durationMinutes,
    String? type,
  }) {
    if (index >= 0 && index < _dialysisRecords.length) {
      final old = _dialysisRecords[index];
      _dialysisRecords[index] = _DialysisRecord(
        date: date ?? old.date,
        preWeight: preWeight ?? old.preWeight,
        postWeight: postWeight ?? old.postWeight,
        durationMinutes: durationMinutes ?? old.durationMinutes,
        type: type ?? old.type,
      );
      _save();
      notifyListeners();
    }
  }

  void deleteDialysis(int index) {
    if (index >= 0 && index < _dialysisRecords.length) {
      _dialysisRecords.removeAt(index);
      _save();
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════
  // 饮水管理
  // ═══════════════════════════════════════════════════

  List<_WaterRecord> get waterRecords => List.unmodifiable(_waterRecords);

  double get todayWaterIntake {
    final today = DateTime.now();
    return _waterRecords
        .where((r) =>
            r.time.year == today.year &&
            r.time.month == today.month &&
            r.time.day == today.day)
        .fold<double>(0, (sum, r) => sum + r.amount);
  }

  /// 每日饮水上限 (ml) —— 通常 = 前日尿量 + 500ml
  static const double dailyWaterLimit = 1000;

  double get waterProgress =>
      (todayWaterIntake / dailyWaterLimit).clamp(0.0, 1.5);

  bool get waterOverLimit => todayWaterIntake > dailyWaterLimit;

  void addWater(double amount) {
    _waterRecords.insert(
      0,
      _WaterRecord(time: DateTime.now(), amount: amount),
    );
    _save();
    notifyListeners();
  }

  void updateWater(int index, {double? amount}) {
    if (index >= 0 && index < _waterRecords.length) {
      final old = _waterRecords[index];
      _waterRecords[index] = _WaterRecord(
        time: old.time,
        amount: amount ?? old.amount,
      );
      _save();
      notifyListeners();
    }
  }

  void deleteWater(int index) {
    if (index >= 0 && index < _waterRecords.length) {
      _waterRecords.removeAt(index);
      _save();
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════
  // 饮食（钾 / 磷）
  // ═══════════════════════════════════════════════════

  List<_DietRecord> get dietRecords => List.unmodifiable(_dietRecords);

  List<_DietRecord> get recentDiet {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return _dietRecords.where((r) => r.date.isAfter(cutoff)).toList();
  }

  void addDiet({
    required DateTime date,
    required double potassium,
    required double phosphorus,
  }) {
    _dietRecords.insert(
      0,
      _DietRecord(
        date: date,
        potassium: potassium,
        phosphorus: phosphorus,
      ),
    );
    _save();
    notifyListeners();
  }

  void updateDiet(int index, {DateTime? date, double? potassium, double? phosphorus}) {
    if (index >= 0 && index < _dietRecords.length) {
      final old = _dietRecords[index];
      _dietRecords[index] = _DietRecord(
        date: date ?? old.date,
        potassium: potassium ?? old.potassium,
        phosphorus: phosphorus ?? old.phosphorus,
      );
      _save();
      notifyListeners();
    }
  }

  void deleteDiet(int index) {
    if (index >= 0 && index < _dietRecords.length) {
      _dietRecords.removeAt(index);
      _save();
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════
  // 体重
  // ═══════════════════════════════════════════════════

  double get todayWeight {
    final latest = latestDialysis;
    return latest?.postWeight ?? 65.0;
  }

  static const double dryWeight = 62.0;

  double get weightDeviation => todayWeight - dryWeight;

  // ═══════════════════════════════════════════════════
  // 持久化
  // ═══════════════════════════════════════════════════

  static const _keyDialysis = 'uremia_dialysis';
  static const _keyWater = 'uremia_water';
  static const _keyDiet = 'uremia_diet';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final dialysisRaw = prefs.getString(_keyDialysis);
      if (dialysisRaw != null) {
        final list = jsonDecode(dialysisRaw) as List<dynamic>;
        _dialysisRecords = list
            .map((e) => _DialysisRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _dialysisRecords = _generateDialysisDummy();
      }

      final waterRaw = prefs.getString(_keyWater);
      if (waterRaw != null) {
        final list = jsonDecode(waterRaw) as List<dynamic>;
        _waterRecords = list
            .map((e) => _WaterRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _waterRecords = _generateWaterDummy();
      }

      final dietRaw = prefs.getString(_keyDiet);
      if (dietRaw != null) {
        final list = jsonDecode(dietRaw) as List<dynamic>;
        _dietRecords = list
            .map((e) => _DietRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _dietRecords = _generateDietDummy();
      }

      // 首次运行保存示例数据
      if (dialysisRaw == null) _saveDialysis();
      if (waterRaw == null) _saveWater();
      if (dietRaw == null) _saveDiet();
    } catch (_) {
      _dialysisRecords = _generateDialysisDummy();
      _waterRecords = _generateWaterDummy();
      _dietRecords = _generateDietDummy();
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    await _saveDialysis();
    await _saveWater();
    await _saveDiet();
  }

  Future<void> _saveDialysis() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _keyDialysis, jsonEncode(_dialysisRecords.map((r) => r.toJson()).toList()));
    } catch (e) {
      // 保存失败
    }
  }

  Future<void> _saveWater() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _keyWater, jsonEncode(_waterRecords.map((r) => r.toJson()).toList()));
    } catch (e) {
      // 保存失败
    }
  }

  Future<void> _saveDiet() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _keyDiet, jsonEncode(_dietRecords.map((r) => r.toJson()).toList()));
    } catch (e) {
      // 保存失败
    }
  }

  // ═══════════════════════════════════════════════════
  // 模拟数据生成
  // ═══════════════════════════════════════════════════

  static List<_DialysisRecord> _generateDialysisDummy() {
    final now = DateTime.now();
    return [
      _DialysisRecord(
        date: now.subtract(const Duration(days: 1)),
        preWeight: 67.2,
        postWeight: 64.8,
        durationMinutes: 240,
        type: 'HD',
      ),
      _DialysisRecord(
        date: now.subtract(const Duration(days: 3)),
        preWeight: 67.8,
        postWeight: 65.0,
        durationMinutes: 240,
        type: 'HD',
      ),
      _DialysisRecord(
        date: now.subtract(const Duration(days: 5)),
        preWeight: 67.0,
        postWeight: 64.5,
        durationMinutes: 240,
        type: 'HD',
      ),
      _DialysisRecord(
        date: now.subtract(const Duration(days: 8)),
        preWeight: 68.1,
        postWeight: 65.2,
        durationMinutes: 240,
        type: 'HD',
      ),
    ];
  }

  static List<_WaterRecord> _generateWaterDummy() {
    final now = DateTime.now();
    return [
      _WaterRecord(time: now.subtract(const Duration(hours: 1)), amount: 150),
      _WaterRecord(time: now.subtract(const Duration(hours: 3)), amount: 200),
      _WaterRecord(time: now.subtract(const Duration(hours: 5)), amount: 180),
      _WaterRecord(time: now.subtract(const Duration(hours: 8)), amount: 100),
    ];
  }

  static List<_DietRecord> _generateDietDummy() {
    final now = DateTime.now();
    return [
      _DietRecord(date: now.subtract(const Duration(days: 1)), potassium: 4.5, phosphorus: 1.6),
      _DietRecord(date: now.subtract(const Duration(days: 2)), potassium: 5.1, phosphorus: 1.8),
      _DietRecord(date: now.subtract(const Duration(days: 3)), potassium: 4.2, phosphorus: 1.4),
      _DietRecord(date: now.subtract(const Duration(days: 4)), potassium: 5.4, phosphorus: 1.9),
      _DietRecord(date: now.subtract(const Duration(days: 5)), potassium: 4.0, phosphorus: 1.3),
    ];
  }
}

// ═══════════════════════════════════════════════════════════
// 数据模型
// ═══════════════════════════════════════════════════════════

class _DialysisRecord {
  final DateTime date;
  final double preWeight; // 透前体重 kg
  final double postWeight; // 透后体重 kg
  final int durationMinutes; // 透析时长
  final String type; // HD=血液透析, PD=腹膜透析

  const _DialysisRecord({
    required this.date,
    required this.preWeight,
    required this.postWeight,
    required this.durationMinutes,
    required this.type,
  });

  double get ultrafiltration => preWeight - postWeight;

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'preWeight': preWeight,
        'postWeight': postWeight,
        'durationMinutes': durationMinutes,
        'type': type,
      };

  factory _DialysisRecord.fromJson(Map<String, dynamic> json) {
    return _DialysisRecord(
      date: DateTime.parse(json['date'] as String),
      preWeight: (json['preWeight'] as num).toDouble(),
      postWeight: (json['postWeight'] as num).toDouble(),
      durationMinutes: json['durationMinutes'] as int,
      type: json['type'] as String,
    );
  }
}

class _WaterRecord {
  final DateTime time;
  final double amount; // ml

  const _WaterRecord({required this.time, required this.amount});

  Map<String, dynamic> toJson() => {
        'time': time.toIso8601String(),
        'amount': amount,
      };

  factory _WaterRecord.fromJson(Map<String, dynamic> json) {
    return _WaterRecord(
      time: DateTime.parse(json['time'] as String),
      amount: (json['amount'] as num).toDouble(),
    );
  }
}

class _DietRecord {
  final DateTime date;
  final double potassium; // mmol/L
  final double phosphorus; // mmol/L

  const _DietRecord({
    required this.date,
    required this.potassium,
    required this.phosphorus,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'potassium': potassium,
        'phosphorus': phosphorus,
      };

  factory _DietRecord.fromJson(Map<String, dynamic> json) {
    return _DietRecord(
      date: DateTime.parse(json['date'] as String),
      potassium: (json['potassium'] as num).toDouble(),
      phosphorus: (json['phosphorus'] as num).toDouble(),
    );
  }
}
