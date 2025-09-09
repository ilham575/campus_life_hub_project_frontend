import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'timetable_state.dart';

class SubjectDialog extends StatelessWidget {
  final String? selectedDay;
  final String? selectedTime;
  final TextEditingController controller;
  final void Function(String?) onDayChanged;
  final void Function(String?) onTimeChanged;
  final VoidCallback onSave;
  final VoidCallback? onDelete;
  final bool showDropdowns;

  const SubjectDialog({
    super.key,
    required this.selectedDay,
    required this.selectedTime,
    required this.controller,
    required this.onDayChanged,
    required this.onTimeChanged,
    required this.onSave,
    this.onDelete,
    this.showDropdowns = true,
  });

  @override
  Widget build(BuildContext context) {
    final timetable = Provider.of<TimetableState>(context);

    return AlertDialog(
      title: const Text('จัดการตารางเรียน'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showDropdowns) ...[
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'เลือกวัน'),
              value: selectedDay,
              items: timetable.days
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: onDayChanged,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'เลือกเวลา'),
              value: selectedTime,
              items: timetable.times
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: onTimeChanged,
            ),
            const SizedBox(height: 12),
          ] else ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                selectedDay ?? '',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                selectedTime ?? '',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'ชื่อวิชา'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        if (onDelete != null)
          TextButton(
            onPressed: () {
              onDelete!();
              Navigator.pop(context);
            },
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: () {
            onSave();
            Navigator.pop(context);
          },
          child: const Text('บันทึก'),
        ),
      ],
    );
  }
}