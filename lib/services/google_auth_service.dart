// lib/services/google_auth_service.dart
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  // Singleton pattern
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
    serverClientId: '893111338629-rq5j7s1rallibe172340fss3tefrreag.apps.googleusercontent.com.apps.googleusercontent.com',
  );

  /// Đăng nhập Google
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      print('🔵 Bắt đầu đăng nhập Google...');

      // 1. Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('⚠️ User hủy đăng nhập');
        return null; // User canceled
      }

      print('✅ Đăng nhập Google thành công: ${googleUser.email}');

      // 2. Lấy thông tin user
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Trả về data để gửi lên backend
      return {
        'idToken': googleAuth.idToken, // Optional, có thể dùng để verify
        'googleId': googleUser.id,
        'email': googleUser.email,
        'name': googleUser.displayName ?? '',
        'photoUrl': googleUser.photoUrl ?? '',
      };

    } catch (error) {
      print('❌ Lỗi đăng nhập Google: $error');
      throw 'Đăng nhập Google thất bại: $error';
    }
  }

  /// Đăng xuất Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      print('✅ Đã đăng xuất Google');
    } catch (error) {
      print('❌ Lỗi đăng xuất Google: $error');
    }
  }

  /// Kiểm tra đã đăng nhập chưa
  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }
}