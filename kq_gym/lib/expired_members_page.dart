import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'member_provider.dart';
import 'member.dart';
import 'package:intl/intl.dart';
import 'main.dart';

class ExpiredMembersPage extends ConsumerStatefulWidget {
  const ExpiredMembersPage({super.key});

  @override
  ConsumerState<ExpiredMembersPage> createState() => _ExpiredMembersPageState();
}

class _ExpiredMembersPageState extends ConsumerState<ExpiredMembersPage> {
  @override
  void initState() {
    super.initState();
    // Load all members (including expired) when the page is first opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(expiredMembersProvider.notifier).loadAllMembers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final expiredProvider = ref.watch(expiredMembersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Expired Members')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search by name or phone',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (query) {
                if (query.isEmpty) {
                  ref.read(expiredMembersProvider.notifier).loadAllMembers();
                } else {
                  ref.read(expiredMembersProvider.notifier).searchMembers(query);
                }
              },
            ),
          ),
          Expanded(
            child: expiredProvider.when(
              data: (members) {
                final expired = members.where((m) => !m.isActive).toList();
                if (expired.isEmpty) {
                  return const Center(child: Text('No expired members.'));
                }
                return ListView.builder(
                  itemCount: expired.length,
                  itemBuilder: (context, i) {
                    final m = expired[i];
                    return ListTile(
                      title: Text(m.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${m.phone}'),
                          Text('Sub: ${DateFormat.yMMMd().format(m.startDate)} | Ends: ${DateFormat.yMMMd().format(m.endDate)}'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            tooltip: 'Edit',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditExpiredMemberPage(member: m),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.green),
                            tooltip: 'Renew',
                            onPressed: () async {
                              final result = await showDialog<_RenewResult?>(
                                context: context,
                                builder: (ctx) => const RenewDialog(),
                              );
                              if (result != null) {
                                final newEnd = _calculateNewEnd(DateTime.now(), result.value, result.unit);
                                final renewed = Member(
                                  id: m.id,
                                  name: m.name,
                                  phone: m.phone,
                                  startDate: DateTime.now(),
                                  endDate: newEnd,
                                  isActive: true,
                                  notes: m.notes,
                                );
                                await ref.read(expiredMembersProvider.notifier).updateMember(renewed);
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Delete Permanently',
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Member'),
                                  content: const Text('Are you sure you want to permanently delete this member?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                await ref.read(expiredMembersProvider.notifier).deleteMember(m.id!);
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class RenewDialog extends StatefulWidget {
  const RenewDialog({super.key});
  @override
  State<RenewDialog> createState() => _RenewDialogState();
}

class _RenewDialogState extends State<RenewDialog> {
  int _value = 1;
  String _unit = 'month';
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Renew Subscription'),
      content: Row(
        children: [
          Expanded(
            child: TextFormField(
              initialValue: '1',
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Period'),
              onChanged: (v) {
                final val = int.tryParse(v);
                if (val != null && val > 0) setState(() => _value = val);
              },
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _unit,
            items: const [
              DropdownMenuItem(value: 'day', child: Text('Days')),
              DropdownMenuItem(value: 'week', child: Text('Weeks')),
              DropdownMenuItem(value: 'month', child: Text('Months')),
              DropdownMenuItem(value: 'year', child: Text('Years')),
            ],
            onChanged: (v) => setState(() => _unit = v!),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(context, _RenewResult(_value, _unit)),
          child: const Text('Renew'),
        ),
      ],
    );
  }
}

class _RenewResult {
  final int value;
  final String unit;
  _RenewResult(this.value, this.unit);
}

DateTime _calculateNewEnd(DateTime from, int value, String unit) {
  switch (unit) {
    case 'day':
      return from.add(Duration(days: value));
    case 'week':
      return from.add(Duration(days: 7 * value));
    case 'month':
      return DateTime(from.year, from.month + value, from.day);
    case 'year':
      return DateTime(from.year + value, from.month, from.day);
    default:
      return from;
  }
}

class EditExpiredMemberPage extends ConsumerStatefulWidget {
  final Member member;
  const EditExpiredMemberPage({super.key, required this.member});

  @override
  ConsumerState<EditExpiredMemberPage> createState() => _EditExpiredMemberPageState();
}

class _EditExpiredMemberPageState extends ConsumerState<EditExpiredMemberPage> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member.name);
    _phoneController = TextEditingController(text: widget.member.phone);
    _notesController = TextEditingController(text: widget.member.notes ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Expired Member')),
      body: Form(
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
              subtitle: Text(DateFormat.yMMMd().format(widget.member.startDate)),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Expired Date'),
              subtitle: Text(DateFormat.yMMMd().format(widget.member.endDate)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final updated = Member(
                  id: widget.member.id,
                  name: _nameController.text.trim(),
                  phone: _phoneController.text.trim(),
                  startDate: widget.member.startDate, // Cannot change
                  endDate: widget.member.endDate, // Cannot change
                  isActive: false, // Remains expired
                  notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
                );
                await ref.read(expiredMembersProvider.notifier).updateMember(updated);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
} 