import 'dart:async';

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:UniSync/ads%20Manager/add_manager.dart';
import 'package:UniSync/app/providers.dart';
import 'package:UniSync/constants/constant.dart';
import 'package:UniSync/firebase_service.dart';

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
  // Replace this with your exact Google Play product ID if it differs.
  static const String productIdAdFreeLifetime = 'ad_free_purchase';
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
    _log(
      'initialize started. products=$productIdCoins100,$productIdAdFreeLifetime',
    );
    try {
      _purchaseSub = _iap.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () => _purchaseSub?.cancel(),
        onError: (err) {
          _log('purchaseStream error: $err');
          _showMessage(
            title: 'Purchase error',
            message: 'Something went wrong. Dont worry your money will be refunded if deducted.',
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
    await FirebaseService.logEvent(
      name: 'coin_purchase_started',
      parameters: {'product_id': productIdCoins100},
    );
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
      await FirebaseService.logEvent(
        name: 'coin_purchase_product_query_failed',
        parameters: {'product_id': productIdCoins100},
      );
      return 'Could not load product details. Please try again later.';
    }

    if (response.productDetails.isEmpty) {
      await FirebaseService.logEvent(
        name: 'coin_purchase_product_missing',
        parameters: {'product_id': productIdCoins100},
      );
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
      await FirebaseService.logEvent(
        name: 'coin_purchase_launch_failed',
        parameters: {'product_id': product.id},
      );
      return 'Unable to start purchase flow. Please retry.';
    }

    return null;
  }

  Future<String?> buyAdFreeAccess() async {
    _log('buyAdFreeAccess triggered.');
    await FirebaseService.logEvent(
      name: 'ad_free_purchase_started',
      parameters: {'product_id': productIdAdFreeLifetime},
    );
    await initialize();

    if (!_billingReady) {
      _log('ad-free buy blocked: billingReady=false, initError=$_initErrorMessage');
      return _initErrorMessage ??
          'Billing is currently unavailable. Please restart the app and retry.';
    }

    final currentUser = _ref.read(userProvider);
    if (currentUser?.hasAdFreeAccess == true || AdManager.instance.isAdFree) {
      _log('ad-free buy skipped: user already has access.');
      await FirebaseService.logEvent(
        name: 'ad_free_purchase_already_owned',
        parameters: {'product_id': productIdAdFreeLifetime},
      );
      return 'You already have ad-free access on this account.';
    }

    bool isAvailable;
    try {
      isAvailable = await _iap.isAvailable();
      _log('ad-free runtime billing availability: $isAvailable');
    } on PlatformException catch (e) {
      _log('ad-free isAvailable PlatformException code=${e.code} message=${e.message}');
      return 'Billing connection failed. Restart the app and try again.';
    } on MissingPluginException {
      _log('ad-free isAvailable MissingPluginException');
      return 'Billing plugin is missing in this run. Please relaunch the app.';
    }

    if (!isAvailable) {
      _log('ad-free buy blocked: billing unavailable on device.');
      return 'Google Play Billing is unavailable on this device right now.';
    }

    final response = await _iap.queryProductDetails({productIdAdFreeLifetime});
    _log('ad-free queryProductDetails completed. '
        'found=${response.productDetails.length} '
        'notFound=${response.notFoundIDs.join(',')} '
        'error=${response.error?.code}:${response.error?.message}');

    if (response.error != null) {
      await FirebaseService.logEvent(
        name: 'ad_free_product_query_failed',
        parameters: {'product_id': productIdAdFreeLifetime},
      );
      return 'Could not load ad-free product details. Please try again later.';
    }

    if (response.productDetails.isEmpty) {
      await FirebaseService.logEvent(
        name: 'ad_free_product_missing',
        parameters: {'product_id': productIdAdFreeLifetime},
      );
      return 'Ad-free product is not ready yet. Check Play Console product ID.';
    }

    final product = response.productDetails.first;
    _log('ad-free product selected: id=${product.id}, title=${product.title}, price=${product.price}');
    final purchaseParam = PurchaseParam(productDetails: product);
    final started = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    _log('buyNonConsumable started=$started for product=${product.id}');

    if (!started) {
      await FirebaseService.logEvent(
        name: 'ad_free_purchase_launch_failed',
        parameters: {'product_id': product.id},
      );
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
            await FirebaseService.logEvent(
              name: 'purchase_pending',
              parameters: {'product_id': purchase.productID},
            );
            _showMessage(
              title: 'Purchase pending',
              message: 'Waiting for Play Store confirmation...',
              type: ContentType.warning,
            );
            break;
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            if (purchase.productID == productIdCoins100) {
              await _grantCoinsIfNeeded(purchase);
            } else if (purchase.productID == productIdAdFreeLifetime) {
              await _grantAdFreeIfNeeded(purchase);
            } else {
              _log('purchase ignored: unsupported productId=${purchase.productID}');
            }
            break;
          case PurchaseStatus.error:
            await FirebaseService.logEvent(
              name: 'purchase_failed',
              parameters: {
                'product_id': purchase.productID,
                'status': purchase.status.name,
              },
            );
            _showMessage(
              title: 'Purchase failed',
              message: purchase.error?.message ??
                  'Payment failed. Your coins were not added.',
              type: ContentType.failure,
            );
            break;
          case PurchaseStatus.canceled:
            await FirebaseService.logEvent(
              name: 'purchase_canceled',
              parameters: {'product_id': purchase.productID},
            );
            _showMessage(
              title: 'Purchase cancelled',
              message: 'No worries. You can come back anytime and purchase again.',
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
    await FirebaseService.logEvent(
      name: 'coin_purchase_completed',
      parameters: {
        'product_id': purchase.productID,
        'coins': coinsPerPack,
      },
    );

    _showMessage(
      title: 'Coins added',
      message: '$coinsPerPack coins are now in your wallet.',
      type: ContentType.success,
    );
  }

  Future<void> _grantAdFreeIfNeeded(PurchaseDetails purchase) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      _log('ad-free grant skipped: no signed-in Firebase user.');
      _showMessage(
        title: 'Sign in required',
        message: 'Please sign in before buying ad-free access.',
        type: ContentType.failure,
      );
      return;
    }

    if (purchase.productID != productIdAdFreeLifetime) {
      _log('ad-free grant skipped: unexpected productId=${purchase.productID}.');
      return;
    }

    final purchaseId = purchase.purchaseID ??
        '${purchase.productID}_${purchase.transactionDate ?? DateTime.now().millisecondsSinceEpoch}';

    if (_processedPurchaseIds.contains(purchaseId)) {
      _log('ad-free grant skipped: purchase already processed in-memory purchaseId=$purchaseId');
      _syncLocalAdFreeAccess(firebaseUser.uid);
      return;
    }

    _log('ad-free grant transaction start: uid=${firebaseUser.uid}, purchaseId=$purchaseId');

    final userRef = _firestore.collection('users').doc(firebaseUser.uid);
    final purchaseRef = userRef.collection('premiumPurchases').doc(purchaseId);

    final granted = await _firestore.runTransaction<bool>((tx) async {
      final purchaseSnap = await tx.get(purchaseRef);
      if (purchaseSnap.exists) {
        _log('ad-free grant transaction: duplicate found in Firestore purchaseId=$purchaseId');
        tx.set(
          userRef,
          {
            'hasAdFreeAccess': true,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        return false;
      }

      tx.set(
        purchaseRef,
        {
          'purchaseId': purchaseId,
          'productId': purchase.productID,
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
          'hasAdFreeAccess': true,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      return true;
    });

    _processedPurchaseIds.add(purchaseId);
    _syncLocalAdFreeAccess(firebaseUser.uid);

    if (!granted) {
      _log('ad-free grant result: not granted (already processed previously).');
      return;
    }

    _log('ad-free grant success: access enabled in Firestore for purchaseId=$purchaseId');
    await FirebaseService.logEvent(
      name: 'ad_free_purchase_completed',
      parameters: {'product_id': purchase.productID},
    );

    _showMessage(
      title: 'Ad-free unlocked',
      message: 'Ads are now turned off for this account.',
      type: ContentType.success,
    );
  }

  void _syncLocalAdFreeAccess(String uid) {
    final currentUser = _ref.read(userProvider);
    if (currentUser != null && currentUser.id == uid && !currentUser.hasAdFreeAccess) {
      _ref.read(userProvider.notifier).state =
          currentUser.copyWith(hasAdFreeAccess: true);
      _log('local userProvider ad-free access updated.');
    }
    AdManager.instance.setAdFree(true);
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
