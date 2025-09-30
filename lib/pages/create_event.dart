import 'package:flutter/material.dart';

/// Simple Event model to pass back to the caller.
class Event {
  final String title;
  final String? description;
  final String? location;
  final DateTime start;
  final DateTime end;
  final Duration? reminder; // e.g., 10 minutes before

  Event({
    required this.title,
    required this.start,
    required this.end,
    this.description,
    this.location,
    this.reminder,
  });
}

/// Usage
/// final Event? created = await Navigator.push(
///   context,
///   MaterialPageRoute(builder: (_) => const CreateEventPage()),
/// );
/// if (created != null) { /* save to backend or calendar */ }
class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  DateTime _start = _roundToNext15(DateTime.now().add(const Duration(minutes: 5)));
  DateTime _end = _roundToNext15(DateTime.now().add(const Duration(hours: 1)));

  Duration? _reminder; // null = none

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
    _locationCtrl.dispose();
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
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      location: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
      start: _start,
      end: _end,
      reminder: _reminder,
    );
    Navigator.of(context).pop(event);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Event'),
        actions: [
          TextButton(
            onPressed: _submit,
            child: const Text('SAVE'),
          )
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Project meeting, Dentist, ...',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              _DateTimeTile(
                label: 'Start',
                dateTime: _start,
                onTap: _pickStart,
              ),
              const SizedBox(height: 8),
              _DateTimeTile(
                label: 'End',
                dateTime: _end,
                onTap: _pickEnd,
              ),
              const SizedBox(height: 16),
              _ReminderDropdown(
                value: _reminder,
                onChanged: (d) => setState(() => _reminder = d),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check),
                label: const Text('Create Event'),
              ),
             
            ],
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
    final styleLabel = Theme.of(context).textTheme.labelLarge;
    final styleValue = Theme.of(context).textTheme.titleMedium;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(12),
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
            const Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    // Simple local formatting without intl dependency.
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h:$m';
  }
}

class _ReminderDropdown extends StatelessWidget {
  const _ReminderDropdown({
    required this.value,
    required this.onChanged,
  });

  final Duration? value;
  final ValueChanged<Duration?> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = <(String, Duration?)>[
      ('No reminder', null),
      ('At start time', const Duration(minutes: 0)),
      ('5 minutes before', const Duration(minutes: 5)),
      ('10 minutes before', const Duration(minutes: 10)),
      ('15 minutes before', const Duration(minutes: 15)),
      ('30 minutes before', const Duration(minutes: 30)),
      ('1 hour before', const Duration(hours: 1)),
      ('1 day before', const Duration(days: 1)),
    ];

    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Reminder',
        border: OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Duration?>(
          isExpanded: true,
          value: value,
          items: [
            for (final (label, dur) in items)
              DropdownMenuItem(value: dur, child: Text(label)),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
