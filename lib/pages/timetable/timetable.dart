import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'timetable_state.dart';
import 'subject_dialog.dart';

class TimetablePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final timetable = Provider.of<TimetableState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ตารางเรียน'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: Icon(timetable.isGrid ? Icons.list : Icons.grid_on),
            onPressed: timetable.toggleView,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: timetable.isGrid
                ? buildGrid(context, timetable)
                : buildList(context, timetable),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: () {
                String? selectedDay;
                String? selectedTime;
                final controller = TextEditingController();
                final timetable = Provider.of<TimetableState>(context, listen: false);

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
                            selectedDay!,
                            selectedTime!,
                            controller.text.trim(),
                          );
                        }
                      },
                      onDelete: hasSubject()
                          ? () {
                              timetable.removeSubject(
                                  selectedDay!, selectedTime!);
                            }
                          : null,
                      showDropdowns: true, // เพิ่มตรงนี้ (default ก็ได้)
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.edit_calendar),
              label: const Text('จัดการตารางเรียน'),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildGrid(BuildContext context, TimetableState timetable) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        border: TableBorder.all(color: Colors.grey),
        defaultColumnWidth: const FixedColumnWidth(100),
        children: [
          TableRow(
            decoration: BoxDecoration(color: Colors.grey[300]),
            children: [
              const TableCell(child: Center(child: Text('วัน/เวลา'))),
              ...timetable.times.map((t) => TableCell(child: Center(child: Text(t)))),
            ],
          ),
          ...timetable.days.map((day) {
            return TableRow(
              children: [
                TableCell(child: Center(child: Text(day))),
                ...timetable.times.map((time) {
                  final subject = timetable.subjects['$day|$time'] ?? '';
                  return TableCell(
                    child: InkWell(
                      onTap: () {
                        final controller = TextEditingController(text: subject);
                        String selectedDay = day;
                        String selectedTime = time;

                        showDialog(
                          context: context,
                          builder: (_) => SubjectDialog(
                            selectedDay: selectedDay,
                            selectedTime: selectedTime,
                            controller: controller,
                            onDayChanged: (_) {}, // ไม่ต้องแก้วันใน Grid mode
                            onTimeChanged: (_) {},
                            onSave: () {
                              if (controller.text.trim().isNotEmpty) {
                                timetable.updateSubject(
                                    selectedDay, selectedTime, controller.text.trim());
                              }
                            },
                            onDelete: subject.isNotEmpty
                                ? () => timetable.removeSubject(selectedDay, selectedTime)
                                : null,
                            showDropdowns: false, // ซ่อน dropdown
                          ),
                        );
                      },
                      child: Container(
                        alignment: Alignment.center,
                        height: 50,
                        color: subject.isNotEmpty ? Colors.blue[50] : null,
                        child: Text(subject),
                      ),
                    ),
                  );
                }),
              ],
            );
          }),
        ],
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
        SizedBox(
          height: 60,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: timetable.days.map((d) {
              final selected = d == day;
              return Padding(
                padding: const EdgeInsets.all(4.0),
                child: ChoiceChip(
                  label: Text(d),
                  selected: selected,
                  onSelected: (_) => timetable.setDay(d),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('ไม่มีตารางเรียน'))
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final item = filtered[i];
                    final subject = item['subject']!;
                    final time = item['time']!;
                    final day = timetable.selectedWeekday;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        title: Text(subject),
                        subtitle: Text(time),
                        onTap: () {
                          final controller = TextEditingController(text: subject);

                          showDialog(
                            context: context,
                            builder: (_) => SubjectDialog(
                              selectedDay: day,
                              selectedTime: time,
                              controller: controller,
                              onDayChanged: (_) {}, // ไม่ให้เปลี่ยนวันใน list mode
                              onTimeChanged: (_) {},
                              onSave: () {
                                if (controller.text.trim().isNotEmpty) {
                                  timetable.updateSubject(day, time, controller.text.trim());
                                }
                              },
                              onDelete: () => timetable.removeSubject(day, time),
                              showDropdowns: false, // ซ่อน dropdown
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}