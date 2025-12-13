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
      if (_socket != null && _socket!.connected) {
        return;
      }

      final token = await _storage.read(key: 'token');
      if (token == null) {
        print('❌ Socket: Không tìm thấy token');
        return;
      }

      // === SỬA LỖI TẠI ĐÂY: XỬ LÝ URL ===
      // Lấy URL từ config
      String socketUrl = AppConfig.baseUrl;

      // Nếu URL có đuôi "/api", cắt bỏ đi để về root domain
      // Ví dụ: .../api -> .../
      if (socketUrl.endsWith('/api')) {
        socketUrl = socketUrl.substring(0, socketUrl.length - 4);
      } else if (socketUrl.endsWith('/api/')) {
        socketUrl = socketUrl.substring(0, socketUrl.length - 5);
      }

      print("🔌 Đang kết nối tới Socket URL: $socketUrl");
      // Kết quả mong đợi: https://checkmyhealth-api.onrender.com

      _socket = IO.io(
        socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setAuth({'token': token})
            .setReconnectionAttempts(5)
            .build(),
      );

      _socket!.connect();

      _socket!.onConnect((_) {
        print('✅ Socket Connected ID: ${_socket!.id}');
      });

      _socket!.onDisconnect((_) {
        print('❌ Socket Disconnected');
      });

      // Lắng nghe lỗi kết nối để dễ debug
      _socket!.onConnectError((data) {
        print('❌ Socket Error: $data');
      });

      _socket!.onError((data) {
        print('❌ Socket General Error: $data');
      });

      _socket!.on('watch:update', (data) {
        print('⌚ Nhận dữ liệu từ Watch: $data');
        if (data != null) {
          _watchDataController.add(Map<String, dynamic>.from(data));
        }
      });

    } catch (e) {
      print('❌ Lỗi khởi tạo Socket: $e');
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  void dispose() {
    _watchDataController.close();
  }
}