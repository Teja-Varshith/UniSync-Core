import 'dart:async';

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:unisync/app/providers.dart';
import 'package:unisync/constants/constant.dart';

final coinPurchaseServiceProvider = Provider<CoinPurchaseService>((ref) {
  final service = CoinPurchaseService(
    firestore: ref.read(firebaseFirestoreProvider),
    auth: ref.read(FirebaseAuthProvider),
    ref: ref,
  );
  ref.onDispose(service.dispose);
  return service;
});

class CoinPurchaseService {
  CoinPurchaseService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required Ref ref,
  })  : _firestore = firestore,
        _auth = auth,
        _ref = ref;

  static const String productIdCoins100 = 'coins_100_inr9';
  static const int coinsPerPack = 100;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final Ref _ref;
  final InAppPurchase _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  final Set<String> _processedPurchaseIds = <String>{};
  bool _initialized = false;
  bool _billingReady = false;
  String? _initErrorMessage;

  void _log(String message) {
    if (!kDebugMode) return;
    debugPrint('[CoinPurchaseService] $message');
  }

  Future<void> initialize() async {
    if (_initialized) {
      _log('initialize skipped (already initialized).');
      return;
    }
    _log('initialize started. productId=$productIdCoins100');
    try {
      _purchaseSub = _iap.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () => _purchaseSub?.cancel(),
        onError: (err) {
          _log('purchaseStream error: $err');
          _showMessage(
            title: 'Purchase error',
            message: 'Something went wrong while listening to purchases.',
            type: ContentType.failure,
          );
        },
      );

      final available = await _iap.isAvailable();
      _log('initialize billing availability: $available');

      _initialized = true;
      _billingReady = true;
      _initErrorMessage = null;
      _log('initialize success.');
    } on PlatformException catch (e) {
      _billingReady = false;
      _initErrorMessage =
          'Billing is not ready yet. Please fully restart the app and try again.';
      _log('initialize PlatformException code=${e.code} message=${e.message}');
    } on MissingPluginException {
      _billingReady = false;
      _initErrorMessage =
          'Billing plugin not loaded. Stop and run the app again from scratch.';
      _log('initialize MissingPluginException (plugin/channel not registered).');
    } catch (e) {
      _billingReady = false;
      _initErrorMessage =
          'Could not initialize billing right now. Please try again later.';
      _log('initialize unexpected error: $e');
    }
  }

  Future<String?> buy100CoinsPack() async {
    _log('buy100CoinsPack triggered.');
    await initialize();

    if (!_billingReady) {
      _log('buy blocked: billingReady=false, initError=$_initErrorMessage');
      return _initErrorMessage ??
          'Billing is currently unavailable. Please restart the app and retry.';
    }

    bool isAvailable;
    try {
      isAvailable = await _iap.isAvailable();
      _log('runtime billing availability: $isAvailable');
    } on PlatformException catch (e) {
      _log('isAvailable PlatformException code=${e.code} message=${e.message}');
      return 'Billing connection failed. Restart the app and try again.';
    } on MissingPluginException {
      _log('isAvailable MissingPluginException');
      return 'Billing plugin is missing in this run. Please relaunch the app.';
    }

    if (!isAvailable) {
      _log('buy blocked: billing unavailable on device.');
      return 'Google Play Billing is unavailable on this device right now.';
    }

    final response = await _iap.queryProductDetails({productIdCoins100});
    _log('queryProductDetails completed. '
        'found=${response.productDetails.length} '
        'notFound=${response.notFoundIDs.join(',')} '
        'error=${response.error?.code}:${response.error?.message}');

    if (response.error != null) {
      return 'Could not load product details. Please try again later.';
    }

    if (response.productDetails.isEmpty) {
      return 'Coin pack is not ready yet. Check Play Console product ID.';
    }

    final product = response.productDetails.first;
    _log('product selected: id=${product.id}, title=${product.title}, price=${product.price}');
    final purchaseParam = PurchaseParam(productDetails: product);
    final started = await _iap.buyConsumable(
      purchaseParam: purchaseParam,
      autoConsume: true,
    );
    _log('buyConsumable started=$started for product=${product.id}');

    if (!started) {
      return 'Unable to start purchase flow. Please retry.';
    }

    return null;
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    _log('purchase update batch received: count=${purchases.length}');
    for (final purchase in purchases) {
      _log('purchase status=${purchase.status.name} '
          'product=${purchase.productID} '
          'purchaseId=${purchase.purchaseID} '
          'pendingComplete=${purchase.pendingCompletePurchase} '
          'error=${purchase.error?.code}:${purchase.error?.message}');
      try {
        switch (purchase.status) {
          case PurchaseStatus.pending:
            _showMessage(
              title: 'Purchase pending',
              message: 'Waiting for Play Store confirmation...',
              type: ContentType.warning,
            );
            break;
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            await _grantCoinsIfNeeded(purchase);
            break;
          case PurchaseStatus.error:
            _showMessage(
              title: 'Purchase failed',
              message: purchase.error?.message ??
                  'Payment failed. Your coins were not added.',
              type: ContentType.failure,
            );
            break;
          case PurchaseStatus.canceled:
            _showMessage(
              title: 'Purchase cancelled',
              message: 'No worries. You can buy coins anytime.',
              type: ContentType.warning,
            );
            break;
        }
      } finally {
        if (purchase.pendingCompletePurchase) {
          _log('completePurchase called for purchaseId=${purchase.purchaseID}');
          await _iap.completePurchase(purchase);
        }
      }
    }
  }

  Future<void> _grantCoinsIfNeeded(PurchaseDetails purchase) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      _log('grant skipped: no signed-in Firebase user.');
      _showMessage(
        title: 'Sign in required',
        message: 'Please sign in before purchasing coins.',
        type: ContentType.failure,
      );
      return;
    }

    if (purchase.productID != productIdCoins100) {
      _log('grant skipped: unexpected productId=${purchase.productID}.');
      return;
    }

    final purchaseId = purchase.purchaseID ??
        '${purchase.productID}_${purchase.transactionDate ?? DateTime.now().millisecondsSinceEpoch}';

    if (_processedPurchaseIds.contains(purchaseId)) {
      _log('grant skipped: purchase already processed in-memory purchaseId=$purchaseId');
      return;
    }

    _log('grant transaction start: uid=${firebaseUser.uid}, purchaseId=$purchaseId, coins=$coinsPerPack');

    final userRef = _firestore.collection('users').doc(firebaseUser.uid);
    final purchaseRef = userRef.collection('coinPurchases').doc(purchaseId);

    final granted = await _firestore.runTransaction<bool>((tx) async {
      final purchaseSnap = await tx.get(purchaseRef);
      if (purchaseSnap.exists) {
        _log('grant transaction: duplicate found in Firestore purchaseId=$purchaseId');
        return false;
      }

      tx.set(
        purchaseRef,
        {
          'purchaseId': purchaseId,
          'productId': purchase.productID,
          'coins': coinsPerPack,
          'source': 'play_billing_frontend_only',
          'status': purchase.status.name,
          'transactionDate': purchase.transactionDate,
          'verificationSource': purchase.verificationData.source,
          'verificationPayload': purchase.verificationData.serverVerificationData,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      tx.set(
        userRef,
        {
          'coins': FieldValue.increment(coinsPerPack),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      return true;
    });

    _processedPurchaseIds.add(purchaseId);

    if (!granted) {
      _log('grant result: not granted (already processed previously).');
      return;
    }

    final currentUser = _ref.read(userProvider);
    if (currentUser != null && currentUser.id == firebaseUser.uid) {
      _ref.read(userProvider.notifier).state =
          currentUser.copyWith(coins: currentUser.coins + coinsPerPack);
      _log('local userProvider coin balance updated: +$coinsPerPack');
    }

    _log('grant success: coins credited in Firestore for purchaseId=$purchaseId');

    _showMessage(
      title: 'Coins added',
      message: '$coinsPerPack coins are now in your wallet.',
      type: ContentType.success,
    );
  }

  void _showMessage({
    required String title,
    required String message,
    required ContentType type,
  }) {
    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: title,
            message: message,
            contentType: type,
          ),
        ),
      );
  }

  void dispose() {
    _log('dispose called. purchase stream cancelled.');
    _purchaseSub?.cancel();
  }
}
