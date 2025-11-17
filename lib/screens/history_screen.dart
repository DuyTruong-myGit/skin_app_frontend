// import 'package:flutter/material.dart';
// import 'package:app/models/diagnosis_record.dart'; // Đổi 'app' nếu cần
// import 'package:app/services/api_service.dart'; // Đổi 'app' nếu cần
// import 'package:intl/intl.dart';
// import 'dart:convert'; // Để giải mã JSON
// import 'package:app/screens/result_screen.dart'; // Màn hình kết quả
//
// class HistoryScreen extends StatefulWidget {
//   // Nếu 2 biến này null, nghĩa là "Lịch sử của tôi"
//   // Nếu có, nghĩa là "Admin xem lịch sử của user..."
//   final int? userId;
//   final String? userName;
//   // =============================
//
//   const HistoryScreen({super.key, this.userId, this.userName});
//
//   @override
//   State<HistoryScreen> createState() => _HistoryScreenState();
// }
//
// class _HistoryScreenState extends State<HistoryScreen> {
//   final ApiService _apiService = ApiService();
//
//   // SỬA LỖI 1: Dùng 'late' và không dùng '?' (nullable)
//   late Future<List<DiagnosisRecord>> _historyFuture;
//
//   @override
//   void initState() {
//     super.initState();
//     _refreshHistory(isInit: true); // Tải lần đầu
//   }
//
//   Future<void> _refreshHistory({bool isInit = false}) async {
//     // Chỉ setState nếu không phải lần đầu (tránh lỗi)
//     if (!isInit) {
//       setState(() {
//         _historyFuture = _fetchData();
//       });
//     } else {
//       _historyFuture = _fetchData();
//     }
//   }
//
//   // Tách logic gọi API ra
//   Future<List<DiagnosisRecord>> _fetchData() {
//     if (widget.userId != null) {
//       // (Admin) Lấy lịch sử của user cụ thể
//       return _apiService.getAdminHistoryForUser(widget.userId!);
//     } else {
//       // (User) Lấy lịch sử của chính mình
//       return _apiService.getHistory();
//     }
//   }
//
//   String _formatDate(DateTime date) {
//     return DateFormat("HH:mm, 'Ngày' dd/MM/yyyy").format(date);
//   }
//
//   void _viewHistoryDetail(DiagnosisRecord record) {
//     if (record.resultJson == null || record.resultJson!.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Không tìm thấy dữ liệu chi tiết.'),
//           backgroundColor: Colors.orange,
//         ),
//       );
//       return;
//     }
//
//     try {
//       final Map<String, dynamic> resultData = json.decode(record.resultJson!);
//
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => ResultScreen(diagnosisResult: resultData),
//         ),
//       );
//
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Lỗi giải mã dữ liệu: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.userId == null
//             ? 'Lịch sử Chẩn đoán'
//             : 'Lịch sử của ${widget.userName}'
//         ),
//       ),
//       body: RefreshIndicator(
//         onRefresh: () => _refreshHistory(), // onRefresh không cần isInit
//         child: FutureBuilder<List<DiagnosisRecord>>(
//           future: _historyFuture, // Luôn luôn có 1 future hợp lệ
//           builder: (context, snapshot) {
//             // 1. TRẠNG THÁI: ĐANG TẢI
//             // (Sẽ chạy ở initState và mỗi lần refresh)
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Center(child: CircularProgressIndicator());
//             }
//
//             // 2. TRẠNG THÁI: CÓ LỖI
//             if (snapshot.hasError) {
//               return SingleChildScrollView(
//                 physics: const AlwaysScrollableScrollPhysics(),
//                 child: Container(
//                   height: MediaQuery.of(context).size.height * 0.7,
//                   alignment: Alignment.center,
//                   child: Text(
//                     'Lỗi tải dữ liệu: ${snapshot.error}',
//                     style: const TextStyle(color: Colors.red),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//               );
//             }
//
//             // 3. TRẠNG THÁI: KHÔNG CÓ DỮ LIỆU (List rỗng)
//             if (!snapshot.hasData || snapshot.data!.isEmpty) {
//               return SingleChildScrollView(
//                 physics: const AlwaysScrollableScrollPhysics(),
//                 child: Container(
//                   height: MediaQuery.of(context).size.height * 0.7,
//                   alignment: Alignment.center,
//                   child: const Text('Bạn chưa có lịch sử chẩn đoán nào.'),
//                 ),
//               );
//             }
//
//             // 4. TRẠNG THÁI: CÓ DỮ LIỆU
//             final historyList = snapshot.data!;
//
//             return ListView.builder(
//               itemCount: historyList.length,
//               itemBuilder: (context, index) {
//                 final record = historyList[index];
//                 return Card(
//                   margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//                   color: Colors.white,
//                   elevation: 0.5,
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12)
//                   ),
//                   child: ListTile(
//                     leading: ClipRRect(
//                       borderRadius: BorderRadius.circular(8.0),
//                       child: Image.network(
//                         record.imageUrl,
//                         width: 50,
//                         height: 50,
//                         fit: BoxFit.cover,
//                         loadingBuilder: (context, child, progress) =>
//                         progress == null ? child : const CircularProgressIndicator(),
//                         errorBuilder: (context, error, stackTrace) =>
//                         const Icon(Icons.broken_image, color: Colors.grey),
//                       ),
//                     ),
//                     title: Text(
//                       record.diseaseName ?? 'Không rõ bệnh',
//                       style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           color: Color(0xFF1F2937)
//                       ),
//                     ),
//                     subtitle: Text(
//                       _formatDate(record.diagnosedAt),
//                       style: TextStyle(color: Colors.grey[600]),
//                     ),
//                     trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//                     onTap: () {
//                       _viewHistoryDetail(record);
//                     },
//                   ),
//                 );
//               },
//             );
//           },
//         ),
//       ),
//     );
//   }
// }



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
  bool _isNewestFirst = true; // true = mới nhất trước, false = cũ nhất trước

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

    // Sắp xếp theo thời gian
    records.sort((a, b) {
      if (_isNewestFirst) {
        return b.diagnosedAt.compareTo(a.diagnosedAt); // Mới nhất trước
      } else {
        return a.diagnosedAt.compareTo(b.diagnosedAt); // Cũ nhất trước
      }
    });

    return records;
  }

  String _formatDate(DateTime date) {
    return DateFormat("HH:mm, 'Ngày' dd/MM/yyyy").format(date);
  }

  void _viewHistoryDetail(DiagnosisRecord record) {
    if (record.resultJson == null || record.resultJson!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Không tìm thấy dữ liệu chi tiết.',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFFF9800),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          elevation: 4,
        ),
      );
      return;
    }

    try {
      final Map<String, dynamic> resultData = json.decode(record.resultJson!);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(diagnosisResult: resultData),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Lỗi giải mã dữ liệu: $e',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          elevation: 4,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0066CC), Color(0xFF00B4D8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.history_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.userId == null ? 'Lịch sử Chẩn đoán' : 'Lịch sử của ${widget.userName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isNewestFirst = !_isNewestFirst;
                  });
                  _refreshHistory();
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Icon(
                        _isNewestFirst ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isNewestFirst ? 'Mới nhất' : 'Cũ nhất',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshHistory(),
        color: const Color(0xFF0066CC),
        backgroundColor: Colors.white,
        child: FutureBuilder<List<DiagnosisRecord>>(
          future: _historyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF0066CC).withOpacity(0.1),
                        const Color(0xFF00B4D8).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0066CC)),
                    strokeWidth: 3,
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.error_outline_rounded,
                          size: 64,
                          color: Color(0xFFE53935),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Lỗi tải dữ liệu',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${snapshot.error}',
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF666666),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF0066CC).withOpacity(0.1),
                              const Color(0xFF00B4D8).withOpacity(0.1),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.folder_open_rounded,
                          size: 64,
                          color: Color(0xFF0066CC),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Chưa có lịch sử',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Bạn chưa có lịch sử chẩn đoán nào.',
                        style: TextStyle(
                          fontSize: 15,
                          color: const Color(0xFF666666),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            final historyList = snapshot.data!;

            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF0066CC).withOpacity(0.08),
                        const Color(0xFF00B4D8).withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF0066CC).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0066CC), Color(0xFF00B4D8)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tổng số bản ghi',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF666666),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${historyList.length} chẩn đoán',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0066CC),
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0066CC), Color(0xFF00B4D8)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0066CC).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.bar_chart_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: historyList.length,
                    itemBuilder: (context, index) {
                      final record = historyList[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _viewHistoryDetail(record),
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF0066CC).withOpacity(0.15),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.network(
                                        record.imageUrl,
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, progress) =>
                                        progress == null
                                            ? child
                                            : Container(
                                          width: 70,
                                          height: 70,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0066CC).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                  Color(0xFF0066CC)),
                                            ),
                                          ),
                                        ),
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          width: 70,
                                          height: 70,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0066CC).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: const Icon(
                                            Icons.broken_image_rounded,
                                            color: Color(0xFF666666),
                                            size: 32,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          record.diseaseName ?? 'Không rõ bệnh',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1A1A1A),
                                            height: 1.3,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.access_time_rounded,
                                              size: 16,
                                              color: const Color(0xFF666666),
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                _formatDate(record.diagnosedAt),
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Color(0xFF666666),
                                                  height: 1.3,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF0066CC), Color(0xFF00B4D8)],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF0066CC).withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}