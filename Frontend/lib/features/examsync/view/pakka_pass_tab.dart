import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:routemaster/routemaster.dart';
import 'package:UniSync/features/examsync/brand/brand.dart';
import 'package:UniSync/features/examsync/controller/examsync_controller.dart';
import 'package:UniSync/features/examsync/models/subject.dart';
import 'package:UniSync/features/examsync/repository/examsync_repository.dart';
import 'package:UniSync/features/examsync/theme/es_theme.dart';
import 'package:UniSync/features/examsync/view/widgets/es_scope.dart';
import 'package:UniSync/features/examsync/widgets/es_toast.dart';
import 'package:UniSync/features/examsync/widgets/es_widgets.dart';

void openPakkaPassQuestions(BuildContext context, String courseCode) {
  Routemaster.of(context)
      .push('/examsync/subject/${Uri.encodeComponent(courseCode)}/pakka-pass');
}

/// The Pakka Pass paywall inside the subject screen.
class PakkaPassTab extends ConsumerStatefulWidget {
  const PakkaPassTab({super.key, required this.subject});

  final Subject subject;

  @override
  ConsumerState<PakkaPassTab> createState() => _PakkaPassTabState();
}

class _PakkaPassTabState extends ConsumerState<PakkaPassTab> {
  bool _unlocking = false;

  Subject get subject => widget.subject;

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(examSyncUidProvider);
    final access = ref.watch(examSyncHasAccessProvider(subject.courseCode));
    final coins = ref.watch(examSyncCoinsProvider);

    final checking = access.isLoading || (uid != null && coins.isLoading);
    if (checking) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (access.hasError) {
      return EsErrorState(
        title: 'Couldn’t check your access',
        onRetry: () =>
            ref.invalidate(examSyncHasAccessProvider(subject.courseCode)),
      );
    }
    if (access.valueOrNull == true) return _unlocked();
    return _locked(uid: uid, coins: coins.valueOrNull);
  }

  Widget _unlocked() {
    return _Panel(
      children: [
        const EsIllustration(IllustrationKind.unlocked, size: 96),
        const SizedBox(height: 16),
        const EsChip('Unlocked',
            variant: EsChipVariant.success, icon: Icons.check_rounded),
        const SizedBox(height: 12),
        Text(
          'Pakka Pass is yours',
          textAlign: TextAlign.center,
          style: EsText.display(size: 24),
        ),
        const SizedBox(height: 6),
        Text(
          'Every important question for ${subject.subjectName}, with answers.',
          textAlign: TextAlign.center,
          style: EsText.body(size: 13.5, color: EsColors.textMuted),
        ),
        const SizedBox(height: 20),
        EsButton(
          label: 'View Pakka Pass questions',
          variant: EsButtonVariant.premium,
          size: EsButtonSize.lg,
          icon: Icons.bolt_rounded,
          expand: true,
          onPressed: () => openPakkaPassQuestions(context, subject.courseCode),
        ),
      ],
    );
  }

  Widget _locked({required String? uid, required int? coins}) {
    final price = subject.price;
    final free = subject.isFree;
    final enough = coins != null && coins >= price;
    final canUnlock = uid != null && (free || enough);

    String? hint;
    if (uid == null) {
      hint = 'Sign in to UniSync to use your coins.';
    } else if (!free && coins != null && !enough) {
      hint = null; // Rendered as rich text below.
    }

    return _Panel(
      children: [
        const EsIllustration(IllustrationKind.lock, size: 96),
        const SizedBox(height: 16),
        const EsChip('Premium',
            variant: EsChipVariant.premium, icon: Icons.bolt_rounded),
        const SizedBox(height: 12),
        Text(
          'Pakka Pass',
          textAlign: TextAlign.center,
          style: EsText.display(size: 26),
        ),
        const SizedBox(height: 6),
        Text(
          'The questions that keep coming back in Mid 1, Mid 2 and Sem, with ready answers.',
          textAlign: TextAlign.center,
          style:
              EsText.body(size: 13.5, color: EsColors.textMuted, height: 1.4),
        ),
        const SizedBox(height: 20),
        _PriceBox(price: price, free: free, coins: uid == null ? null : coins),
        const SizedBox(height: 14),
        const _Disclaimer(),
        const SizedBox(height: 20),
        EsButton(
          label: free ? 'Unlock for free' : 'Unlock for $price coins',
          variant: EsButtonVariant.premium,
          size: EsButtonSize.lg,
          icon: Icons.lock_open_rounded,
          expand: true,
          loading: _unlocking,
          onPressed: canUnlock && !_unlocking ? () => _onUnlock(coins) : null,
        ),
        if (hint != null) ...[
          const SizedBox(height: 12),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: EsText.body(size: 12.5, color: EsColors.textMuted),
          ),
        ],
        if (uid != null && !free && coins != null && !enough) ...[
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(children: [
              const TextSpan(text: 'You need '),
              TextSpan(
                text: '${price - coins} more coins',
                style: EsText.body(
                    size: 12.5, weight: FontWeight.w800, color: EsColors.text),
              ),
              const TextSpan(text: ' to unlock this.'),
            ]),
            textAlign: TextAlign.center,
            style: EsText.body(size: 12.5, color: EsColors.textMuted),
          ),
          const SizedBox(height: 12),
          EsButton(
            label: 'Get more coins',
            variant: EsButtonVariant.secondary,
            size: EsButtonSize.sm,
            onPressed: () => showBuyCoinsSheet(context, ref),
          ),
        ],
      ],
    );
  }

  Future<void> _onUnlock(int? coins) async {
    if (_unlocking) return;
    if (!subject.isFree) {
      final confirmed = await _confirm(coins ?? 0);
      if (confirmed != true || !mounted) return;
    }
    setState(() => _unlocking = true);
    try {
      await unlockPakkaPass(ref, subject);
      if (!mounted) return;
      showEsToast(context, 'Unlocked!');
      openPakkaPassQuestions(context, subject.courseCode);
    } on UnlockException catch (e) {
      if (mounted) showEsToast(context, e.message, type: EsToastType.error);
    } finally {
      if (mounted) setState(() => _unlocking = false);
    }
  }

  Future<bool?> _confirm(int coins) {
    final price = subject.price;
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: EsColors.surface,
      shape: const RoundedRectangleBorder(),
      builder: (sheetContext) => ExamSyncScope(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const EsEyebrow('Confirm unlock'),
                const SizedBox(height: 8),
                Text('Unlock for $price coins?',
                    style: EsText.display(size: 24)),
                const SizedBox(height: 8),
                Text(
                  'Pakka Pass for ${subject.subjectName}.',
                  style: EsText.body(size: 13.5, color: EsColors.textMuted),
                ),
                const SizedBox(height: 16),
                PlunkBox(
                  color: EsColors.bgSecondary,
                  rightColor: EsColors.borderLight,
                  bottomColor: EsColors.border,
                  border: EsColors.border,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('Balance after unlock',
                            style: EsText.body(
                                size: 13, color: EsColors.textSecondary)),
                      ),
                      const EsCoin(size: 16),
                      const SizedBox(width: 6),
                      Text('${coins - price}', style: EsText.mono(size: 15)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const _Disclaimer(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: EsButton(
                        label: 'Cancel',
                        variant: EsButtonVariant.secondary,
                        expand: true,
                        onPressed: () => Navigator.of(sheetContext).pop(false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: EsButton(
                        label: 'Unlock',
                        variant: EsButtonVariant.premium,
                        expand: true,
                        onPressed: () => Navigator.of(sheetContext).pop(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Plain-language liability disclaimer shown wherever a student is about to
/// pay for or view Pakka Pass content: this is student-compiled exam prep,
/// not an official or guaranteed paper.
class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, size: 14, color: EsColors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Pakka Pass is exam-prep material compiled by students and '
            'volunteers for guidance only. It is not an official question '
            'paper and UniSync does not guarantee it will match your exam '
            'or improve your result.',
            style: EsText.body(
              size: 11.5,
              color: EsColors.textMuted,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return PlunkBox(
      color: EsColors.surface,
      rightColor: EsColors.premiumRight,
      bottomColor: EsColors.premiumBottom,
      border: EsColors.border,
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 22),
      child: Column(children: children),
    );
  }
}

class _PriceBox extends StatelessWidget {
  const _PriceBox({required this.price, required this.free, this.coins});

  final int price;
  final bool free;
  final int? coins;

  @override
  Widget build(BuildContext context) {
    final balanceColor = coins == null
        ? EsColors.textMuted
        : (free || coins! >= price)
            ? EsColors.success
            : EsColors.error;
    Widget cell(String label, Widget value) => Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EsEyebrow(label),
                const SizedBox(height: 6),
                value,
              ],
            ),
          ),
        );
    return Container(
      decoration: BoxDecoration(
        color: EsColors.bgSecondary,
        border: Border.all(color: EsColors.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            cell(
              'Price',
              free
                  ? Text('Free',
                      style: EsText.body(size: 18, weight: FontWeight.w800))
                  : Row(children: [
                      const EsCoin(size: 16),
                      const SizedBox(width: 6),
                      Text('$price', style: EsText.mono(size: 18)),
                    ]),
            ),
            const VerticalDivider(width: 1, color: EsColors.border),
            cell(
              'Your balance',
              Row(children: [
                const EsCoin(size: 16),
                const SizedBox(width: 6),
                Text(coins == null ? '—' : '$coins',
                    style: EsText.mono(size: 18, color: balanceColor)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
