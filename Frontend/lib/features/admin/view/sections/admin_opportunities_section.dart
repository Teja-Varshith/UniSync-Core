import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:UniSync/features/opputunities/oppurtunities_edit.dart';
import 'package:UniSync/features/opputunities/oppurtunities_repository.dart';
import 'package:UniSync/features/opputunities/oppurtunity_model.dart';

/// Every opportunity, including inactive ones.
///
/// The public screen filters by type and hides inactive rows; an admin needs
/// to see everything, so this reads the unfiltered stream the app already
/// exposes rather than adding a parallel query.
final adminAllOpportunitiesProvider =
    StreamProvider<List<OpportunityModel>>((ref) {
  return ref.watch(opportunityRepositoryProvider).getAllOpportunities();
});

class AdminOpportunitiesSection extends ConsumerWidget {
  const AdminOpportunitiesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opportunities = ref.watch(adminAllOpportunitiesProvider);

    return Scaffold(
      body: opportunities.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load: $error', textAlign: TextAlign.center),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No opportunities yet'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _OpportunityRow(
              opportunity: items[index],
              onEdit: () => _openForm(context, items[index]),
              onDelete: () => _confirmDelete(context, ref, items[index]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: '_adminAddOpportunity',
        onPressed: () => _openForm(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }

  /// Reuses the existing add/edit form — it already handles both cases via a
  /// nullable [OpportunityModel], so the panel needs no form of its own.
  void _openForm(BuildContext context, OpportunityModel? opportunity) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OpportunityFormScreen(opportunity: opportunity),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    OpportunityModel opportunity,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete opportunity?'),
        content: Text(
          '"${opportunity.title}" will be removed permanently. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(opportunityRepositoryProvider)
          .deleteOpportunity(opportunity.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted "${opportunity.title}"')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $error')),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _OpportunityRow extends StatelessWidget {
  const _OpportunityRow({
    required this.opportunity,
    required this.onEdit,
    required this.onDelete,
  });

  final OpportunityModel opportunity;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expired = opportunity.deadline.isBefore(DateTime.now());

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opportunity.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${opportunity.company} · ${opportunity.type.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: theme.hintColor),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: [
                        _Tag(
                          label: opportunity.isActive ? 'Active' : 'Inactive',
                          color: opportunity.isActive
                              ? Colors.green
                              : Colors.grey,
                        ),
                        if (expired)
                          const _Tag(label: 'Expired', color: Colors.orange),
                        if (opportunity.isRemote)
                          const _Tag(label: 'Remote', color: Colors.blue),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_outlined, size: 19),
                onPressed: onEdit,
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline,
                    size: 19, color: Colors.redAccent),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
