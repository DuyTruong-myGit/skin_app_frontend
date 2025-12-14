import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:app/config/app_config.dart';
import 'dart:async';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final _watchDataController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get watchDataStream => _watchDataController.stream;
  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    try {
      // Nếu đang kết nối thì thôi
      if (_socket != null && _socket!.connected) return;

      final token = await _storage.read(key: 'token');
      if (token == null) {
        print('❌ SOCKET DEBUG: Không tìm thấy token');
        return;
      }

      // 1. Xử lý URL (Cắt bỏ /api nếu có)
      String socketUrl = AppConfig.baseUrl;
      if (socketUrl.endsWith('/api')) {
        socketUrl = socketUrl.substring(0, socketUrl.length - 4);
      } else if (socketUrl.endsWith('/api/')) {
        socketUrl = socketUrl.substring(0, socketUrl.length - 5);
      }

      print("🔌 SOCKET DEBUG: Đang kết nối tới: $socketUrl");
      print("🔑 SOCKET DEBUG: Token (4 ký tự đầu): ${token.substring(0, 4)}...");

      // 2. Cấu hình Socket tối ưu cho Render (HTTPS)
      _socket = IO.io(
        socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setAuth({'token': token})
        // Tăng số lần thử lại
            .setReconnectionAttempts(10)
        // Tăng thời gian chờ (Timeout) lên 20 giây để tránh bị ngắt kết nối sớm
            .setTimeout(20000)
        // Bật tính năng tự động kết nối lại
            .enableReconnection()
            .build(),
      );

      // 3. Kết nối
      _socket!.connect();

      // --- 4. LẮNG NGHE LOG ---
      _socket!.onConnect((_) {
        print('✅ SOCKET DEBUG: KẾT NỐI THÀNH CÔNG! (ID: ${_socket!.id})');
      });

      _socket!.onDisconnect((_) {
        print('❌ SOCKET DEBUG: Mất kết nối');
      });

      _socket!.onConnectError((data) {
        print('❌ SOCKET DEBUG: Lỗi kết nối (Connect Error): $data');
      });

      _socket!.onError((data) {
        print('❌ SOCKET DEBUG: Lỗi chung (Error): $data');
      });

      // Lắng nghe dữ liệu
      _socket!.on('watch:update', (data) {
        print('⚡ SOCKET DEBUG: Nhận dữ liệu WATCH: $data');
        if (data != null) {
          _watchDataController.add(Map<String, dynamic>.from(data));
        }
      });

    } catch (e) {
      print('❌ SOCKET DEBUG: Exception khi khởi tạo: $e');
    }
  }

  void disconnect() {
    print('🔌 SOCKET DEBUG: Đang ngắt kết nối...');
    _socket?.disconnect();
    _socket = null;
  }

  void dispose() {
    _watchDataController.close();
  }
}