import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:UniSync/features/examsync/brand/brand.dart';
import 'package:UniSync/features/examsync/controller/examsync_controller.dart';
import 'package:UniSync/features/examsync/controller/study_progress.dart';
import 'package:UniSync/features/examsync/models/exam_data.dart';
import 'package:UniSync/features/examsync/models/subject.dart';
import 'package:UniSync/features/examsync/theme/es_theme.dart';
import 'package:UniSync/features/examsync/view/widgets/es_scope.dart';
import 'package:UniSync/features/examsync/widgets/es_disclaimer.dart';
import 'package:UniSync/features/examsync/widgets/es_widgets.dart';

/// Swatch colours for the numbered tag cards, cycled in order.
const _tagSwatches = <(Color, Color)>[
  (EsColors.accent, Colors.black),
  (EsColors.premium, Colors.white),
  (EsColors.lime, Colors.black),
  (EsColors.pink, Colors.black),
  (Color(0xFFFF8744), Colors.black),
  (Color(0xFF144CC7), Colors.white),
];

/// A list of questions the student opened: one tag, or a smart list
/// (saved / to revise). Frozen when opened so marking a question doesn't
/// make it jump out of the list being studied.
class _StudyList {
  const _StudyList({required this.title, required this.questions});

  final String title;
  final List<ImpQuestion> questions;
}

class PrepPackScreen extends ConsumerStatefulWidget {
  const PrepPackScreen({super.key, required this.courseCode});

  final String courseCode;

  @override
  ConsumerState<PrepPackScreen> createState() => _PrepPackScreenState();
}

class _PrepPackScreenState extends ConsumerState<PrepPackScreen> {
  String _exam = kExamKeys.first;
  _StudyList? _list;

  void _close() => setState(() => _list = null);

  @override
  Widget build(BuildContext context) {
    final code = widget.courseCode;
    final subject = ref.watch(examSyncSubjectProvider(code));
    final access = ref.watch(examSyncHasAccessProvider(code));

    return ExamSyncScope(
      child: PopScope(
        canPop: _list == null,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && _list != null) _close();
        },
        child: Scaffold(
          backgroundColor: EsColors.bg,
          body: SafeArea(
            child: Column(
              children: [
                _TopBar(
                  subtitle: subject.valueOrNull?.subjectName ?? code,
                  onBack: () =>
                      _list != null ? _close() : examSyncBack(context),
                ),
                Expanded(child: _body(access, subject)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(AsyncValue<bool> access, AsyncValue<Subject?> subject) {
    final code = widget.courseCode;
    if (access.isLoading || subject.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (access.hasError || subject.hasError) {
      return Center(
        child: EsErrorState(onRetry: () {
          ref.invalidate(examSyncHasAccessProvider(code));
          ref.invalidate(examSyncSubjectProvider(code));
        }),
      );
    }
    if (access.valueOrNull != true) {
      // Questions are only fetched once access is confirmed.
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const EsIllustration(IllustrationKind.lock, size: 88),
              const SizedBox(height: 16),
              Text('Prep Pack is locked',
                  style: EsText.body(size: 16, weight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                'Unlock it from the subject page to start studying.',
                textAlign: TextAlign.center,
                style: EsText.body(size: 13, color: EsColors.textMuted),
              ),
              const SizedBox(height: 16),
              EsButton(
                label: 'Go back',
                variant: EsButtonVariant.secondary,
                onPressed: () => examSyncBack(context),
              ),
            ],
          ),
        ),
      );
    }

    final bank = ref.watch(examSyncImpQuestionsProvider(code));
    return bank.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: EsErrorState(
          title: 'Couldn’t load questions',
          onRetry: () => ref.invalidate(examSyncImpQuestionsProvider(code)),
        ),
      ),
      data: (b) => _content(b, subject.valueOrNull?.customTags ?? const []),
    );
  }

  Widget _content(ImpQuestionBank bank, List<String> customTags) {
    final code = widget.courseCode;
    final questions = bank.forExam(_exam);
    final list = _list;
    if (list != null) {
      return _StudyListView(
        key: ValueKey('$_exam::${list.title}'),
        courseCode: code,
        exam: _exam,
        list: list,
      );
    }

    final progress = ref.watch(studyProgressProvider(code));
    String keyOf(ImpQuestion q) => questionKey(_exam, q);
    final toRevise = questions
        .where((q) => progress.markOf(keyOf(q)) == QuestionMark.revise)
        .toList();
    final saved = questions.where((q) => progress.isSaved(keyOf(q))).toList();
    final tags = orderedTags(customTags, questions);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        const EsAlertBanner(
          message:
              'Exam-prep material compiled by students and volunteers, not '
              'an official question paper. Not a guarantee of what will '
              'appear in your exam.',
        ),
        const SizedBox(height: 16),
        EsSegmented<String>(
          segments: [
            for (final e in kExamKeys)
              EsSegment(
                value: e,
                label: examLabel(e),
                count: bank.forExam(e).length,
              ),
          ],
          value: _exam,
          onChanged: (e) => setState(() => _exam = e),
          activeColor: EsColors.premium,
          activeInk: Colors.white,
          activeRight: EsColors.premiumRight,
          activeBottom: EsColors.premiumBottom,
        ),
        const SizedBox(height: 16),
        if (questions.isEmpty)
          EsEmptyState(
            title: 'No questions for ${examLabel(_exam)} yet',
            message: 'Authors are still adding them. Check back soon.',
          ),
        if (questions.isNotEmpty) ...[
          _ProgressCard(
            exam: _exam,
            total: questions.length,
            known: progress.knownIn(questions.map(keyOf)),
            revise: toRevise.length,
            saved: saved.length,
          ),
          const SizedBox(height: 20),
          if (toRevise.isNotEmpty || saved.isNotEmpty) ...[
            const EsEyebrow('Your lists'),
            const SizedBox(height: 10),
            if (toRevise.isNotEmpty)
              _ListCard(
                leading: const _ListIcon(
                    Icons.replay_rounded, EsColors.warning, Colors.black),
                title: 'To revise',
                count: toRevise.length,
                onTap: () => setState(() => _list =
                    _StudyList(title: 'To revise', questions: toRevise)),
              ),
            if (saved.isNotEmpty)
              _ListCard(
                leading: const _ListIcon(
                    Icons.bookmark_rounded, EsColors.accent, Colors.black),
                title: 'Saved',
                count: saved.length,
                onTap: () => setState(
                    () => _list = _StudyList(title: 'Saved', questions: saved)),
              ),
            const SizedBox(height: 8),
          ],
          const EsEyebrow('Pick a list'),
          const SizedBox(height: 10),
          for (var i = 0; i < tags.length; i++)
            Builder(builder: (context) {
              final qs = questions.where((q) => q.tag == tags[i]).toList();
              final (swatch, ink) = _tagSwatches[i % _tagSwatches.length];
              return _ListCard(
                leading:
                    _ListNumber(i + 1, swatch, ink, enabled: qs.isNotEmpty),
                title: tagLabel(tags[i]),
                count: qs.length,
                known: progress.knownIn(qs.map(keyOf)),
                onTap: () => setState(() => _list =
                    _StudyList(title: tagLabel(tags[i]), questions: qs)),
              );
            }),
        ],
        const SizedBox(height: 12),
        const EsDisclaimerNote(),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.subtitle, required this.onBack});

  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          EsIconButton(
            icon: Icons.arrow_back_rounded,
            semanticLabel: 'Back',
            onPressed: onBack,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Prep Pack', style: EsText.display(size: 20)),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: EsText.body(size: 12, color: EsColors.textMuted),
                ),
              ],
            ),
          ),
          const _TextSizeButton(),
          const SizedBox(width: 10),
          const EsChip('Pro', variant: EsChipVariant.premium),
        ],
      ),
    );
  }
}

/// Cycles the reading size of questions and answers.
class _TextSizeButton extends ConsumerWidget {
  const _TextSizeButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = ref.watch(readingScaleProvider);
    final step = kReadingScales.indexOf(scale) + 1;
    return PlunkTap(
      color: EsColors.surfaceElevated,
      rightColor: EsColors.borderLight,
      bottomColor: EsColors.border,
      semanticLabel:
          'Text size $step of ${kReadingScales.length}. Tap to change.',
      onTap: ref.read(readingScaleProvider.notifier).cycle,
      child: SizedBox(
        width: 48,
        height: 41,
        child: Center(
          child: Text.rich(TextSpan(children: [
            TextSpan(
                text: 'A',
                style: EsText.body(size: 12, weight: FontWeight.w800)),
            TextSpan(
                text: 'a',
                style: EsText.body(
                    size: 12 + step * 3.0,
                    weight: FontWeight.w800,
                    color: EsColors.accent)),
          ])),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value, this.height = 6});

  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: EsColors.surfaceElevated,
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: value.clamp(0.0, 1.0),
        child: Container(color: EsColors.success),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.exam,
    required this.total,
    required this.known,
    required this.revise,
    required this.saved,
  });

  final String exam;
  final int total;
  final int known;
  final int revise;
  final int saved;

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0 : (known * 100 / total).round();
    return PlunkBox(
      color: EsColors.surface,
      rightColor: EsColors.premiumRight,
      bottomColor: EsColors.premiumBottom,
      border: EsColors.border,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EsEyebrow('Your ${examLabel(exam)} progress'),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$known', style: EsText.display(size: 30)),
              Padding(
                padding: const EdgeInsets.only(bottom: 5, left: 4),
                child: Text('/ $total revised',
                    style: EsText.body(size: 13, color: EsColors.textMuted)),
              ),
              const Spacer(),
              Text('$pct%',
                  style: EsText.mono(size: 16, color: EsColors.success)),
            ],
          ),
          const SizedBox(height: 10),
          _ProgressBar(value: total == 0 ? 0 : known / total, height: 8),
          const SizedBox(height: 10),
          Text(
            known == 0
                ? 'Open a list, read an answer, then tap “Got it” to track it.'
                : '$revise to revise · $saved saved',
            style: EsText.body(size: 12, color: EsColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _ListNumber extends StatelessWidget {
  const _ListNumber(this.n, this.swatch, this.ink, {required this.enabled});

  final int n;
  final Color swatch;
  final Color ink;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      color: enabled ? swatch : EsColors.surfaceElevated,
      child: Text(
        n.toString().padLeft(2, '0'),
        style: EsText.mono(
          size: 15,
          color: enabled ? ink : EsColors.textDisabled,
        ),
      ),
    );
  }
}

class _ListIcon extends StatelessWidget {
  const _ListIcon(this.icon, this.swatch, this.ink);

  final IconData icon;
  final Color swatch;
  final Color ink;

  @override
  Widget build(BuildContext context) => Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        color: swatch,
        child: Icon(icon, size: 20, color: ink),
      );
}

class _ListCard extends StatelessWidget {
  const _ListCard({
    required this.leading,
    required this.title,
    required this.count,
    required this.onTap,
    this.known,
  });

  final Widget leading;
  final String title;
  final int count;
  final int? known;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = count > 0;
    final k = known;
    final body = Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: EsText.body(
                    size: 15,
                    weight: FontWeight.w800,
                    color: enabled ? EsColors.text : EsColors.textDisabled,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  k == null || !enabled
                      ? '$count ${count == 1 ? 'question' : 'questions'}'
                      : '$count ${count == 1 ? 'question' : 'questions'} · $k revised',
                  style: EsText.body(size: 12, color: EsColors.textMuted),
                ),
                if (k != null && enabled) ...[
                  const SizedBox(height: 6),
                  _ProgressBar(value: k / count, height: 4),
                ],
              ],
            ),
          ),
          if (enabled) ...[
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: EsColors.textSecondary),
          ],
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: enabled
          ? PlunkTap(
              color: EsColors.surface,
              rightColor: EsColors.borderLight,
              bottomColor: EsColors.border,
              border: EsColors.border,
              semanticLabel: '$title, $count questions',
              onTap: onTap,
              child: body,
            )
          : PlunkBox(
              color: EsColors.surface,
              border: EsColors.border,
              child: body,
            ),
    );
  }
}

class _StudyListView extends ConsumerStatefulWidget {
  const _StudyListView({
    super.key,
    required this.courseCode,
    required this.exam,
    required this.list,
  });

  final String courseCode;
  final String exam;
  final _StudyList list;

  @override
  ConsumerState<_StudyListView> createState() => _StudyListViewState();
}

class _StudyListViewState extends ConsumerState<_StudyListView> {
  final Set<int> _open = {};

  String _key(ImpQuestion q) => questionKey(widget.exam, q);

  @override
  Widget build(BuildContext context) {
    final qs = widget.list.questions;
    final progress = ref.watch(studyProgressProvider(widget.courseCode));
    final known = progress.knownIn(qs.map(_key));

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.list.title, style: EsText.display(size: 22)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: EsEyebrow(
                    '$known of ${qs.length} revised · ${examLabel(widget.exam)}'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _ProgressBar(value: qs.isEmpty ? 0 : known / qs.length),
          const SizedBox(height: 14),
        ],
      ),
    );

    if (qs.isEmpty) {
      return ListView(
        children: [
          header,
          const EsEmptyState(
            title: 'No questions here yet',
            message: 'Try another list.',
          ),
        ],
      );
    }

    final allOpen = _open.length == qs.length;
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        header,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Read the answer, then mark how well you know it.',
                  style: EsText.body(size: 12, color: EsColors.textMuted),
                ),
              ),
              const SizedBox(width: 8),
              EsButton(
                label: allOpen ? 'Collapse all' : 'Expand all',
                size: EsButtonSize.sm,
                variant: EsButtonVariant.secondary,
                onPressed: () => setState(() {
                  if (allOpen) {
                    _open.clear();
                  } else {
                    _open.addAll(List.generate(qs.length, (i) => i));
                  }
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < qs.length; i++)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _QuestionTile(
              index: i,
              question: qs[i],
              questionKey: _key(qs[i]),
              courseCode: widget.courseCode,
              open: _open.contains(i),
              onToggle: () => setState(
                  () => _open.contains(i) ? _open.remove(i) : _open.add(i)),
            ),
          ),
      ],
    );
  }
}

class _QuestionTile extends ConsumerWidget {
  const _QuestionTile({
    required this.index,
    required this.question,
    required this.questionKey,
    required this.courseCode,
    required this.open,
    required this.onToggle,
  });

  final int index;
  final ImpQuestion question;
  final String questionKey;
  final String courseCode;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final scale = ref.watch(readingScaleProvider);
    final progress = ref.watch(studyProgressProvider(courseCode));
    final notifier = ref.read(studyProgressProvider(courseCode).notifier);
    final mark = progress.markOf(questionKey);
    final saved = progress.isSaved(questionKey);

    return PlunkBox(
      color: EsColors.surface,
      rightColor: open ? EsColors.premiumRight : EsColors.borderLight,
      bottomColor: open ? EsColors.premiumBottom : EsColors.border,
      border: EsColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: open,
            child: InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _QBadge(index: index, open: open, mark: mark),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        question.question,
                        style: EsText.body(
                          size: 14.5 * scale,
                          weight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      open
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: EsColors.textMuted,
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
            child: !open
                ? const SizedBox(width: double.infinity)
                : Container(
                    decoration: const BoxDecoration(
                      color: EsColors.bgSecondary,
                      border: Border(top: BorderSide(color: EsColors.border)),
                    ),
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const EsEyebrow('Answer', color: EsColors.premium),
                        const SizedBox(height: 8),
                        AnswerHtml(html: question.answerHtml, scale: scale),
                        const SizedBox(height: 12),
                        _MarkBar(
                          mark: mark,
                          saved: saved,
                          onMark: (m) =>
                              notifier.mark(questionKey, m == mark ? null : m),
                          onToggleSaved: () =>
                              notifier.toggleSaved(questionKey),
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

class _QBadge extends StatelessWidget {
  const _QBadge({required this.index, required this.open, this.mark});

  final int index;
  final bool open;
  final QuestionMark? mark;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (mark) {
      QuestionMark.known => (EsColors.success, Colors.black),
      QuestionMark.revise => (EsColors.warning, Colors.black),
      null => open
          ? (EsColors.premium, Colors.white)
          : (EsColors.surfaceElevated, EsColors.textSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      color: bg,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (mark == QuestionMark.known) ...[
            Icon(Icons.check_rounded, size: 12, color: fg),
            const SizedBox(width: 2),
          ],
          Text('Q${index + 1}', style: EsText.mono(size: 12, color: fg)),
        ],
      ),
    );
  }
}

/// Save + "Revise again" / "Got it" row under an answer.
class _MarkBar extends StatelessWidget {
  const _MarkBar({
    required this.mark,
    required this.saved,
    required this.onMark,
    required this.onToggleSaved,
  });

  final QuestionMark? mark;
  final bool saved;
  final ValueChanged<QuestionMark> onMark;
  final VoidCallback onToggleSaved;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        EsIconButton(
          icon: saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          semanticLabel: saved ? 'Remove from saved' : 'Save for later',
          iconColor: saved ? EsColors.accent : EsColors.text,
          onPressed: onToggleSaved,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: EsButton(
            label: 'Revise again',
            icon: Icons.replay_rounded,
            size: EsButtonSize.sm,
            expand: true,
            variant: mark == QuestionMark.revise
                ? EsButtonVariant.primary
                : EsButtonVariant.secondary,
            onPressed: () => onMark(QuestionMark.revise),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: EsButton(
            label: 'Got it',
            icon: Icons.check_rounded,
            size: EsButtonSize.sm,
            expand: true,
            variant: mark == QuestionMark.known
                ? EsButtonVariant.success
                : EsButtonVariant.secondary,
            onPressed: () => onMark(QuestionMark.known),
          ),
        ),
      ],
    );
  }
}

/// Renders TipTap HTML: p, strong, em, u, h1–h3, ul/ol/li, blockquote, img.
class AnswerHtml extends StatelessWidget {
  const AnswerHtml({super.key, required this.html, this.scale = 1.0});

  final String html;

  /// Reading size multiplier from the text-size control.
  final double scale;

  @override
  Widget build(BuildContext context) {
    if (html.trim().isEmpty) {
      return Text('Answer coming soon.',
          style: EsText.body(size: 13.5, color: EsColors.textMuted));
    }
    return HtmlWidget(
      html,
      textStyle: EsText.body(
          size: 14 * scale, color: EsColors.textSecondary, height: 1.55),
      customStylesBuilder: (element) {
        switch (element.localName) {
          case 'h1':
            return {
              'font-size': '1.4em',
              'color': '#FFFFFF',
              'margin': '8px 0 4px'
            };
          case 'h2':
            return {
              'font-size': '1.25em',
              'color': '#FFFFFF',
              'margin': '8px 0 4px'
            };
          case 'h3':
            return {
              'font-size': '1.1em',
              'color': '#FFFFFF',
              'margin': '6px 0 4px'
            };
          case 'strong':
          case 'b':
            return {'color': '#FFFFFF'};
          case 'blockquote':
            return {
              'border-left': '3px solid #6A35FF',
              'padding-left': '10px',
              'margin': '8px 0',
              'color': '#BDBDBD',
              'font-style': 'italic',
            };
          case 'p':
            return {'margin': '0 0 8px 0'};
          case 'img':
            return {'max-width': '100%', 'height': 'auto'};
        }
        return null;
      },
      customWidgetBuilder: (element) {
        if (element.localName != 'img') return null;
        final src = element.attributes['src'] ?? '';
        if (src.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Image.network(
            src,
            width: double.infinity,
            fit: BoxFit.fitWidth,
            semanticLabel: element.attributes['alt'],
            errorBuilder: (_, __, ___) => Container(
              height: 80,
              color: EsColors.surfaceElevated,
              alignment: Alignment.center,
              child: Text('Image couldn’t load',
                  style: EsText.body(size: 12, color: EsColors.textMuted)),
            ),
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : const SizedBox(height: 120, child: EsSkeleton(height: 120)),
          ),
        );
      },
    );
  }
}
