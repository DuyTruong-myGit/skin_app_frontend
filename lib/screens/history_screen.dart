import 'package:flutter/material.dart';
import 'package:app/models/diagnosis_record.dart';
import 'package:app/services/api_service.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:app/screens/result_screen.dart';

class HistoryScreen extends StatefulWidget {
  final int? userId;
  final String? userName;

  const HistoryScreen({super.key, this.userId, this.userName});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<DiagnosisRecord>> _historyFuture;
  bool _isNewestFirst = true;

  @override
  void initState() {
    super.initState();
    _refreshHistory(isInit: true);
  }

  Future<void> _refreshHistory({bool isInit = false}) async {
    if (!isInit) {
      setState(() {
        _historyFuture = _fetchData();
      });
    } else {
      _historyFuture = _fetchData();
    }
  }

  Future<List<DiagnosisRecord>> _fetchData() async {
    List<DiagnosisRecord> records;
    if (widget.userId != null) {
      records = await _apiService.getAdminHistoryForUser(widget.userId!);
    } else {
      records = await _apiService.getHistory();
    }

    records.sort((a, b) {
      if (_isNewestFirst) {
        return b.diagnosedAt.compareTo(a.diagnosedAt);
      } else {
        return a.diagnosedAt.compareTo(b.diagnosedAt);
      }
    });

    return records;
  }

  String _formatDate(DateTime date) {
    final vietnamTime = date.add(const Duration(hours: 7));
    return DateFormat("HH:mm, dd/MM/yyyy").format(vietnamTime);
  }

  void _viewHistoryDetail(DiagnosisRecord record) {
    if (record.resultJson == null || record.resultJson!.isEmpty) {
      _showSnackBar('Không tìm thấy dữ liệu chi tiết.', isError: true);
      return;
    }

    try {
      final Map<String, dynamic> resultData = json.decode(record.resultJson!);

      // Điều hướng sang ResultScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            diagnosisResult: resultData,
            imageUrl: record.imageUrl, // Truyền ảnh sang để hiển thị lại
          ),
        ),
      );
    } catch (e) {
      _showSnackBar('Lỗi dữ liệu: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[400] : Colors.green[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _confirmDelete(int historyId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('Xóa kết quả này?'),
        content: const Text('Hành động này sẽ xóa vĩnh viễn kết quả chẩn đoán khỏi lịch sử của bạn.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Hủy', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[50],
              foregroundColor: Colors.red,
              elevation: 0,
            ),
            child: const Text('Xóa ngay'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.deleteDiagnosisHistory(historyId);
        _refreshHistory();
        if (!mounted) return;
        _showSnackBar('Đã xóa bản ghi thành công');
      } catch (e) {
        if (!mounted) return;
        _showSnackBar('Lỗi khi xóa: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // Nền xám rất nhạt (Modern)
      appBar: AppBar(
        backgroundColor: Colors.white, // AppBar trắng sạch
        elevation: 0,
        centerTitle: false, // Để tiêu đề căn trái cho hiện đại
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.userId == null ? 'Lịch sử Chẩn đoán' : 'Hồ sơ: ${widget.userName}',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Nút sắp xếp tối giản
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton.icon(
              onPressed: () {
                setState(() => _isNewestFirst = !_isNewestFirst);
                _refreshHistory();
              },
              icon: Icon(
                _isNewestFirst ? Icons.sort_rounded : Icons.filter_list_rounded,
                size: 20,
                color: const Color(0xFF0066CC),
              ),
              label: Text(
                _isNewestFirst ? 'Mới nhất' : 'Cũ nhất',
                style: const TextStyle(
                  color: Color(0xFF0066CC),
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF0066CC).withOpacity(0.05),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey[200], height: 1.0), // Đường kẻ mờ ngăn cách
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshHistory(),
        color: const Color(0xFF0066CC),
        child: FutureBuilder<List<DiagnosisRecord>>(
          future: _historyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text('Không thể tải dữ liệu', style: TextStyle(color: Colors.grey[600])),
                    TextButton(onPressed: () => _refreshHistory(), child: const Text('Thử lại')),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.history_edu_rounded, size: 50, color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Chưa có lịch sử khám',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hãy chụp ảnh để chẩn đoán ngay!',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              );
            }

            final historyList = snapshot.data!;

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: [
                // Text thống kê đơn giản
                Padding(
                  padding: const EdgeInsets.only(bottom: 16, left: 4),
                  child: Text(
                    'Bạn có ${historyList.length} kết quả đã lưu',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                // Danh sách
                ...historyList.map((record) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04), // Bóng rất mờ
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: Colors.grey[100]!), // Viền siêu mỏng
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _viewHistoryDetail(record),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // 1. Ảnh Thumbnail
                              Hero(
                                tag: 'history_img_${record.historyId}',
                                child: Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: Colors.grey[200],
                                    image: DecorationImage(
                                      image: NetworkImage(record.imageUrl),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 16),

                              // 2. Nội dung text
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      record.diseaseName ?? 'Chưa xác định',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF212121),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today_rounded, size: 12, color: Colors.grey[500]),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatDate(record.diagnosedAt),
                                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // 3. Nút hành động
                              Row(
                                children: [
                                  // Nút xóa (Icon xám nhạt để tránh bấm nhầm)
                                  IconButton(
                                    icon: Icon(Icons.delete_outline_rounded, size: 20, color: Colors.grey[400]),
                                    onPressed: () => _confirmDelete(record.historyId),
                                    tooltip: 'Xóa',
                                  ),
                                  // Nút xem chi tiết (Màu chủ đạo)
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0066CC).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 18,
                                      color: Color(0xFF0066CC),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),

                // Footer padding
                const SizedBox(height: 40),
              ],
            );
          },
        ),
      ),
    );
  }
}