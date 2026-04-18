import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
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
import 'package:UniSync/features/interview/view/interview_palette.dart';
import 'package:UniSync/sockets/socket_methods.dart';

InterviewPalette _ui(BuildContext context) => InterviewPalette.of(context);

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
    final themeContext = rootScaffoldMessengerKey.currentContext;
    final errorColor = themeContext != null
        ? _ui(themeContext).error
        : Colors.redAccent;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: errorColor,
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
      final firestore = ref.read(firebaseFirestoreProvider);
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
        backgroundColor: _ui(context).backgroundSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Start Interview?',
          style: TextStyle(
            color: _ui(context).textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'This will deduct $coinPrice UniCoins from your wallet.\n'
          'Questions to be asked: $effectiveQuestionCount\n'
          'Remaining balance: ${remainingCoins < 0 ? 0 : remainingCoins} UniCoins.',
          style: TextStyle(
            color: _ui(context).textSecondary,
            fontSize: 13,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child:  Text(
              'Cancel',
              style: TextStyle(
                color: _ui(context).textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child:  Text(
              'Start',
              style: TextStyle(
                color: _ui(context).accent,
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
      backgroundColor: _ui(context).backgroundPrimary,

       // ── Floating shimmer CTA ─────────────────────────────────────
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _loading
          ? Container(
              height: 56,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              color: _ui(context).accent,
              child: Center(
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _ui(context).buttonPrimaryFg),
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: NeoPopTiltedButton(
                isFloating: true,
                decoration: NeoPopTiltedButtonDecoration(
                  color: hasEnoughCoins
                      ? _ui(context).accent
                      : _ui(context).textDisabled,
                  plunkColor: hasEnoughCoins
                      ? _ui(context).accent
                      : _ui(context).textDisabled,
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
                            color: _ui(context).buttonPrimaryFg),
                        SizedBox(width: 8),
                        Text(hasEnoughCoins
                            ? 'Start Interview'
                            : 'Need ${tmplte.coinPrice} coins',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: hasEnoughCoins
                                  ? _ui(context).buttonPrimaryFg
                                  : _ui(context).backgroundPrimary,
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
            color: _ui(context).backgroundSecondary,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(children: [
              // NeoPopButton(
              //   color: _ui(context).surfaceCard,
              //   bottomShadowColor: _ui(context).border,
              //   rightShadowColor: _ui(context).border,
              //   depth: 3,
              //   onTapUp: () => Routemaster.of(context)
              //       .replace('/carrer-interview-screen'),
              //   onTapDown: () {},
              //   child: const SizedBox(width: 40, height: 40,
              //     child: Center(child: Icon(Icons.arrow_back_ios_new_rounded,
              //         size: 16, color: _ui(context).textPrimary)),
              //   ),
              // ),
              // const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('#INTERVIEW', style: TextStyle(
                    color: _ui(context).accent, fontSize: 9,
                    fontWeight: FontWeight.w700, letterSpacing: 1.8,
                  )),
                  const SizedBox(height: 2),
                  RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(children: [
                      TextSpan(text: 'Detailed ',
                          style: TextStyle(color: _ui(context).textPrimary,
                              fontSize: 18, fontWeight: FontWeight.w800,
                              letterSpacing: -0.4)),
                      TextSpan(text: 'info',
                          style: TextStyle(color: _ui(context).accent,
                              fontSize: 18, fontWeight: FontWeight.w800,
                              letterSpacing: -0.4)),
                    ]),
                  ),
                  const SizedBox(height: 3),
                   Text(
                    'Feel the actual butterflies before the real one',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _ui(context).textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ]),
              ),
              const SizedBox(width: 10),
              NeoPopButton(
                color: _ui(context).surfaceCard,
                bottomShadowColor: _ui(context).accent,
                rightShadowColor: _ui(context).accent,
                depth: 3,
                onTapUp: () {
                  ref.invalidate(ReportsControllerProvider);
                  Routemaster.of(context).push('/reportsScreen');
                },
                onTapDown: () {},
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('Reports', style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: _ui(context).accent)),
                    SizedBox(width: 5),
                    Icon(Icons.launch_rounded,
                        size: 13, color: _ui(context).accent),
                  ]),
                ),
              ),
            ]),
          ),

          Container(height: 0.8, color: _ui(context).divider),

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
                      color: _ui(context).backgroundSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _ui(context).borderSubtle),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 60, height: 60,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _ui(context).surfaceCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _ui(context).border),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: tmplte.icon, fit: BoxFit.contain,
                            placeholder: (_, __) => SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: _ui(context).textMuted)),
                            errorWidget: (_, __, ___) => Icon(
                                Icons.psychology_outlined,
                                color: _ui(context).textMuted, size: 24),
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
                                  style:  TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.w800,
                                    color: _ui(context).textPrimary,
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
                                      color: _ui(context).accentSoft,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: _ui(context).accent
                                            .withOpacity(0.4),
                                      ),
                                    ),
                                    child: Text(
                                      'Cost: ${tmplte.coinPrice} coins',
                                      style:  TextStyle(
                                        color: _ui(context).accent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _ui(context).surfaceCard,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: _ui(context).border,
                                      ),
                                    ),
                                    child: Text(
                                      'You have: $availableCoins coins',
                                      style:  TextStyle(
                                        color: _ui(context).textSecondary,
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
                      color: _ui(context).backgroundSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _ui(context).borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children:  [
                            Icon(
                              Icons.tune_rounded,
                              size: 16,
                              color: _ui(context).accent,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Interview Length',
                              style: TextStyle(
                                color: _ui(context).textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                         Text(
                          'Select how many questions AI should ask. Minimum 4, maximum 20. Leave custom empty to use default 6.',
                                      style: TextStyle(
                            color: _ui(context).textSecondary,
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
                                      ? _ui(context).accent.withOpacity(0.15)
                                      : _ui(context).surfaceCard,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? _ui(context).accent
                                        : _ui(context).border,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '$count',
                                      style: TextStyle(
                                        color: isSelected
                                            ? _ui(context).accent
                                            : _ui(context).textSecondary,
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
                                          color: _ui(context).accentSoft,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'DEFAULT',
                                          style: TextStyle(
                                            color: _ui(context).accent,
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
                            prefixIcon: Icon(
                              Icons.help_outline_rounded,
                              size: 18,
                              color: _ui(context).accent,
                            ),
                            suffixIcon:
                                _questionCountController.text.trim().isEmpty
                                    ? null
                                    : IconButton(
                                        onPressed: () {
                                          _questionCountController.clear();
                                          setState(() {});
                                        },
                                        icon: Icon(
                                          Icons.close_rounded,
                                          size: 18,
                                          color: _ui(context).textMuted,
                                        ),
                                      ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            filled: true,
                            fillColor: _ui(context).surfaceCard,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:  BorderSide(
                                color: _ui(context).border,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:  BorderSide(
                                color: _ui(context).accent,
                                width: 1.5,
                              ),
                            ),
                          ),
                          style: TextStyle(
                            color: _ui(context).textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Interview will run for ${parsedQuestionLimit ?? _defaultQuestionCount} question${(parsedQuestionLimit ?? _defaultQuestionCount) > 1 ? 's' : ''}.',
                          style: TextStyle(
                            color: _ui(context).textMuted,
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
                        color: _ui(context).surfaceCard,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _ui(context).border),
                      ),
                      child: Text(chip, style:  TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: _ui(context).textSecondary,
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
      Text(eyebrow, style: TextStyle(
        color: _ui(context).accent, fontSize: 9,
        fontWeight: FontWeight.w700, letterSpacing: 1.8,
      )),
      const SizedBox(height: 4),
      RichText(text: TextSpan(children: [
        TextSpan(text: '$title ',
            style: TextStyle(
              color: _ui(context).textPrimary, fontSize: 22,
              fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.1,
            )),
        TextSpan(text: highlight,
            style: TextStyle(
              color: _ui(context).accent, fontSize: 22,
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
        color: _ui(context).surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _ui(context).borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Index badge
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: _ui(context).accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: _ui(context).accent.withOpacity(0.25)),
            ),
            child: Center(child: Text('$index', style: TextStyle(
              color: _ui(context).accent, fontSize: 11,
              fontWeight: FontWeight.w800,
            ))),
          ),

          const SizedBox(width: 12),

          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: _ui(context).textPrimary, letterSpacing: -0.1,
              )),
              const SizedBox(height: 5),
              Text(description, style: TextStyle(
                fontSize: 12, color: _ui(context).textSecondary, height: 1.45,
              )),
            ],
          )),
        ]),
      ),
    );
  }
}







