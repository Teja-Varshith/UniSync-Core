import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neopop/neopop.dart';
import 'package:routemaster/routemaster.dart';
import 'package:unisync/constants/constant.dart';
import 'package:unisync/features/interview/controllers/carrer_controller.dart';
import 'package:unisync/features/interview/controllers/reports_controller.dart';
import 'package:unisync/features/interview/view/carrer_interview_screen.dart';

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
      backgroundColor: UniSyncColors.backgroundPrimary,
      body: SafeArea(
        child: Column(children: [

          // ── Header ─────────────────────────────────────────────
          Container(
            color: UniSyncColors.backgroundSecondary,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('#MY ATTEMPTS', style: TextStyle(
                        color: UniSyncColors.accent, fontSize: 9,
                        fontWeight: FontWeight.w700, letterSpacing: 1.8,
                      )),
                      const SizedBox(height: 4),
                      RichText(text: const TextSpan(children: [
                        TextSpan(text: 'Mock ',
                            style: TextStyle(
                              color: UniSyncColors.textPrimary, fontSize: 22,
                              fontWeight: FontWeight.w800, letterSpacing: -0.5,
                            )),
                        TextSpan(text: 'interviews',
                            style: TextStyle(
                              color: UniSyncColors.accent, fontSize: 22,
                              fontWeight: FontWeight.w800, letterSpacing: -0.5,
                            )),
                      ])),
                      const SizedBox(height: 3),
                      // Count subtitle
                      tmplt.when(
                        loading: () => const Text('Loading...',
                            style: TextStyle(
                              color: UniSyncColors.textMuted, fontSize: 11,
                            )),
                        error: (_, __) => const Text('0 interviews attempted',
                            style: TextStyle(
                              color: UniSyncColors.textMuted, fontSize: 11,
                            )),
                        data: (data) => Text(
                          '${data.length} interview${data.length == 1 ? '' : 's'} attempted',
                          style: const TextStyle(
                            color: UniSyncColors.textMuted, fontSize: 11,
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
                      color: UniSyncColors.surfaceCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: UniSyncColors.border),
                    ),
                    child: const Center(
                      child: Icon(Icons.refresh_rounded,
                          size: 17, color: UniSyncColors.textMuted),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Container(height: 0.8, color: UniSyncColors.divider),

          // ── List ───────────────────────────────────────────────
          Expanded(
            child: tmplt.when(
              skipLoadingOnRefresh: false,
              loading: () => const Center(
                child: SizedBox(width: 24, height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: UniSyncColors.accent)),
              ),
              error: (e, _) => Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.error_outline_rounded,
                      color: UniSyncColors.textMuted, size: 36),
                  const SizedBox(height: 12),
                  const Text(
                    'Unable to load your interview history.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: UniSyncColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {
                      ref.invalidate(getAllUserTemplate);
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Retry'),
                    style: TextButton.styleFrom(
                      foregroundColor: UniSyncColors.accent,
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
                        color: UniSyncColors.surfaceCard,
                        child: const Icon(Icons.psychology_outlined,
                            color: UniSyncColors.textMuted, size: 26),
                      ),
                      const SizedBox(height: 16),
                      const Text('No interviews yet',
                          style: TextStyle(
                            color: UniSyncColors.textPrimary, fontSize: 15,
                            fontWeight: FontWeight.w700,
                          )),
                      const SizedBox(height: 6),
                      const Text('Start a mock interview to see your history',
                          style: TextStyle(
                            color: UniSyncColors.textSecondary, fontSize: 12,
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
      color: UniSyncColors.surfaceCard,
      bottomShadowColor: UniSyncColors.accent,
      rightShadowColor: UniSyncColors.accent,
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
              color: UniSyncColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: UniSyncColors.border),
            ),
            child: CachedNetworkImage(
              imageUrl: logoUrl, fit: BoxFit.contain,
              placeholder: (_, __) => const SizedBox(width: 14, height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 1.5, color: UniSyncColors.textMuted)),
              errorWidget: (_, __, ___) => const Icon(
                  Icons.psychology_outlined,
                  color: UniSyncColors.textMuted, size: 20),
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
                    style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: UniSyncColors.textPrimary, letterSpacing: -0.2,
                    )),
                const SizedBox(height: 5),
                Text(subheading,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12, color: UniSyncColors.textSecondary,
                      height: 1.4,
                    )),
                const SizedBox(height: 8),
                // "View reports" link
                Row(mainAxisSize: MainAxisSize.min, children: const [
                  Icon(Icons.bar_chart_rounded,
                      size: 12, color: UniSyncColors.accent),
                  SizedBox(width: 4),
                  Text('View reports',
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: UniSyncColors.accent,
                      )),
                ]),
              ],
            ),
          ),

          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios_rounded,
              size: 12, color: UniSyncColors.accent),
        ]),
      ),
    );
  }
}