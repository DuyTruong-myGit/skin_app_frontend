import 'package:flutter/material.dart';
import 'package:app/services/api_service.dart';

class ProfileProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _profileData;
  bool _isLoading = false;

  Map<String, dynamic>? get profileData => _profileData;
  bool get isLoading => _isLoading;

  ProfileProvider() {
    loadProfile(); // Tải hồ sơ ngay khi provider được tạo
  }

  Future<void> loadProfile() async {
    _isLoading = true;
    notifyListeners();
    try {
      _profileData = await _apiService.getProfile();
    } catch (e) {
      print("Lỗi tải profile: $e");
    }
    _isLoading = false;
    notifyListeners();
  }

  // Hàm này được gọi từ ProfileScreen sau khi upload
  void updateAvatarUrl(String? newAvatarUrl) {
    if (_profileData != null) {
      _profileData!['avatar_url'] = newAvatarUrl;
      notifyListeners(); // Thông báo cho mọi màn hình đang nghe
    }
  }
}