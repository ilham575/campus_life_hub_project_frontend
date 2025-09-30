import 'dart:ui';
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

class _TimetablePageState extends State<TimetablePage> {
  bool _isLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isLoaded) {
      Provider.of<TimetableState>(context, listen: false).loadFromApi(widget.userId);
      _isLoaded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timetable = Provider.of<TimetableState>(context);

    return Scaffold(
      backgroundColor: const LinearGradient(
        colors: [Color(0xFFF5F7FB), Color(0xFFE8ECF7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, MediaQuery.of(context).size.width, MediaQuery.of(context).size.height)) !=
              null
          ? null
          : Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.indigo[700],
        foregroundColor: Colors.white,
        title: const Text(
          "ตารางเรียน",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 0.2),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.13),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              icon: Icon(
                timetable.isGrid ? Icons.view_agenda_rounded : Icons.grid_view_rounded,
                color: Colors.white,
                size: 26,
              ),
              onPressed: timetable.toggleView,
              splashRadius: 24,
            ),
          ),
        ],
      ),
      body: timetable.subjects.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.schedule_outlined, size: 90, color: Colors.indigo[100]),
                  const SizedBox(height: 18),
                  Text(
                    "ยังไม่มีรายวิชา",
                    style: TextStyle(fontSize: 20, color: Colors.indigo[400], fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "เพิ่มรายวิชาแรกของคุณ",
                    style: TextStyle(fontSize: 15, color: Colors.indigo[200]),
                  ),
                ],
              ),
            )
          : (timetable.isGrid ? buildGrid(context, timetable) : buildList(context, timetable)),
      floatingActionButton: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: [Colors.indigo[600]!.withOpacity(0.92), Colors.indigo[300]!.withOpacity(0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withOpacity(0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: () => _showAddDialog(context, timetable),
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: const Icon(Icons.add_rounded, size: 32, color: Colors.white),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              splashColor: Colors.indigo[100],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, TimetableState timetable) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SubjectDialog(userId: widget.userId),
    );
  }

  Widget buildGrid(BuildContext context, TimetableState timetable) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.82,
          crossAxisSpacing: 18,
          mainAxisSpacing: 18,
        ),
        itemCount: timetable.subjects.length,
        itemBuilder: (context, index) {
          final subject = timetable.subjects[index];
          final colors = [
            [Colors.blue[400]!, Colors.blue[200]!],
            [Colors.purple[400]!, Colors.purple[200]!],
            [Colors.teal[400]!, Colors.teal[200]!],
            [Colors.orange[400]!, Colors.orange[200]!],
            [Colors.pink[400]!, Colors.pink[200]!],
          ];
          final colorPair = colors[index % colors.length];

          return ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorPair[0].withOpacity(0.93),
                      colorPair[1].withOpacity(0.82),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: colorPair[0].withOpacity(0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(color: Colors.white.withOpacity(0.13), width: 1.2),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => SubjectDialog(
                          userId: widget.userId,
                          subject: subject,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.22),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.book_rounded, color: Colors.white, size: 22),
                              ),
                              const Spacer(),
                              Icon(Icons.more_vert, color: Colors.white.withOpacity(0.85), size: 22),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            subject.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "${subject.schedules.length} ช่วงเวลา",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.85),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          ...subject.schedules.take(3).map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(Icons.access_time_rounded, size: 13, color: Colors.white.withOpacity(0.85)),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    "${s.day} ${s.startTime}-${s.endTime}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.93),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildList(BuildContext context, TimetableState timetable) {
    final day = timetable.selectedWeekday;
    final todaySchedules = timetable.subjects.expand((subj) {
      return subj.schedules.where((s) => s.day == day).map((s) => {
            "subject": subj.name,
            "start": s.startTime,
            "end": s.endTime,
            "subject_id": subj.id,
            "schedule_id": s.id,
          });
    }).toList();

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(18),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.indigo.withOpacity(0.06),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.indigo[50]!, width: 1.1),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: timetable.days.map((d) {
                final isSelected = d == day;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.indigo[600] : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.indigo.withOpacity(0.13),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => timetable.setDay(d),
                    child: Text(
                      d,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.indigo[400],
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 15,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          child: todaySchedules.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy_rounded, size: 70, color: Colors.indigo[100]),
                      const SizedBox(height: 14),
                      Text(
                        "ไม่มีตารางเรียนในวัน$day",
                        style: TextStyle(fontSize: 17, color: Colors.indigo[400], fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  itemCount: todaySchedules.length,
                  itemBuilder: (context, index) {
                    final item = todaySchedules[index];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.97),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.indigo.withOpacity(0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: Colors.indigo[50]!, width: 1.1),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(18),
                            leading: Container(
                              padding: const EdgeInsets.all(13),
                              decoration: BoxDecoration(
                                color: Colors.indigo[50],
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Icon(Icons.book_rounded, color: Colors.indigo[600], size: 26),
                            ),
                            title: Text(
                              item["subject"]! as String,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.1,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  Icon(Icons.access_time_rounded, size: 17, color: Colors.indigo[300]),
                                  const SizedBox(width: 5),
                                  Text(
                                    "${item["start"]! as String} - ${item["end"]! as String}",
                                    style: TextStyle(color: Colors.indigo[400], fontSize: 15, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                  onPressed: () {
                                    final subject = timetable.subjects.firstWhere(
                                      (subj) => subj.id == item["subject_id"],
                                    );
                                    showDialog(
                                      context: context,
                                      builder: (_) => SubjectDialog(
                                        userId: widget.userId,
                                        subject: subject,
                                      ),
                                    );
                                  },
                                  splashRadius: 22,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                                  onPressed: () async {
                                    await timetable.removeScheduleAndCheck(item["schedule_id"] as int);
                                  },
                                  splashRadius: 22,
                                ),
                              ],
                            ),
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
