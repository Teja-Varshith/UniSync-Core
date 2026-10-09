import 'package:flutter/material.dart';
import 'package:UniSync/features/examsync/theme/es_theme.dart';
import 'package:UniSync/features/examsync/view/widgets/es_scope.dart';
import 'package:UniSync/features/examsync/widgets/es_widgets.dart';

const String kExamSyncSupportEmail = 'hello.unisync@gmail.com';

/// One-line version, shown next to anything students pay for or study from.
const String kExamSyncDisclaimerShort =
    'Study aid only. Not an official question paper and no guarantee of '
    'questions, marks or results.';

/// Text the student ticks before spending coins.
const String kExamSyncAcknowledgement =
    'I understand this is study material only. It is not an official or '
    'leaked paper, and UniSync does not guarantee any question will appear '
    'in my exam or that I will pass or score any marks.';

/// The full disclaimer, as (heading, body) pairs.
const List<(String, String)> kExamSyncDisclaimerPoints = [
  (
    'Study aid only',
    'ExamSync, including Prep Pack, is exam-preparation material: a '
        'selection of topics and practice questions with model answers, '
        'compiled by students and volunteers to help you revise.',
  ),
  (
    'No guarantee',
    'We do not predict, know or guarantee which questions will be asked in '
        'any exam. Nothing here promises that you will pass, score a '
        'particular mark or grade, or that any question will appear.',
  ),
  (
    'Not official or leaked',
    'Content is not an official question paper, answer key or syllabus, '
        'and is never sourced from confidential or unreleased exam papers. '
        'Previous-year papers are shared only for practice.',
  ),
  (
    'Not affiliated',
    'UniSync and ExamSync are independent student tools and are not '
        'affiliated with, endorsed by or acting for any university, college, '
        'board or examining body. Always follow your official syllabus and '
        'your faculty’s instructions.',
  ),
  (
    'Accuracy',
    'Answers are written by people and may contain mistakes or be out of '
        'date. Check important points against your textbooks and lecture '
        'notes.',
  ),
  (
    'What coins buy',
    'Coins unlock access to the study content for that subject inside this '
        'app for your account only. Do not copy, record, resell or share it.',
  ),
  (
    'Content concerns',
    'If you own any material shown here and want it credited or removed, '
        'or you spot an error, write to $kExamSyncSupportEmail and we will '
        'review it promptly.',
  ),
];

/// Small muted disclaimer line with a "Read full disclaimer" link.
class EsDisclaimerNote extends StatelessWidget {
  const EsDisclaimerNote({
    super.key,
    this.text = kExamSyncDisclaimerShort,
    this.center = false,
  });

  final String text;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final style =
        EsText.body(size: 11.5, color: EsColors.textMuted, height: 1.45);
    return Semantics(
      button: true,
      label: '$text Read full disclaimer.',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => showExamSyncDisclaimer(context),
        child: Row(
          mainAxisAlignment:
              center ? MainAxisAlignment.center : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child:
                  Icon(Icons.info_outline, size: 14, color: EsColors.textMuted),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: '$text '),
                  TextSpan(
                    text: 'Read full disclaimer',
                    style: style.copyWith(
                      color: EsColors.textSecondary,
                      fontWeight: FontWeight.w800,
                      decoration: TextDecoration.underline,
                      decorationColor: EsColors.textSecondary,
                    ),
                  ),
                ]),
                textAlign: center ? TextAlign.center : TextAlign.start,
                style: style,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showExamSyncDisclaimer(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: EsColors.surface,
    shape: const RoundedRectangleBorder(),
    builder: (sheetContext) => ExamSyncScope(
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.85,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            children: [
              const EsEyebrow('Please read'),
              const SizedBox(height: 6),
              Text('Disclaimer', style: EsText.display(size: 24)),
              const SizedBox(height: 16),
              for (final (title, body) in kExamSyncDisclaimerPoints) ...[
                Text(title,
                    style: EsText.body(size: 14, weight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: EsText.body(
                    size: 13,
                    color: EsColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
              ],
              const SizedBox(height: 6),
              EsButton(
                label: 'Got it',
                variant: EsButtonVariant.secondary,
                expand: true,
                onPressed: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
