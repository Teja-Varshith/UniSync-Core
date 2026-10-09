import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:UniSync/features/admin/controllers/admin_data_controllers.dart';
import 'package:UniSync/features/admin/repository/admin_users_repository.dart';

class AdminUsersSection extends ConsumerStatefulWidget {
  const AdminUsersSection({super.key});

  @override
  ConsumerState<AdminUsersSection> createState() => _AdminUsersSectionState();
}

class _AdminUsersSectionState extends ConsumerState<AdminUsersSection> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (value) => setState(() => _query = value.trim()),
            decoration: InputDecoration(
              hintText: 'JNTU number, email, or user id',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              border: const OutlineInputBorder(),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    ),
            ),
          ),
        ),
        Expanded(
          child: _query.isEmpty
              ? const _RecentPayments()
              : _SearchResults(query: _query),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.query});
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(adminUserSearchProvider(query));

    return results.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _Centered('Search failed: $error'),
      data: (users) {
        if (users.isEmpty) {
          return const _Centered(
            'No user found.\n\nFirestore matches exactly, so the roll number '
            'must be stored exactly as typed. Try the other casing, or '
            'search by email.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _UserCard(user: users[i]),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _UserCard extends ConsumerStatefulWidget {
  const _UserCard({required this.user});
  final AdminUserRecord user;

  @override
  ConsumerState<_UserCard> createState() => _UserCardState();
}

class _UserCardState extends ConsumerState<_UserCard> {
  late bool _adFree = widget.user.hasAdFreeAccess;
  bool _busy = false;

  Future<void> _toggleAdFree(bool value) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(adminUsersRepositoryProvider)
          .setAdFree(widget.user.uid, value);
      setState(() => _adFree = value);
      _toast(value ? 'Ad-free granted' : 'Ad-free revoked');
    } catch (error) {
      _toast('Failed: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.name.isEmpty ? '(no name)' : user.name,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 2),
            Text(
              user.email,
              style: TextStyle(fontSize: 12, color: theme.hintColor),
            ),
            const SizedBox(height: 10),
            _KeyValue('JNTU no', user.jntuNumber.isEmpty ? '—' : user.jntuNumber),
            _KeyValue('College', user.collegeName.isEmpty ? '—' : user.collegeName),
            _KeyValue(
              'Year / sem',
              '${user.year ?? '—'} / ${user.semester ?? '—'}',
            ),
            _KeyValue('Coins', '${user.coins}'),
            _KeyValue('User id', user.uid, copyable: true),
            _KeyValue(
              'FCM token',
              user.hasFcmToken ? user.fcmToken : 'none stored',
              copyable: user.hasFcmToken,
            ),
            const Divider(height: 22),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Ad-free access',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
                if (_busy)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Switch(value: _adFree, onChanged: _toggleAdFree),
              ],
            ),
            TextButton.icon(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => _UserPaymentsSheet(user: user),
              ),
              icon: const Icon(Icons.receipt_long_outlined, size: 17),
              label: const Text('View payments'),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _UserPaymentsSheet extends ConsumerWidget {
  const _UserPaymentsSheet({required this.user});
  final AdminUserRecord user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(adminUserPaymentsProvider(user.uid));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payments · ${user.name}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 12),
            payments.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Text('Failed: $error'),
              data: (items) => items.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text('No purchases recorded'),
                    )
                  : ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 360),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(height: 14),
                        itemBuilder: (_, i) => _PaymentRow(payment: items[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _RecentPayments extends ConsumerWidget {
  const _RecentPayments();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(adminRecentPaymentsProvider);

    return payments.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _Centered('Could not load payments: $error'),
      data: (items) {
        if (items.isEmpty) {
          return const _Centered('No purchases recorded yet');
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminRecentPaymentsProvider),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
            itemCount: items.length + 1,
            separatorBuilder: (_, __) => const Divider(height: 16),
            itemBuilder: (context, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'Recent payments (${items.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                );
              }
              return _PaymentRow(payment: items[i - 1], showUid: true);
            },
          ),
        );
      },
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.payment, this.showUid = false});

  final AdminPaymentRecord payment;
  final bool showUid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final when = payment.purchasedAt;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                payment.productId.isEmpty ? '(unknown product)' : payment.productId,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                [
                  if (payment.coins > 0) '${payment.coins} coins',
                  payment.status,
                  if (when != null)
                    '${when.day}/${when.month}/${when.year}',
                  if (showUid) payment.uid,
                ].join(' · '),
                style: TextStyle(fontSize: 11, color: theme.hintColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _KeyValue extends StatelessWidget {
  const _KeyValue(this.label, this.value, {this.copyable = false});

  final String label;
  final String value;
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: TextStyle(fontSize: 11.5, color: theme.hintColor),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: copyable ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5),
            ),
          ),
          if (copyable)
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$label copied')),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(Icons.copy, size: 13, color: theme.hintColor),
              ),
            ),
        ],
      ),
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).hintColor, height: 1.5),
          ),
        ),
      );
}
