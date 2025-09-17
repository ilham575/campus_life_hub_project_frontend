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

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 16,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFF8F9FA)],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.edit_calendar,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'จัดการรายวิชา',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Form Content
            if (showDropdowns) ...[
              _buildDropdownField(
                label: 'เลือกวัน',
                icon: Icons.calendar_today,
                value: selectedDay,
                items: timetable.days,
                onChanged: onDayChanged,
              ),
              const SizedBox(height: 16),
              _buildDropdownField(
                label: 'เลือกเวลา',
                icon: Icons.access_time,
                value: selectedTime,
                items: timetable.times,
                onChanged: onTimeChanged,
              ),
              const SizedBox(height: 16),
            ] else ...[
              _buildInfoCard(
                icon: Icons.calendar_today,
                label: 'วัน',
                value: selectedDay ?? '',
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                icon: Icons.access_time,
                label: 'เวลา',
                value: selectedTime ?? '',
              ),
              const SizedBox(height: 16),
            ],
            
            // Subject Input
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
                color: Colors.grey[50],
              ),
              child: TextField(
                controller: controller,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'ชื่อวิชา',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: const Icon(Icons.book, color: Color(0xFF6A11CB)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Action Buttons
            Row(
              children: [
                // Cancel Button
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: const Text(
                      'ยกเลิก',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6C757D),
                      ),
                    ),
                  ),
                ),
                
                if (onDelete != null) ...[
                  const SizedBox(width: 12),
                  // Delete Button
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        onDelete!();
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.red[50],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'ลบ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(width: 12),
                // Save Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      onSave();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A11CB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save_outlined, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'บันทึก',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        color: Colors.grey[50],
      ),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(icon, color: const Color(0xFF6A11CB)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        value: value,
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(item, style: const TextStyle(fontSize: 16)),
                ))
            .toList(),
        onChanged: onChanged,
        dropdownColor: Colors.white,
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF6A11CB).withOpacity(0.1),
        border: Border.all(color: const Color(0xFF6A11CB).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6A11CB), size: 20),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6A11CB),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
        ],
      ),
    );
  }
}