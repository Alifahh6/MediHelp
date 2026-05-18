// lib/screens/reminder_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medi_help/providers/reminder_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final FlutterLocalNotificationsPlugin _notifPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initNotifications();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReminderProvider>().loadReminders();
    });
  }

  Future<void> _initNotifications() async {
    tz.initializeTimeZones();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _notifPlugin.initialize(initSettings);
    final androidPlugin = _notifPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
  }

  Future<void> _scheduleNotifications({
    required int reminderId,
    required String medicineName,
    required List<String> times,
    required int durationDays,
  }) async {
    await _cancelNotifications(reminderId);

    final now = tz.TZDateTime.now(tz.local);
    List<int> hours = [];

    if (times.length == 1) {
      hours = [7];
    } else if (times.length == 2) {
      hours = [7, 19];
    } else {
      hours = [7, 15, 23];
    }

    const androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'Pengingat Obat',
      channelDescription: 'Notifikasi pengingat minum obat',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const notifDetails = NotificationDetails(android: androidDetails);

    for (int day = 0; day < durationDays; day++) {
      for (int i = 0; i < hours.length; i++) {
        final scheduleTime = tz.TZDateTime(
          tz.local,
          now.year, now.month, now.day + day,
          hours[i], 0,
        );
        if (scheduleTime.isBefore(now)) continue;

        final notifId =
            reminderId.hashCode.abs() % 10000 * 1000 + day * 10 + i;

        final timeLabel = times.length == 1
            ? 'Pagi'
            : times.length == 2
                ? (i == 0 ? 'Pagi' : 'Malam')
                : (i == 0 ? 'Pagi' : i == 1 ? 'Siang' : 'Malam');

        await _notifPlugin.zonedSchedule(
          notifId,
          '💊 Waktunya Minum Obat',
          '$medicineName - $timeLabel (${hours[i].toString().padLeft(2, '0')}:00)',
          scheduleTime,
          notifDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
    debugPrint(
        '✅ Scheduled ${hours.length * durationDays} notifications for $medicineName');
  }

  Future<void> _cancelNotifications(int reminderId) async {
    for (int day = 0; day < 30; day++) {
      for (int i = 0; i < 3; i++) {
        final notifId =
            reminderId.hashCode.abs() % 10000 * 1000 + day * 10 + i;
        await _notifPlugin.cancel(notifId);
      }
    }
  }

  // ─── Form state ───────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rulesController = TextEditingController();
  final _purposeController = TextEditingController();

  bool _morning = false;
  bool _afternoon = false;
  bool _evening = false;
  int _morningDose = 1;
  int _afternoonDose = 1;
  int _eveningDose = 1;
  int _durationDays = 7;

  @override
  void dispose() {
    _nameController.dispose();
    _rulesController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _nameController.clear();
    _rulesController.clear();
    _purposeController.clear();
    _morning = false;
    _afternoon = false;
    _evening = false;
    _morningDose = 1;
    _afternoonDose = 1;
    _eveningDose = 1;
    _durationDays = 7;
  }

  void _fillFormFromReminder(Map<String, dynamic> reminder) {
    _nameController.text = reminder['name'] ?? '';
    _rulesController.text =
        reminder['rules'] == '-' ? '' : (reminder['rules'] ?? '');
    _purposeController.text =
        reminder['purpose'] == '-' ? '' : (reminder['purpose'] ?? '');
    _durationDays = reminder['days'] ?? 7;

    final times = (reminder['times'] as List<String>);
    _morning = times.contains('Pagi');
    _afternoon = times.contains('Siang');
    _evening = times.contains('Malam');

    final doses = (reminder['doses'] as List<String>);
    for (final d in doses) {
      if (d.startsWith('Pagi:')) {
        _morningDose =
            int.tryParse(d.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
      } else if (d.startsWith('Siang:')) {
        _afternoonDose =
            int.tryParse(d.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
      } else if (d.startsWith('Malam:')) {
        _eveningDose =
            int.tryParse(d.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
      }
    }
  }

  void _showReminderSheet({int? editIndex, Map<String, dynamic>? existing}) {
    if (existing != null) {
      _fillFormFromReminder(existing);
    } else {
      _resetForm();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            final textColor =
                isDark ? Colors.white : const Color(0xFF1E1E1E);
            final inputFill = isDark
                ? const Color(0xFF2A2A2A)
                : const Color(0xFFF5F5F5);

            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.grey.shade600
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        editIndex != null ? 'Edit Reminder' : 'Add Reminder',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor),
                      ),
                      const SizedBox(height: 24),

                      _sectionLabel('Nama Obat', textColor),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        style: TextStyle(color: textColor),
                        decoration: _inputDeco(
                            hint: 'Contoh: Amoxicillin 500 mg',
                            isDark: isDark,
                            inputFill: inputFill),
                        validator: (v) => v == null || v.isEmpty
                            ? 'Nama obat wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 20),

                      _sectionLabel('Waktu Minum', textColor),
                      const SizedBox(height: 4),
                      Text(
                        '1x=07:00 | 2x=07:00&19:00 | 3x=07:00,15:00&23:00',
                        style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade500),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _timeCheckbox(
                              label: 'Pagi',
                              value: _morning,
                              onChanged: (v) =>
                                  setSheet(() => _morning = v!),
                              textColor: textColor),
                          const SizedBox(width: 20),
                          _timeCheckbox(
                              label: 'Siang',
                              value: _afternoon,
                              onChanged: (v) =>
                                  setSheet(() => _afternoon = v!),
                              textColor: textColor),
                          const SizedBox(width: 20),
                          _timeCheckbox(
                              label: 'Malam',
                              value: _evening,
                              onChanged: (v) =>
                                  setSheet(() => _evening = v!),
                              textColor: textColor),
                        ],
                      ),
                      const SizedBox(height: 20),

                      if (_morning || _afternoon || _evening) ...[
                        _sectionLabel('Dosis (Tablet)', textColor),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (_morning)
                              _doseCounter(
                                label: 'Pagi',
                                value: _morningDose,
                                onDecrement: () => setSheet(() {
                                  if (_morningDose > 0) _morningDose--;
                                }),
                                onIncrement: () =>
                                    setSheet(() => _morningDose++),
                                isDark: isDark,
                                textColor: textColor,
                              ),
                            if (_afternoon)
                              _doseCounter(
                                label: 'Siang',
                                value: _afternoonDose,
                                onDecrement: () => setSheet(() {
                                  if (_afternoonDose > 0) _afternoonDose--;
                                }),
                                onIncrement: () =>
                                    setSheet(() => _afternoonDose++),
                                isDark: isDark,
                                textColor: textColor,
                              ),
                            if (_evening)
                              _doseCounter(
                                label: 'Malam',
                                value: _eveningDose,
                                onDecrement: () => setSheet(() {
                                  if (_eveningDose > 0) _eveningDose--;
                                }),
                                onIncrement: () =>
                                    setSheet(() => _eveningDose++),
                                isDark: isDark,
                                textColor: textColor,
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      _sectionLabel('Aturan Minum', textColor),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _rulesController,
                        style: TextStyle(color: textColor),
                        decoration: _inputDeco(
                            hint: 'Contoh: Setelah Makan',
                            isDark: isDark,
                            inputFill: inputFill),
                      ),
                      const SizedBox(height: 20),

                      _sectionLabel('Berapa Hari?', textColor),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: inputFill,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                size: 20, color: Color(0xFF1E88E5)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text('$_durationDays Hari',
                                  style: TextStyle(
                                      fontSize: 15, color: textColor)),
                            ),
                            GestureDetector(
                              onTap: () => setSheet(() {
                                if (_durationDays > 1) _durationDays--;
                              }),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF3A3A3A)
                                      : Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.remove, size: 18),
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () =>
                                  setSheet(() => _durationDays++),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF3A3A3A)
                                      : Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      _sectionLabel('Kegunaan', textColor),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _purposeController,
                        style: TextStyle(color: textColor),
                        decoration: _inputDeco(
                            hint: 'Contoh: Antibiotik untuk infeksi',
                            isDark: isDark,
                            inputFill: inputFill),
                      ),
                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => _onSave(ctx, editIndex),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E88E5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                            elevation: 0,
                          ),
                          child: Text(
                            editIndex != null ? 'Update' : 'Save',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _onSave(BuildContext ctx, int? editIndex) async {
    if (!_formKey.currentState!.validate()) return;
    if (!_morning && !_afternoon && !_evening) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal 1 waktu minum')),
      );
      return;
    }

    final times = <String>[];
    final doses = <String>[];
    if (_morning) {
      times.add('Pagi');
      doses.add('Pagi: $_morningDose tablet');
    }
    if (_afternoon) {
      times.add('Siang');
      doses.add('Siang: $_afternoonDose tablet');
    }
    if (_evening) {
      times.add('Malam');
      doses.add('Malam: $_eveningDose tablet');
    }

    final data = {
      'name': _nameController.text.trim(),
      'times': times,
      'doses': doses,
      'rules': _rulesController.text.trim().isEmpty
          ? '-'
          : _rulesController.text.trim(),
      'days': _durationDays,
      'purpose': _purposeController.text.trim().isEmpty
          ? '-'
          : _purposeController.text.trim(),
      'isActive': true,
      'addedAt': DateTime.now().toIso8601String(),
    };

    final provider = Provider.of<ReminderProvider>(context, listen: false);
    Navigator.pop(ctx);

    if (editIndex != null) {
      await provider.updateReminder(editIndex, data);
      final reminders = provider.reminders;
      if (editIndex < reminders.length) {
        final id = reminders[editIndex]['id'] ?? editIndex;
        await _scheduleNotifications(
          reminderId: id.hashCode,
          medicineName: data['name'] as String,
          times: times,
          durationDays: _durationDays,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Reminder berhasil diupdate!'),
              backgroundColor: Color(0xFF1E88E5)),
        );
      }
    } else {
      await provider.addReminder(data);

      final reminders = provider.reminders;
      if (reminders.isNotEmpty) {
        final newReminder = reminders.first;
        final id = newReminder['id'] ?? DateTime.now().millisecondsSinceEpoch;
        await _scheduleNotifications(
          reminderId: id.hashCode,
          medicineName: data['name'] as String,
          times: times,
          durationDays: _durationDays,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Reminder berhasil ditambahkan!'),
              backgroundColor: Color(0xFF1E88E5)),
        );
      }
    }
  }

  // ✅ PERBAIKAN UTAMA: hapus berdasarkan id (bukan index)
  // agar tidak salah target saat list berubah
  Future<void> _deleteReminder(Map<String, dynamic> reminder) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Dialog konfirmasi sebelum hapus
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(Icons.delete_outline, color: Colors.red.shade400),
          const SizedBox(width: 8),
          Text('Hapus Reminder',
              style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF1E1E1E),
                  fontSize: 18)),
        ]),
        content: Text(
          'Hapus reminder "${reminder['name']}"?\nNotifikasi terjadwal juga akan dibatalkan.',
          style: TextStyle(
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal',
                style: TextStyle(
                    color:
                        isDark ? Colors.white60 : Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0),
            child: const Text('Hapus',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Tampilkan loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF1E88E5)),
      ),
    );

    try {
      // ✅ _cancelNotifications dibungkus try-catch sendiri
      // agar error ProGuard/R8 dari flutter_local_notifications
      // tidak menghentikan proses hapus data Firestore
      try {
        final reminderId = reminder['id'] ?? reminder['name'];
        await _cancelNotifications(reminderId.hashCode);
      } catch (notifError) {
        debugPrint('⚠️ Cancel notif error (diabaikan): $notifError');
      }

      final provider = Provider.of<ReminderProvider>(context, listen: false);

      // Cari index fresh dari provider berdasarkan id
      final freshIndex = provider.reminders
          .indexWhere((r) => r['id'] == reminder['id']);

      // Tutup loading
      if (mounted) Navigator.pop(context);

      if (freshIndex == -1) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Debug: id="${reminder['id']}", total=${provider.reminders.length}'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 8)),
          );
        }
        return;
      }

      await provider.removeReminder(freshIndex);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Reminder berhasil dihapus'),
              backgroundColor: Color(0xFF1E88E5)),
        );
      }
    } catch (e) {
      // Tutup loading jika error
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 8)),
        );
      }
    }
  }

  Widget _sectionLabel(String text, Color textColor) => Text(
        text,
        style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
      );

  InputDecoration _inputDeco({
    String hint = '',
    required bool isDark,
    required Color inputFill,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
            fontSize: 14),
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF1E88E5), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  Widget _timeCheckbox({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
    required Color textColor,
  }) =>
      Row(
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF1E88E5),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          Text(label, style: TextStyle(fontSize: 14, color: textColor)),
        ],
      );

  Widget _doseCounter({
    required String label,
    required int value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    required bool isDark,
    required Color textColor,
  }) =>
      Column(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54)),
          const SizedBox(height: 6),
          Row(
            children: [
              GestureDetector(
                onTap: onDecrement,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF3A3A3A)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.remove, size: 16, color: textColor),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('$value',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor)),
              ),
              GestureDetector(
                onTap: onIncrement,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF3A3A3A)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.add, size: 16, color: textColor),
                ),
              ),
            ],
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E1E1E);
    final subColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;
    final provider = context.watch<ReminderProvider>();
    final reminders = provider.reminders;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        toolbarHeight: 56,
        title: const Text('Reminder',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        elevation: 0,
        backgroundColor: const Color(0xFF1E88E5),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: reminders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E88E5).withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.alarm_off,
                        size: 64, color: Color(0xFF1E88E5)),
                  ),
                  const SizedBox(height: 20),
                  Text('Belum ada reminder',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: textColor)),
                  const SizedBox(height: 8),
                  Text('Ketuk + untuk menambahkan reminder',
                      style: TextStyle(fontSize: 14, color: subColor)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: reminders.length,
              itemBuilder: (context, index) {
                // ✅ Ambil snapshot reminder di awal builder
                // agar seluruh widget dalam item pakai data yang sama
                final reminder =
                    Map<String, dynamic>.from(reminders[index]);
                final isActive = reminder['isActive'] as bool;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFF1E88E5)
                                        .withOpacity(0.1)
                                    : (isDark
                                        ? const Color(0xFF3A3A3A)
                                        : Colors.grey.shade100),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.alarm,
                                  color: isActive
                                      ? const Color(0xFF1E88E5)
                                      : Colors.grey,
                                  size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(reminder['name'],
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: textColor)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  size: 20, color: Color(0xFF1E88E5)),
                              onPressed: () => _showReminderSheet(
                                  editIndex: index, existing: reminder),
                              tooltip: 'Edit',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 4),
                            Switch(
                              value: isActive,
                              onChanged: (val) async {
                                await provider.toggleReminder(index, val);
                                if (!val) {
                                  final id = reminder['id'] ?? index;
                                  await _cancelNotifications(id.hashCode);
                                } else {
                                  final id = reminder['id'] ?? index;
                                  final times = (reminder['times']
                                      as List<String>);
                                  await _scheduleNotifications(
                                    reminderId: id.hashCode,
                                    medicineName: reminder['name'],
                                    times: times,
                                    durationDays: reminder['days'] ?? 7,
                                  );
                                }
                              },
                              activeColor: const Color(0xFF1E88E5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...(reminder['doses'] as List<String>).map(
                          (d) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(d,
                                style: TextStyle(
                                    fontSize: 13, color: textColor)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.info_outline,
                                size: 14, color: subColor),
                            const SizedBox(width: 4),
                            Text('Aturan: ${reminder['rules']}',
                                style: TextStyle(
                                    fontSize: 12, color: subColor)),
                            const SizedBox(width: 12),
                            Icon(Icons.calendar_today_outlined,
                                size: 14, color: subColor),
                            const SizedBox(width: 4),
                            Text('${reminder['days']} Hari',
                                style: TextStyle(
                                    fontSize: 12, color: subColor)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          children: (reminder['times'] as List<String>)
                              .map((t) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFF1E88E5)
                                        .withOpacity(0.1)
                                    : (isDark
                                        ? const Color(0xFF3A3A3A)
                                        : Colors.grey.shade100),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(t,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: isActive
                                          ? const Color(0xFF1E88E5)
                                          : subColor,
                                      fontWeight: FontWeight.w500)),
                            );
                          }).toList(),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          // ✅ Panggil _deleteReminder dengan data reminder,
                          // bukan index — aman meski list berubah
                          child: TextButton.icon(
                            onPressed: () => _deleteReminder(reminder),
                            icon: Icon(Icons.delete_outline,
                                size: 16, color: Colors.red.shade300),
                            label: Text('Hapus',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red.shade300)),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF1E88E5).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 6)),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _showReminderSheet(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}