import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:app/config/app_config.dart'; // Đổi 'app' nếu tên dự án khác
import 'package:app/services/navigation_service.dart'; // Đổi 'app' nếu tên dự án khác
import 'package:app/screens/login_screen.dart'; // Đổi 'app' nếu tên dự án khác
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app/models/diagnosis_record.dart';
import 'package:app/models/chat_message.dart';
import 'dart:convert';
import 'package:app/utils/image_helper.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import 'package:app/services/google_auth_service.dart';
import 'package:app/services/socket_service.dart';
class ApiService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService() {
    // Dùng URL từ file config
    _dio.options.baseUrl = AppConfig.baseUrl;
    _dio.options.connectTimeout = const Duration(milliseconds: 120000);
    _dio.options.receiveTimeout = const Duration(milliseconds: 120000);

    // --- INTERCEPTOR XỬ LÝ LỖI 401 (PRODUCTION-READY) ---
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          print("Lỗi 401: Token hết hạn. Đang đăng xuất...");

          await _storage.delete(key: 'token');

          final context = NavigationService.navigatorKey.currentContext;
          if (context != null && context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
            );
          }
        }
        return handler.next(e);
      },
    ));
    // --- KẾT THÚC INTERCEPTOR ---
  }

  // Hàm private để lấy token và gán vào header
  Future<Options> _getAuthHeaders() async {
    final token = await _storage.read(key: 'token');
    return Options(
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
  }

  // API Đăng ký
  Future<String> register(String fullName, String email, String password) async {
    try {
      // === SỬA LỖI Ở ĐÂY: Thêm data trở lại ===
      final response = await _dio.post(
        '/auth/register',
        data: {
          'fullName': fullName,
          'email': email,
          'password': password,
        },
      );
      // ===================================
      return response.data['message'];
    } on DioException catch (e) {
      if (e.response != null) throw e.response!.data['message'];
      throw 'Không thể kết nối đến máy chủ.';
    } catch (e) {
      throw 'Đã xảy ra lỗi không xác định.';
    }
  }

  // API Đăng nhập
  Future<String> login(String email, String password) async {
    try {
      // === SỬA LỖI Ở ĐÂY: Thêm data trở lại ===
      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );
      return response.data['token'];
    } on DioException catch (e) {
      if (e.response != null) throw e.response!.data['message'];
      throw 'Không thể kết nối đến máy chủ.';
    } catch (e) {
      throw 'Đã xảy ra lỗi không xác định.';
    }
  }

  Future<Map<String, dynamic>> diagnose(XFile imageFile) async {
    try {
      // === 1. RESIZE & COMPRESS ẢNH ===
      print('🔄 Đang xử lý ảnh...');
      File file = File(imageFile.path);

      // Validate kích thước
      bool isValidSize = await ImageHelper.validateFileSize(file);
      if (!isValidSize) {
        throw 'Ảnh quá lớn (>10MB). Vui lòng chọn ảnh khác.';
      }

      // Resize và compress
      File optimizedFile = await ImageHelper.resizeAndCompressImage(file);
      print('✅ Ảnh đã được tối ưu hóa');
      // ================================

      // 2. Chuẩn bị FormData
      String fileName = path.basename(optimizedFile.path);
      FormData formData = FormData.fromMap({
        "image": await MultipartFile.fromFile(
          optimizedFile.path,
          filename: fileName,
        ),
      });

      // 3. Gọi API
      print('📤 Đang gửi ảnh lên server...');
      final response = await _dio.post(
        '/diagnose',
        data: formData,
        options: await _getAuthHeaders(),
      );

      print('✅ Nhận được kết quả từ server');

      // === 4. XỬ LÝ RESPONSE MỚI ===
      final result = response.data as Map<String, dynamic>;

      // Kiểm tra nếu ảnh không hợp lệ
      if (result['success'] == false || result['is_valid_skin_image'] == false) {
        throw result['description'] ?? 'Ảnh không hợp lệ';
      }

      return result;
      // ============================

    } on DioException catch (e) {
      print('❌ DioException: ${e.response?.statusCode}');

      if (e.response != null) {
        // Backend trả về lỗi validation
        final errorData = e.response!.data;

        if (errorData is Map && errorData['message'] != null) {
          throw errorData['message'];
        }

        throw 'Lỗi từ server: ${e.response!.statusCode}';
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw 'Timeout: Server AI đang khởi động. Vui lòng thử lại sau 30 giây.';
      }

      throw 'Không thể kết nối đến máy chủ. Kiểm tra kết nối mạng.';

    } catch (e) {
      print('❌ Error: $e');
      throw 'Đã xảy ra lỗi: $e';
    }
  }

  // === API MỚI: LẤY LỊCH SỬ ===
  // Trả về một List các đối tượng DiagnosisRecord
  Future<List<DiagnosisRecord>> getHistory() async {
    try {
      // 1. Gửi request (đã kèm token)
      final response = await _dio.get(
        '/diagnose/history',
        options: await _getAuthHeaders(), // Lấy header có token
      );

      // 2. Chuyển đổi List<dynamic> (từ JSON) sang List<DiagnosisRecord>
      List<DiagnosisRecord> historyList = (response.data as List)
          .map((item) => DiagnosisRecord.fromJson(item))
          .toList();

      // 3. Trả về danh sách
      return historyList;

    } on DioException catch (e) {
      // Lỗi 401 sẽ được Interceptor xử lý
      if (e.response != null && e.response?.statusCode != 401) {
        throw e.response!.data['message'];
      }
      throw 'Không thể kết nối đến máy chủ.';
    } catch (e) {
      throw 'Đã xảy ra lỗi không xác định: $e';
    }
  }

  /// Lấy thông tin hồ sơ
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _dio.get(
        '/profile',
        options: await _getAuthHeaders(),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response != null && e.response?.statusCode != 401) {
        throw e.response!.data['message'];
      }
      throw 'Không thể kết nối đến máy chủ.';
    } catch (e) {
      throw 'Đã xảy ra lỗi không xác định.';
    }
  }

  /// Cập nhật hồ sơ (fullName)
  Future<String> updateProfile(String fullName) async {
    try {
      final response = await _dio.put(
        '/profile',
        data: {'fullName': fullName},
        options: await _getAuthHeaders(),
      );
      return response.data['message']; // "Cập nhật hồ sơ thành công."
    } on DioException catch (e) {
      if (e.response != null && e.response?.statusCode != 401) {
        throw e.response!.data['message'];
      }
      throw 'Không thể kết nối đến máy chủ.';
    } catch (e) {
      throw 'Đã xảy ra lỗi không xác định.';
    }
  }

  /// Yêu cầu gửi mã reset
  Future<String> requestPasswordReset() async {
    try {
      final response = await _dio.post(
        '/auth/request-password-reset',
        options: await _getAuthHeaders(),
      );
      return response.data['message']; // "Đã gửi mã..."
    } on DioException catch (e) {
      if (e.response != null && e.response?.statusCode != 401) {
        throw e.response!.data['message'];
      }
      throw 'Không thể kết nối đến máy chủ.';
    } catch (e) {
      throw 'Đã xảy ra lỗi không xác định.';
    }
  }

  /// Gửi mã 6 số và mật khẩu mới
  Future<String> resetPasswordWithCode(String code, String newPassword) async {
    try {
      final response = await _dio.post(
        '/auth/reset-password-with-code',
        data: {
          'code': code,
          'newPassword': newPassword,
        },
        options: await _getAuthHeaders(), // Phải đăng nhập để làm việc này
      );
      return response.data['message']; // "Đổi mật khẩu thành công!"
    } on DioException catch (e) {
      if (e.response != null && e.response?.statusCode != 401) {
        throw e.response!.data['message'];
      }
      throw 'Không thể kết nối đến máy chủ.';
    } catch (e) {
      throw 'Đã xảy ra lỗi không xác định.';
    }
  }

  Future<Map<String, dynamic>> getAdminStatistics() async {
    try {
      final response = await _dio.get(
        '/admin/statistics',
        options: await _getAuthHeaders(), // Đã có auth + admin check
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response != null && e.response?.statusCode != 401) {
        throw e.response!.data['message'];
      }
      throw 'Không thể kết nối đến máy chủ.';
    } catch (e) {
      throw 'Đã xảy ra lỗi không xác định.';
    }
  }

  /// (Admin) Lấy danh sách user (CÓ TÌM KIẾM)
  Future<List<Map<String, dynamic>>> getAdminUserList(String searchTerm) async {
    try {
      final response = await _dio.get(
        '/admin/users',
        queryParameters: {'search': searchTerm},
        options: await _getAuthHeaders(),
      );

      // === SỬA LỖI TẠI ĐÂY ===
      // Backend trả về { "items": [...], "total": ... }
      // Nên ta phải lấy response.data['items']
      final data = response.data;
      if (data is Map<String, dynamic> && data['items'] != null) {
        return List<Map<String, dynamic>>.from(data['items']);
      } else {
        // Fallback: Nếu backend thay đổi hoặc trả về mảng trực tiếp (đề phòng)
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return []; // Trả về rỗng nếu không đúng định dạng
      }
      // =======================

    } on DioException catch (e) {
      if (e.response != null && e.response?.statusCode != 401) {
        throw e.response!.data['message'];
      }
      throw 'Không thể kết nối đến máy chủ.';
    } catch (e) {
      print("Lỗi getAdminUserList: $e"); // In log để dễ debug
      throw 'Đã xảy ra lỗi không xác định: $e'; // Hiển thị chi tiết lỗi nếu cần
    }
  }

  /// (Admin) Lấy lịch sử của user cụ thể
  Future<List<DiagnosisRecord>> getAdminHistoryForUser(int userId) async {
    try {
      final response = await _dio.get(
        '/admin/history/$userId', // <-- Route mới
        options: await _getAuthHeaders(),
      );

      List<DiagnosisRecord> historyList = (response.data as List)
          .map((item) => DiagnosisRecord.fromJson(item))
          .toList();
      return historyList;

    } on DioException catch (e) {
      if (e.response != null && e.response?.statusCode != 401) {
        throw e.response!.data['message'];
      }
      throw 'Không thể kết nối đến máy chủ.';
    } catch (e) {
      throw 'Đã xảy ra lỗi không xác định: $e';
    }
  }

  // === HÀM MỚI: XÓA LỊCH SỬ CHẨN ĐOÁN ===
  Future<void> deleteDiagnosisHistory(int historyId) async {
    try {
      await _dio.delete(
        '/diagnose/$historyId',
        options: await _getAuthHeaders(),
      );
    } on DioException catch (e) {
      if (e.response != null) throw e.response!.data['message'];
      throw 'Lỗi xóa lịch sử';
    }
  }

  /// (Admin) Cập nhật trạng thái
  Future<String> updateUserStatus(int userId, String status) async {
    try {
      final response = await _dio.put(
        '/admin/users/$userId/status',
        data: {'status': status},
        options: await _getAuthHeaders(),
      );
      return response.data['message'];
    } on DioException catch (e) {
      if (e.response != null && e.response?.statusCode != 401) {
        throw e.response!.data['message'];
      }
      throw 'Không thể kết nối đến máy chủ.';
    } catch (e) {
      throw 'Đã xảy ra lỗi không xác định.';
    }
  }

  /// (Admin) Cập nhật quyền
  Future<String> updateUserRole(int userId, String role) async {
    try {
      final response = await _dio.put(
        '/admin/users/$userId/role',
        data: {'role': role},
        options: await _getAuthHeaders(),
      );
      return response.data['message'];
    } on DioException catch (e) {
      if (e.response != null && e.response?.statusCode != 401) {
        throw e.response!.data['message'];
      }
      throw 'Không thể kết nối đến máy chủ.';
    } catch (e) {
      throw 'Đã xảy ra lỗi không xác định.';
    }
  }

  /// (Admin) Xóa user
  Future<String> deleteUser(int userId) async {
    try {
      final response = await _dio.delete(
        '/admin/users/$userId',
        options: await _getAuthHeaders(),
      );
      return response.data['message'];
    } on DioException catch (e) {
      if (e.response != null && e.response?.statusCode != 401) {
        throw e.response!.data['message'];
      }
      throw 'Không thể kết nối đến máy chủ.';
    } catch (e) {
      throw 'Đã xảy ra lỗi không xác định.';
    }
  }

  // === HÀM MỚI 1: UPLOAD AVATAR ===
  /// (User) Tải lên ảnh đại diện
  Future<Map<String, dynamic>> uploadAvatar(XFile imageFile) async {
    try {
      String fileName = imageFile.path.split('/').last;
      FormData formData = FormData.fromMap({
        "image": await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      final response = await _dio.put(
        '/profile/avatar',
        data: formData,
        options: await _getAuthHeaders(),
      );

      return response.data as Map<String, dynamic>;

    } on DioException catch (e) {
      if (e.response != null && e.response?.statusCode != 401) {
        throw e.response!.data['message'];
      }
      throw 'Không thể kết nối đến máy chủ.';
    } catch (e) {
      throw 'Đã xảy ra lỗi không xác định: $e';
    }
  }


  /// (User) Gửi Phản hồi
  Future<String> submitFeedback(String feedbackType, String content) async {
    try {
      final response = await _dio.post(
        '/feedback',
        data: {
          'feedback_type': feedbackType,
          'content': content
        },
        options: await _getAuthHeaders(), // Yêu cầu đăng nhập
      );
      return response.data['message']; // "Cảm ơn bạn!..."
    } on DioException catch (e) {
      if (e.response != null && e.response?.statusCode != 401) {
        throw e.response!.data['message'];
      }
      throw 'Không thể kết nối đến máy chủ.';
    } catch (e) {
      throw 'Đã xảy ra lỗi không xác định.';
    }
  }

  /// Xóa tất cả token và điều hướng về trang Đăng nhập
  Future<void> logout() async {
    SocketService().disconnect();
    // 1. Xóa tất cả dữ liệu an toàn
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'role');
    await _storage.delete(key: 'userId');

    // 2. Lấy context toàn cục (từ NavigationService)
    final context = NavigationService.navigatorKey.currentContext;

    // 3. Điều hướng về Login
    if (context != null && context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false, // Xóa tất cả màn hình cũ
      );
    }
  }

// === SỬA HÀM CHATBOT ĐỂ NHẬN STREAM ===

  /// (User) Gửi tin nhắn Chatbot (Streaming)
  Stream<String> sendMessageToGemini(String message) async* {
    try {
      final token = await _storage.read(key: 'token');

      // Sử dụng ResponseType.stream
      final response = await _dio.post(
        '/chat', // Endpoint vẫn là POST
        data: {'message': message},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          responseType: ResponseType.stream, // <-- Yêu cầu Dio trả về Stream
        ),
      );

      // Lắng nghe stream từ ResponseBody
      // Dùng utf8.decode để xử lý các mẩu data (Uint8List)
      await for (final chunk in response.data!.stream) {
        yield utf8.decode(chunk); // Gửi từng mẩu text về App
      }

    } catch (e) {
      // Nếu có lỗi, ném (throw) lỗi để StreamBuilder bắt được
      print("Lỗi Stream: $e");
      throw Exception('Lỗi kết nối hoặc server AI gặp sự cố.');
    }
  }

  /// (User) Lấy Lịch sử Chat
  Future<List<ChatMessage>> getChatHistory() async {
    try {
      final response = await _dio.get(
        '/chat/history',
        options: await _getAuthHeaders(),
      );

      // Chuyển đổi List<dynamic> (JSON) sang List<ChatMessage>
      List<ChatMessage> chatList = (response.data as List)
          .map((item) => ChatMessage(
        text: item['content'],
        isUser: item['role'] == 'user',
      ))
          .toList();

      return chatList;

    } on DioException catch (e) {
      if (e.response != null && e.response?.statusCode != 401) {
        throw e.response!.data['message'];
      }
      throw 'Không thể kết nối đến máy chủ.';
    } catch (e) {
      throw 'Đã xảy ra lỗi không xác định.';
    }
  }


  /// (Public) Yêu cầu gửi mã reset (khi quên)
  Future<String> publicRequestPasswordReset(String email) async {
    try {
      final response = await _dio.post(
        '/auth/public-forgot-password',
        data: {'email': email},
        // KHÔNG CẦN HEADER AUTH
      );
      return response.data['message']; // "Đã gửi mã..."
    } on DioException catch (e) {
      if (e.response != null) throw e.response!.data['message'];
      throw 'Không thể kết nối đến máy chủ.';
    } catch (e) {
      throw 'Đã xảy ra lỗi không xác định.';
    }
  }

  /// (Public) Gửi mã 6 số và mật khẩu mới (khi quên)
  Future<String> publicResetPasswordWithCode(String email, String code, String newPassword) async {
    try {
      final response = await _dio.post(
        '/auth/public-reset-password',
        data: {
          'email': email,
          'code': code,
          'newPassword': newPassword,
        },
        // KHÔNG CẦN HEADER AUTH
      );
      return response.data['message']; // "Đổi mật khẩu thành công!"
    } on DioException catch (e) {
      if (e.response != null) throw e.response!.data['message'];
      throw 'Không thể kết nối đến máy chủ.';
    } catch (e) {
      throw 'Đã xảy ra lỗi không xác định.';
    }
  }



  /// (Admin) Lấy danh sách feedback
  Future<List<Map<String, dynamic>>> getAdminFeedbackList() async {
    try {
      final response = await _dio.get(
        '/admin/feedback',
        options: await _getAuthHeaders(),
      );
      // Trả về List<Map>
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      if (e.response != null && e.response?.statusCode != 401) {
        throw e.response!.data['message'];
      }
      throw 'Không thể kết nối đến máy chủ.';
    } catch (e) {
      throw 'Đã xảy ra lỗi không xác định.';
    }
  }

  // === API MỚI: NEWS ===

  /// Lấy danh sách các nguồn tin (VnExpress, v.v.)
  Future<List<Map<String, dynamic>>> getNewsSources() async {
    try {
      final response = await _dio.get('/news/sources'); // Không cần auth
      return List<Map<String, dynamic>>.from(response.data['data']);
    } on DioException catch (e) {
      if (e.response != null) throw e.response!.data['message'];
      throw 'Không thể kết nối đến máy chủ.';
    } catch (e) {
      throw 'Đã xảy ra lỗi không xác định.';
    }
  }

  /// Cạo (scrape) bài viết từ một URL cụ thể
  Future<List<Map<String, dynamic>>> scrapeNews(String newsUrl) async {
    try {
      final response = await _dio.get(
        '/news/scrape',
        queryParameters: {'url': newsUrl}, // Gửi URL qua query param
      );
      return List<Map<String, dynamic>>.from(response.data['articles']);
    } on DioException catch (e) {
      if (e.response != null) throw e.response!.data['message'];
      throw 'Không thể kết nối đến máy chủ.';
    } catch (e) {
      throw 'Đã xảy ra lỗi không xác định.';
    }
  }

  // --- ADMIN FEEDBACK ---

  Future<String> deleteFeedback(int feedbackId) async {
    try {
      final response = await _dio.delete(
        '/admin/feedback/$feedbackId',
        options: await _getAuthHeaders(),
      );
      return response.data['message'];
    } on DioException catch (e) {
      if (e.response != null) throw e.response!.data['message'];
      throw 'Lỗi kết nối';
    }
  }

  Future<String> updateFeedbackStatus(int feedbackId, String status) async {
    try {
      final response = await _dio.put(
        '/admin/feedback/$feedbackId/status',
        data: {'status': status},
        options: await _getAuthHeaders(),
      );
      return response.data['message'];
    } on DioException catch (e) {
      if (e.response != null) throw e.response!.data['message'];
      throw 'Lỗi kết nối';
    }
  }

  // --- NOTIFICATIONS ---

  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final response = await _dio.get(
        '/notifications',
        options: await _getAuthHeaders(),
      );
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw 'Lỗi tải thông báo';
    }
  }

  // Hàm đánh dấu đã đọc (tùy chọn dùng sau)
  Future<void> markNotificationRead(int id) async {
    await _dio.put('/notifications/$id/read', options: await _getAuthHeaders());
  }



  // --- BỆNH LÝ (DISEASES) ---

  // Lấy danh sách (có search)
  Future<List<Map<String, dynamic>>> getDiseases({String search = ''}) async {
    try {
      final response = await _dio.get(
        '/diseases',
        queryParameters: {'search': search},
        options: await _getAuthHeaders(),
      );
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw 'Lỗi tải danh sách bệnh';
    }
  }

  // Lấy chi tiết
  Future<Map<String, dynamic>> getDiseaseDetail(int id) async {
    try {
      final response = await _dio.get('/diseases/$id', options: await _getAuthHeaders());
      return response.data;
    } on DioException catch (e) {
      throw 'Lỗi tải chi tiết bệnh';
    }
  }

  // (Admin) Tạo mới
  Future<void> createDisease(Map<String, dynamic> data) async {
    try {
      await _dio.post('/diseases', data: data, options: await _getAuthHeaders());
    } on DioException catch (e) {
      if (e.response != null) throw e.response!.data['message']; // Báo lỗi duplicate code chẳng hạn
      throw 'Lỗi tạo bệnh';
    }
  }

  // (Admin) Cập nhật
  Future<void> updateDisease(int id, Map<String, dynamic> data) async {
    try {
      await _dio.put('/diseases/$id', data: data, options: await _getAuthHeaders());
    } on DioException catch (e) {
      throw 'Lỗi cập nhật';
    }
  }

  // (Admin) Xóa
  Future<void> deleteDisease(int id) async {
    try {
      await _dio.delete('/diseases/$id', options: await _getAuthHeaders());
    } on DioException catch (e) {
      throw 'Lỗi xóa';
    }
  }



  // --- LỊCH TRÌNH (SCHEDULES) ---
  // --- LỊCH TRÌNH (SCHEDULES) ---

  /// 1. Tạo lịch trình mới
  Future<int> createSchedule(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(
          '/schedules',
          data: data,
          options: await _getAuthHeaders()
      );

      // Backend trả về: { message: '...', id: X }
      // Lấy id từ response (có thể là 'id' hoặc 'insertId')
      return response.data['id'] ?? response.data['insertId'] ?? 0;

    } on DioException catch (e) {
      if (e.response != null) {
        throw e.response!.data['message'] ?? 'Lỗi tạo lịch trình';
      }
      throw 'Không thể kết nối đến máy chủ.';
    }
  }

  /// 2. Cập nhật lịch trình
  Future<void> updateSchedule(int id, Map<String, dynamic> data) async {
    try {
      await _dio.put(
          '/schedules/$id',
          data: data,
          options: await _getAuthHeaders()
      );
    } on DioException catch (e) {
      if (e.response != null) {
        throw e.response!.data['message'] ?? 'Lỗi cập nhật lịch trình';
      }
      throw 'Không thể kết nối đến máy chủ.';
    }
  }

  /// 3. Lấy danh sách công việc theo ngày
  Future<List<Map<String, dynamic>>> getDailyTasks(DateTime date) async {
    try {
      // Format ngày: YYYY-MM-DD
      String dateStr = DateFormat('yyyy-MM-dd').format(date);

      // Chuyển đổi thứ: Dart (1=Mon..7=Sun) -> Backend (2=T2..8=CN)
      int dayOfWeek = date.weekday == 7 ? 8 : date.weekday + 1;

      final response = await _dio.get(
        '/schedules/daily',
        queryParameters: {
          'date': dateStr,
          'dayOfWeek': dayOfWeek.toString()
        },
        options: await _getAuthHeaders(),
      );

      // Backend trả về array trực tiếp
      return List<Map<String, dynamic>>.from(response.data);

    } on DioException catch (e) {
      print("❌ Get Daily Tasks Error: ${e.message}");
      // Trả về list rỗng thay vì throw để UI không crash
      return [];
    }
  }

  /// 4. Toggle trạng thái hoàn thành
  Future<void> toggleTask(int scheduleId, DateTime date, bool isCompleted) async {
    try {
      String dateStr = DateFormat('yyyy-MM-dd').format(date);

      await _dio.put(
        '/schedules/$scheduleId/toggle',
        data: {
          'date': dateStr,
          'status': isCompleted ? 'completed' : 'pending'
        },
        options: await _getAuthHeaders(),
      );
    } on DioException catch (e) {
      if (e.response != null) {
        throw e.response!.data['message'] ?? 'Lỗi cập nhật trạng thái';
      }
      throw 'Không thể kết nối đến máy chủ.';
    }
  }

  /// 5. Xóa lịch trình
  Future<void> deleteSchedule(int id) async {
    try {
      await _dio.delete(
          '/schedules/$id',
          options: await _getAuthHeaders()
      );
    } on DioException catch (e) {
      if (e.response != null) {
        throw e.response!.data['message'] ?? 'Lỗi xóa lịch';
      }
      throw 'Không thể kết nối đến máy chủ.';
    }
  }

  /// 6. Lấy tất cả lịch trình (không filter theo ngày)
  Future<List<Map<String, dynamic>>> getAllSchedules() async {
    try {
      final response = await _dio.get(
        '/schedules/all',
        options: await _getAuthHeaders(),
      );
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      print("❌ Get All Schedules Error: ${e.message}");
      return [];
    }
  }

  /// 7. Lấy thống kê
  Future<Map<String, dynamic>> getScheduleStats() async {
    try {
      final response = await _dio.get(
        '/schedules/stats',
        options: await _getAuthHeaders(),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      return {'total_logs': 0, 'completed_count': 0};
    }
  }


  /// API Đăng nhập Google
  Future<String> googleLoginMobile(Map<String, dynamic> googleData) async {
    try {
      final response = await _dio.post(
        '/auth/google/mobile',
        data: googleData,
      );

      // Kiểm tra response
      if (response.data['success'] == false) {
        throw response.data['message'] ?? 'Đăng nhập thất bại';
      }

      // Lưu provider để biết user đăng nhập bằng cách nào
      await _storage.write(key: 'auth_provider', value: 'google');

      return response.data['token'];

    } on DioException catch (e) {
      if (e.response != null) {
        throw e.response!.data['message'] ?? 'Lỗi đăng nhập Google';
      }
      throw 'Không thể kết nối đến máy chủ.';
    } catch (e) {
      throw 'Đã xảy ra lỗi không xác định: $e';
    }
  }

  /// Cập nhật logout để xử lý Google Sign-Out
  Future<void> logoutWithGoogle() async {
    // 1. Kiểm tra provider
    final provider = await _storage.read(key: 'auth_provider');

    // 2. Nếu đăng nhập bằng Google, logout khỏi Google
    if (provider == 'google') {
      try {
        await GoogleAuthService().signOut();
      } catch (e) {
        print('Lỗi đăng xuất Google: $e');
      }
    }

    // 3. Xóa dữ liệu local
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'role');
    await _storage.delete(key: 'userId');
    await _storage.delete(key: 'auth_provider');

    // 4. Điều hướng về Login
    final context = NavigationService.navigatorKey.currentContext;
    if (context != null && context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    }
  }


  // === HÀM MỚI: ĐỔI MẬT KHẨU (LOGIC MỚI) ===
  Future<String> changePassword(String oldPassword, String newPassword) async {
    try {
      final response = await _dio.post(
        '/auth/change-password',
        data: {
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        },
        options: await _getAuthHeaders(), // Yêu cầu token
      );
      return response.data['message']; // "Đổi mật khẩu thành công!"
    } on DioException catch (e) {
      if (e.response != null) {
        throw e.response!.data['message'] ?? 'Lỗi đổi mật khẩu';
      }
      throw 'Không thể kết nối đến máy chủ.';
    } catch (e) {
      throw 'Đã xảy ra lỗi không xác định.';
    }
  }



  // Cập nhật FCM Token
  Future<void> updateFcmToken(String token) async {
    try {
      await _dio.put(
        '/profile/fcm-token',
        data: {'fcmToken': token},
        options: await _getAuthHeaders(),
      );
      print("✅ Đã cập nhật FCM Token lên server");
    } catch (e) {
      print("❌ Lỗi cập nhật FCM Token: $e");
    }
  }



  // 1. Liên kết đồng hồ
  Future<String> linkWatch(String deviceId) async {
    try {
      final response = await _dio.post(
        '/watch/link',
        data: {'deviceId': deviceId},
        options: await _getAuthHeaders(),
      );
      return response.data['message'];
    } on DioException catch (e) {
      if (e.response != null) throw e.response!.data['message'];
      throw 'Lỗi kết nối server';
    }
  }

  // 2. Lấy dữ liệu đo mới nhất từ Watch
  Future<Map<String, dynamic>?> getLatestWatchData() async {
    try {
      final response = await _dio.get(
        '/watch/measurements/latest',
        options: await _getAuthHeaders(),
      );
      return response.data;
    } on DioException catch (e) {
      // 404 nghĩa là chưa có dữ liệu đo nào
      if (e.response?.statusCode == 404) return null;
      throw 'Lỗi tải dữ liệu watch';
    }
  }

  // === 3. Lấy dữ liệu chi tiết hôm nay (Để vẽ biểu đồ) ===
  Future<List<Map<String, dynamic>>> getTodayMeasurements() async {
    try {
      final response = await _dio.get(
        '/watch/measurements/today', // Backend đã có route này
        options: await _getAuthHeaders(),
      );
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      print("Lỗi lấy dữ liệu hôm nay: $e");
      return [];
    }
  }

  // === 4. Lấy thống kê tổng hợp (Trung bình, Max, Min) ===
  Future<Map<String, dynamic>> getDailyStatistics() async {
    try {
      final response = await _dio.get(
        '/watch/measurements/stats', // Backend đã có route này
        queryParameters: {'period': 'today'}, // Lấy thống kê hôm nay
        options: await _getAuthHeaders(),
      );
      return response.data['summary'];
    } catch (e) {
      print("Lỗi lấy thống kê: $e");
      return {};
    }
  }

  // [MỚI] Hủy liên kết đồng hồ
  Future<String> unlinkWatch() async {
    try {
      final response = await _dio.post(
        '/watch/unlink',
        options: await _getAuthHeaders(),
      );
      return response.data['message']; // "Đã hủy kết nối..."
    } on DioException catch (e) {
      if (e.response != null) throw e.response!.data['message'];
      throw 'Lỗi kết nối server';
    }
  }



}


