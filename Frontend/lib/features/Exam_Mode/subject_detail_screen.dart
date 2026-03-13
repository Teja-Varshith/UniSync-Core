import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:unisync/features/Exam_Mode/controller/exam_controller.dart';
import 'package:unisync/features/Exam_Mode/models/exam_author_model.dart';
import 'package:unisync/features/Exam_Mode/models/exam_purchase_model.dart';
import 'package:unisync/features/Exam_Mode/models/exam_subject_model.dart';
import 'package:unisync/features/Exam_Mode/repository/exam_repository.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';

class SubjectDetailScreen extends ConsumerStatefulWidget {
  final String subjectId;

  const SubjectDetailScreen({
    super.key,
    required this.subjectId,
  });

  @override
  ConsumerState<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends ConsumerState<SubjectDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final subjectAsync = ref.watch(examSubjectProvider(widget.subjectId));

    return subjectAsync.when(
      data: (subject) {
        if (subject == null) {
          return const Scaffold(
            body: Center(child: Text('Subject not found')),
          );
        }

        final authorsAsync = ref.watch(subjectAuthorsProvider(subject.code));

        return DefaultTabController(
          length: 5,
          child: Scaffold(
            backgroundColor: const Color(0xFFF7F4EE),
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 280,
                    pinned: true,
                    stretch: true,
                    backgroundColor: const Color(0xFF18181B),
                    foregroundColor: Colors.white,
                    title: Text('Dive Deep here....'),
                    flexibleSpace: FlexibleSpaceBar(
                      background: _SubjectHero(subject: subject),
                    ),
                    bottom: const TabBar(
                      labelColor: Colors.white,
                      indicatorColor: Colors.white,
                      unselectedLabelColor: Color.fromARGB(128, 255, 255, 255),
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      tabs: [
                        Tab(text: 'Syllabus',),
                        Tab(text: 'PYQs'),
                        Tab(text: 'Cheatsheet'),
                        Tab(text: 'Videos'),
                        Tab(text: 'Important Questions'),
                      ],
                    ),
                  ),
                ];
              },
              body: TabBarView(
                children: [
                  _SyllabusTab(items: subject.syllabusUnits),
                  _PyqsTab(pyqs: subject.pyqs),
                  _CheatsheetTab(cheatsheetUrl: subject.cheatsheetUrl),
                  _VideosTab(videoLinks: subject.videoLinks),
                  authorsAsync.when(
                    data: (authors) => _AuthorsTab(
                      authors: authors,
                      subjectCode: subject.code,
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(child: Text(error.toString())),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(child: Text(error.toString())),
      ),
    );
  }
}

class _SubjectHero extends StatelessWidget {
  final ExamSubjectModel subject;

  const _SubjectHero({required this.subject});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(16, topInset + 76, 16, kTextTabBarHeight + 20),
      color: const Color(0xFF1F2937),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            subject.code,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subject.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroChip(label: 'Sem ${subject.semester}'),
              _HeroChip(label: 'Units ${subject.syllabusUnits.length}'),
              _HeroChip(label: 'PYQs ${subject.pyqs.length}'),
              _HeroChip(label: 'Videos ${subject.videoLinks.length}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final String label;

  const _HeroChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SyllabusTab extends StatelessWidget {
  final List<String> items;

  const _SyllabusTab({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyTabState(message: 'No syllabus added yet.');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (_, index) {
        if (index == 0) {
          return const _AccessBanner(
            title: 'Free Access',
            subtitle: 'Syllabus roadmap is free for every student.',
          );
        }

        final item = items[index - 1];
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE7E5E4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF18181B),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$index',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: items.length + 1,
    );
  }
}

class _PyqsTab extends StatelessWidget {
  final Map<String, String> pyqs;

  const _PyqsTab({required this.pyqs});

  @override
  Widget build(BuildContext context) {
    final entries = pyqs.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    if (entries.isEmpty) {
      return const _EmptyTabState(message: 'No PYQs added yet.');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (_, index) {
        if (index == 0) {
          return const _AccessBanner(
            title: 'Free Access',
            subtitle: 'All PYQ PDFs are free to access right now.',
          );
        }

        final entry = entries[index - 1];
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE7E5E4)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.tonal(
                onPressed: () => _openPdfInApp(context, entry.value, title: entry.key),
                child: const Text('Open PDF'),
              ),
            ],
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: entries.length + 1,
    );
  }
}

class _CheatsheetTab extends StatelessWidget {
  final String? cheatsheetUrl;

  const _CheatsheetTab({required this.cheatsheetUrl});

  @override
  Widget build(BuildContext context) {
    if (cheatsheetUrl == null || cheatsheetUrl!.isEmpty) {
      return const _EmptyTabState(message: 'No cheatsheet URL added yet.');
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _AccessBanner(
          title: 'Free Access',
          subtitle: 'Cheatsheet PDFs are free for quick revision.',
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE7E5E4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cheatsheet PDF',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                cheatsheetUrl!,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => _openPdfInApp(
                  context,
                  cheatsheetUrl!,
                  title: 'Cheatsheet',
                ),
                child: const Text('Open Cheatsheet'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VideosTab extends StatelessWidget {
  final Map<String, String> videoLinks;

  const _VideosTab({required this.videoLinks});

  @override
  Widget build(BuildContext context) {
    final entries = videoLinks.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    if (entries.isEmpty) {
      return const _EmptyTabState(message: 'No YouTube quick content links added yet.');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        if (index == 0) {
          return const _AccessBanner(
            title: 'Free Access',
            subtitle: 'Quick YouTube topic links are open for everyone.',
          );
        }

        final entry = entries[index - 1];
        final videoId = _extractYoutubeId(entry.value);
        final thumbnail = videoId == null ? null : 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE7E5E4)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 120,
                  height: 80,
                  color: const Color(0xFF18181B),
                  child: thumbnail == null
                      ? const Icon(Icons.play_circle_fill, color: Colors.white, size: 38)
                      : Image.network(
                          thumbnail,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.play_circle_fill,
                            color: Colors.white,
                            size: 38,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.tonal(
                      onPressed: () => _openVideoInApp(
                        context,
                        entry.value,
                        title: entry.key,
                      ),
                      child: const Text('Watch Video'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: entries.length + 1,
    );
  }
}

class _AuthorsTab extends ConsumerStatefulWidget {
  final List<ExamAuthorModel> authors;
  final String subjectCode;

  const _AuthorsTab({
    required this.authors,
    required this.subjectCode,
  });

  @override
  ConsumerState<_AuthorsTab> createState() => _AuthorsTabState();
}

class _AuthorsTabState extends ConsumerState<_AuthorsTab> {
  final Set<String> _unlockedAuthorIds = <String>{};
  final Set<String> _processingAuthorIds = <String>{};
  final Map<String, double> _myRatings = <String, double>{};
  late Razorpay _razorpay;
  String? _pendingAuthorId;
  String _pendingPriceLabel = 'Rs 0';
  Timer? _checkoutWatchdog;

  static const String _razorpayTestKey = 'rzp_test_SQTj3wsuPJyWgp';

  @override
  void initState() {
    super.initState();
    _initRazorpay();
    _loadPurchasedAuthors();
  }

  @override
  void dispose() {
    _checkoutWatchdog?.cancel();
    _razorpay.clear();
    super.dispose();
  }

  void _initRazorpay() {
    debugPrint('[Razorpay] Initializing Razorpay listeners');
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _clearPendingState({String? authorId}) {
    _checkoutWatchdog?.cancel();
    _checkoutWatchdog = null;
    final id = authorId ?? _pendingAuthorId;
    debugPrint('[Razorpay] Clearing pending state for authorId=$id');
    if (!mounted) {
      _pendingAuthorId = null;
      return;
    }
    setState(() {
      if (id != null) {
        _processingAuthorIds.remove(id);
      }
      _pendingAuthorId = null;
    });
  }

  Future<void> _loadPurchasedAuthors() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    debugPrint('[Razorpay] Loading purchased authors for uid=$uid subject=${widget.subjectCode}');
    if (uid == null) return;

    final purchased = await ref.read(examRepositoryProvider).getPurchasedAuthorIds(
          uid: uid,
          subjectCode: widget.subjectCode,
        );

    if (!mounted) return;
    setState(() {
      _unlockedAuthorIds.addAll(purchased);
    });
    debugPrint('[Razorpay] Loaded purchased author ids: ${purchased.join(',')}');
  }

  int _parseAmountToPaise(String displayPrice) {
    final numeric = displayPrice.replaceAll(RegExp(r'[^0-9.]'), '').trim();
    final rupees = double.tryParse(numeric);
    if (rupees == null || rupees <= 0) {
      debugPrint('[Razorpay] Could not parse price "$displayPrice". Fallback to Rs 1 test amount');
      return 100;
    }
    return (rupees * 100).round();
  }

  Future<void> _persistRazorpayPurchase({
    required String authorId,
    required String purchaseId,
    required String priceLabel,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    debugPrint('[Razorpay] Persisting purchase uid=$uid authorId=$authorId purchaseId=$purchaseId');
    if (uid == null) return;

    final record = ExamPurchaseModel(
      uid: uid,
      authorId: authorId,
      subjectCode: widget.subjectCode,
      productId: 'razorpay_test',
      purchaseId: purchaseId,
      status: 'purchased',
      priceLabel: priceLabel,
      createdAt: DateTime.now(),
    );
    await ref.read(examRepositoryProvider).saveExamPurchase(record);
    debugPrint('[Razorpay] Purchase persisted successfully');
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final authorId = _pendingAuthorId;
    debugPrint(
      '[Razorpay] PAYMENT_SUCCESS paymentId=${response.paymentId} orderId=${response.orderId} signature=${response.signature} pendingAuthorId=$authorId',
    );
    if (authorId == null) return;

    try {
      await _persistRazorpayPurchase(
        authorId: authorId,
        purchaseId: response.paymentId ?? '',
        priceLabel: _pendingPriceLabel,
      );
      if (!mounted) return;
      setState(() {
        _unlockedAuthorIds.add(authorId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment successful. Content unlocked.')),
      );
    } catch (error) {
      debugPrint('[Razorpay] Error while persisting successful payment: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment captured but unlock save failed: $error')),
        );
      }
    } finally {
      _clearPendingState(authorId: authorId);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint(
      '[Razorpay] PAYMENT_ERROR code=${response.code} message=${response.message}',
    );
    final authorId = _pendingAuthorId;
    _clearPendingState(authorId: authorId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed (${response.code}): ${response.message ?? 'Unknown error'}')),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('[Razorpay] EXTERNAL_WALLET wallet=${response.walletName}');
    _clearPendingState();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External wallet selected: ${response.walletName ?? 'Wallet'}')),
    );
  }

  Future<bool> _isRazorpayPluginAvailable() async {
    const channel = MethodChannel('razorpay_flutter');
    try {
      await channel.invokeMethod('resync');
      debugPrint('[Razorpay] Plugin channel is available');
      return true;
    } on MissingPluginException catch (error) {
      debugPrint('[Razorpay] Plugin channel unavailable: $error');
      return false;
    } catch (error) {
      // Any non-missing-plugin exception still means channel is wired.
      debugPrint('[Razorpay] Plugin channel probe returned non-fatal error: $error');
      return true;
    }
  }

  Future<void> _showRatingSheet(ExamAuthorModel author) async {
    if (!_unlockedAuthorIds.contains(author.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase required before rating this author.')),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login required to submit rating.')),
      );
      return;
    }

    var currentRating = _myRatings[author.id];
    currentRating ??= await ref.read(examRepositoryProvider).getUserAuthorRating(
          uid: uid,
          authorId: author.id,
          subjectCode: widget.subjectCode,
        );

    var selectedRating = currentRating ?? 5.0;
    var isSaving = false;

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
              decoration: const BoxDecoration(
                color: Color(0xFFFFFCF7),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD6D3D1),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Rate ${author.name}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your feedback updates the public average for this subject.',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    children: List<Widget>.generate(5, (index) {
                      final star = index + 1;
                      final isSelected = selectedRating >= star;
                      return IconButton.filledTonal(
                        onPressed: isSaving
                            ? null
                            : () {
                                setSheetState(() {
                                  selectedRating = star.toDouble();
                                });
                              },
                        icon: Icon(
                          Icons.star_rounded,
                          color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFFA8A29E),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              setSheetState(() => isSaving = true);
                              try {
                                await ref.read(examRepositoryProvider).submitAuthorRating(
                                      uid: uid,
                                      authorId: author.id,
                                      subjectCode: widget.subjectCode,
                                      rating: selectedRating,
                                    );
                                if (!mounted) return;
                                setState(() {
                                  _myRatings[author.id] = selectedRating;
                                });
                                if (ctx.mounted) Navigator.of(ctx).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Rating submitted. Thank you!')),
                                );
                              } catch (error) {
                                if (ctx.mounted) setSheetState(() => isSaving = false);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to submit rating: $error')),
                                );
                              }
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1C1917),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Submit Rating'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _startPurchase(ExamAuthorModel author) async {
    if (_processingAuthorIds.contains(author.id)) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login required to purchase content.')),
      );
      return;
    }

    final displayPrice = author.displayPriceFor(widget.subjectCode);
    final amount = _parseAmountToPaise(displayPrice);
    debugPrint('[Razorpay] Starting checkout uid=$uid authorId=${author.id} displayPrice=$displayPrice amountPaise=$amount');

    final available = await _isRazorpayPluginAvailable();
    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Razorpay native plugin not available in this build. Do flutter clean and full restart.'),
          ),
        );
      }
      return;
    }

    setState(() {
      _processingAuthorIds.add(author.id);
      _pendingAuthorId = author.id;
      _pendingPriceLabel = displayPrice;
    });

    _checkoutWatchdog?.cancel();
    _checkoutWatchdog = Timer(const Duration(seconds: 90), () {
      if (!mounted) return;
      if (_pendingAuthorId == author.id) {
        debugPrint('[Razorpay] Timeout while waiting for callback authorId=${author.id}');
        _clearPendingState(authorId: author.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment timeout. Please retry checkout.')),
        );
      }
    });

    final options = {
      'key': _razorpayTestKey,
      'amount': amount,
      'name': 'UniSync',
      'description': 'Unlock ${author.name} - ${widget.subjectCode}',
      'prefill': {
        'email': FirebaseAuth.instance.currentUser?.email ?? '',
      },
      'notes': {
        'subjectCode': widget.subjectCode,
        'authorId': author.id,
      },
      'theme': {
        'color': '#111827',
      },
    };

    debugPrint('[Razorpay] Checkout options prepared: $options');
    try {
      _razorpay.open(options);
      debugPrint('[Razorpay] Checkout opened');
    } on MissingPluginException catch (error) {
      debugPrint('[Razorpay] Missing plugin implementation: $error');
      _clearPendingState(authorId: author.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Razorpay plugin not linked in current build. Do a full app restart after flutter clean.',
            ),
          ),
        );
      }
    } catch (error) {
      debugPrint('[Razorpay] Failed to open checkout: $error');
      _clearPendingState(authorId: author.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to open Razorpay: $error')),
        );
      }
    }
  }

  Future<void> _openImportantQuestions(ExamAuthorModel author) async {
    final questions = author.importantQuestionsFor(widget.subjectCode);
    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No important questions uploaded yet for this author.')),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ImportantQuestionsReaderScreen(
          authorName: author.name,
          subjectCode: widget.subjectCode,
          questions: questions,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.authors.isEmpty) {
      return const _EmptyTabState(message: 'No authors found for this subject yet.');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (_, index) {
        final author = widget.authors[index];
        final samplePdfUrl = author.samplePdfFor(widget.subjectCode);
        final rating = author.ratingFor(widget.subjectCode);
        final feedbackCount = author.ratingCountFor(widget.subjectCode);
        final unlocked = _unlockedAuthorIds.contains(author.id);
        final isProcessing = _processingAuthorIds.contains(author.id);
        final displayPrice = author.displayPriceFor(widget.subjectCode);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: unlocked ? const Color(0xFFBBF7D0) : const Color(0xFFE7E5E4),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFFEDE9FE),
                    child: Text(
                      _initials(author.name),
                      style: const TextStyle(
                        color: Color(0xFF4C1D95),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          author.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          unlocked ? 'Purchased' : 'Locked by paywall',
                          style: TextStyle(
                            color: unlocked ? const Color(0xFF166534) : const Color(0xFFB45309),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      displayPrice,
                      style: TextStyle(
                        color: Color(0xFF9A3412),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _RatingChip(rating: rating, feedbackCount: feedbackCount),
                  _TextChip(label: unlocked ? 'Access Granted' : 'Requires Unlock'),
                  _TextChip(
                    label: '${author.importantQuestionsFor(widget.subjectCode).length} Q&A',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Razorpay test checkout is enabled. Unlock to access premium important questions with rich HTML answers.',
                style: const TextStyle(
                  color: Color(0xFF475569),
                  height: 1.35,
                ),
              ),
              if (samplePdfUrl != null && samplePdfUrl.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    samplePdfUrl,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (samplePdfUrl != null && samplePdfUrl.isNotEmpty)
                    FilledButton.tonal(
                      onPressed: () => _openPdfInApp(
                        context,
                        samplePdfUrl,
                        title: '${author.name} Sample PDF',
                      ),
                      child: const Text('Open Sample PDF'),
                    ),
                  FilledButton(
                    onPressed: unlocked
                        ? () => _openImportantQuestions(author)
                        : (isProcessing ? null : () => _startPurchase(author)),
                    child: isProcessing
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            unlocked
                                ? 'View Important Questions'
                                : 'Unlock ${displayPrice.isEmpty ? 'Now' : displayPrice}',
                          ),
                  ),
                  if (unlocked)
                    OutlinedButton.icon(
                      onPressed: () => _showRatingSheet(author),
                      icon: const Icon(Icons.star_rate_rounded),
                      label: Text(
                        _myRatings[author.id] == null
                            ? 'Rate Author'
                            : 'Your Rating ${_myRatings[author.id]!.toStringAsFixed(1)}',
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: widget.authors.length,
    );
  }
}

class _ImportantQuestionsReaderScreen extends StatefulWidget {
  final String authorName;
  final String subjectCode;
  final List<ExamImportantQuestion> questions;

  const _ImportantQuestionsReaderScreen({
    required this.authorName,
    required this.subjectCode,
    required this.questions,
  });

  @override
  State<_ImportantQuestionsReaderScreen> createState() =>
      _ImportantQuestionsReaderScreenState();
}

class _ImportantQuestionsReaderScreenState
    extends State<_ImportantQuestionsReaderScreen> {
  final ScrollController _scrollController = ScrollController();
  final Set<int> _revised = <int>{};

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.questions.length;
    final progress = total == 0 ? 0.0 : _revised.length / total;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EE),
      appBar: AppBar(
        title: Text('${widget.subjectCode} • ${widget.authorName}'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE7E5E4))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _TextChip(label: '$total Questions'),
                    const SizedBox(width: 8),
                    _TextChip(label: '${_revised.length} Revised'),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        _scrollController.animateTo(
                          0,
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOut,
                        );
                      },
                      child: const Text('Back To Top'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE7E5E4),
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              itemCount: total,
              itemBuilder: (context, index) {
                final question = widget.questions[index];
                final isRevised = _revised.contains(index);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isRevised
                            ? const Color(0xFFBBF7D0)
                            : const Color(0xFFE7E5E4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _TextChip(label: 'Q${index + 1}'),
                            const SizedBox(width: 8),
                            _TextChip(label: isRevised ? 'Revised' : 'Pending'),
                            const Spacer(),
                            IconButton(
                              tooltip: isRevised
                                  ? 'Mark as pending'
                                  : 'Mark as revised',
                              onPressed: () {
                                setState(() {
                                  if (isRevised) {
                                    _revised.remove(index);
                                  } else {
                                    _revised.add(index);
                                  }
                                });
                              },
                              icon: Icon(
                                isRevised
                                    ? Icons.check_circle
                                    : Icons.check_circle_outline,
                                color: isRevised
                                    ? const Color(0xFF15803D)
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          question.question,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Html(
                          data: question.answerHtml,
                          style: {
                            'body': Style(
                              margin: Margins.zero,
                              fontSize: FontSize(15),
                              lineHeight: const LineHeight(1.45),
                              color: const Color(0xFF1F2937),
                            ),
                            'p': Style(margin: Margins.only(bottom: 14)),
                            'li': Style(margin: Margins.only(bottom: 6)),
                            'code': Style(
                              backgroundColor: const Color(0xFFF5F5F4),
                              padding: HtmlPaddings.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                            ),
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingChip extends StatelessWidget {
  final double rating;
  final int feedbackCount;

  const _RatingChip({required this.rating, required this.feedbackCount});

  @override
  Widget build(BuildContext context) {
    final hasRating = rating > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
          const SizedBox(width: 4),
          Text(
            hasRating ? '${rating.toStringAsFixed(1)} ($feedbackCount reviews)' : 'No ratings yet',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _TextChip extends StatelessWidget {
  final String label;

  const _TextChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F4),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _AccessBanner extends StatelessWidget {
  final String title;
  final String subtitle;

  const _AccessBanner({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F4FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_open_rounded, color: Color(0xFF0369A1)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0C4A6E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF0C4A6E),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTabState extends StatelessWidget {
  final String message;

  const _EmptyTabState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(' ').where((e) => e.isNotEmpty).toList();
  if (parts.isEmpty) return 'AU';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
}

String? _extractYoutubeId(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return null;

  if (uri.host.contains('youtu.be')) {
    if (uri.pathSegments.isNotEmpty) return uri.pathSegments.first;
  }

  if (uri.host.contains('youtube.com')) {
    final videoId = uri.queryParameters['v'];
    if (videoId != null && videoId.isNotEmpty) return videoId;

    final segments = uri.pathSegments;
    final embedIndex = segments.indexOf('embed');
    if (embedIndex != -1 && segments.length > embedIndex + 1) {
      return segments[embedIndex + 1];
    }
  }

  return null;
}

Future<void> _openPdfInApp(BuildContext context, String url, {String? title}) async {
  final encodedUrl = Uri.encodeComponent(url);
  final viewerUrl = 'https://drive.google.com/viewerng/viewer?embedded=true&url=$encodedUrl';
  await _openWebInApp(context, url: viewerUrl, title: title ?? 'PDF Viewer');
}

Future<void> _openVideoInApp(BuildContext context, String url, {String? title}) async {
  final videoId = _extractYoutubeId(url);
  final embedUrl = videoId == null ? url : 'https://www.youtube.com/embed/$videoId';
  await _openWebInApp(context, url: embedUrl, title: title ?? 'Video');
}

Future<void> _openWebInApp(
  BuildContext context, {
  required String url,
  required String title,
}) async {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invalid URL')),
    );
    return;
  }

  if (!context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => _InAppWebViewerScreen(title: title, initialUrl: uri),
    ),
  );
}

class _InAppWebViewerScreen extends StatefulWidget {
  final String title;
  final Uri initialUrl;

  const _InAppWebViewerScreen({
    required this.title,
    required this.initialUrl,
  });

  @override
  State<_InAppWebViewerScreen> createState() => _InAppWebViewerScreenState();
}

class _InAppWebViewerScreenState extends State<_InAppWebViewerScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadRequest(widget.initialUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('widget.title'),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
