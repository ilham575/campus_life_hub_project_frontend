import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'timetable_state.dart';

class SubjectDialog extends StatefulWidget {
  final String userId;
  final Subject? subject; // ✅ null = add, not null = edit

  const SubjectDialog({super.key, required this.userId, this.subject});

  @override
  State<SubjectDialog> createState() => _SubjectDialogState();
}

class _SubjectDialogState extends State<SubjectDialog> with SingleTickerProviderStateMixin {
  final TextEditingController _subjectController = TextEditingController();
  List<Schedule> schedules = [Schedule(day: "", startTime: "", endTime: "")];
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  String? errorText;

  @override
  void initState() {
    super.initState();

    // ✅ ถ้ามี subject แสดงว่าแก้ไข
    if (widget.subject != null) {
      _subjectController.text = widget.subject!.name;
      schedules = widget.subject!.schedules
          .map((s) => Schedule(id: s.id, day: s.day, startTime: s.startTime, endTime: s.endTime))
          .toList();
    }

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  void addSchedule() {
    setState(() {
      schedules.add(Schedule(day: "", startTime: "", endTime: ""));
    });
  }

  void removeSchedule(int index) {
    setState(() {
      schedules.removeAt(index);
    });
  }

  Future<void> _pickTime(int index, bool isStart) async {
    final initial = TimeOfDay(
      hour: int.tryParse((isStart ? schedules[index].startTime : schedules[index].endTime).split(":").first) ?? 9,
      minute: int.tryParse((isStart ? schedules[index].startTime : schedules[index].endTime).split(":").last) ?? 0,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.indigo[600]!,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.indigo[900]!,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        final formatted = picked.format(context);
        final parts = formatted.split(' ');
        String time24 = picked.hour.toString().padLeft(2, '0') + ':' + picked.minute.toString().padLeft(2, '0');
        if (isStart) {
          schedules[index].startTime = time24;
        } else {
          schedules[index].endTime = time24;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final timetable = Provider.of<TimetableState>(context);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Center(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 650, maxWidth: 420),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.85),
                        Colors.indigo[50]!.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withOpacity(0.08),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                    border: Border.all(color: Colors.indigo[100]!, width: 1.2),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.indigo[700]!, Colors.indigo[400]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(28),
                            topRight: Radius.circular(28),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.indigo.withOpacity(0.10),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                widget.subject == null ? Icons.add_rounded : Icons.edit,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 18),
                            Text(
                              widget.subject == null ? "เพิ่มรายวิชาใหม่" : "แก้ไขรายวิชา",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Spacer(),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(30),
                                onTap: () => Navigator.pop(context),
                                child: const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: Icon(Icons.close_rounded, color: Colors.white, size: 26),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Content
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Subject name input
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.92),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: Colors.indigo[100]!),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.indigo.withOpacity(0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _subjectController,
                                  style: const TextStyle(fontSize: 17),
                                  decoration: InputDecoration(
                                    labelText: "ชื่อรายวิชา",
                                    prefixIcon: Icon(Icons.book_rounded, color: Colors.indigo[600]),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(20),
                                    labelStyle: TextStyle(color: Colors.indigo[400]),
                                  ),
                                ),
                              ),
                              if (errorText != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8, left: 8),
                                  child: Text(
                                    errorText!,
                                    style: const TextStyle(color: Colors.red, fontSize: 13),
                                  ),
                                ),
                              const SizedBox(height: 26),

                              // Schedule header
                              Row(
                                children: [
                                  Icon(Icons.schedule_rounded, color: Colors.indigo[600], size: 22),
                                  const SizedBox(width: 10),
                                  const Text(
                                    "ตารางเวลา",
                                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),

                              // Schedule list
                              ...List.generate(schedules.length, (index) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 18),
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.97),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: Colors.indigo[50]!),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.indigo.withOpacity(0.03),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Text("ช่วงเวลา ${index + 1}",
                                              style: const TextStyle(
                                                  fontSize: 15, fontWeight: FontWeight.w600)),
                                          const Spacer(),
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(20),
                                              onTap: () => removeSchedule(index),
                                              child: const Padding(
                                                padding: EdgeInsets.all(4),
                                                child: Icon(Icons.delete, color: Colors.red, size: 22),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      DropdownButtonFormField<String>(
                                        value: schedules[index].day.isEmpty ? null : schedules[index].day,
                                        decoration: InputDecoration(
                                          labelText: "วัน",
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.indigo[100]!),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        ),
                                        items: timetable.days
                                            .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                                            .toList(),
                                        onChanged: (val) => setState(() => schedules[index].day = val ?? ""),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () => _pickTime(index, true),
                                              child: AbsorbPointer(
                                                child: TextField(
                                                  controller: TextEditingController(text: schedules[index].startTime),
                                                  decoration: InputDecoration(
                                                    labelText: "เวลาเริ่ม (เช่น 09:00)",
                                                    border: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                      borderSide: BorderSide(color: Colors.indigo[100]!),
                                                    ),
                                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                                    suffixIcon: Icon(Icons.access_time, color: Colors.indigo[400], size: 20),
                                                  ),
                                                  style: const TextStyle(fontSize: 15),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () => _pickTime(index, false),
                                              child: AbsorbPointer(
                                                child: TextField(
                                                  controller: TextEditingController(text: schedules[index].endTime),
                                                  decoration: InputDecoration(
                                                    labelText: "เวลาสิ้นสุด (เช่น 10:30)",
                                                    border: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                      borderSide: BorderSide(color: Colors.indigo[100]!),
                                                    ),
                                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                                    suffixIcon: Icon(Icons.access_time, color: Colors.indigo[400], size: 20),
                                                  ),
                                                  style: const TextStyle(fontSize: 15),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              Center(
                                child: TextButton.icon(
                                  icon: const Icon(Icons.add, color: Colors.indigo),
                                  label: const Text("เพิ่มช่วงเวลาใหม่", style: TextStyle(fontWeight: FontWeight.w600)),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.indigo[700],
                                    textStyle: const TextStyle(fontSize: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: addSchedule,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Footer
                      Padding(
                        padding: const EdgeInsets.all(28),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.indigo[700],
                                  side: BorderSide(color: Colors.indigo[200]!),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text("ยกเลิก", style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  setState(() => errorText = null);
                                  if (_subjectController.text.trim().isEmpty) {
                                    setState(() => errorText = "กรุณากรอกชื่อรายวิชา");
                                    return;
                                  }
                                  bool hasEmpty = schedules.any((s) =>
                                    s.day.isEmpty || s.startTime.isEmpty || s.endTime.isEmpty);
                                  if (hasEmpty) {
                                    setState(() => errorText = "กรุณากรอกข้อมูลตารางเวลาให้ครบถ้วน");
                                    return;
                                  }
                                  if (widget.subject == null) {
                                    await timetable.addSubject(
                                      _subjectController.text.trim(),
                                      schedules,
                                      widget.userId,
                                    );
                                  } else {
                                    await timetable.updateSubject(
                                      widget.subject!.id,
                                      _subjectController.text.trim(),
                                      schedules,
                                      widget.userId,
                                    );
                                  }
                                  Navigator.pop(context, true);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo[600],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 2,
                                ),
                                child: Text(
                                  widget.subject == null ? "บันทึก" : "อัพเดต",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
