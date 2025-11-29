import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:app/services/api_service.dart';
import 'package:app/screens/schedule/add_schedule_screen.dart';
import 'package:intl/intl.dart';
import 'package:app/services/notification_service.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final ApiService _apiService = ApiService();

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  /// Lấy danh sách tasks theo ngày
  Future<void> _fetchTasks() async {
    setState(() => _isLoading = true);

    try {
      final tasks = await _apiService.getDailyTasks(_selectedDay);

      if (mounted) {
        setState(() {
          _tasks = tasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Error fetching tasks: $e");
      if (mounted) {
        setState(() {
          _tasks = [];
          _isLoading = false;
        });
      }
    }
  }

  /// Toggle trạng thái hoàn thành
  void _toggleTask(int index) async {
    final task = _tasks[index];
    final scheduleId = task['schedule_id'];
    final currentStatus = task['log_status'] == 'completed';
    final newStatus = !currentStatus;

    // Optimistic Update
    setState(() {
      _tasks[index]['log_status'] = newStatus ? 'completed' : 'pending';
    });

    try {
      await _apiService.toggleTask(scheduleId, _selectedDay, newStatus);
    } catch (e) {
      // Revert nếu lỗi
      if (mounted) {
        setState(() {
          _tasks[index]['log_status'] = currentStatus ? 'completed' : 'pending';
        });
        _showSnackBar('Lỗi cập nhật trạng thái', isError: true);
      }
    }
  }

  /// Xóa lịch trình
  void _deleteTask(int scheduleId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa lịch trình?'),
        content: const Text(
            'Lịch trình này sẽ bị xóa vĩnh viễn khỏi tất cả các ngày.'
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')
          ),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                  'Xóa',
                  style: TextStyle(color: Colors.red)
              )
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.deleteSchedule(scheduleId);
        await NotificationService().cancelNotification(scheduleId);

        if (mounted) {
          _showSnackBar('Đã xóa thành công');
          _fetchTasks(); // Reload
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('Lỗi xóa: ${e.toString()}', isError: true);
        }
      }
    }
  }

  /// Helper: Hiển thị SnackBar
  void _showSnackBar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: isError ? Colors.red : Colors.green,
          duration: const Duration(seconds: 2),
        )
    );
  }

  /// Helper: Lấy config hiển thị theo type
  Map<String, dynamic> _getTypeConfig(String type) {
    switch (type) {
      case 'medication':
        return {
          'icon': Icons.medication,
          'color': Colors.red[100],
          'iconColor': Colors.red
        };
      case 'skincare':
        return {
          'icon': Icons.face,
          'color': Colors.pink[100],
          'iconColor': Colors.pink
        };
      case 'checkup':
        return {
          'icon': Icons.local_hospital,
          'color': Colors.blue[100],
          'iconColor': Colors.blue
        };
      case 'exercise':
        return {
          'icon': Icons.fitness_center,
          'color': Colors.orange[100],
          'iconColor': Colors.deepOrange
        };
      case 'appointment':
        return {
          'icon': Icons.calendar_month,
          'color': Colors.purple[100],
          'iconColor': Colors.purple
        };
      default:
        return {
          'icon': Icons.assignment,
          'color': Colors.grey[200],
          'iconColor': Colors.grey[700]
        };
    }
  }

  /// Helper: Parse thời gian từ backend
  String _formatTime(dynamic timeValue) {
    if (timeValue == null) return '??:??';

    try {
      final timeStr = timeValue.toString();
      // Nếu có dạng HH:mm:ss hoặc HH:mm
      if (timeStr.contains(':')) {
        return timeStr.substring(0, 5); // Lấy HH:mm
      }
      return timeStr;
    } catch (e) {
      return '??:??';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tính toán progress
    int completedCount = _tasks.where((t) => t['log_status'] == 'completed').length;
    double progress = _tasks.isEmpty ? 0 : completedCount / _tasks.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch trình Sức khỏe'),
        elevation: 0,
        actions: [
          IconButton(
              onPressed: _fetchTasks,
              icon: const Icon(Icons.refresh),
              tooltip: 'Tải lại'
          )
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final result = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AddScheduleScreen()
              )
          );
          if (result == true) _fetchTasks();
        },
      ),

      body: Column(
        children: [
          // ===== 1. CALENDAR =====
          TableCalendar(
            locale: 'vi_VN',
            firstDay: DateTime.utc(2023, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            currentDay: DateTime.now(),
            calendarFormat: CalendarFormat.week,

            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),

            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _fetchTasks();
            },

            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle
              ),
              selectedDecoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle
              ),
            ),

            headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true
            ),
          ),

          const Divider(),

          // ===== 2. PROGRESS BAR =====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ngày: ${DateFormat('dd/MM/yyyy (EEEE)', 'vi').format(_selectedDay)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Đã hoàn thành $completedCount/${_tasks.length}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                // Progress Circle
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[200],
                        color: progress == 1.0 ? Colors.green : Colors.blue,
                        strokeWidth: 6,
                      ),
                    ),
                    Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold
                        )
                    ),
                  ],
                )
              ],
            ),
          ),

          // ===== 3. TASK LIST =====
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _tasks.isEmpty
                ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                        Icons.event_available,
                        size: 64,
                        color: Colors.grey[300]
                    ),
                    const SizedBox(height: 10),
                    Text(
                        'Không có lịch trình nào',
                        style: TextStyle(color: Colors.grey[500])
                    ),
                    const SizedBox(height: 4),
                    Text(
                        'Nhấn nút + để thêm mới',
                        style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12
                        )
                    ),
                  ],
                )
            )
                : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                final isDone = task['log_status'] == 'completed';
                final config = _getTypeConfig(task['type'] ?? 'other');

                return Dismissible(
                  key: Key('${task['schedule_id']}_$index'),
                  direction: DismissDirection.endToStart,

                  background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 32
                      )
                  ),

                  confirmDismiss: (direction) async {
                    _deleteTask(task['schedule_id']);
                    return false; // Không tự xóa UI
                  },

                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                          color: isDone
                              ? Colors.green.withOpacity(0.5)
                              : Colors.transparent
                      ),
                    ),

                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8
                      ),

                      // Icon
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: config['color'],
                            borderRadius: BorderRadius.circular(10)
                        ),
                        child: Icon(
                            config['icon'],
                            color: config['iconColor']
                        ),
                      ),

                      // Title
                      title: Text(
                        task['title'] ?? 'Không có tên',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: isDone
                                ? TextDecoration.lineThrough
                                : null,
                            color: isDone
                                ? Colors.grey
                                : Colors.black87
                        ),
                      ),

                      // Subtitle: Thời gian
                      subtitle: Row(
                        children: [
                          const Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey
                          ),
                          const SizedBox(width: 4),
                          Text(
                              _formatTime(task['reminder_time']),
                              style: const TextStyle(color: Colors.grey)
                          ),
                        ],
                      ),

                      // Checkbox
                      trailing: Checkbox(
                        value: isDone,
                        shape: const CircleBorder(),
                        activeColor: Colors.green,
                        onChanged: (val) => _toggleTask(index),
                      ),

                      // Tap để Edit
                      onTap: () async {
                        final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => AddScheduleScreen(
                                    schedule: task
                                )
                            )
                        );
                        if (result == true) _fetchTasks();
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}