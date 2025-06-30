import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MemberStatusFilter { all, active, expired }

class DateRangeFilter {
  final DateTime? start;
  final DateTime? end;
  const DateRangeFilter({this.start, this.end});
}

final statusFilterProvider = StateProvider<MemberStatusFilter>((ref) => MemberStatusFilter.active);
final dateRangeFilterProvider = StateProvider<DateRangeFilter>((ref) => const DateRangeFilter()); 