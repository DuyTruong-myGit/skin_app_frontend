import 'package:app/screens/login_screen.dart'; // Đổi 'app' nếu tên dự án khác
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // Bộ điều khiển cho PageView
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Hàm được gọi khi nhấn "Bỏ qua" hoặc "Hoàn thành"
  Future<void> _completeOnboarding() async {
    // 1. Lưu lại là đã xem
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    if (!mounted) return;
    // 2. Điều hướng đến Trang Đăng nhập
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Phần 1: Các trang lướt qua (Slides)
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: const [
                  // Slide 1
                  OnboardingPage(
                    icon: Icons.document_scanner_outlined,
                    title: 'Chẩn đoán Nhanh chóng',
                    description: 'Tải ảnh lên và để AI phân tích tình trạng da của bạn chỉ trong vài giây.',
                  ),
                  // Slide 2
                  OnboardingPage(
                    icon: Icons.history_edu_outlined,
                    title: 'Xem Lại Lịch sử',
                    description: 'Dễ dàng theo dõi và xem lại các kết quả chẩn đoán trước đây của bạn.',
                  ),
                  // Slide 3
                  OnboardingPage(
                    icon: Icons.health_and_safety_outlined,
                    title: 'Tham khảo Y tế',
                    description: 'Nhận các khuyến nghị và mô tả tham khảo. (Lưu ý: Luôn tham khảo ý kiến bác sĩ).',
                  ),
                ],
              ),
            ),

            // Phần 2: Dấu chấm và Nút bấm
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Nút Bỏ qua (Chỉ hiện ở 2 slide đầu)
                  _currentPage != 2
                      ? TextButton(
                    onPressed: _completeOnboarding,
                    child: const Text('Bỏ qua'),
                  )
                      : const SizedBox(width: 60), // Giữ chỗ

                  // Dấu chấm (Dots)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) => _buildDot(index)),
                  ),

                  // Nút Tiếp / Hoàn thành
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage == 2) {
                        // Nếu là slide cuối -> Hoàn thành
                        _completeOnboarding();
                      } else {
                        // Nếu là slide 1, 2 -> Sang slide tiếp
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeIn,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
                    ),
                    child: Text(
                      _currentPage == 2 ? 'Bắt đầu' : 'Tiếp',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget con để vẽ dấu chấm
  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: _currentPage == index ? 24 : 8, // Dài hơn nếu được chọn
      decoration: BoxDecoration(
        color: _currentPage == index ? Theme.of(context).primaryColor : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}


// === TÁCH WIDGET CHO MỘT TRANG SLIDE ===
class OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const OnboardingPage({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 120,
            color: Theme.of(context).primaryColor.withOpacity(0.7),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600]
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}