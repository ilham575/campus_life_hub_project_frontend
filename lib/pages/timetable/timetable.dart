import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'timetable_state.dart';
import 'subject_dialog.dart';

class TimetablePage extends StatefulWidget {
  final String userId;

  const TimetablePage({super.key, required this.userId});

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> with TickerProviderStateMixin {
  bool _isLoaded = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isLoaded) {
      Provider.of<TimetableState>(context, listen: false)
          .loadFromApi(widget.userId);
      _isLoaded = true;
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final timetable = Provider.of<TimetableState>(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6A11CB),
              Color(0xFF2575FC),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'ตารางเรียน',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          timetable.isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded,
                          color: Colors.white,
                        ),
                        onPressed: timetable.toggleView,
                      ),
                    ),
                  ],
                ),
              ),
              // Content Area
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Expanded(
                          child: timetable.isGrid
                              ? buildGrid(context, timetable)
                              : buildList(context, timetable),
                        ),
                        // Modern FAB
                        Container(
                          margin: const EdgeInsets.all(20),
                          child: ElevatedButton(
                            onPressed: () => _showAddDialog(context, timetable),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6A11CB),
                              foregroundColor: Colors.white,
                              elevation: 8,
                              shadowColor: const Color(0xFF6A11CB).withOpacity(0.5),
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_circle_outline, size: 24),
                                SizedBox(width: 8),
                                Text(
                                  'เพิ่มรายวิชา',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, TimetableState timetable) {
    String? selectedDay;
    String? selectedTime;
    final controller = TextEditingController();

    void updateController() {
      if (selectedDay != null && selectedTime != null) {
        final key = '$selectedDay|$selectedTime';
        controller.text = timetable.subjects[key] ?? '';
      }
    }

    bool hasSubject() {
      if (selectedDay == null || selectedTime == null) return false;
      return timetable.subjects.containsKey('$selectedDay|$selectedTime');
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => SubjectDialog(
          selectedDay: selectedDay,
          selectedTime: selectedTime,
          controller: controller,
          onDayChanged: (val) {
            setState(() {
              selectedDay = val;
              updateController();
            });
          },
          onTimeChanged: (val) {
            setState(() {
              selectedTime = val;
              updateController();
            });
          },
          onSave: () {
            if (selectedDay != null &&
                selectedTime != null &&
                controller.text.trim().isNotEmpty) {
              timetable.updateSubject(
                widget.userId,
                selectedDay!,
                selectedTime!,
                controller.text.trim(),
              );
            }
          },
          onDelete: hasSubject()
              ? () {
                  final id = timetable.getIdFor(selectedDay!, selectedTime!);
                  if (id != null) {
                    timetable.removeSubject(id, selectedDay!, selectedTime!);
                  }
                }
              : null,
          showDropdowns: true,
        ),
      ),
    );
  }

  Widget buildGrid(BuildContext context, TimetableState timetable) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Card(
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
            ),
            child: Table(
              border: TableBorder.all(color: Colors.grey[200]!, width: 1),
              defaultColumnWidth: const FixedColumnWidth(120),
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  children: [
                    const TableCell(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(
                          child: Text(
                            'วัน/เวลา',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    ...timetable.times.map((t) => TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Center(
                          child: Text(
                            t,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    )),
                  ],
                ),
                ...timetable.days.map((day) {
                  return TableRow(
                    children: [
                      TableCell(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                          ),
                          child: Center(
                            child: Text(
                              day,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6A11CB),
                              ),
                            ),
                          ),
                        ),
                      ),
                      ...timetable.times.map((time) {
                        final key = '$day|$time';
                        final subject = timetable.subjects[key] ?? '';
                        return TableCell(
                          child: InkWell(
                            onTap: () => _showEditDialog(context, timetable, day, time, subject),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              alignment: Alignment.center,
                              height: 60,
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: subject.isNotEmpty 
                                    ? const Color(0xFF6A11CB).withOpacity(0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: subject.isNotEmpty
                                    ? Border.all(color: const Color(0xFF6A11CB).withOpacity(0.3))
                                    : null,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Text(
                                  subject,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: subject.isNotEmpty ? FontWeight.w500 : FontWeight.normal,
                                    color: subject.isNotEmpty ? const Color(0xFF6A11CB) : Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, TimetableState timetable, String day, String time, String subject) {
    final controller = TextEditingController(text: subject);

    showDialog(
      context: context,
      builder: (_) => SubjectDialog(
        selectedDay: day,
        selectedTime: time,
        controller: controller,
        onDayChanged: (_) {},
        onTimeChanged: (_) {},
        onSave: () {
          if (controller.text.trim().isNotEmpty) {
            timetable.updateSubject(
              widget.userId,
              day,
              time,
              controller.text.trim(),
            );
          }
        },
        onDelete: subject.isNotEmpty
            ? () {
                final id = timetable.getIdFor(day, time);
                if (id != null) {
                  timetable.removeSubject(id, day, time);
                }
              }
            : null,
        showDropdowns: false,
      ),
    );
  }

  Widget buildList(BuildContext context, TimetableState timetable) {
    final day = timetable.selectedWeekday;
    final filtered = timetable.times.map((time) {
      final key = '$day|$time';
      return {
        'time': time,
        'subject': timetable.subjects[key] ?? '',
      };
    }).where((e) => e['subject']!.isNotEmpty).toList();

    return Column(
      children: [
        Container(
          height: 80,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: timetable.days.map((d) {
              final selected = d == day;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: FilterChip(
                  label: Text(
                    d,
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF6A11CB),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  selected: selected,
                  onSelected: (_) => timetable.setDay(d),
                  backgroundColor: Colors.white,
                  selectedColor: const Color(0xFF6A11CB),
                  checkmarkColor: Colors.white,
                  elevation: selected ? 4 : 2,
                  shadowColor: const Color(0xFF6A11CB).withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'ไม่มีตารางเรียนในวันนี้',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final item = filtered[i];
                    final subject = item['subject']!;
                    final time = item['time']!;
                    final day = timetable.selectedWeekday;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        elevation: 4,
                        shadowColor: Colors.black.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                const Color(0xFF6A11CB).withOpacity(0.1),
                                Colors.white,
                              ],
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.book_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            title: Text(
                              subject,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            subtitle: Text(
                              time,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              color: Color(0xFF6A11CB),
                              size: 16,
                            ),
                            onTap: () => _showEditDialog(context, timetable, day, time, subject),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
