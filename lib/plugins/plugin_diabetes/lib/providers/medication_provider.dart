import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 用药提醒 Provider
///
/// 管理糖尿病相关药物列表与每日打卡状态。
/// 每日自动重置（基于 SharedPreferences 中的日期标记）。
/// 支持用户自定义添加/删除药物。
class MedicationProvider extends ChangeNotifier {
  // ── 药物列表（可变，支持增删）──
  List<_Medication> _medications = [];

  List<_Medication> get medications => List.unmodifiable(_medications);

  // ── 今日打卡状态 ──
  // key = "{medicationId}_{timeIndex}"  如 "metformin_0"
  Map<String, bool> _taken = {};

  Map<String, bool> get taken => Map.unmodifiable(_taken);

  /// 已完成的服药剂次
  int get takenCount => _taken.values.where((v) => v).length;

  /// 今日总剂次
  int get totalCount {
    int count = 0;
    for (final med in _medications) {
      count += med.times.length;
    }
    return count;
  }

  /// 完成度 0.0 ~ 1.0
  double get progress => totalCount == 0 ? 0 : takenCount / totalCount;

  /// 全部完成
  bool get allDone => totalCount > 0 && takenCount == totalCount;

  MedicationProvider() {
    _load();
  }

  /// 添加自定义药物
  void addMedication({
    required String name,
    required String dosage,
    required List<String> times,
    IconData icon = Icons.medication,
    Color color = const Color(0xFFFF9800),
  }) {
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    _medications.add(_Medication(
      id: id,
      name: name,
      dosage: dosage,
      times: times,
      icon: icon,
      color: color,
    ));
    _save();
    notifyListeners();
  }

  /// 删除药物（预设药物的 id 不可删）
  void removeMedication(String id) {
    // 预设药物不允许删除
    if (['metformin', 'insulin', 'aspirin'].contains(id)) return;
    _medications.removeWhere((m) => m.id == id);
    // 清理对应打卡状态
    _taken.removeWhere((key, _) => key.startsWith('$id\_'));
    _save();
    notifyListeners();
  }

  /// 切换某药某剂次的打卡状态
  void toggle(String medId, int timeIndex) {
    final key = '${medId}_$timeIndex';
    _taken[key] = !(_taken[key] ?? false);
    _save();
    notifyListeners();
  }

  /// 是否已打卡
  bool isTaken(String medId, int timeIndex) {
    return _taken['${medId}_$timeIndex'] ?? false;
  }

  /// 重置今日打卡（每日凌晨调用）
  void resetDaily() {
    _taken.clear();
    _save();
    notifyListeners();
  }

  // ════════════════════════════════════════════════════
  // 持久化
  // ════════════════════════════════════════════════════

  static const _keyMedications = 'medication_list';
  static const _keyTaken = 'medication_taken';
  static const _keyDate = 'medication_date';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = _dateKey();

      // ── 加载药物列表 ──
      final medRaw = prefs.getString(_keyMedications);
      if (medRaw != null) {
        final list = jsonDecode(medRaw) as List<dynamic>;
        _medications = list
            .map((e) => _Medication.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _medications = _defaultMedications();
        _saveMedications(prefs);
      }

      // ── 加载打卡状态 ──
      final savedDate = prefs.getString(_keyDate);
      if (savedDate != today) {
        _taken = {};
        await prefs.setString(_keyDate, today);
        await prefs.remove(_keyTaken);
      } else {
        final raw = prefs.getString(_keyTaken);
        if (raw != null) {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          _taken = map.map((k, v) => MapEntry(k, v == true));
        }
      }
    } catch (_) {
      _medications = _defaultMedications();
      _taken = {};
    }
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyDate, _dateKey());
      await prefs.setString(_keyTaken, jsonEncode(_taken));
      await _saveMedications(prefs);
    } catch (e) {
      // 保存失败，但不影响主流程
    }
  }

  Future<void> _saveMedications(SharedPreferences prefs) async {
    await prefs.setString(
      _keyMedications,
      jsonEncode(_medications.map((m) => m.toJson()).toList()),
    );
  }

  String _dateKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// 默认药物列表
  static List<_Medication> _defaultMedications() {
    return [
      const _Medication(
        id: 'metformin',
        name: '二甲双胍',
        dosage: '500mg / 片',
        times: ['早餐后', '晚餐后'],
        icon: Icons.medication,
        color: Color(0xFFFF9800),
      ),
      const _Medication(
        id: 'insulin',
        name: '胰岛素注射',
        dosage: '10 单位',
        times: ['早餐前', '晚餐前'],
        icon: Icons.vaccines,
        color: Color(0xFF2196F3),
      ),
      const _Medication(
        id: 'aspirin',
        name: '阿司匹林肠溶片',
        dosage: '100mg / 片',
        times: ['早餐后'],
        icon: Icons.healing,
        color: Color(0xFF4CAF50),
      ),
    ];
  }
}

/// 药物数据模型
class _Medication {
  final String id;
  final String name;
  final String dosage;
  final List<String> times; // 服药时段
  final IconData icon;
  final Color color;

  const _Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.times,
    required this.icon,
    required this.color,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'dosage': dosage,
        'times': times,
        'iconCode': icon.codePoint,
        'color': color.toARGB32(),
      };

  factory _Medication.fromJson(Map<String, dynamic> json) {
    return _Medication(
      id: json['id'] as String,
      name: json['name'] as String,
      dosage: json['dosage'] as String,
      times: List<String>.from(json['times'] as List),
      icon: IconData(
        json['iconCode'] as int,
        fontFamily: 'MaterialIcons',
      ),
      color: Color(json['color'] as int),
    );
  }
}
