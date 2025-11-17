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

class ApiService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService() {
    // Dùng URL từ file config
    _dio.options.baseUrl = AppConfig.baseUrl;
    _dio.options.connectTimeout = const Duration(milliseconds: 10000);
    _dio.options.receiveTimeout = const Duration(milliseconds: 30000);

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
      // ===================================
      return response.data['token'];
    } on DioException catch (e) {
      if (e.response != null) throw e.response!.data['message'];
      throw 'Không thể kết nối đến máy chủ.';
    } catch (e) {
      throw 'Đã xảy ra lỗi không xác định.';
    }
  }

  // API CHẨN ĐOÁN (Giữ nguyên)
  Future<Map<String, dynamic>> diagnose(XFile imageFile) async {
    try {
      String fileName = imageFile.path.split('/').last;
      FormData formData = FormData.fromMap({
        "image": await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        '/diagnose',
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
  Future<List<Map<String, dynamic>>> getAdminUserList(String searchTerm) async { // <-- SỬA 1: Thêm tham số
    try {
      final response = await _dio.get(
        '/admin/users', // <-- SỬA 2: Path là tham số đầu tiên
        queryParameters: {'search': searchTerm}, // <-- SỬA 3: queryParameters là tham số named
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

  
}