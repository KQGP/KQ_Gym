import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'member.dart';
import 'member_provider.dart';
import 'package:intl/intl.dart';
import 'main.dart';

class EditMemberForm extends ConsumerStatefulWidget {
  final Member member;
  const EditMemberForm({super.key, required this.member});

  @override
  ConsumerState<EditMemberForm> createState() => _EditMemberFormState();
}

class _EditMemberFormState extends ConsumerState<EditMemberForm> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _notesController;
  late DateTime _startDate;
  late DateTime _endDate;
  int _extendValue = 0;
  String _extendUnit = 'month';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member.name);
    _phoneController = TextEditingController(text: widget.member.phone);
    _notesController = TextEditingController(text: widget.member.notes ?? '');
    _startDate = widget.member.startDate;
    _endDate = widget.member.endDate;
  }

  DateTime get _newEndDate {
    if (_extendValue == 0) return _endDate;
    switch (_extendUnit) {
      case 'day':
        return _endDate.add(Duration(days: _extendValue));
      case 'week':
        return _endDate.add(Duration(days: 7 * _extendValue));
      case 'month':
        return DateTime(_endDate.year, _endDate.month + _extendValue, _endDate.day);
      case 'year':
        return DateTime(_endDate.year + _extendValue, _endDate.month, _endDate.day);
      default:
        return _endDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
            validator: (v) => v == null || v.trim().isEmpty ? 'Name required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(labelText: 'Phone Number'),
            keyboardType: TextInputType.phone,
            validator: (v) => v == null || v.trim().isEmpty ? 'Phone required' : null,
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Subscription Start Date'),
            subtitle: Text(DateFormat.yMMMd().format(_startDate)),
            trailing: IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _startDate = picked);
              },
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Current End Date'),
            subtitle: Text(DateFormat.yMMMd().format(_endDate)),
            trailing: IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _endDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _endDate = picked);
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: '0',
                  decoration: const InputDecoration(labelText: 'Extend by'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final val = int.tryParse(v);
                    setState(() => _extendValue = (val ?? 0));
                  },
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _extendUnit,
                items: const [
                  DropdownMenuItem(value: 'day', child: Text('Days')),
                  DropdownMenuItem(value: 'week', child: Text('Weeks')),
                  DropdownMenuItem(value: 'month', child: Text('Months')),
                  DropdownMenuItem(value: 'year', child: Text('Years')),
                ],
                onChanged: (v) => setState(() => _extendUnit = v!),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('New End Date: ${DateFormat.yMMMd().format(_newEndDate)}'),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(labelText: 'Notes (optional)'),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    if (_extendValue > 0) {
                      // If extending, check if member is expired
                      final now = DateTime.now();
                      final isExpired = widget.member.endDate.isBefore(now);
                      
                      if (isExpired) {
                        // If expired, count from today
                        final updated = Member(
                          id: widget.member.id,
                          name: _nameController.text.trim(),
                          phone: _phoneController.text.trim(),
                          startDate: DateTime.now(),
                          endDate: _newEndDate,
                          isActive: true,
                          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
                        );
                        await ref.read(memberListProvider.notifier).updateMember(updated);
                      } else {
                        // If not expired, add to remaining time
                        final updated = Member(
                          id: widget.member.id,
                          name: _nameController.text.trim(),
                          phone: _phoneController.text.trim(),
                          startDate: widget.member.startDate, // Keep original start date
                          endDate: _newEndDate,
                          isActive: true,
                          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
                        );
                        await ref.read(memberListProvider.notifier).updateMember(updated);
                      }
                      if (context.mounted) Navigator.pop(context);
                    } else {
                      // If not extending, use the edited dates
                      final updated = Member(
                        id: widget.member.id,
                        name: _nameController.text.trim(),
                        phone: _phoneController.text.trim(),
                        startDate: _startDate,
                        endDate: _endDate,
                        isActive: true,
                        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
                      );
                      await ref.read(memberListProvider.notifier).updateMember(updated);
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  child: Text(_extendValue > 0 ? 'Extend & Save' : 'Save'),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  await ref.read(memberListProvider.notifier).softDeleteMember(widget.member.id!);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Move to Expired'),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 