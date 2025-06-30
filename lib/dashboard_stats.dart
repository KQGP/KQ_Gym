import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'member_provider.dart';

class DashboardStats extends ConsumerWidget {
  const DashboardStats({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberList = ref.watch(allMembersProvider);
    return memberList.when(
      data: (members) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));
        
        final totalActive = members.where((m) => m.isActive).length;
        final expiringSoon = members.where((m) => 
          m.isActive && 
          m.endDate.difference(now).inDays <= 7 && 
          m.endDate.difference(now).inDays >= 0
        ).length;
        final expiringTomorrow = members.where((m) => 
          m.isActive && 
          DateTime(m.endDate.year, m.endDate.month, m.endDate.day).isAtSameMomentAs(tomorrow)
        ).length;
        final expiredCount = members.where((m) => !m.isActive).length;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatCard(label: 'Active', value: totalActive.toString(), icon: Icons.check_circle, color: Colors.green),
              _StatCard(label: 'Expiring Soon', value: expiringSoon.toString(), icon: Icons.schedule, color: Colors.orange),
              _StatCard(label: 'Tomorrow', value: expiringTomorrow.toString(), icon: Icons.warning, color: Colors.red),
              _StatCard(label: 'Expired', value: expiredCount.toString(), icon: Icons.person_off, color: Colors.grey),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
} 