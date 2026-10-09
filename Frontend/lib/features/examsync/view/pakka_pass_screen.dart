import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:UniSync/features/examsync/brand/brand.dart';
import 'package:UniSync/features/examsync/controller/examsync_controller.dart';
import 'package:UniSync/features/examsync/models/exam_data.dart';
import 'package:UniSync/features/examsync/models/subject.dart';
import 'package:UniSync/features/examsync/theme/es_theme.dart';
import 'package:UniSync/features/examsync/view/widgets/es_scope.dart';
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

class PakkaPassScreen extends ConsumerStatefulWidget {
  const PakkaPassScreen({super.key, required this.courseCode});

  final String courseCode;

  @override
  ConsumerState<PakkaPassScreen> createState() => _PakkaPassScreenState();
}

class _PakkaPassScreenState extends ConsumerState<PakkaPassScreen> {
  String _exam = kExamKeys.first;
  String? _tag;

  @override
  Widget build(BuildContext context) {
    final code = widget.courseCode;
    final subject = ref.watch(examSyncSubjectProvider(code));
    final access = ref.watch(examSyncHasAccessProvider(code));

    return ExamSyncScope(
      child: PopScope(
        canPop: _tag == null,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && _tag != null) setState(() => _tag = null);
        },
        child: Scaffold(
          backgroundColor: EsColors.bg,
          body: SafeArea(
            child: Column(
              children: [
                _TopBar(
                  subtitle: subject.valueOrNull?.subjectName ?? code,
                  onBack: () => _tag != null
                      ? setState(() => _tag = null)
                      : examSyncBack(context),
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
              Text('Pakka Pass is locked',
                  style: EsText.body(size: 16, weight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                'Unlock it from the subject page to see the questions.',
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
    final questions = bank.forExam(_exam);
    final tag = _tag;
    if (tag != null) {
      return _TagDetail(
        key: ValueKey('$_exam::$tag'),
        tag: tag,
        questions: questions.where((q) => q.tag == tag).toList(),
      );
    }

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
        const SizedBox(height: 20),
        if (questions.isEmpty)
          EsEmptyState(
            title: 'No questions for ${examLabel(_exam)} yet',
            message: 'Authors are still adding them. Check back soon.',
          ),
        if (questions.isNotEmpty) ...[
          const EsEyebrow('Pick a list'),
          const SizedBox(height: 10),
          for (var i = 0; i < tags.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TagCard(
                index: i,
                tag: tags[i],
                count: questions.where((q) => q.tag == tags[i]).length,
                onTap: () => setState(() => _tag = tags[i]),
              ),
            ),
        ],
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
                Text('Pakka Pass', style: EsText.display(size: 20)),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: EsText.body(size: 12, color: EsColors.textMuted),
                ),
              ],
            ),
          ),
          const EsChip('Pro', variant: EsChipVariant.premium),
        ],
      ),
    );
  }
}

class _TagCard extends StatelessWidget {
  const _TagCard({
    required this.index,
    required this.tag,
    required this.count,
    required this.onTap,
  });

  final int index;
  final String tag;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = count > 0;
    final (swatch, swatchInk) = _tagSwatches[index % _tagSwatches.length];
    final body = Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            color: enabled ? swatch : EsColors.surfaceElevated,
            child: Text(
              (index + 1).toString().padLeft(2, '0'),
              style: EsText.mono(
                size: 15,
                color: enabled ? swatchInk : EsColors.textDisabled,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tag,
                  style: EsText.body(
                    size: 15,
                    weight: FontWeight.w800,
                    color: enabled ? EsColors.text : EsColors.textDisabled,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count ${count == 1 ? 'question' : 'questions'}',
                  style: EsText.body(size: 12, color: EsColors.textMuted),
                ),
              ],
            ),
          ),
          if (enabled)
            const Icon(Icons.chevron_right_rounded,
                color: EsColors.textSecondary),
        ],
      ),
    );
    if (!enabled) {
      return PlunkBox(
        color: EsColors.surface,
        border: EsColors.border,
        child: body,
      );
    }
    return PlunkTap(
      color: EsColors.surface,
      rightColor: EsColors.borderLight,
      bottomColor: EsColors.border,
      border: EsColors.border,
      semanticLabel: '$tag, $count questions',
      onTap: onTap,
      child: body,
    );
  }
}

class _TagDetail extends StatefulWidget {
  const _TagDetail({super.key, required this.tag, required this.questions});

  final String tag;
  final List<ImpQuestion> questions;

  @override
  State<_TagDetail> createState() => _TagDetailState();
}

class _TagDetailState extends State<_TagDetail> {
  final Set<int> _open = {};

  @override
  Widget build(BuildContext context) {
    final qs = widget.questions;
    final allOpen = qs.isNotEmpty && _open.length == qs.length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text(widget.tag, style: EsText.display(size: 22)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: EsEyebrow(
                  '${qs.length} ${qs.length == 1 ? 'question' : 'questions'}'),
            ),
            if (qs.isNotEmpty)
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
        const SizedBox(height: 16),
        if (qs.isEmpty)
          const EsEmptyState(
            title: 'No questions here yet',
            message: 'Try another list.',
          ),
        for (var i = 0; i < qs.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _QuestionTile(
              index: i,
              question: qs[i],
              open: _open.contains(i),
              onToggle: () => setState(
                  () => _open.contains(i) ? _open.remove(i) : _open.add(i)),
            ),
          ),
      ],
    );
  }
}

class _QuestionTile extends StatelessWidget {
  const _QuestionTile({
    required this.index,
    required this.question,
    required this.open,
    required this.onToggle,
  });

  final int index;
  final ImpQuestion question;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      color: open ? EsColors.premium : EsColors.surfaceElevated,
                      child: Text(
                        'Q${index + 1}',
                        style: EsText.mono(
                          size: 12,
                          color: open ? Colors.white : EsColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        question.question,
                        style: EsText.body(
                          size: 14.5,
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
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const EsEyebrow('Answer', color: EsColors.premium),
                        const SizedBox(height: 8),
                        AnswerHtml(html: question.answerHtml),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Renders TipTap HTML: p, strong, em, u, h1–h3, ul/ol/li, blockquote, img.
class AnswerHtml extends StatelessWidget {
  const AnswerHtml({super.key, required this.html});

  final String html;

  @override
  Widget build(BuildContext context) {
    if (html.trim().isEmpty) {
      return Text('Answer coming soon.',
          style: EsText.body(size: 13.5, color: EsColors.textMuted));
    }
    return HtmlWidget(
      html,
      textStyle:
          EsText.body(size: 14, color: EsColors.textSecondary, height: 1.55),
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
