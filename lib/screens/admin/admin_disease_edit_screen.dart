import 'package:flutter/material.dart';
import 'package:app/services/api_service.dart';

class AdminDiseaseEditScreen extends StatefulWidget {
  final int? diseaseId; // Nếu null là Thêm mới, có id là Sửa
  const AdminDiseaseEditScreen({super.key, this.diseaseId});

  @override
  State<AdminDiseaseEditScreen> createState() => _AdminDiseaseEditScreenState();
}

class _AdminDiseaseEditScreenState extends State<AdminDiseaseEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {
    'disease_code': TextEditingController(),
    'disease_name_vi': TextEditingController(),
    'description': TextEditingController(),
    'symptoms': TextEditingController(),
    'identification_signs': TextEditingController(),
    'prevention_measures': TextEditingController(),
    'treatments_medications': TextEditingController(),
    'dietary_advice': TextEditingController(),
    'source_references': TextEditingController(),
  };
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.diseaseId != null) _loadData();
  }

  void _loadData() async {
    final data = await ApiService().getDiseaseDetail(widget.diseaseId!);
    _controllers.forEach((key, controller) {
      controller.text = data[key] ?? '';
    });
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = _controllers.map((key, value) => MapEntry(key, value.text));
    try {
      if (widget.diseaseId == null) {
        await ApiService().createDisease(data);
      } else {
        await ApiService().updateDisease(widget.diseaseId!, data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.diseaseId == null ? 'Thêm bệnh mới' : 'Cập nhật bệnh')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildField('Mã bệnh (Key)', 'disease_code', required: true),
            _buildField('Tên bệnh', 'disease_name_vi', required: true),
            _buildField('Mô tả', 'description', maxLines: 3),
            _buildField('Triệu chứng', 'symptoms', maxLines: 3),
            _buildField('Dấu hiệu', 'identification_signs', maxLines: 3),
            _buildField('Phòng ngừa', 'prevention_measures', maxLines: 3),
            _buildField('Điều trị', 'treatments_medications', maxLines: 3),
            _buildField('Ăn uống', 'dietary_advice', maxLines: 3),
            _buildField('Nguồn tham khảo', 'source_references'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _save,
              child: Text(_isLoading ? 'Đang lưu...' : 'Lưu thông tin'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, String key, {bool required = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _controllers[key],
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        maxLines: maxLines,
        validator: required ? (v) => v!.isEmpty ? 'Không được để trống' : null : null,
      ),
    );
  }
}