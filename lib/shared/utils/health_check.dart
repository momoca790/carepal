/// 健康评估工具
///
/// 共享工具层 —— 所有插件可复用的通用函数
class HealthCheck {
  HealthCheck._();

  /// 血糖评估（mmol/L）
  static String bloodSugar(double value) {
    if (value > 13) return '请及时就医';
    if (value >= 7) return '请注意饮食';
    if (value < 3.9) return '低血糖风险';
    return '状态良好';
  }
}
