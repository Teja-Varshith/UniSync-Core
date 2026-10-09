import 'package:flutter/material.dart';
import 'package:UniSync/features/examsync/brand/abstract_art.dart';
import 'package:UniSync/features/examsync/models/subject.dart';
import 'package:UniSync/features/examsync/theme/es_theme.dart';
import 'package:UniSync/features/examsync/widgets/es_widgets.dart';

class SubjectCard extends StatelessWidget {
  const SubjectCard({super.key, required this.subject, required this.onTap});

  final Subject subject;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tone = EsTone.forCode(subject.courseCode);
    return PlunkTap(
      color: tone.face,
      rightColor: tone.right,
      bottomColor: tone.bottom,
      semanticLabel: '${subject.subjectName}, ${subject.courseCode}',
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: EsChip(
                        subject.courseCode,
                        variant: EsChipVariant.ink,
                        mono: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      subject.subjectName,
                      style: EsText.display(size: 21, color: tone.ink),
                    ),
                    if (subject.description != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        subject.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: EsText.body(
                          size: 12.5,
                          color: tone.ink.withValues(alpha: 0.78),
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Text(
                      'Start prepping ↗',
                      style: EsText.body(
                        size: 13,
                        weight: FontWeight.w800,
                        color: tone.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 104,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: tone.bottom, width: 2),
                  ),
                ),
                child: AbstractArt(courseCode: subject.courseCode, tone: tone),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SubjectCardSkeleton extends StatelessWidget {
  const SubjectCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlunkBox(
      color: EsColors.surface,
      rightColor: EsColors.border,
      bottomColor: EsColors.border,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EsSkeleton(height: 20, width: 72),
          SizedBox(height: 14),
          EsSkeleton(height: 22, width: 220),
          SizedBox(height: 8),
          EsSkeleton(height: 12, width: 180),
          SizedBox(height: 18),
          EsSkeleton(height: 14, width: 110),
        ],
      ),
    );
  }
}
