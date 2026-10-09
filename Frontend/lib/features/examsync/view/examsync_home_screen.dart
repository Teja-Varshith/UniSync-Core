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
import 'package:UniSync/features/examsync/widgets/es_widgets.dart';

class ExamSyncHomeScreen extends ConsumerWidget {
  const ExamSyncHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(examSyncFiltersProvider);
    final subjects = ref.watch(examSyncSubjectsProvider(filters.semester));

    return ExamSyncScope(
      child: Scaffold(
        backgroundColor: EsColors.bg,
        body: SafeArea(
          child: RefreshIndicator(
            color: EsColors.accent,
            backgroundColor: EsColors.surface,
            onRefresh: () =>
                ref.refresh(examSyncSubjectsProvider(filters.semester).future),
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: _TopBar()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  sliver: SliverList.list(
                    children: [
                      const _Greeting(),
                      const SizedBox(height: 20),
                      const _FiltersCard(),
                      const SizedBox(height: 20),
                      _CourseTypeSwitch(subjects: subjects.valueOrNull),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                ..._subjectSlivers(context, ref, subjects, filters),
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
              ],
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
            const SliverToBoxAdapter(
              child: EsEmptyState(
                title: 'Nothing here yet…',
                message:
                    'No subjects for this semester and course type yet. Check back soon.',
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

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          EsIconButton(
            icon: Icons.arrow_back_rounded,
            semanticLabel: 'Back',
            onPressed: () => examSyncBack(context),
          ),
          const SizedBox(width: 12),
          const ExamSyncLogo(),
          const Spacer(),
          const CoinBalanceChip(),
        ],
      ),
    );
  }
}

class _Greeting extends ConsumerWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(userProvider.select((u) => u?.name)) ?? '';
    final first = name.trim().split(RegExp(r'\s+')).first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          first.isEmpty ? 'Hey there!' : 'Hey there,',
          style: EsText.body(size: 15, color: EsColors.textSecondary),
        ),
        if (first.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(first, style: EsText.display(size: 34)),
        ],
        const SizedBox(height: 6),
        Text(
          'No stress, just smart prep.',
          style: EsText.body(size: 14, color: EsColors.textMuted),
        ),
      ],
    );
  }
}

/// Collapsed by default to a single summary row ("Year 3 · Sem 5 · CSE").
/// Tapping it expands the pickers in place; tapping "Done" (or the row
/// again) collapses them back so the subject list isn't pushed down by
/// controls most visits don't need to touch.
class _FiltersCard extends ConsumerStatefulWidget {
  const _FiltersCard();

  @override
  ConsumerState<_FiltersCard> createState() => _FiltersCardState();
}

class _FiltersCardState extends ConsumerState<_FiltersCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(examSyncFiltersProvider);
    final notifier = ref.read(examSyncFiltersProvider.notifier);
    final semesters = kSemestersByYear[filters.year] ?? const [1];

    return PlunkBox(
      color: EsColors.surface,
      rightColor: EsColors.borderLight,
      bottomColor: EsColors.border,
      border: EsColors.border,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _summaryRow(filters),
          if (_expanded) ..._expandedPickers(filters, notifier, semesters),
        ],
      ),
    );
  }

  Widget _summaryRow(ExamSyncFilters filters) {
    return Semantics(
      button: true,
      label:
          'Year ${filters.year}, semester ${filters.semester}, CSE. Tap to change.',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.tune_rounded,
                  size: 18, color: EsColors.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Year ${filters.year} · Sem ${filters.semester} · CSE',
                  style: EsText.body(size: 14, weight: FontWeight.w800),
                ),
              ),
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 150),
                child: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: EsColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _expandedPickers(
    ExamSyncFilters filters,
    ExamSyncFiltersNotifier notifier,
    List<int> semesters,
  ) {
    return [
      const Divider(height: 1, color: EsColors.border),
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 14),
            const EsEyebrow('Semester'),
            const SizedBox(height: 8),
            EsSegmented<int>(
              segments: [
                for (final s in semesters)
                  EsSegment(value: s, label: 'Sem $s'),
              ],
              value: filters.semester,
              onChanged: notifier.setSemester,
            ),
            const SizedBox(height: 16),
            EsButton(
              label: 'Done',
              variant: EsButtonVariant.secondary,
              expand: true,
              onPressed: () => setState(() => _expanded = false),
            ),
          ],
        ),
      ),
    ];
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
