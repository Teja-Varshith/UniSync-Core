import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:routemaster/routemaster.dart';
import 'package:UniSync/features/coins/coin_purchase_service.dart';
import 'package:UniSync/features/examsync/brand/brand.dart';
import 'package:UniSync/features/examsync/controller/examsync_controller.dart';
import 'package:UniSync/features/examsync/theme/es_theme.dart';
import 'package:UniSync/features/examsync/widgets/es_toast.dart';
import 'package:UniSync/features/examsync/widgets/es_widgets.dart';

/// Applies ExamSync's dark NeoPOP theme to a screen, whatever UniSync's own
/// theme mode is.
class ExamSyncScope extends StatelessWidget {
  const ExamSyncScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: examSyncTheme(Theme.of(context)),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: EsColors.bg,
        ),
        child: child,
      ),
    );
  }
}

/// Pops the current ExamSync page, or goes back to UniSync's home if this is
/// the first page in the stack (e.g. opened from a deep link).
void examSyncBack(BuildContext context) {
  final navigator = Navigator.of(context);
  if (navigator.canPop()) {
    navigator.maybePop();
  } else {
    Routemaster.of(context).replace('/');
  }
}

/// Coin balance chip. Tapping opens UniSync's existing coin purchase flow.
class CoinBalanceChip extends ConsumerWidget {
  const CoinBalanceChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(examSyncUidProvider) == null) return const SizedBox.shrink();
    final coins = ref.watch(examSyncCoinsProvider).valueOrNull;
    return PlunkTap(
      color: EsColors.surfaceElevated,
      rightColor: EsColors.borderLight,
      bottomColor: EsColors.border,
      semanticLabel:
          coins == null ? 'Coin balance. Buy coins' : '$coins coins. Buy coins',
      onTap: () => showBuyCoinsSheet(context, ref),
      child: SizedBox(
        height: 41,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const EsCoin(size: 18),
              const SizedBox(width: 7),
              Text(
                coins == null ? '—' : '$coins',
                style: EsText.mono(size: 14),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.add, size: 14, color: EsColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showBuyCoinsSheet(BuildContext context, WidgetRef ref) async {
  final coins = ref.read(examSyncCoinsProvider).valueOrNull;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: EsColors.surface,
    shape: const RoundedRectangleBorder(),
    builder: (sheetContext) {
      var buying = false;
      return StatefulBuilder(
        builder: (context, setSheetState) => ExamSyncScope(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const EsEyebrow('Uni-Coins'),
                  const SizedBox(height: 6),
                  Text('Top up your coins', style: EsText.display(size: 22)),
                  const SizedBox(height: 6),
                  Text(
                    'Current balance: ${coins ?? '—'} coins',
                    style: EsText.body(size: 13, color: EsColors.textMuted),
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
                        const EsCoin(size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${CoinPurchaseService.coinsPerPack} coins pack',
                            style: EsText.body(weight: FontWeight.w800),
                          ),
                        ),
                        EsButton(
                          label: 'Rs 9',
                          size: EsButtonSize.sm,
                          loading: buying,
                          onPressed: () async {
                            setSheetState(() => buying = true);
                            final error = await ref
                                .read(coinPurchaseServiceProvider)
                                .buy100CoinsPack();
                            if (!sheetContext.mounted) return;
                            setSheetState(() => buying = false);
                            if (error != null) {
                              showEsToast(context, error,
                                  type: EsToastType.error);
                              return;
                            }
                            Navigator.of(sheetContext).pop();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
