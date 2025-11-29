import 'package:flutter/material.dart';
import 'package:app/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class DiseaseDetailScreen extends StatefulWidget {
  final int diseaseId;
  final String diseaseName;

  const DiseaseDetailScreen({super.key, required this.diseaseId, required this.diseaseName});

  @override
  State<DiseaseDetailScreen> createState() => _DiseaseDetailScreenState();
}

class _DiseaseDetailScreenState extends State<DiseaseDetailScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = _apiService.getDiseaseDetail(widget.diseaseId);
  }

  Future<void> _openMapSearch(String query) async {
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Không thể mở bản đồ';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  void _showMapOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tìm cơ sở y tế gần bạn',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.local_pharmacy, color: Colors.green, size: 30),
              title: const Text('Tìm Nhà thuốc gần nhất'),
              subtitle: const Text('Mua thuốc bôi, thuốc uống thông thường'),
              onTap: () {
                Navigator.pop(context);
                _openMapSearch('Nhà thuốc gần đây');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.local_hospital, color: Colors.red, size: 30),
              title: const Text('Tìm Phòng khám Da liễu'),
              subtitle: const Text('Khám chuyên sâu với bác sĩ'),
              onTap: () {
                Navigator.pop(context);
                _openMapSearch('Bệnh viện da liễu gần đây');
              },
            ),
          ],
        ),
      ),
    );
  }

  // Hàm hiển thị ảnh full màn hình khi bấm vào
  void _viewFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(imageUrl),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF), // Màu nền nhẹ nhàng
      appBar: AppBar(
        title: Text(widget.diseaseName),
        backgroundColor: const Color(0xFF0066CC),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showMapOptions,
        icon: const Icon(Icons.map, color: Colors.white),
        label: const Text('Tìm nơi chữa', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFE65100),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          final String? imageUrl = data['image_url']; // Lấy URL ảnh từ API

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // [NEW] 1. Hiển thị Ảnh Bệnh Lý (Nếu có)
                if (imageUrl != null && imageUrl.isNotEmpty)
                  GestureDetector(
                    onTap: () => _viewFullImage(imageUrl),
                    child: Container(
                      width: double.infinity,
                      height: 250, // Chiều cao ảnh banner
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Gradient mờ ở dưới ảnh để text dễ đọc hơn nếu cần chèn text
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.black54, Colors.transparent],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                              ),
                            ),
                          ),
                          const Positioned(
                            bottom: 10,
                            right: 10,
                            child: Icon(Icons.zoom_in, color: Colors.white, size: 28),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Nội dung chi tiết
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tiêu đề bệnh lớn hơn
                      if (imageUrl == null) ...[ // Chỉ hiện tên ở đây nếu ko có ảnh (vì AppBar có rồi, nhưng thêm cho rõ nếu cần)
                        Text(
                          data['disease_name_vi'] ?? widget.diseaseName,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0066CC)),
                        ),
                        const SizedBox(height: 16),
                      ],

                      _buildSection('Mô tả chung', data['description']),
                      _buildSection('Triệu chứng', data['symptoms']),
                      _buildSection('Dấu hiệu nhận biết', data['identification_signs']),
                      _buildSection('Cách phòng ngừa', data['prevention_measures']),
                      _buildSection('Điều trị & Thuốc', data['treatments_medications']),
                      _buildSection('Lời khuyên ăn uống', data['dietary_advice']),

                      const Divider(height: 40),
                      if (data['source_references'] != null)
                        Text(
                          'Nguồn tham khảo: ${data['source_references']}',
                          style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 13),
                        ),

                      // Khoảng trống cuối cùng để không bị nút FAB che
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, String? content) {
    if (content == null || content.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                color: const Color(0xFF0066CC),
                margin: const EdgeInsets.only(right: 8),
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0066CC)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black87),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }
}