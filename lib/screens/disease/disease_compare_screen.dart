import 'package:flutter/material.dart';
import 'package:app/services/api_service.dart';

class DiseaseCompareScreen extends StatefulWidget {
  const DiseaseCompareScreen({super.key});

  @override
  State<DiseaseCompareScreen> createState() => _DiseaseCompareScreenState();
}

class _DiseaseCompareScreenState extends State<DiseaseCompareScreen> {
  final ApiService _apiService = ApiService();

  // Danh sách rút gọn để chọn (Dropdown/Modal)
  List<Map<String, dynamic>> _allDiseases = [];

  // Dữ liệu chi tiết của 2 bệnh được chọn
  Map<String, dynamic>? _diseaseA;
  Map<String, dynamic>? _diseaseB;

  bool _isLoadingList = true;
  bool _isComparing = false;

  @override
  void initState() {
    super.initState();
    _loadAllDiseases();
  }

  // 1. Tải danh sách bệnh để người dùng chọn
  Future<void> _loadAllDiseases() async {
    try {
      final list = await _apiService.getDiseases(search: '');
      if (mounted) {
        setState(() {
          _allDiseases = list;
          _isLoadingList = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingList = false);
      // Xử lý lỗi nhe nhàng
    }
  }

  // 2. Tải chi tiết bệnh khi người dùng chọn
  Future<void> _selectDisease(bool isA) async {
    // Hiển thị BottomSheet để chọn bệnh
    final Map<String, dynamic>? selected = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _DiseaseSelectionModal(diseases: _allDiseases),
    );

    if (selected != null) {
      final int id = selected['info_id'];

      // Gọi API lấy chi tiết đầy đủ (description, treatment, v.v.)
      try {
        setState(() => _isComparing = true);
        final detail = await _apiService.getDiseaseDetail(id);

        setState(() {
          if (isA) {
            _diseaseA = detail;
          } else {
            _diseaseB = detail;
          }
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu: $e')));
      } finally {
        setState(() => _isComparing = false);
      }
    }
  }

  // 3. Widget hiển thị tiêu đề cột so sánh
  Widget _buildHeaderCard(String title, Map<String, dynamic>? disease, bool isA) {
    return Expanded(
      child: InkWell(
        onTap: () => _selectDisease(isA),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: disease != null
                ? (isA ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1))
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: disease != null
                    ? (isA ? Colors.blue : Colors.orange)
                    : Colors.grey.shade300,
                width: 2
            ),
          ),
          child: Column(
            children: [
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              const SizedBox(height: 8),
              if (disease == null)
                const Icon(Icons.add_circle_outline, size: 40, color: Colors.grey)
              else ...[
                if (disease['image_url'] != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(disease['image_url'], height: 60, width: 60, fit: BoxFit.cover),
                  ),
                const SizedBox(height: 8),
                Text(
                  disease['disease_name_vi'] ?? 'Tên bệnh',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  // 4. Widget hiển thị 1 dòng so sánh
  Widget _buildComparisonRow(String label, String key) {
    if (_diseaseA == null && _diseaseB == null) return const SizedBox.shrink();

    final String valA = _diseaseA?[key] ?? '---';
    final String valB = _diseaseB?[key] ?? '---';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
      ),
      child: Column(
        children: [
          // Tiêu đề mục so sánh (Ví dụ: Triệu chứng)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0066CC),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cột A
              Expanded(
                child: Text(valA, style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black87)),
              ),
              // Đường kẻ giữa
              Container(width: 1, height: 40, color: Colors.grey[300], margin: const EdgeInsets.symmetric(horizontal: 12)),
              // Cột B
              Expanded(
                child: Text(valB, style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black87)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      appBar: AppBar(
        title: const Text('So sánh Bệnh lý'),
        backgroundColor: const Color(0xFF0066CC),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // HEADER: Khu vực chọn bệnh
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                _buildHeaderCard('Bệnh A', _diseaseA, true),
                const SizedBox(width: 16),
                const Icon(Icons.compare_arrows, color: Colors.grey),
                const SizedBox(width: 16),
                _buildHeaderCard('Bệnh B', _diseaseB, false),
              ],
            ),
          ),

          if (_isComparing) const LinearProgressIndicator(),

          // BODY: Nội dung so sánh
          Expanded(
            child: (_diseaseA == null && _diseaseB == null)
                ? Center(child: Text('Chọn 2 bệnh để bắt đầu so sánh', style: TextStyle(color: Colors.grey[500])))
                : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildComparisonRow('Mã bệnh', 'disease_code'),
                  _buildComparisonRow('Mô tả chung', 'description'),
                  _buildComparisonRow('Triệu chứng', 'symptoms'),
                  _buildComparisonRow('Dấu hiệu nhận biết', 'identification_signs'),
                  _buildComparisonRow('Cách phòng ngừa', 'prevention_measures'),
                  _buildComparisonRow('Điều trị & Thuốc', 'treatments_medications'),
                  _buildComparisonRow('Chế độ ăn uống', 'dietary_advice'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Modal tìm kiếm và chọn bệnh (Internal Widget)
class _DiseaseSelectionModal extends StatefulWidget {
  final List<Map<String, dynamic>> diseases;
  const _DiseaseSelectionModal({required this.diseases});

  @override
  State<_DiseaseSelectionModal> createState() => _DiseaseSelectionModalState();
}

class _DiseaseSelectionModalState extends State<_DiseaseSelectionModal> {
  List<Map<String, dynamic>> _filtered = [];
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filtered = widget.diseases;
  }

  void _filter(String query) {
    setState(() {
      _filtered = widget.diseases.where((d) {
        final name = d['disease_name_vi'].toString().toLowerCase();
        return name.contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Chọn bệnh để so sánh', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Tìm tên bệnh...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: _filter,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final item = _filtered[index];
                return ListTile(
                  leading: const Icon(Icons.medical_services_outlined, color: Colors.blue),
                  title: Text(item['disease_name_vi'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(item['disease_code'] ?? '', style: const TextStyle(fontSize: 12)),
                  onTap: () => Navigator.pop(context, item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}