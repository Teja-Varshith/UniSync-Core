import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:UniSync/constants/constant.dart';
import 'package:UniSync/features/admin/repository/admin_notification_service.dart';
import 'package:UniSync/features/admin/repository/admin_users_repository.dart';

final adminUsersRepositoryProvider = Provider<AdminUsersRepository>((ref) {
  return AdminUsersRepository(FirebaseFirestore.instance);
});

final adminNotificationServiceProvider =
    Provider<AdminNotificationService>((ref) {
  return AdminNotificationService(ref.watch(dioProvider));
});

/// Search results for the users tab. Family-keyed on the query so repeated
/// searches for the same roll number are served from cache.
final adminUserSearchProvider =
    FutureProvider.family<List<AdminUserRecord>, String>((ref, query) async {
  if (query.trim().isEmpty) return const [];
  return ref.watch(adminUsersRepositoryProvider).searchUsers(query);
});

final adminRecentPaymentsProvider =
    FutureProvider<List<AdminPaymentRecord>>((ref) async {
  return ref.watch(adminUsersRepositoryProvider).recentPayments();
});

final adminUserPaymentsProvider =
    FutureProvider.family<List<AdminPaymentRecord>, String>((ref, uid) async {
  return ref.watch(adminUsersRepositoryProvider).paymentsForUser(uid);
});
