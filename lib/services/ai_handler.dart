import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class AiHandler {
  static final AiHandler _instance = AiHandler._internal();
  factory AiHandler() => _instance;
  AiHandler._internal();

  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isLoaded = false;

  static const int INPUT_SIZE = 224;
  static const int NUM_CLASSES = 12;

  Future<void> loadModel() async {
    if (_isLoaded) return;
    try {
      final options = InterpreterOptions();
      _interpreter = await Interpreter.fromAsset(
        'assets/models/best_float32.tflite',
        options: options,
      );

      final labelData = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelData.split('\n').where((s) => s.trim().isNotEmpty).toList();

      _isLoaded = true;
      print("✅ AI Model Loaded Successfully!");
    } catch (e) {
      print("❌ Lỗi load model: $e");
      throw Exception("Không thể khởi động AI: $e");
    }
  }

  // --- HÀM SOFTMAX: Chuyển Logits thành % ---
  List<double> _softmax(List<double> logits) {
    // 1. Tìm giá trị lớn nhất để ổn định số học (tránh tràn số)
    double maxLogit = logits.reduce(max);

    // 2. Tính exp (e mũ x)
    List<double> exps = logits.map((x) => exp(x - maxLogit)).toList();

    // 3. Tính tổng
    double sumExps = exps.reduce((a, b) => a + b);

    // 4. Chia để lấy xác suất
    return exps.map((e) => e / sumExps).toList();
  }

  Future<Map<String, dynamic>> predictDisease(File imageFile) async {
    if (!_isLoaded) await loadModel();

    try {
      final imageBytes = await imageFile.readAsBytes();
      img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) throw "Không thể đọc ảnh";

      // Resize
      img.Image resizedImage = img.copyResize(
          originalImage,
          width: INPUT_SIZE,
          height: INPUT_SIZE
      );

      // Normalize Input (0-1)
      var input = List.generate(1, (i) => List.generate(INPUT_SIZE, (y) => List.generate(INPUT_SIZE, (x) {
        var pixel = resizedImage.getPixel(x, y);
        return [
          pixel.r / 255.0,
          pixel.g / 255.0,
          pixel.b / 255.0
        ];
      })));

      var output = List.filled(1 * NUM_CLASSES, 0.0).reshape([1, NUM_CLASSES]);

      // Run Model
      _interpreter!.run(input, output);

      // Lấy kết quả thô (Logits)
      List<double> rawLogits = List<double>.from(output[0]);

      // --- SỬA LỖI Ở ĐÂY: ÁP DỤNG SOFTMAX ---
      List<double> probabilities = _softmax(rawLogits);

      // Tìm max score từ danh sách xác suất đã chuẩn hóa
      double maxScore = -1.0;
      int maxIndex = -1;

      for (int i = 0; i < probabilities.length; i++) {
        if (probabilities[i] > maxScore) {
          maxScore = probabilities[i];
          maxIndex = i;
        }
      }

      String className = "Unknown";
      if (maxIndex >= 0 && maxIndex < _labels.length) {
        className = _labels[maxIndex];
      }

      // Filter
      if (maxScore < 0.25) {
        className = "Unknown_Normal";
      }

      print("🔍 AI Prediction: $className (${(maxScore * 100).toStringAsFixed(2)}%)");

      return {
        "class": className,
        "confidence": maxScore, // Giá trị này giờ là 0.0 -> 1.0 chuẩn
        "confidence_percent": "${(maxScore * 100).toStringAsFixed(2)}%",
        "is_detected": true,
        "raw_probabilities": probabilities
      };

    } catch (e) {
      print("❌ Lỗi dự đoán: $e");
      return {
        "class": "Unknown_Normal",
        "confidence": 0.0,
        "is_detected": false,
        "error": e.toString()
      };
    }
  }

  void close() {
    _interpreter?.close();
    _isLoaded = false;
  }
}