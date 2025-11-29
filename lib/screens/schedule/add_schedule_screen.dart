import 'package:flutter/material.dart';
import 'package:app/services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:app/services/notification_service.dart';

class AddScheduleScreen extends StatefulWidget {
  final Map<String, dynamic>? schedule;

  const AddScheduleScreen({super.key, this.schedule});

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  final _titleController = TextEditingController();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  String _selectedType = 'medication';

  List<int> _selectedDays = [2, 3, 4, 5, 6, 7, 8];
  DateTime? _specificDate;
  bool _isRepeating = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _specificDate = DateTime.now();

    if (widget.schedule != null) {
      _loadScheduleData();
    }
  }

  /// 🔧 LOAD DỮ LIỆU - FIX HOÀN TOÀN Ở FE
  void _loadScheduleData() {
    try {
      final s = widget.schedule!;

      // 1. Load cơ bản
      _titleController.text = s['title']?.toString() ?? '';
      _selectedType = s['type']?.toString() ?? 'medication';

      // 2. Parse time
      if (s['reminder_time'] != null) {
        try {
          final timeStr = s['reminder_time'].toString();
          final timeParts = timeStr.split(':');
          if (timeParts.length >= 2) {
            _selectedTime = TimeOfDay(
                hour: int.parse(timeParts[0]),
                minute: int.parse(timeParts[1])
            );
          }
        } catch (e) {
          print('⚠️ Lỗi parse time: $e');
          _selectedTime = const TimeOfDay(hour: 8, minute: 0);
        }
      }

      // 🎯 3. XỬ LÝ REPEAT_DAYS vs SPECIFIC_DATE - LOGIC AN TOÀN 100%
      final repeatDaysRaw = s['repeat_days'];
      final specificDateRaw = s['specific_date'];

      print('📊 Raw data: repeat_days=$repeatDaysRaw, specific_date=$specificDateRaw');

      // Helper: Kiểm tra giá trị có null/empty không
      bool _isNullOrEmpty(dynamic value) {
        if (value == null) return true;
        final str = value.toString().trim().toLowerCase();
        return str.isEmpty || str == 'null';
      }

      // Helper: Parse repeat_days thành List<int>
      List<int> _parseRepeatDays(dynamic value) {
        try {
          if (_isNullOrEmpty(value)) return [];

          return value.toString()
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty && s != 'null')
              .map((s) => int.tryParse(s) ?? 0)
              .where((d) => d >= 2 && d <= 8)
              .toList();
        } catch (e) {
          print('⚠️ Parse repeat_days error: $e');
          return [];
        }
      }

      // Helper: Parse specific_date thành DateTime
      DateTime? _parseSpecificDate(dynamic value) {
        try {
          if (_isNullOrEmpty(value)) return null;
          return DateTime.parse(value.toString());
        } catch (e) {
          print('⚠️ Parse specific_date error: $e');
          return null;
        }
      }

      // Parse cả 2 trường
      final parsedDays = _parseRepeatDays(repeatDaysRaw);
      final parsedDate = _parseSpecificDate(specificDateRaw);

      print('📊 Parsed: days=$parsedDays, date=$parsedDate');

      // 🔥 LOGIC QUY ƯỚC ƯU TIÊN:
      // - Nếu repeat_days có giá trị hợp lệ → Lịch lặp lại
      // - Nếu không, kiểm tra specific_date → Lịch 1 lần
      // - Nếu cả 2 đều có → Ưu tiên repeat_days (vì backend thường lưu đúng logic này)
      // - Nếu cả 2 đều null → Mặc định lịch lặp lại

      if (parsedDays.isNotEmpty) {
        // CASE 1: Có repeat_days hợp lệ → Lịch lặp lại
        print('✅ CASE 1: Lịch lặp lại');
        _isRepeating = true;
        _selectedDays = parsedDays;
        _specificDate = DateTime.now(); // Giá trị dự phòng (không dùng)

      } else if (parsedDate != null) {
        // CASE 2: Không có repeat_days, nhưng có specific_date → Lịch 1 lần
        print('✅ CASE 2: Lịch 1 lần');
        _isRepeating = false;
        _selectedDays = [];
        _specificDate = parsedDate;

      } else {
        // CASE 3: Cả 2 đều null → Fallback mặc định
        print('⚠️ CASE 3: Fallback - Không có dữ liệu hợp lệ');
        _isRepeating = true;
        _selectedDays = [2, 3, 4, 5, 6, 7, 8]; // Mặc định cả tuần
        _specificDate = DateTime.now();
      }

      print('✅ Final state: isRepeating=$_isRepeating, days=$_selectedDays, date=$_specificDate');

    } catch (e) {
      // Fallback toàn bộ nếu có lỗi không mong muốn
      print('❌ Critical error in _loadScheduleData: $e');
      _isRepeating = true;
      _selectedDays = [2, 3, 4, 5, 6, 7, 8];
      _specificDate = DateTime.now();
      _titleController.text = '';
      _selectedType = 'medication';
    }
  }

  /// Validate và Lưu
  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      _showError('Vui lòng nhập tên hoạt động');
      return;
    }

    if (_isRepeating && _selectedDays.isEmpty) {
      _showError('Vui lòng chọn ít nhất 1 ngày hoặc tắt chế độ lặp');
      return;
    }

    if (!_isRepeating && _specificDate == null) {
      _showError('Vui lòng chọn ngày thực hiện');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final timeStr = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

      Map<String, dynamic> payload = {
        'title': _titleController.text.trim(),
        'type': _selectedType,
        'reminder_time': timeStr,
      };

      if (_isRepeating) {
        _selectedDays.sort();
        payload['repeat_days'] = _selectedDays.join(',');
        payload['specific_date'] = null;
      } else {
        payload['repeat_days'] = null;
        payload['specific_date'] = DateFormat('yyyy-MM-dd').format(_specificDate!);
      }

      print('📤 Sending payload: $payload');

      int scheduleId;

      if (widget.schedule == null) {
        scheduleId = await ApiService().createSchedule(payload);
        if (scheduleId == 0) throw 'Không nhận được ID từ server';
      } else {
        scheduleId = widget.schedule!['schedule_id'];
        await ApiService().updateSchedule(scheduleId, payload);
      }

      await _scheduleLocalNotification(scheduleId);

      if (mounted) {
        Navigator.pop(context, true);
        _showSuccess(widget.schedule == null ? 'Đã thêm lịch trình' : 'Đã cập nhật');
      }

    } catch (e) {
      print('❌ Save error: $e');
      _showError('Lỗi: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Đặt lịch thông báo local
  Future<void> _scheduleLocalNotification(int scheduleId) async {
    try {
      await NotificationService().cancelNotification(scheduleId);

      if (_isRepeating) {
        await NotificationService().scheduleNotification(
          id: scheduleId,
          title: 'Đến giờ: ${_titleController.text}',
          body: 'Hãy thực hiện: ${_getVnTypeName(_selectedType)}',
          time: _selectedTime,
          days: _selectedDays,
        );
      } else {
        final scheduledDateTime = DateTime(
            _specificDate!.year,
            _specificDate!.month,
            _specificDate!.day,
            _selectedTime.hour,
            _selectedTime.minute
        );

        if (scheduledDateTime.isAfter(DateTime.now())) {
          await NotificationService().scheduleOneTimeNotification(
            id: scheduleId,
            title: 'Đến giờ: ${_titleController.text}',
            body: 'Nhắc nhở: ${_getVnTypeName(_selectedType)}',
            date: scheduledDateTime,
          );
        }
      }
    } catch (e) {
      print('⚠️ Lỗi đặt thông báo local: $e');
    }
  }

  String _getVnTypeName(String type) {
    switch (type) {
      case 'medication': return 'Uống thuốc';
      case 'skincare': return 'Chăm sóc da';
      case 'checkup': return 'Tái khám';
      case 'exercise': return 'Tập thể dục';
      case 'appointment': return 'Cuộc hẹn';
      default: return 'Hoạt động khác';
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red)
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.green)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.schedule == null ? 'Thêm Lịch trình' : 'Sửa Lịch trình'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 1. Tên hoạt động
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
                labelText: 'Tên thuốc / Hoạt động *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit_note),
                hintText: 'VD: Uống Aspirin, Bôi kem dưỡng...'
            ),
          ),
          const SizedBox(height: 20),

          // 2. Loại hoạt động
          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: const InputDecoration(
                labelText: 'Loại hoạt động',
                border: OutlineInputBorder()
            ),
            items: const [
              DropdownMenuItem(value: 'medication', child: Row(children: [Icon(Icons.medication, color: Colors.red), SizedBox(width: 10), Text('Uống thuốc')])),
              DropdownMenuItem(value: 'skincare', child: Row(children: [Icon(Icons.face, color: Colors.pink), SizedBox(width: 10), Text('Chăm sóc da')])),
              DropdownMenuItem(value: 'checkup', child: Row(children: [Icon(Icons.local_hospital, color: Colors.blue), SizedBox(width: 10), Text('Tái khám')])),
              DropdownMenuItem(value: 'exercise', child: Row(children: [Icon(Icons.fitness_center, color: Colors.orange), SizedBox(width: 10), Text('Tập thể dục')])),
              DropdownMenuItem(value: 'appointment', child: Row(children: [Icon(Icons.calendar_month, color: Colors.purple), SizedBox(width: 10), Text('Cuộc hẹn')])),
              DropdownMenuItem(value: 'other', child: Row(children: [Icon(Icons.format_list_bulleted, color: Colors.grey), SizedBox(width: 10), Text('Khác')])),
            ],
            onChanged: (v) => setState(() => _selectedType = v!),
          ),
          const SizedBox(height: 20),

          // 3. Giờ nhắc
          ListTile(
            title: const Text('Giờ nhắc *'),
            subtitle: const Text('Chạm để thay đổi'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)
              ),
              child: Text(
                  _selectedTime.format(context),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)
              ),
            ),
            onTap: () async {
              final t = await showTimePicker(context: context, initialTime: _selectedTime);
              if (t != null) setState(() => _selectedTime = t);
            },
          ),
          const Divider(height: 30),

          // 4. Switch Lặp lại
          SwitchListTile(
            title: const Text('Lặp lại hàng tuần?'),
            subtitle: Text(_isRepeating ? 'Lặp lại vào các ngày trong tuần' : 'Chỉ nhắc một ngày cụ thể'),
            value: _isRepeating,
            activeColor: Colors.blue,
            onChanged: (val) => setState(() => _isRepeating = val),
          ),
          const SizedBox(height: 10),

          // 5. Chọn ngày
          if (_isRepeating) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text('Chọn các ngày lặp lại: *', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Wrap(
              spacing: 8,
              children: [2, 3, 4, 5, 6, 7, 8].map((day) {
                final isSelected = _selectedDays.contains(day);
                return FilterChip(
                  label: Text(day == 8 ? 'CN' : 'T$day'),
                  selected: isSelected,
                  selectedColor: Colors.blue.withOpacity(0.3),
                  checkmarkColor: Colors.blue,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedDays.add(day);
                      } else {
                        if (_selectedDays.length > 1) _selectedDays.remove(day);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ] else ...[
            ListTile(
              title: const Text('Ngày thực hiện *'),
              subtitle: Text(DateFormat('dd/MM/yyyy (EEEE)', 'vi').format(_specificDate!)),
              trailing: const Icon(Icons.calendar_today, color: Colors.blue),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey.shade300)
              ),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _specificDate!,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  locale: const Locale('vi', 'VN'),
                );
                if (d != null) setState(() => _specificDate = d);
              },
            ),
          ],

          const SizedBox(height: 30),

          // 6. Nút Lưu
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(widget.schedule == null ? 'THÊM MỚI' : 'CẬP NHẬT', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
}