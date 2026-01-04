class AppConfig {
  // 1. Chuyển sang `true` khi bạn build app để deploy
  static const bool isProduction = true;

  // 2. Định nghĩa 2 URL
  static const String devBaseUrl = 'http://10.0.2.2:3000/api';

  //static const String devBaseUrl = 'http://10.107.50.209:3000/api';


  static const String prodBaseUrl = 'https://checkmyhealth-skindetect.onrender.com/api';
  //static const String prodBaseUrl = 'https://checkmyhealth-api.onrender.com/api';


  // 3. Hàm getter tự động chọn URL
  static String get baseUrl {
    return isProduction ? prodBaseUrl : devBaseUrl;
  }
}