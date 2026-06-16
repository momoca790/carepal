import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 模拟用户服务 —— 管理登录状态和疾病配置
///
/// 实际应用中应替换为真实 API 调用。这里使用 SharedPreferences 模拟
/// 持久化的 "用户-疾病" 绑定关系。
class UserService {
  static const _keyUser = 'current_user';
  static const _keyDiseases = 'user_diseases';

  UserService._();

  /// 当前用户名
  static String? _userName;

  /// 当前用户的疾病 ID 列表，如 `['diabetes']`
  static List<String> _diseases = [];

  /// 模拟登录
  ///
  /// 返回该用户注册的疾病列表。
  /// 如果用户是新用户，返回空列表。
  static Future<List<String>> login(String userName) async {
    _userName = userName;

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_keyDiseases);

    if (saved != null) {
      _diseases = List<String>.from(jsonDecode(saved));
    } else {
      _diseases = [];
    }

    await prefs.setString(_keyUser, userName);
    return _diseases;
  }

  /// 给当前用户添加一个疾病
  static Future<void> addDisease(String diseaseId) async {
    if (!_diseases.contains(diseaseId)) {
      _diseases.add(diseaseId);
      await _save();
    }
  }

  /// 移除一个疾病
  static Future<void> removeDisease(String diseaseId) async {
    _diseases.remove(diseaseId);
    await _save();
  }

  /// 当前用户的疾病列表
  static List<String> get diseases => List.unmodifiable(_diseases);

  /// 当前用户名
  static String? get userName => _userName;

  /// 是否已登录
  static bool get isLoggedIn => _userName != null;

  /// 登出
  static Future<void> logout() async {
    _userName = null;
    _diseases = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUser);
    await prefs.remove(_keyDiseases);
  }

  // ── 内部持久化 ──
  static Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDiseases, jsonEncode(_diseases));
  }
}
