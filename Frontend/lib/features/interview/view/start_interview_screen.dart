import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neopop/neopop.dart';
import 'package:routemaster/routemaster.dart';
import 'package:UniSync/app/providers.dart';
import 'package:UniSync/constants/constant.dart';
import 'package:UniSync/features/interview/controllers/reports_controller.dart';
import 'package:UniSync/features/interview/controllers/interview_controller.dart';
import 'package:UniSync/features/interview/view/carrer_interview_screen.dart';
import 'package:UniSync/sockets/socket_methods.dart';

class StartInterviewScreen extends ConsumerStatefulWidget {
  const StartInterviewScreen({super.key});

  @override
  ConsumerState<StartInterviewScreen> createState() =>
      _StartInterviewScreenState();
}

class _StartInterviewScreenState
    extends ConsumerState<StartInterviewScreen> {
  static const int _defaultQuestionCount = 6;
  static const List<int> _questionPresets = [4, 6, 8, 10, 12];

  bool _loading = false;
  Timer? _startTimeout;
  final TextEditingController _questionCountController =
      TextEditingController();

  void _showStartError(String message) {
    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: UniSyncColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _stopLoading() {
    _startTimeout?.cancel();
    _startTimeout = null;
    if (mounted && _loading) {
      setState(() => _loading = false);
    }
  }

  void _beginStartTimeout() {
    _startTimeout?.cancel();
    _startTimeout = Timer(const Duration(seconds: 30), () {
      if (!mounted || !_loading) return;
      setState(() => _loading = false);
      _showStartError(
        'Interview service is taking longer than expected to wake up. Please try again.',
      );
    });
  }

  Future<int> _refreshUserCoins(String uid) async {
    try {
      final firestore = ref.read(firebaseFirestoreProvider) as FirebaseFirestore;
      final snap = await firestore.collection('users').doc(uid).get();
      final latestCoins = (snap.data()?['coins'] as num?)?.toInt() ?? 0;

      final currentUser = ref.read(userProvider);
      if (currentUser != null) {
        ref.read(userProvider.notifier).state =
            currentUser.copyWith(coins: latestCoins);
      }
      return latestCoins;
    } catch (_) {
      final currentUser = ref.read(userProvider);
      return currentUser?.coins ?? 0;
    }
  }

  Future<bool> _confirmInterviewStart({
    required int coinPrice,
    required int availableCoins,
    required int effectiveQuestionCount,
  }) async {
    final remainingCoins = availableCoins - coinPrice;
    final shouldStart = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: UniSyncColors.backgroundSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Start Interview?',
          style: TextStyle(
            color: UniSyncColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'This will deduct $coinPrice UniCoins from your wallet.\n'
          'Questions to be asked: $effectiveQuestionCount\n'
          'Remaining balance: ${remainingCoins < 0 ? 0 : remainingCoins} UniCoins.',
          style: const TextStyle(
            color: UniSyncColors.textSecondary,
            fontSize: 13,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: UniSyncColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Start',
              style: TextStyle(
                color: UniSyncColors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    return shouldStart ?? false;
  }

  int? _parseQuestionLimit() {
    final raw = _questionCountController.text.trim();
    if (raw.isEmpty) return null;
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed < 4 || parsed > 20) return null;
    return parsed;
  }

  void _setQuestionLimitFromPreset(int value) {
    _questionCountController.text = value.toString();
    _questionCountController.selection = TextSelection.fromPosition(
      TextPosition(offset: _questionCountController.text.length),
    );
    setState(() {});
  }

  Future<void> _handleStartTap() async {
    final user = ref.read(userProvider);
    final tmplte = ref.read(selectedTemplateProvider)!;
    final rawQuestionCount = _questionCountController.text.trim();
    final requestedQuestionLimit = _parseQuestionLimit();

    if (rawQuestionCount.isNotEmpty && requestedQuestionLimit == null) {
      _showStartError('Please enter between 4 and 20 questions.');
      return;
    }

    if (user == null || user.id == null || user.id!.isEmpty) {
      _showStartError('Unable to verify your account. Please sign in again.');
      return;
    }

    final latestCoins = await _refreshUserCoins(user.id!);
    if (latestCoins < tmplte.coinPrice) {
      _showStartError(
        'Not enough coins. You need ${tmplte.coinPrice} coins to start this interview.',
      );
      return;
    }

    if (!mounted) return;
    final confirmed = await _confirmInterviewStart(
      coinPrice: tmplte.coinPrice,
      availableCoins: latestCoins,
      effectiveQuestionCount:
          requestedQuestionLimit ?? _defaultQuestionCount,
    );
    if (!confirmed || !mounted) return;

    setState(() => _loading = true);

    _beginStartTimeout();

    final started = await ref
        .read(socketMethodProvider)
        .startInterview(
          tmplte.id,
          user.id!,
          questionLimit: requestedQuestionLimit,
        );

    if (!started) {
      _stopLoading();
      return;
    }
  }

  @override
  void dispose() {
    _startTimeout?.cancel();
    _questionCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ── logic unchanged ────────────────────────────────────────────
    ref.listen(interviewControllerProvider, (prev, next) {
      if (next.questionreceived != null) {
        _stopLoading();
        Routemaster.of(context).replace('/coreInterviewScreen');
      }
    });

    final user   = ref.watch(userProvider);
    final tmplte = ref.read(selectedTemplateProvider)!;
    final chips  = tmplte.topics;
    final availableCoins = user?.coins ?? 0;
    final hasEnoughCoins = availableCoins >= tmplte.coinPrice;
    final rawQuestionInput = _questionCountController.text.trim();
    final parsedQuestionLimit = _parseQuestionLimit();
    final hasInvalidQuestionInput =
        rawQuestionInput.isNotEmpty && parsedQuestionLimit == null;
    // ──────────────────────────────────────────────────────────────

    return Scaffold(
      backgroundColor: UniSyncColors.backgroundPrimary,

       // ── Floating shimmer CTA ─────────────────────────────────────
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _loading
          ? Container(
              height: 56,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              color: UniSyncColors.accent,
              child: const Center(
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: UniSyncColors.buttonPrimaryFg),
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: NeoPopTiltedButton(
                isFloating: true,
                decoration: NeoPopTiltedButtonDecoration(
                  color: hasEnoughCoins
                      ? UniSyncColors.accent
                      : UniSyncColors.textDisabled,
                  plunkColor: hasEnoughCoins
                      ? UniSyncColors.accent
                      : UniSyncColors.textDisabled,
                  shadowColor: Colors.black.withOpacity(0.5),
                  showShimmer: hasEnoughCoins,
                ),
                onTapUp: hasEnoughCoins ? _handleStartTap : () {},
                child: SizedBox(
                  height: 56,
                  width: double.maxFinite,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.rocket_launch_rounded,
                            size: 16,
                            color: UniSyncColors.buttonPrimaryFg),
                        SizedBox(width: 8),
                        Text(hasEnoughCoins
                            ? 'Start Interview'
                            : 'Need ${tmplte.coinPrice} coins',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: hasEnoughCoins
                                  ? UniSyncColors.buttonPrimaryFg
                                  : UniSyncColors.backgroundPrimary,
                              letterSpacing: 0.2,
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            ),

      body: SafeArea(
        child: Column(children: [

          // ── App bar (unchanged) ────────────────────────────────
          Container(
            color: UniSyncColors.backgroundSecondary,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(children: [
              // NeoPopButton(
              //   color: UniSyncColors.surfaceCard,
              //   bottomShadowColor: UniSyncColors.border,
              //   rightShadowColor: UniSyncColors.border,
              //   depth: 3,
              //   onTapUp: () => Routemaster.of(context)
              //       .replace('/carrer-interview-screen'),
              //   onTapDown: () {},
              //   child: const SizedBox(width: 40, height: 40,
              //     child: Center(child: Icon(Icons.arrow_back_ios_new_rounded,
              //         size: 16, color: UniSyncColors.textPrimary)),
              //   ),
              // ),
              // const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('#INTERVIEW', style: TextStyle(
                    color: UniSyncColors.accent, fontSize: 9,
                    fontWeight: FontWeight.w700, letterSpacing: 1.8,
                  )),
                  const SizedBox(height: 2),
                  RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: const TextSpan(children: [
                      TextSpan(text: 'Detailed ',
                          style: TextStyle(color: UniSyncColors.textPrimary,
                              fontSize: 18, fontWeight: FontWeight.w800,
                              letterSpacing: -0.4)),
                      TextSpan(text: 'info',
                          style: TextStyle(color: UniSyncColors.accent,
                              fontSize: 18, fontWeight: FontWeight.w800,
                              letterSpacing: -0.4)),
                    ]),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Feel the actual butterflies before the real one',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: UniSyncColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ]),
              ),
              const SizedBox(width: 10),
              NeoPopButton(
                color: UniSyncColors.surfaceCard,
                bottomShadowColor: UniSyncColors.accent,
                rightShadowColor: UniSyncColors.accent,
                depth: 3,
                onTapUp: () {
                  ref.invalidate(ReportsControllerProvider);
                  Routemaster.of(context).push('/reportsScreen');
                },
                onTapDown: () {},
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('Reports', style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: UniSyncColors.accent)),
                    SizedBox(width: 5),
                    Icon(Icons.launch_rounded,
                        size: 13, color: UniSyncColors.accent),
                  ]),
                ),
              ),
            ]),
          ),

          Container(height: 0.8, color: UniSyncColors.divider),

          // ── Body ────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              // extra bottom padding so FAB doesn't cover last item
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Template header ────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: UniSyncColors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: UniSyncColors.borderSubtle),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 60, height: 60,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: UniSyncColors.surfaceCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: UniSyncColors.border),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: tmplte.icon, fit: BoxFit.contain,
                            placeholder: (_, __) => const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: UniSyncColors.textMuted)),
                            errorWidget: (_, __, ___) => const Icon(
                                Icons.psychology_outlined,
                                color: UniSyncColors.textMuted, size: 24),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tmplte.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.w800,
                                    color: UniSyncColors.textPrimary,
                                    letterSpacing: -0.3,
                                  )),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: UniSyncColors.accentSoft,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: UniSyncColors.accent
                                            .withOpacity(0.4),
                                      ),
                                    ),
                                    child: Text(
                                      'Cost: ${tmplte.coinPrice} coins',
                                      style: const TextStyle(
                                        color: UniSyncColors.accent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: UniSyncColors.surfaceCard,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: UniSyncColors.border,
                                      ),
                                    ),
                                    child: Text(
                                      'You have: $availableCoins coins',
                                      style: const TextStyle(
                                        color: UniSyncColors.textSecondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: UniSyncColors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: UniSyncColors.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.tune_rounded,
                              size: 16,
                              color: UniSyncColors.accent,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Interview Length',
                              style: TextStyle(
                                color: UniSyncColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Select how many questions AI should ask. Minimum 4, maximum 20. Leave custom empty to use default 6.',
                          style: TextStyle(
                            color: UniSyncColors.textSecondary,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _questionPresets.map((count) {
                            final currentValue =
                                _questionCountController.text.trim();
                            final isSelected =
                                currentValue == count.toString() ||
                                    (currentValue.isEmpty &&
                                        count == _defaultQuestionCount);
                            return InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => _setQuestionLimitFromPreset(count),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? UniSyncColors.accent.withOpacity(0.15)
                                      : UniSyncColors.surfaceCard,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? UniSyncColors.accent
                                        : UniSyncColors.border,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '$count',
                                      style: TextStyle(
                                        color: isSelected
                                            ? UniSyncColors.accent
                                            : UniSyncColors.textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (count == _defaultQuestionCount) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: UniSyncColors.accentSoft,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'DEFAULT',
                                          style: TextStyle(
                                            color: UniSyncColors.accent,
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _questionCountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            TextInputFormatter.withFunction(
                              (oldValue, newValue) {
                                if (newValue.text.isEmpty) return newValue;
                                final value = int.tryParse(newValue.text);
                                if (value == null || value > 20) {
                                  return oldValue;
                                }
                                return newValue;
                              },
                            ),
                          ],
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Custom question count',
                            hintText: 'Min 4, max 20, default 6',
                            errorText: hasInvalidQuestionInput
                                ? 'Enter between 4 and 20'
                                : null,
                            prefixIcon: const Icon(
                              Icons.help_outline_rounded,
                              size: 18,
                              color: UniSyncColors.accent,
                            ),
                            suffixIcon:
                                _questionCountController.text.trim().isEmpty
                                    ? null
                                    : IconButton(
                                        onPressed: () {
                                          _questionCountController.clear();
                                          setState(() {});
                                        },
                                        icon: const Icon(
                                          Icons.close_rounded,
                                          size: 18,
                                          color: UniSyncColors.textMuted,
                                        ),
                                      ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            filled: true,
                            fillColor: UniSyncColors.surfaceCard,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: UniSyncColors.border,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: UniSyncColors.accent,
                                width: 1.5,
                              ),
                            ),
                          ),
                          style: const TextStyle(
                            color: UniSyncColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Interview will run for ${parsedQuestionLimit ?? _defaultQuestionCount} question${(parsedQuestionLimit ?? _defaultQuestionCount) > 1 ? 's' : ''}.',
                          style: const TextStyle(
                            color: UniSyncColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Topics section ──────────────────────────────
                  // Spotlight heading — same pattern as home page
                  _SectionHeading(eyebrow: '#WHAT YOU\'LL COVER',
                      title: 'Key', highlight: 'topics'),
                  const SizedBox(height: 14),

                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: chips.map((chip) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: UniSyncColors.surfaceCard,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: UniSyncColors.border),
                      ),
                      child: Text(chip, style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: UniSyncColors.textSecondary,
                      )),
                    )).toList(),
                  ),

                  const SizedBox(height: 28),

                  // ── Evaluation metrics section ──────────────────
                  _SectionHeading(eyebrow: '#HOW YOU\'LL BE SCORED',
                      title: 'Evaluation', highlight: 'metrics'),
                  const SizedBox(height: 14),

                  ...tmplte.evaluationMetrics.asMap().entries.map((entry) {
                    final i      = entry.key;
                    final metric = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _MetricCard(
                        index:       i + 1,
                        title:       metric.topic,
                        description: metric.description,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SECTION HEADING  — same system as home page SpotlightHeader
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    required this.highlight,
  });

  final String eyebrow, title, highlight;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(eyebrow, style: const TextStyle(
        color: UniSyncColors.accent, fontSize: 9,
        fontWeight: FontWeight.w700, letterSpacing: 1.8,
      )),
      const SizedBox(height: 4),
      RichText(text: TextSpan(children: [
        TextSpan(text: '$title ',
            style: const TextStyle(
              color: UniSyncColors.textPrimary, fontSize: 22,
              fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.1,
            )),
        TextSpan(text: highlight,
            style: const TextStyle(
              color: UniSyncColors.accent, fontSize: 22,
              fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.1,
            )),
      ])),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  METRIC CARD  — NeoPop elevated
// ─────────────────────────────────────────────────────────────────────────────
class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.index,
    required this.title,
    required this.description,
  });

  final int index;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: UniSyncColors.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: UniSyncColors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Index badge
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: UniSyncColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: UniSyncColors.accent.withOpacity(0.25)),
            ),
            child: Center(child: Text('$index', style: const TextStyle(
              color: UniSyncColors.accent, fontSize: 11,
              fontWeight: FontWeight.w800,
            ))),
          ),

          const SizedBox(width: 12),

          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: UniSyncColors.textPrimary, letterSpacing: -0.1,
              )),
              const SizedBox(height: 5),
              Text(description, style: const TextStyle(
                fontSize: 12, color: UniSyncColors.textSecondary, height: 1.45,
              )),
            ],
          )),
        ]),
      ),
    );
  }
}
