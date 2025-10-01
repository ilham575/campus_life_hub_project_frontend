import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class Event {
  final int? id;
  final String title;
  final String? description;
  final DateTime start;
  final DateTime end;

  Event({
    this.id,
    required this.title,
    required this.start,
    required this.end,
    this.description,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      start: DateTime.parse(json['start_time']),
      end: DateTime.parse(json['end_time']),
    );
  }

  Map<String, dynamic> toJson({required String userId}) {
    return {
      'title': title,
      'description': description,
      'start_time': start.toIso8601String(),
      'end_time': end.toIso8601String(),
      'user_id': userId,
    };
  }
}

class CreateEventScreen extends StatefulWidget {
  final String userId;
  const CreateEventScreen({super.key, required this.userId});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  List<Event> _events = [];
  bool _isLoading = false;

  final String apiUrl = 'http://10.0.2.2:8000/events/';

  String get _userId => widget.userId;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    if (_userId.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse('$apiUrl?user_id=$_userId'));
      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        setState(() {
          _events = data.map((e) => Event.fromJson(e)).toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('โหลดกิจกรรมล้มเหลว: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createEvent() async {
    final created = await Navigator.push<Event>(
      context,
      MaterialPageRoute(builder: (_) => const CreateEventPage()),
    );
    if (created != null && _userId.isNotEmpty) {
      try {
        final res = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(created.toJson(userId: _userId)),
        );
        if (res.statusCode == 200 || res.statusCode == 201) {
          _loadEvents();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('สร้างกิจกรรมล้มเหลว: $e')),
        );
      }
    }
  }

  Future<void> _editEvent(Event event) async {
    final edited = await Navigator.push<Event>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateEventPage(event: event),
      ),
    );
    if (edited != null && event.id != null && _userId.isNotEmpty) {
      try {
        final res = await http.put(
          Uri.parse('$apiUrl${event.id}'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(edited.toJson(userId: _userId)),
        );
        if (res.statusCode == 200) {
          _loadEvents();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('แก้ไขกิจกรรมล้มเหลว: $e')),
        );
      }
    }
  }

  Future<void> _deleteEvent(Event event) async {
    if (event.id == null || _userId.isEmpty) return;
    try {
      final res = await http.delete(
        Uri.parse('$apiUrl${event.id}?user_id=$_userId'),
      );
      if (res.statusCode == 200) {
        _loadEvents();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ลบกิจกรรมล้มเหลว: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(
      colors: [Color(0xFFF5F7FB), Color(0xFFE8ECF7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.indigo[700],
          foregroundColor: Colors.white,
          title: const Text(
            'กิจกรรมของฉัน',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 0.2),
          ),
        ),
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
                onPressed: _createEvent,
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const Icon(Icons.add_rounded, size: 32, color: Colors.white),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                splashColor: Colors.indigo[100],
              ),
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _events.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_note_rounded, size: 90, color: Colors.indigo[100]),
                        const SizedBox(height: 18),
                        Text(
                          "ยังไม่มีกิจกรรม",
                          style: TextStyle(fontSize: 20, color: Colors.indigo[400], fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "เพิ่มกิจกรรมแรกของคุณ",
                          style: TextStyle(fontSize: 15, color: Colors.indigo[200]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(18),
                    itemCount: _events.length,
                    itemBuilder: (context, index) {
                      final event = _events[index];
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
                            margin: const EdgeInsets.only(bottom: 18),
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
                                onTap: () {},
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
                                            child: const Icon(Icons.event, color: Colors.white, size: 22),
                                          ),
                                          const Spacer(),
                                          PopupMenuButton<String>(
                                            color: Colors.white,
                                            onSelected: (value) {
                                              if (value == 'edit') {
                                                _editEvent(event);
                                              } else if (value == 'delete') {
                                                _deleteEvent(event);
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(
                                                value: 'edit',
                                                child: Text('แก้ไข'),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Text('ลบ'),
                                              ),
                                            ],
                                            icon: Icon(Icons.more_vert, color: Colors.white.withOpacity(0.85), size: 22),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        event.title,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.2,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (event.description != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text(
                                            event.description!,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.white.withOpacity(0.93),
                                            ),
                                          ),
                                        ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: Row(
                                          children: [
                                            Icon(Icons.access_time_rounded, size: 16, color: Colors.white.withOpacity(0.93)),
                                            const SizedBox(width: 7),
                                            Text(
                                              'เริ่ม: ${DateFormat('d MMMM yyyy, HH:mm', 'th').format(event.start)}',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.93),
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Row(
                                          children: [
                                            Icon(Icons.access_time_rounded, size: 16, color: Colors.white.withOpacity(0.93)),
                                            const SizedBox(width: 7),
                                            Text(
                                              'สิ้นสุด: ${DateFormat('d MMMM yyyy, HH:mm', 'th').format(event.end)}',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.93),
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
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
      ),
    );
  }
}

class CreateEventPage extends StatefulWidget {
  final Event? event;

  const CreateEventPage({super.key, this.event});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _titleCtrl.text = widget.event!.title;
      _descCtrl.text = widget.event!.description ?? '';
      _start = widget.event!.start;
      _end = widget.event!.end;
    } else {
      _start = _roundToNext15(DateTime.now().add(const Duration(minutes: 5)));
      _end = _roundToNext15(DateTime.now().add(const Duration(hours: 1)));
    }
  }

  static DateTime _roundToNext15(DateTime dt) {
    final minutes = ((dt.minute + 14) ~/ 15) * 15;
    final addMinutes = (minutes == 60) ? (60 - dt.minute) : (minutes - dt.minute);
    final rounded = dt.add(Duration(minutes: addMinutes));
    return DateTime(dt.year, dt.month, dt.day, rounded.hour, rounded.minute);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      initialDate: _start,
    );
    if (d == null) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_start),
    );
    if (t == null) return;
    setState(() {
      _start = DateTime(d.year, d.month, d.day, t.hour, t.minute);
      if (!_start.isBefore(_end)) {
        _end = _start.add(const Duration(hours: 1));
      }
    });
  }

  Future<void> _pickEnd() async {
    final d = await showDatePicker(
      context: context,
      firstDate: _start,
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      initialDate: _end,
    );
    if (d == null) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_end),
    );
    if (t == null) return;
    setState(() {
      _end = DateTime(d.year, d.month, d.day, t.hour, t.minute);
      if (!_start.isBefore(_end)) {
        _start = _end.subtract(const Duration(hours: 1));
      }
    });
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    final event = Event(
      id: widget.event?.id,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      start: _start,
      end: _end,
    );
    Navigator.of(context).pop(event);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.event != null;
    final gradient = const LinearGradient(
      colors: [Color(0xFFF5F7FB), Color(0xFFE8ECF7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.indigo[700],
          foregroundColor: Colors.white,
          title: Text(isEditing ? 'แก้ไขกิจกรรม' : 'สร้างกิจกรรม'),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.indigo.withOpacity(0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: Colors.indigo[50]!, width: 1.1),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextFormField(
                              controller: _titleCtrl,
                              decoration: InputDecoration(
                                labelText: 'หัวข้อ',
                                hintText: 'ประชุมโปรเจค, หาหมอ, ...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              textInputAction: TextInputAction.next,
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty) ? 'กรุณาใส่หัวข้อ' : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _descCtrl,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'รายละเอียด',
                                alignLabelWithHint: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 18),
                            _DateTimeTile(
                              label: 'เริ่ม',
                              dateTime: _start,
                              onTap: _pickStart,
                            ),
                            const SizedBox(height: 10),
                            _DateTimeTile(
                              label: 'สิ้นสุด',
                              dateTime: _end,
                              onTap: _pickEnd,
                            ),
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _submit,
                                icon: const Icon(Icons.check, color: Colors.white),
                                label: Text(
                                  isEditing ? 'บันทึกการแก้ไข' : 'สร้างกิจกรรม',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.indigo[600],
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile({
    required this.label,
    required this.dateTime,
    required this.onTap,
  });

  final String label;
  final DateTime dateTime;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final styleLabel = Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.indigo[700]);
    final styleValue = Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.indigo[900]);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.indigo[50],
          border: Border.all(color: Colors.indigo[100]!),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: styleLabel),
                  const SizedBox(height: 2),
                  Text(
                    _formatDateTime(dateTime),
                    style: styleValue,
                  ),
                ],
              ),
            ),
            const Icon(Icons.calendar_today, color: Colors.indigo),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final buddhistYear = dt.year + 543;
    final formatter = DateFormat('d MMMM', 'th');
    final dateStr = formatter.format(dt);
    final timeStr = DateFormat('HH:mm', 'th').format(dt);
    return '$dateStr $buddhistYear, $timeStr';
  }
}