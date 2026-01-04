import 'dart:convert';
class DiagnosisRecord {
  final int historyId;
  final int userId;
  final String imageUrl;
  final String? diseaseName;
  final double? confidenceScore;
  final String? resultJson; // Lưu JSON thô
  final DateTime diagnosedAt;

  DiagnosisRecord({
    required this.historyId,
    required this.userId,
    required this.imageUrl,
    this.diseaseName,
    this.confidenceScore,
    this.resultJson,
    required this.diagnosedAt,
  });

  // Factory constructor: Hàm để tạo 1 object từ JSON (Map)
  factory DiagnosisRecord.fromJson(Map<String, dynamic> json) {
    return DiagnosisRecord(
      historyId: json['history_id'],
      userId: json['user_id'],
      imageUrl: json['image_url'],
      diseaseName: json['disease_name'],

      confidenceScore: json['confidence_score'] == null
          ? null
          : double.tryParse(json['confidence_score'].toString()),

      // === [ĐÃ SỬA] Xử lý an toàn cho result_json ===
      // Backend có thể trả về String JSON hoặc đã parse sẵn thành Map
      resultJson: json['result_json'] is Map
          ? jsonEncode(json['result_json']) // Nếu là Map thì chuyển ngược về String
          : json['result_json']?.toString(), // Nếu là String hoặc null
      // ============================================

      diagnosedAt: DateTime.parse(json['diagnosed_at']),
    );
  }
}