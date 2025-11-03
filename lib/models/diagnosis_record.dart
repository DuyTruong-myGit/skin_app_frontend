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

      // === SỬA LỖI Ở ĐÂY ===
      // Chuyển đổi an toàn:
      // 1. Kiểm tra null
      // 2. Chuyển sang String (dù là String hay num)
      // 3. Dùng tryParse (an toàn) để chuyển sang double
      confidenceScore: json['confidence_score'] == null
          ? null
          : double.tryParse(json['confidence_score'].toString()),
      // =======================

      resultJson: json['result_json'],
      diagnosedAt: DateTime.parse(json['diagnosed_at']),
    );
  }
}