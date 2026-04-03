import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:UniSync/app/providers.dart';
import 'package:UniSync/models/portifolo_model.dart';
import 'package:UniSync/features/Carrer_Mode/services/portfolio_repository.dart';

/// Fetches the current user's portfolio from Firestore.
/// Falls back to basic info from [userProvider] when no portfolio doc exists.
final portfolioProvider = FutureProvider<PortifoloModel?>((ref) async {
  final user = ref.watch(userProvider);
  if (user == null || user.id == null) return null;

  final repo = ref.read(portfolioRepositoryProvider);
  final portfolio = await repo.getPortfolio(user.id!);

  // If no doc exists yet, seed defaults from the user profile.
  if (portfolio == null) {
    return PortifoloModel(
      userId: user.id,
      name: user.name,
      email: user.emailId,
    );
  }

  // Ensure name/email stay in sync with the auth profile.
  return portfolio.copyWith(
    userId: user.id,
    name: portfolio.name.isEmpty ? user.name : portfolio.name,
    email: portfolio.email.isEmpty ? user.emailId : portfolio.email,
  );
});
