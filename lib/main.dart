import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'member_provider.dart';
import 'member.dart';
import 'package:intl/intl.dart';
import 'add_member_form.dart';
import 'edit_member_form.dart';
import 'expired_members_page.dart';
import 'expiring_tomorrow_page.dart';
import 'dashboard_stats.dart';
import 'filter_provider.dart';
import 'dart:io';
import 'db_helper.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const ProviderScope(child: KqGymApp()));
}

class KqGymApp extends StatelessWidget {
  const KqGymApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KQ Gym',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> with WidgetsBindingObserver {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Auto-refresh every 10 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _refreshData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app comes back to foreground
      _refreshData();
    }
  }

  void _refreshData() {
    ref.read(memberListProvider.notifier).refresh();
    ref.read(allMembersProvider.notifier).refresh();
    ref.read(expiredMembersProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final memberList = ref.watch(memberListProvider);
    final dateRange = ref.watch(dateRangeFilterProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('KQ Gym'),
        actions: [
          IconButton(
            icon: const Icon(Icons.warning),
            tooltip: 'Expiring Tomorrow',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExpiringTomorrowPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_off),
            tooltip: 'Expired Members',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExpiredMembersPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const DashboardStats(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
            child: Row(
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: Text(_dateRangeLabel(dateRange)),
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      initialDateRange: dateRange.start != null && dateRange.end != null
                          ? DateTimeRange(start: dateRange.start!, end: dateRange.end!)
                          : null,
                    );
                    if (picked != null) {
                      ref.read(dateRangeFilterProvider.notifier).state = DateRangeFilter(start: picked.start, end: picked.end);
                    }
                  },
                ),
                if (dateRange.start != null || dateRange.end != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => ref.read(dateRangeFilterProvider.notifier).state = const DateRangeFilter(),
                  ),
              ],
            ),
          ),
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
                  ref.read(memberListProvider.notifier).loadMembers();
                } else {
                  ref.read(memberListProvider.notifier).searchMembers(query);
                }
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(memberListProvider.notifier).refresh();
                await ref.read(allMembersProvider.notifier).refresh();
                await ref.read(expiredMembersProvider.notifier).refresh();
              },
              child: memberList.when(
                data: (members) {
                  final filtered = members.where((m) {
                    // Only show active members in main list
                    if (!m.isActive) return false;
                    if (dateRange.start != null && m.endDate.isBefore(dateRange.start!)) return false;
                    if (dateRange.end != null && m.endDate.isAfter(dateRange.end!)) return false;
                    return true;
                  }).toList();
                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final m = filtered[i];
                      return ListTile(
                        title: Text(m.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${m.phone}'),
                            Text('Sub: ${DateFormat.yMMMd().format(m.startDate)} | Ends: ${DateFormat.yMMMd().format(m.endDate)}'),
                          ],
                        ),
                        trailing: m.isActive
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : const Icon(Icons.cancel, color: Colors.red),
                        onTap: m.isActive ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditMemberPage(member: m),
                            ),
                          );
                        } : null,
                        enabled: m.isActive,
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error: $e')),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddMemberPage()),
          );
        },
        tooltip: 'Add New Member',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: Transform.translate(
        offset: const Offset(0, -15),
        child: RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            children: [
              TextSpan(
                text: 'By ',
                style: TextStyle(color: Colors.black87),
              ),
              TextSpan(
                text: 'K',
                style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: 'HALIL AL',
                style: TextStyle(color: Colors.black87),
              ),
              TextSpan(
                text: 'Q',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: 'ISY',
                style: TextStyle(color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _dateRangeLabel(DateRangeFilter range) {
  if (range.start == null && range.end == null) return 'All Dates';
  if (range.start != null && range.end != null) {
    return '${DateFormat.yMMMd().format(range.start!)} - ${DateFormat.yMMMd().format(range.end!)}';
  }
  if (range.start != null) return 'From ${DateFormat.yMMMd().format(range.start!)}';
  return 'Until ${DateFormat.yMMMd().format(range.end!)}';
}

class AddMemberPage extends StatelessWidget {
  const AddMemberPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Member')),
      body: const AddMemberForm(),
    );
  }
}

class EditMemberPage extends StatelessWidget {
  final Member member;
  const EditMemberPage({super.key, required this.member});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Member')),
      body: EditMemberForm(member: member),
    );
  }
}
