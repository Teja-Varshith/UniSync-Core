import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:routemaster/routemaster.dart';
import 'package:UniSync/app/providers.dart';
import 'package:UniSync/features/examsync/brand/brand.dart';
import 'package:UniSync/features/examsync/controller/examsync_controller.dart';
import 'package:UniSync/features/examsync/models/subject.dart';
import 'package:UniSync/features/examsync/theme/es_theme.dart';
import 'package:UniSync/features/examsync/view/widgets/es_scope.dart';
import 'package:UniSync/features/examsync/view/widgets/subject_card.dart';
import 'package:UniSync/features/examsync/widgets/es_disclaimer.dart';
import 'package:UniSync/features/examsync/widgets/es_widgets.dart';

class ExamSyncHomeScreen extends ConsumerWidget {
  const ExamSyncHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(examSyncFiltersProvider);
    final subjects = ref.watch(examSyncBranchSubjectsProvider);

    return ExamSyncScope(
      child: PopScope(
        // Opened as the first page (e.g. from a deep link): back goes to
        // UniSync's home instead of closing the app.
        canPop: Navigator.of(context).canPop(),
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) Routemaster.of(context).replace('/');
        },
        child: Scaffold(
          backgroundColor: EsColors.bg,
          body: SafeArea(
            child: RefreshIndicator(
              color: EsColors.accent,
              backgroundColor: EsColors.surface,
              onRefresh: () => ref
                  .refresh(examSyncSubjectsProvider(filters.semester).future),
              child: CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(child: _TopBar()),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    sliver: SliverList.list(
                      children: [
                        const _GreetingRow(),
                        const SizedBox(height: 18),
                        _CourseTypeSwitch(subjects: subjects.valueOrNull),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  ..._subjectSlivers(context, ref, subjects, filters),
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 28),
                    sliver: SliverToBoxAdapter(child: EsDisclaimerNote()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _subjectSlivers(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Subject>> subjects,
    ExamSyncFilters filters,
  ) {
    Widget padded(Widget child) => SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: child,
        );

    return subjects.when(
      skipLoadingOnRefresh: true,
      loading: () => [
        padded(SliverList.separated(
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (_, __) => const SubjectCardSkeleton(),
        )),
      ],
      error: (_, __) => [
        SliverToBoxAdapter(
          child: EsErrorState(
            title: 'Couldn’t load subjects',
            onRetry: () =>
                ref.invalidate(examSyncSubjectsProvider(filters.semester)),
          ),
        ),
      ],
      data: (all) {
        final list =
            all.where((s) => s.courseType == filters.courseType).toList();
        if (list.isEmpty) {
          return [
            SliverToBoxAdapter(
              child: EsEmptyState(
                title: 'Nothing here yet…',
                message: 'No ${filters.courseType.label.toLowerCase()} '
                    'subjects for ${filters.branch}, Sem ${filters.semester} '
                    'yet. Check back soon.',
              ),
            ),
          ];
        }
        return [
          padded(SliverList.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 18),
            itemBuilder: (context, i) => SubjectCard(
              subject: list[i],
              onTap: () => Routemaster.of(context).push(
                '/examsync/subject/${Uri.encodeComponent(list[i].courseCode)}',
              ),
            ),
          )),
        ];
      },
    );
  }
}

/// App bar: just the ExamSync name and the coin balance.
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          Semantics(
            header: true,
            label: 'ExamSync',
            excludeSemantics: true,
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: 'exam', style: EsText.display(size: 24)),
                TextSpan(
                  text: 'sync',
                  style: EsText.display(
                    size: 24,
                    color: EsColors.accent,
                    style: FontStyle.italic,
                  ),
                ),
              ]),
            ),
          ),
          const Spacer(),
          const CoinBalanceChip(),
        ],
      ),
    );
  }
}

/// Greeting on the left, the student's class (year · sem · branch) as a
/// compact chip on the right. The chip opens a sheet to change it, so the
/// pickers never push the subject list down.
class _GreetingRow extends ConsumerWidget {
  const _GreetingRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(userProvider.select((u) => u?.name)) ?? '';
    final first = name.trim().split(RegExp(r'\s+')).first;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                first.isEmpty ? 'Hey there!' : 'Hey there,',
                style: EsText.body(size: 14, color: EsColors.textSecondary),
              ),
              if (first.isNotEmpty)
                Text(
                  first,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: EsText.display(size: 28),
                ),
              const SizedBox(height: 2),
              Text(
                'No stress, just smart prep.',
                style: EsText.body(size: 12.5, color: EsColors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const _ClassChip(),
      ],
    );
  }
}

class _ClassChip extends ConsumerWidget {
  const _ClassChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(examSyncFiltersProvider);
    return PlunkTap(
      color: EsColors.surfaceElevated,
      rightColor: EsColors.borderLight,
      bottomColor: EsColors.border,
      border: EsColors.border,
      semanticLabel: 'Year ${f.year}, semester ${f.semester}, ${f.branch}. '
          'Tap to change.',
      onTap: () => _showClassSheet(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(f.branch,
                    style: EsText.body(
                        size: 14,
                        weight: FontWeight.w800,
                        color: EsColors.accent)),
                Text('Y${f.year} · Sem ${f.semester}',
                    style: EsText.mono(size: 11, color: EsColors.textMuted)),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 20, color: EsColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

Future<void> _showClassSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: EsColors.surface,
    shape: const RoundedRectangleBorder(),
    builder: (sheetContext) => const ExamSyncScope(
      child: SafeArea(child: _ClassSheet()),
    ),
  );
}

class _ClassSheet extends ConsumerWidget {
  const _ClassSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(examSyncFiltersProvider);
    final notifier = ref.read(examSyncFiltersProvider.notifier);
    final semesters = kSemestersByYear[filters.year] ?? const [1];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Your class', style: EsText.display(size: 22)),
          const SizedBox(height: 16),
          const EsEyebrow('Branch'),
          const SizedBox(height: 8),
          _BranchGrid(value: filters.branch, onChanged: notifier.setBranch),
          const SizedBox(height: 16),
          const EsEyebrow('Year'),
          const SizedBox(height: 8),
          EsSegmented<int>(
            segments: [
              for (final y in kSemestersByYear.keys)
                EsSegment(value: y, label: '$y'),
            ],
            value: filters.year,
            onChanged: notifier.setYear,
          ),
          const SizedBox(height: 16),
          const EsEyebrow('Semester'),
          const SizedBox(height: 8),
          EsSegmented<int>(
            segments: [
              for (final s in semesters) EsSegment(value: s, label: 'Sem $s'),
            ],
            value: filters.semester,
            onChanged: notifier.setSemester,
          ),
          const SizedBox(height: 20),
          EsButton(
            label: 'Done',
            expand: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _BranchGrid extends StatelessWidget {
  const _BranchGrid({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      const gap = 8.0;
      final width = (constraints.maxWidth - gap * 3) / 4;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final b in kBranches)
            SizedBox(
              width: width,
              child: _BranchTile(
                label: b,
                selected: b == value,
                onTap: () => onChanged(b),
              ),
            ),
        ],
      );
    });
  }
}

class _BranchTile extends StatelessWidget {
  const _BranchTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Center(
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: EsText.body(
          size: 13,
          weight: FontWeight.w800,
          color: selected ? Colors.black : EsColors.textSecondary,
        ),
      ),
    );
    return Semantics(
      selected: selected,
      child: PlunkTap(
        color: selected ? EsColors.accent : EsColors.bgSecondary,
        rightColor: selected ? EsColors.accentRight : EsColors.borderLight,
        bottomColor: selected ? EsColors.accentBottom : EsColors.border,
        border: selected ? null : EsColors.border,
        semanticLabel: label,
        onTap: selected ? null : onTap,
        child: SizedBox(height: 38, child: text),
      ),
    );
  }
}

class _CourseTypeSwitch extends ConsumerWidget {
  const _CourseTypeSwitch({required this.subjects});

  final List<Subject>? subjects;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(examSyncFiltersProvider);
    int? count(CourseType t) =>
        subjects?.where((s) => s.courseType == t).length;
    return EsSegmented<CourseType>(
      segments: [
        for (final t in CourseType.values)
          EsSegment(value: t, label: t.label, count: count(t)),
      ],
      value: filters.courseType,
      onChanged: ref.read(examSyncFiltersProvider.notifier).setCourseType,
    );
  }
}
