// Tương tự như User List nhưng có thêm nút Thêm/Sửa/Xóa
// Tôi sẽ viết gọn logic ở đây
import 'package:app/screens/admin/admin_disease_edit_screen.dart'; 
import 'package:app/services/api_service.dart';
import 'package:flutter/material.dart';

class AdminDiseaseListScreen extends StatefulWidget {
  const AdminDiseaseListScreen({super.key});

  @override
  State<AdminDiseaseListScreen> createState() => _AdminDiseaseListScreenState();
}

class _AdminDiseaseListScreenState extends State<AdminDiseaseListScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _diseases = [];

  @override
  void initState() { super.initState(); _refresh(); }

  Future<void> _refresh() async {
    final list = await _apiService.getDiseases();
    setState(() => _diseases = list);
  }

  void _delete(int id) async {
    // Hiển thị Dialog confirm rồi gọi _apiService.deleteDisease(id)
    // Sau đó gọi _refresh();
    // (Bạn tự thêm code UI confirm nhé cho ngắn gọn)
    await _apiService.deleteDisease(id);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QL Thông tin Bệnh')),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDiseaseEditScreen()));
          _refresh();
        },
      ),
      body: ListView.builder(
        itemCount: _diseases.length,
        itemBuilder: (context, index) {
          final item = _diseases[index];
          return ListTile(
            title: Text(item['disease_name_vi']),
            subtitle: Text(item['disease_code']),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => AdminDiseaseEditScreen(diseaseId: item['info_id'])));
                    _refresh();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _delete(item['info_id']),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}