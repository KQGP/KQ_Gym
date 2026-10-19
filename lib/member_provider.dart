import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'member.dart';
import 'db_helper.dart';

final memberListProvider = StateNotifierProvider<MemberListNotifier, AsyncValue<List<Member>>>((ref) {
  return MemberListNotifier();
});

final allMembersProvider = StateNotifierProvider<AllMembersNotifier, AsyncValue<List<Member>>>((ref) {
  return AllMembersNotifier();
});

final expiredMembersProvider = StateNotifierProvider<ExpiredMembersNotifier, AsyncValue<List<Member>>>((ref) {
  return ExpiredMembersNotifier();
});

class MemberListNotifier extends StateNotifier<AsyncValue<List<Member>>> {
  MemberListNotifier() : super(const AsyncValue.loading()) {
    loadMembers();
  }

  Future<void> loadMembers({bool activeOnly = true}) async {
    state = const AsyncValue.loading();
    try {
      final members = await DBHelper().getMembers(activeOnly: activeOnly);
      state = AsyncValue.data(members);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addMember(Member member) async {
    await DBHelper().insertMember(member);
    await loadMembers();
  }

  Future<void> updateMember(Member member) async {
    await DBHelper().updateMember(member);
    await loadMembers(activeOnly: true);
  }

  Future<void> softDeleteMember(int id) async {
    await DBHelper().softDeleteMember(id);
    await loadMembers(activeOnly: true);
  }

  Future<void> searchMembers(String query, {bool activeOnly = true}) async {
    state = const AsyncValue.loading();
    try {
      final members = await DBHelper().searchMembers(query, activeOnly: activeOnly);
      state = AsyncValue.data(members);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteMember(int id) async {
    await DBHelper().deleteMember(id);
    await loadMembers(activeOnly: false);
  }

  Future<void> checkExpirations() async {
    final dbClient = await DBHelper().db;
    final now = DateTime.now();
    final maps = await dbClient.query('members', where: 'isActive = 1');
    for (final map in maps) {
      final member = Member.fromMap(map);
      if (member.endDate.isBefore(now)) {
        await DBHelper().softDeleteMember(member.id!);
      }
    }
    await loadMembers(activeOnly: false);
  }

  Future<void> refresh() async {
    await loadMembers();
  }

  // Method to refresh both active and all members providers
  static Future<void> refreshAllProviders() async {
    // This will be called from the main app to refresh both providers
  }
}

class AllMembersNotifier extends StateNotifier<AsyncValue<List<Member>>> {
  AllMembersNotifier() : super(const AsyncValue.loading()) {
    loadAllMembers();
  }

  Future<void> loadAllMembers() async {
    state = const AsyncValue.loading();
    try {
      final members = await DBHelper().getMembers(activeOnly: false);
      state = AsyncValue.data(members);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    await loadAllMembers();
  }
}

class ExpiredMembersNotifier extends StateNotifier<AsyncValue<List<Member>>> {
  ExpiredMembersNotifier() : super(const AsyncValue.loading()) {
    loadAllMembers();
  }

  Future<void> loadAllMembers() async {
    state = const AsyncValue.loading();
    try {
      final members = await DBHelper().getMembers(activeOnly: false);
      state = AsyncValue.data(members);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> searchMembers(String query) async {
    state = const AsyncValue.loading();
    try {
      final members = await DBHelper().searchMembers(query, activeOnly: false);
      state = AsyncValue.data(members);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateMember(Member member) async {
    await DBHelper().updateMember(member);
    await loadAllMembers();
  }

  Future<void> deleteMember(int id) async {
    await DBHelper().deleteMember(id);
    await loadAllMembers();
  }

  Future<void> refresh() async {
    await loadAllMembers();
  }
} 