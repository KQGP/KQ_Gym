import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'member_provider.dart';
import 'member.dart';
import 'package:intl/intl.dart';
import 'edit_member_form.dart';
import 'main.dart';

class ExpiringTomorrowPage extends ConsumerWidget {
  const ExpiringTomorrowPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberList = ref.watch(memberListProvider);
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expiring Tomorrow'),
      ),
      body: memberList.when(
        data: (members) {
          final expiringTomorrow = members.where((m) {
            if (!m.isActive) return false;
            final expiryDate = DateTime(m.endDate.year, m.endDate.month, m.endDate.day);
            final tomorrowDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
            return expiryDate.isAtSameMomentAs(tomorrowDate);
          }).toList();

          if (expiringTomorrow.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text(
                    'No members expiring tomorrow!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'All subscriptions are up to date',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: expiringTomorrow.length,
            itemBuilder: (context, i) {
              final m = expiringTomorrow[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Icon(Icons.warning, color: Colors.white),
                  ),
                  title: Text(m.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${m.phone}'),
                      Text(
                        'Expires: ${DateFormat.yMMMd().format(m.endDate)}',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    tooltip: 'Edit',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditMemberPage(member: m),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
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