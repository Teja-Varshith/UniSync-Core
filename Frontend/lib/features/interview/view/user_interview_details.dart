import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neopop/neopop.dart';
import 'package:routemaster/routemaster.dart';
import 'package:UniSync/features/interview/controllers/carrer_controller.dart';
import 'package:UniSync/features/interview/controllers/reports_controller.dart';
import 'package:UniSync/features/interview/view/carrer_interview_screen.dart';
import 'package:UniSync/features/interview/view/interview_palette.dart';

InterviewPalette _ui(BuildContext context) => InterviewPalette.of(context);

class UserInterviewDetails extends ConsumerStatefulWidget {
  const UserInterviewDetails({super.key});

  @override
  ConsumerState<UserInterviewDetails> createState() =>
      _UserInterviewDetailsState();
}

class _UserInterviewDetailsState extends ConsumerState<UserInterviewDetails> {
  @override
  Widget build(BuildContext context) {
    final tmplt = ref.watch(getAllUserTemplate);

    return Scaffold(
      backgroundColor: _ui(context).backgroundPrimary,
      body: SafeArea(
        child: Column(children: [

          // ── Header ─────────────────────────────────────────────
          Container(
            color: _ui(context).backgroundSecondary,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('#MY ATTEMPTS', style: TextStyle(
                        color: _ui(context).accent, fontSize: 9,
                        fontWeight: FontWeight.w700, letterSpacing: 1.8,
                      )),
                      const SizedBox(height: 4),
                      RichText(text: TextSpan(children: [
                        TextSpan(text: 'Mock ',
                            style: TextStyle(
                              color: _ui(context).textPrimary, fontSize: 22,
                              fontWeight: FontWeight.w800, letterSpacing: -0.5,
                            )),
                        TextSpan(text: 'interviews',
                            style: TextStyle(
                              color: _ui(context).accent, fontSize: 22,
                              fontWeight: FontWeight.w800, letterSpacing: -0.5,
                            )),
                      ])),
                      const SizedBox(height: 3),
                      // Count subtitle
                      tmplt.when(
                        loading: () => Text('Loading...',
                            style: TextStyle(
                              color: _ui(context).textMuted, fontSize: 11,
                            )),
                        error: (_, __) => Text('0 interviews attempted',
                            style: TextStyle(
                              color: _ui(context).textMuted, fontSize: 11,
                            )),
                        data: (data) => Text(
                          '${data.length} interview${data.length == 1 ? '' : 's'} attempted',
                          style: TextStyle(
                            color: _ui(context).textMuted, fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Refresh button
                GestureDetector(
                  onTap: () => ref.invalidate(getAllUserTemplate),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: _ui(context).surfaceCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _ui(context).border),
                    ),
                    child: Center(
                      child: Icon(Icons.refresh_rounded,
                          size: 17, color: _ui(context).textMuted),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Container(height: 0.8, color: _ui(context).divider),

          // ── List ───────────────────────────────────────────────
          Expanded(
            child: tmplt.when(
              skipLoadingOnRefresh: false,
              loading: () => Center(
                child: SizedBox(width: 24, height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _ui(context).accent)),
              ),
              error: (e, _) => Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.error_outline_rounded,
                      color: _ui(context).textMuted, size: 36),
                  const SizedBox(height: 12),
                  Text(
                    'Unable to load your interview history.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: _ui(context).textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {
                      ref.invalidate(getAllUserTemplate);
                    },
                    icon: Icon(Icons.refresh_rounded, size: 16),
                    label: Text('Retry'),
                    style: TextButton.styleFrom(
                      foregroundColor: _ui(context).accent,
                    ),
                  ),
                ]),
              ),
              data: (data) {
                if (data.isEmpty) {
                  return Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      Container(
                        width: 60, height: 60,
                        color: _ui(context).surfaceCard,
                        child: Icon(Icons.psychology_outlined,
                            color: _ui(context).textMuted, size: 26),
                      ),
                      const SizedBox(height: 16),
                        Text('No interviews yet',
                            style: TextStyle(
                            color: _ui(context).textPrimary, fontSize: 15,
                            fontWeight: FontWeight.w700,
                          )),
                      const SizedBox(height: 6),
                        Text('Start a mock interview to see your history',
                            style: TextStyle(
                            color: _ui(context).textSecondary, fontSize: 12,
                          )),
                    ]),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                  itemCount: data.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final t = data[index];
                    return _TemplateCard(
                      heading:    t.title,
                      subheading: t.topics.join(' · '),
                      logoUrl:    t.icon,
                      onTap: () {
                        ref.read(selectedTemplateProvider.notifier).state = t;
                        ref.invalidate(ReportsControllerProvider);
                        Routemaster.of(context).push('/reportsScreen');
                      },
                    );
                  },
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TEMPLATE CARD
// ─────────────────────────────────────────────────────────────────────────────
class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.heading,
    required this.subheading,
    required this.logoUrl,
    required this.onTap,
  });

  final String heading;
  final String subheading;
  final String logoUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NeoPopButton(
      color: _ui(context).surfaceCard,
      bottomShadowColor: _ui(context).accent,
      rightShadowColor: _ui(context).accent,
      depth: 4,
      onTapUp: onTap,
      onTapDown: () {},
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [

          // Icon block
          Container(
            width: 48, height: 48,
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: _ui(context).backgroundSecondary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _ui(context).border),
            ),
            child: CachedNetworkImage(
              imageUrl: logoUrl, fit: BoxFit.contain,
              placeholder: (_, __) => SizedBox(width: 14, height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 1.5, color: _ui(context).textMuted)),
              errorWidget: (_, __, ___) => Icon(
                  Icons.psychology_outlined,
                  color: _ui(context).textMuted, size: 20),
            ),
          ),

          const SizedBox(width: 14),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(heading,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: _ui(context).textPrimary, letterSpacing: -0.2,
                    )),
                const SizedBox(height: 5),
                Text(subheading,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12, color: _ui(context).textSecondary,
                      height: 1.4,
                    )),
                const SizedBox(height: 8),
                // "View reports" link
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.bar_chart_rounded,
                      size: 12, color: _ui(context).accent),
                  SizedBox(width: 4),
                  Text('View reports',
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: _ui(context).accent,
                      )),
                ]),
              ],
            ),
          ),

          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios_rounded,
              size: 12, color: _ui(context).accent),
        ]),
      ),
    );
  }
}





