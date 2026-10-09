import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:routemaster/routemaster.dart';
import 'package:UniSync/features/examsync/brand/abstract_art.dart';
import 'package:UniSync/features/examsync/brand/brand.dart';
import 'package:UniSync/features/examsync/controller/examsync_controller.dart';
import 'package:UniSync/features/examsync/models/exam_data.dart';
import 'package:UniSync/features/examsync/models/subject.dart';
import 'package:UniSync/features/examsync/theme/es_theme.dart';
import 'package:UniSync/features/examsync/view/pakka_pass_tab.dart';
import 'package:UniSync/features/examsync/view/widgets/es_scope.dart';
import 'package:UniSync/features/examsync/widgets/es_widgets.dart';

enum _Tab { syllabus, notes, pyqs, pakkaPass }

class SubjectDetailScreen extends ConsumerWidget {
  const SubjectDetailScreen({super.key, required this.courseCode});

  final String courseCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subject = ref.watch(examSyncSubjectProvider(courseCode));
    return ExamSyncScope(
      child: Scaffold(
        backgroundColor: EsColors.bg,
        body: subject.when(
          loading: () => const _DetailSkeleton(),
          error: (_, __) => _Bare(
            child: EsErrorState(
              title: 'Couldn’t load this subject',
              onRetry: () =>
                  ref.invalidate(examSyncSubjectProvider(courseCode)),
            ),
          ),
          data: (s) => s == null
              ? const _Bare(
                  child: EsEmptyState(
                    title: 'Subject not found',
                    message:
                        'It may have been removed. Go back and pick another.',
                  ),
                )
              : _DetailBody(subject: s),
        ),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.subject});

  final Subject subject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = subject.courseCode;
    final tab = _Tab
        .values[ref.watch(examSyncLastTabProvider.select((m) => m[code])) ?? 0];
    final content = ref.watch(examSyncSubjectContentProvider(code));

    void select(_Tab t) {
      final map = {...ref.read(examSyncLastTabProvider)};
      map[code] = t.index;
      ref.read(examSyncLastTabProvider.notifier).state = map;
    }

    return RefreshIndicator(
      color: EsColors.accent,
      backgroundColor: EsColors.surface,
      onRefresh: () {
        ref.invalidate(examSyncSubjectProvider(code));
        ref.invalidate(examSyncHasAccessProvider(code));
        return ref.refresh(examSyncSubjectContentProvider(code).future);
      },
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Hero(subject: subject)),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabsHeader(
                tab: tab,
                notesCount: content.valueOrNull?.notes.length,
                pyqsCount: content.valueOrNull?.pyqs.length,
                onSelect: select,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
              sliver: SliverToBoxAdapter(
                child: tab == _Tab.pakkaPass
                    ? PakkaPassTab(subject: subject)
                    : content.when(
                        loading: () => const _ListSkeleton(),
                        error: (_, __) => EsErrorState(
                          onRetry: () => ref
                              .invalidate(examSyncSubjectContentProvider(code)),
                        ),
                        data: (c) => switch (tab) {
                          _Tab.syllabus => _SyllabusList(units: c.syllabus),
                          _Tab.notes => _ResourceList(
                              courseCode: code,
                              items: c.notes,
                              emptyTitle: 'Notes coming soon',
                            ),
                          _Tab.pyqs => _ResourceList(
                              courseCode: code,
                              items: c.pyqs,
                              emptyTitle: 'PYQs coming soon',
                            ),
                          _Tab.pakkaPass => const SizedBox.shrink(),
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.subject});

  final Subject subject;

  @override
  Widget build(BuildContext context) {
    final tone = EsTone.forCode(subject.courseCode);
    final units = subject.noOfUnits;
    return Container(
      color: tone.face,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            width: 120,
            height: 120,
            child: AbstractArt(courseCode: subject.courseCode, tone: tone),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EsIconButton(
                  icon: Icons.arrow_back_rounded,
                  semanticLabel: 'Back',
                  color: Colors.black,
                  iconColor: Colors.white,
                  onPressed: () => examSyncBack(context),
                ),
                const SizedBox(height: 36),
                EsChip(subject.courseCode,
                    variant: EsChipVariant.ink, mono: true),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(right: 40),
                  child: Text(
                    subject.subjectName,
                    style: EsText.display(size: 30, color: tone.ink),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  units > 0
                      ? '${subject.courseTypeLabel} · $units ${units == 1 ? 'unit' : 'units'}'
                      : subject.courseTypeLabel,
                  style: EsText.body(
                    size: 13,
                    weight: FontWeight.w700,
                    color: tone.ink.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabsHeader extends SliverPersistentHeaderDelegate {
  _TabsHeader({
    required this.tab,
    required this.notesCount,
    required this.pyqsCount,
    required this.onSelect,
  });

  final _Tab tab;
  final int? notesCount;
  final int? pyqsCount;
  final ValueChanged<_Tab> onSelect;

  static const double _height = 58;

  @override
  double get minExtent => _height;
  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    return Container(
      decoration: const BoxDecoration(
        color: EsColors.bg,
        border: Border(bottom: BorderSide(color: EsColors.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            _tabButton(_Tab.syllabus, 'Syllabus', null),
            _tabButton(_Tab.notes, 'Notes', notesCount),
            _tabButton(_Tab.pyqs, 'PYQs', pyqsCount),
            _tabButton(_Tab.pakkaPass, 'Pakka Pass', null, premium: true),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(_Tab t, String label, int? count, {bool premium = false}) {
    final active = t == tab;
    final face = premium ? EsColors.premium : EsColors.accent;
    final ink = premium ? Colors.white : Colors.black;
    final text = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (premium) ...[
          Icon(Icons.bolt_rounded,
              size: 15, color: active ? ink : EsColors.premium),
          const SizedBox(width: 3),
        ],
        Text(
          label,
          style: EsText.body(
            size: 13,
            weight: FontWeight.w800,
            color: active ? ink : EsColors.textSecondary,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 6),
          Text(
            '$count',
            style: EsText.mono(
              size: 11,
              color: active ? ink.withValues(alpha: 0.7) : EsColors.textMuted,
            ),
          ),
        ],
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Semantics(
        button: true,
        selected: active,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onSelect(t),
          child: active
              ? PlunkBox(
                  color: face,
                  rightColor:
                      premium ? EsColors.premiumRight : EsColors.accentRight,
                  bottomColor:
                      premium ? EsColors.premiumBottom : EsColors.accentBottom,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: text,
                )
              : Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 17, 13),
                  child: text,
                ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_TabsHeader old) =>
      old.tab != tab ||
      old.notesCount != notesCount ||
      old.pyqsCount != pyqsCount;
}

// ── Syllabus ───────────────────────────────────────────────────────────────

class _SyllabusList extends StatelessWidget {
  const _SyllabusList({required this.units});

  final List<SyllabusUnit> units;

  @override
  Widget build(BuildContext context) {
    if (units.isEmpty) {
      return const EsEmptyState(
        title: 'Syllabus coming soon',
        message: 'The units for this subject haven’t been added yet.',
      );
    }
    return Column(
      children: [
        for (var i = 0; i < units.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _UnitTile(unit: units[i], initiallyOpen: i == 0),
          ),
      ],
    );
  }
}

class _UnitTile extends StatefulWidget {
  const _UnitTile({required this.unit, required this.initiallyOpen});

  final SyllabusUnit unit;
  final bool initiallyOpen;

  @override
  State<_UnitTile> createState() => _UnitTileState();
}

class _UnitTileState extends State<_UnitTile> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    final u = widget.unit;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return PlunkBox(
      color: EsColors.surface,
      rightColor: EsColors.borderLight,
      bottomColor: EsColors.border,
      border: EsColors.border,
      child: Column(
        children: [
          Semantics(
            button: true,
            expanded: _open,
            child: InkWell(
              onTap: () => setState(() => _open = !_open),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      color: _open ? EsColors.accent : EsColors.surfaceElevated,
                      alignment: Alignment.center,
                      child: Text(
                        u.number.toString().padLeft(2, '0'),
                        style: EsText.mono(
                          size: 15,
                          color: _open ? Colors.black : EsColors.text,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u.name,
                              style: EsText.body(
                                  size: 15, weight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(
                            '${u.topics.length} ${u.topics.length == 1 ? 'topic' : 'topics'}',
                            style: EsText.body(
                                size: 12, color: EsColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0,
                      duration: reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 180),
                      child: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: EsColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 180),
            alignment: Alignment.topCenter,
            child: !_open
                ? const SizedBox(width: double.infinity)
                : Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: EsColors.bgSecondary,
                      border: Border(top: BorderSide(color: EsColors.border)),
                    ),
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    child: u.topics.isEmpty
                        ? Text('Topics coming soon',
                            style: EsText.body(
                                size: 13, color: EsColors.textMuted))
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var t = 0; t < u.topics.length; t++)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 5),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 44,
                                        child: Text(
                                          '${u.number}.${t + 1}',
                                          style: EsText.mono(
                                              size: 12, color: EsColors.accent),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          u.topics[t],
                                          style: EsText.body(
                                            size: 13.5,
                                            color: EsColors.textSecondary,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Notes & PYQs ───────────────────────────────────────────────────────────

class _ResourceList extends StatelessWidget {
  const _ResourceList({
    required this.courseCode,
    required this.items,
    required this.emptyTitle,
  });

  final String courseCode;
  final List<Resource> items;
  final String emptyTitle;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return EsEmptyState(
        title: emptyTitle,
        message: 'Nothing uploaded for this subject yet.',
      );
    }
    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ResourceRow(courseCode: courseCode, item: item),
          ),
      ],
    );
  }
}

class _ResourceRow extends StatelessWidget {
  const _ResourceRow({required this.courseCode, required this.item});

  final String courseCode;
  final Resource item;

  @override
  Widget build(BuildContext context) {
    final isNotes = item.kind == ResourceKind.notes;
    final enabled = item.hasLink;
    final row = Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            color: enabled
                ? (isNotes ? EsColors.lime : EsColors.pink)
                : EsColors.surfaceElevated,
            child: Icon(
              isNotes ? Icons.description_outlined : Icons.history_edu_rounded,
              color: enabled ? Colors.black : EsColors.textDisabled,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: EsText.body(
                    size: 14.5,
                    weight: FontWeight.w800,
                    color: enabled ? EsColors.text : EsColors.textDisabled,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  enabled ? 'PDF · Tap to open' : 'File not available yet',
                  style: EsText.body(size: 12, color: EsColors.textMuted),
                ),
              ],
            ),
          ),
          if (enabled)
            const Icon(Icons.north_east_rounded,
                size: 18, color: EsColors.textSecondary),
        ],
      ),
    );

    if (!enabled) {
      return PlunkBox(
        color: EsColors.surface,
        rightColor: EsColors.border,
        bottomColor: EsColors.border,
        border: EsColors.border,
        child: row,
      );
    }
    return PlunkTap(
      color: EsColors.surface,
      rightColor: EsColors.borderLight,
      bottomColor: EsColors.border,
      border: EsColors.border,
      semanticLabel: 'Open ${item.title}',
      onTap: () => Routemaster.of(context).push(
        '/examsync/subject/${Uri.encodeComponent(courseCode)}/pdf',
        queryParameters: {
          'url': item.link!,
          'title': item.title,
          'kind': isNotes ? 'notes' : 'pyq',
        },
      ),
      child: row,
    );
  }
}

// ── Loading / bare states ──────────────────────────────────────────────────

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 4; i++)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: EsSkeleton(height: 68),
          ),
      ],
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EsIconButton(
              icon: Icons.arrow_back_rounded,
              semanticLabel: 'Back',
              onPressed: () => examSyncBack(context),
            ),
            const SizedBox(height: 36),
            const EsSkeleton(height: 20, width: 80),
            const SizedBox(height: 12),
            const EsSkeleton(height: 30, width: 240),
            const SizedBox(height: 28),
            const _ListSkeleton(),
          ],
        ),
      ),
    );
  }
}

class _Bare extends StatelessWidget {
  const _Bare({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: EsIconButton(
              icon: Icons.arrow_back_rounded,
              semanticLabel: 'Back',
              onPressed: () => examSyncBack(context),
            ),
          ),
          Expanded(child: Center(child: SingleChildScrollView(child: child))),
        ],
      ),
    );
  }
}
