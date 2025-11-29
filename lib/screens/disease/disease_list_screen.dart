import 'dart:async';
import 'package:app/screens/disease/disease_detail_screen.dart';
import 'package:app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:app/screens/disease/disease_compare_screen.dart';

class DiseaseListScreen extends StatefulWidget {
  const DiseaseListScreen({super.key});

  @override
  State<DiseaseListScreen> createState() => _DiseaseListScreenState();
}

class _DiseaseListScreenState extends State<DiseaseListScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _diseases = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  // Danh sách triệu chứng gợi ý
  final List<String> _symptomSuggestions = [
    'Ngứa',
    'Đỏ',
    'Sưng',
    'Nổi mụn',
    'Đau',
    'Bong tróc',
    'Khô da',
    'Nứt nẻ',
    'Rát',
    'Phồng rộp',
  ];

  @override
  void initState() {
    super.initState();
    _loadDiseases();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _loadDiseases({String search = ''}) async {
    setState(() => _isLoading = true);
    try {
      final list = await _apiService.getDiseases(search: search);
      setState(() => _diseases = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _loadDiseases(search: query);
    });
  }

  void _onSymptomTap(String symptom) {
    _searchController.text = symptom;
    _loadDiseases(search: symptom);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      appBar: AppBar(
        title: const Text('Tra cứu Bệnh lý'),
        backgroundColor: const Color(0xFF0066CC),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DiseaseCompareScreen()),
          );
        },
        backgroundColor: const Color(0xFFE65100), // Màu cam nổi bật
        icon: const Icon(Icons.compare_arrows, color: Colors.white),
        label: const Text('So sánh bệnh', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),

      body: Column(
        children: [
          // Phần tìm kiếm
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên bệnh hoặc triệu chứng...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF0066CC)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        _loadDiseases();
                      },
                    )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF8FBFF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 12),
                // Triệu chứng gợi ý
                Text(
                  'Triệu chứng gợi ý:',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _symptomSuggestions.map((symptom) {
                    return InkWell(
                      onTap: () => _onSymptomTap(symptom),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0066CC).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF0066CC).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_hospital_outlined,
                              size: 16,
                              color: const Color(0xFF0066CC),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              symptom,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF0066CC),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Danh sách bệnh
          Expanded(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0066CC),
              ),
            )
                : _diseases.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Không tìm thấy bệnh nào',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Thử tìm kiếm với từ khóa khác',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _diseases.length,
              itemBuilder: (context, index) {
                final item = _diseases[index];
                return _buildDiseaseCard(item);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiseaseCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0066CC).withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DiseaseDetailScreen(
                  diseaseId: item['info_id'],
                  diseaseName: item['disease_name_vi'],
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon hoặc ảnh bệnh
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0066CC).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: item['image_url'] != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      item['image_url'],
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => const Icon(
                        Icons.medical_services_outlined,
                        size: 32,
                        color: Color(0xFF0066CC),
                      ),
                    ),
                  )
                      : const Icon(
                    Icons.medical_services_outlined,
                    size: 32,
                    color: Color(0xFF0066CC),
                  ),
                ),
                const SizedBox(width: 16),
                // Thông tin bệnh
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['disease_name_vi'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mã: ${item['disease_code']}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (item['symptoms'] != null && item['symptoms'].toString().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          item['symptoms'].toString().length > 80
                              ? '${item['symptoms'].toString().substring(0, 80)}...'
                              : item['symptoms'].toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color(0xFF0066CC),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}