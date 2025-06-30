import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'member.dart';
import 'member_provider.dart';
import 'package:intl/intl.dart';
import 'main.dart';

class AddMemberForm extends ConsumerStatefulWidget {
  const AddMemberForm({super.key});

  @override
  ConsumerState<AddMemberForm> createState() => _AddMemberFormState();
}

class _AddMemberFormState extends ConsumerState<AddMemberForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _startDate = DateTime.now();
  int _periodValue = 1;
  String _periodUnit = 'month';

  DateTime get _endDate {
    switch (_periodUnit) {
      case 'day':
        return _startDate.add(Duration(days: _periodValue));
      case 'week':
        return _startDate.add(Duration(days: 7 * _periodValue));
      case 'month':
        return DateTime(_startDate.year, _startDate.month + _periodValue, _startDate.day);
      case 'year':
        return DateTime(_startDate.year + _periodValue, _startDate.month, _startDate.day);
      default:
        return _startDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
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
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: '1',
                  decoration: const InputDecoration(labelText: 'Period'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final val = int.tryParse(v);
                    if (val != null && val > 0) setState(() => _periodValue = val);
                  },
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _periodUnit,
                items: const [
                  DropdownMenuItem(value: 'day', child: Text('Days')),
                  DropdownMenuItem(value: 'week', child: Text('Weeks')),
                  DropdownMenuItem(value: 'month', child: Text('Months')),
                  DropdownMenuItem(value: 'year', child: Text('Years')),
                ],
                onChanged: (v) => setState(() => _periodUnit = v!),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('End Date: ${DateFormat.yMMMd().format(_endDate)}'),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(labelText: 'Notes (optional)'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final member = Member(
                  name: _nameController.text.trim(),
                  phone: _phoneController.text.trim(),
                  startDate: _startDate,
                  endDate: _endDate,
                  isActive: true,
                  notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
                );
                await ref.read(memberListProvider.notifier).addMember(member);
                
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Add Member'),
          ),
        ],
      ),
    );
  }
} 