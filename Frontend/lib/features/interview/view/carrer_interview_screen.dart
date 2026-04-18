// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neopop/neopop.dart';
import 'package:routemaster/routemaster.dart';
import 'package:UniSync/app/providers.dart';
import 'package:UniSync/features/auth/auth_repository.dart';
import 'package:UniSync/features/interview/controllers/carrer_controller.dart';
import 'package:UniSync/features/interview/view/interview_palette.dart';
import 'package:UniSync/models/template_model.dart';
import 'package:UniSync/sockets/socket_methods.dart';

InterviewPalette _ui(BuildContext context) => InterviewPalette.of(context);

final selectedTemplateProvider = StateProvider<TemplateModel?>((ref) => null);

// ─────────────────────────────────────────────────────────────────────────────
//  MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class CarrerInterviewScreen extends ConsumerStatefulWidget {
  const CarrerInterviewScreen({super.key});

  @override
  ConsumerState<CarrerInterviewScreen> createState() =>
      _CarrerInterviewScreenState();
}

class _CarrerInterviewScreenState extends ConsumerState<CarrerInterviewScreen> {
  // ── unchanged logic fields ────────────────────────────────────────────────
  String _activeDomain = 'All';
  List<String> _selectedDomainFilters = [];

  @override
  void initState() {
    super.initState();
    ref.read(socketMethodProvider).initListeners();
    _refreshCoins();
  }

  Future<void> _refreshCoins() async {
    final latest =
        await ref.read(AuthRepositoryProvider).loadCurrentUserProfile();
    if (!mounted || latest == null) return;
    ref.read(userProvider.notifier).state = latest;
  }

  Future<void> _refreshTemplatesAndCoins() async {
    await Future.wait([
      ref.read(carrerControllerProvider.notifier).refresh(),
      _refreshCoins(),
    ]);
  }

  // ── unchanged logic methods ───────────────────────────────────────────────
  Future<void> _openManageFilters(List<String> availableDomains) async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _ui(context).backgroundSecondary,
      shape: Border(
          top: BorderSide(color: _ui(context).divider, width: 0.8)),
      builder: (_) => _DomainFilterSheet(
        availableDomains: availableDomains,
        initialSelected: _selectedDomainFilters,
      ),
    );
    if (result == null) return;
    setState(() {
      _selectedDomainFilters = result;
      if (_activeDomain != 'All' &&
          !_selectedDomainFilters.contains(_activeDomain)) {
        _activeDomain = 'All';
      }
    });
    ref.read(carrerControllerProvider.notifier).filterByDomain(_activeDomain);
  }

  void _syncSelectedDomainsWithAvailable(List<String> availableDomains) {
    final availableSet = availableDomains.toSet();
    final sanitized =
        _selectedDomainFilters.where(availableSet.contains).toList();
    if (sanitized.length == _selectedDomainFilters.length) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _selectedDomainFilters = sanitized;
        if (_activeDomain != 'All' &&
            !_selectedDomainFilters.contains(_activeDomain)) {
          _activeDomain = 'All';
        }
      });
      ref.read(carrerControllerProvider.notifier).filterByDomain(_activeDomain);
    });
  }

  // ── info dialog ───────────────────────────────────────────────────────────
  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: _ui(context).backgroundSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _ui(context).accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                          color: _ui(context).accent.withOpacity(0.3)),
                    ),
                    child: Icon(Icons.psychology_outlined,
                        size: 18, color: _ui(context).accent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Why Uni interviews?',
                        style: TextStyle(
                          color: _ui(context).textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        )),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close_rounded,
                        size: 18, color: _ui(context).textMuted),
                  ),
                ]),
                const SizedBox(height: 16),
                Divider(color: _ui(context).divider, height: 1),
                const SizedBox(height: 14),
                ...[
                  _InfoPoint(
                      icon: Icons.record_voice_over_rounded,
                      title: 'Real back-and-forth',
                      body:
                          'Uni listens, follows up and challenges you — like a real interviewer.'),
                  _InfoPoint(
                      icon: Icons.analytics_outlined,
                      title: 'Scored on what matters',
                      body:
                          'Responses are scored on domain-specific rubrics, not just keywords.'),
                  _InfoPoint(
                      icon: Icons.track_changes_rounded,
                      title: 'Tracks your growth',
                      body:
                          'Past sessions and scores are saved so you can see improvement over time.'),
                  _InfoPoint(
                      icon: Icons.not_interested_rounded,
                      title: 'Not just ChatGPT',
                      body:
                          'GPT gives generic tips. Uni simulates pressure, evaluates depth and gives structured feedback.',
                      isLast: true),
                ],
              ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final templates = ref.watch(carrerControllerProvider);

    return Scaffold(
      backgroundColor: _ui(context).backgroundPrimary,
      // floatingActionButton: FloatingActionButton.extended(
      //   backgroundColor: _ui(context).accent,
      //   foregroundColor: _ui(context).buttonPrimaryFg,
      //   onPressed: () => _openManageDataSheet(
      //     allTemplates: allTemplates,
      //     allDomains: allDomains,
      //   ),
      //   icon: const Icon(Icons.tune_rounded, size: 18),
      //   label: const Text(
      //     'Manage',
      //     style: TextStyle(fontWeight: FontWeight.w700),
      //   ),
      // ),
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Header ─────────────────────────────────────────────────
          Container(
            color: _ui(context).backgroundSecondary,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        RichText(
                          text: TextSpan(children: [
                        TextSpan(
                            text: 'Mock ',
                            style: TextStyle(
                              color: _ui(context).textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            )),
                        TextSpan(
                            text: 'interviews',
                            style: TextStyle(
                              color: _ui(context).accent,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            )),
                      ])),
                      const SizedBox(height: 2),
                        Text('Pick a template and get started',
                          style: TextStyle(
                            color: _ui(context).textMuted,
                            fontSize: 12,
                          )),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      NeoPopButton(
                        color: _ui(context).surfaceCard,
                        bottomShadowColor: _ui(context).accent,
                        rightShadowColor: _ui(context).accent,
                        depth: 2,
                        onTapUp: () => Routemaster.of(context)
                            .push('/userInterviewDetails'),
                        onTapDown: () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: _ui(context).accent.withOpacity(0.35)),
                          ),
                          child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bar_chart_rounded,
                                    size: 14, color: _ui(context).accent),
                                SizedBox(width: 5),
                                Text('My Reports',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _ui(context).accent,
                                    )),
                              ]),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showInfoDialog(context),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: _ui(context).surfaceCard,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _ui(context).border),
                          ),
                          child: Center(
                            child: Icon(Icons.info_outline_rounded,
                                size: 17, color: _ui(context).textMuted),
                          ),
                        ),
                      ),
                    ]),
                  ],
                ),
              ],
            ),
          ),

          Container(height: 0.8, color: _ui(context).divider),

          // ── Filter bar ──────────────────────────────────────────────
          // Shows: active domain chips (removable) + filter pill button
          // If nothing selected: just the filter button with hint text
          templates.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (data) {
              final allDomains =
                  ref.read(carrerControllerProvider.notifier).AvailableDomains;
              _syncSelectedDomainsWithAvailable(allDomains);

              final hasActive = _selectedDomainFilters.isNotEmpty;

              return Container(
                color: _ui(context).backgroundSecondary,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Row(children: [
                  // ── Left: active chip strip or empty hint ──────────
                  Expanded(
                    child: hasActive
                        // Active: scrollable removable chips + "All" selector
                        ? SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(children: [
                              // "All" toggle
                              GestureDetector(
                                onTap: () {
                                  setState(() => _activeDomain = 'All');
                                  ref
                                      .read(carrerControllerProvider.notifier)
                                      .filterByDomain('All');
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _activeDomain == 'All'
                                        ? _ui(context).accent
                                        : _ui(context).surfaceCard,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: _activeDomain == 'All'
                                          ? _ui(context).accent
                                          : _ui(context).border,
                                    ),
                                  ),
                                  child: Text('All',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _activeDomain == 'All'
                                            ? _ui(context).buttonPrimaryFg
                                            : _ui(context).textSecondary,
                                      )),
                                ),
                              ),
                              // Active domain chips
                              ..._selectedDomainFilters.map((domain) {
                                final isActive = _activeDomain == domain;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() => _activeDomain = domain);
                                    ref
                                        .read(carrerControllerProvider.notifier)
                                        .filterByDomain(domain);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    margin: const EdgeInsets.only(right: 8),
                                    padding:
                                        const EdgeInsets.fromLTRB(11, 6, 6, 6),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? _ui(context).accent
                                          : _ui(context).surfaceCard,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isActive
                                            ? _ui(context).accent
                                            : _ui(context).border,
                                      ),
                                    ),
                                    child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(domain,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: isActive
                                                    ? _ui(context).buttonPrimaryFg
                                                    : _ui(context).textSecondary,
                                              )),
                                          const SizedBox(width: 6),
                                          // Remove ×
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _selectedDomainFilters
                                                    .remove(domain);
                                                if (_activeDomain == domain) {
                                                  _activeDomain = 'All';
                                                  ref
                                                      .read(
                                                          carrerControllerProvider
                                                              .notifier)
                                                      .filterByDomain('All');
                                                }
                                              });
                                            },
                                            child: Container(
                                              width: 16,
                                              height: 16,
                                              decoration: BoxDecoration(
                                                color: isActive
                                                    ? _ui(context)
                                                        .buttonPrimaryFg
                                                        .withOpacity(0.2)
                                                    : _ui(context)
                                                        .backgroundPrimary,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Icon(Icons.close_rounded,
                                                  size: 10,
                                                  color: isActive
                                                      ? _ui(context)
                                                          .buttonPrimaryFg
                                                      : _ui(context).textMuted),
                                            ),
                                          ),
                                        ]),
                                  ),
                                );
                              }),
                            ]),
                          )
                        // Empty: hint text
                        : Text(
                            'No tech selected — showing all templates',
                            style: TextStyle(
                              color: _ui(context).textMuted,
                              fontSize: 11,
                            ),
                          ),
                  ),

                  const SizedBox(width: 10),

                  // ── Right: filter button ────────────────────────────
                  GestureDetector(
                    onTap: () => _openManageFilters(allDomains),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 7),
                      decoration: BoxDecoration(
                        color: hasActive
                            ? _ui(context).accent.withOpacity(0.1)
                            : _ui(context).surfaceCard,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: hasActive
                              ? _ui(context).accent.withOpacity(0.45)
                              : _ui(context).border,
                        ),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(
                          hasActive ? Icons.tune_rounded : Icons.add_rounded,
                          size: 14,
                          color: hasActive
                              ? _ui(context).accent
                              : _ui(context).textMuted,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          hasActive
                              ? '${_selectedDomainFilters.length} domain${_selectedDomainFilters.length > 1 ? 's' : ''}'
                              : 'Filter',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: hasActive
                                ? _ui(context).accent
                                : _ui(context).textMuted,
                          ),
                        ),
                      ]),
                    ),
                  ),
                ]),
              );
            },
          ),

          Container(height: 0.8, color: _ui(context).divider),

          // ── Template list ───────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              color: _ui(context).accent,
              onRefresh: _refreshTemplatesAndCoins,
              child: templates.when(
                loading: () => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: 300,
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _ui(context).accent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                error: (error, _) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: 360,
                      child: Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline_rounded,
                                  color: _ui(context).textMuted, size: 36),
                              const SizedBox(height: 12),
                              Text(
                                'No Cache Found',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: _ui(context).textSecondary,
                                    fontSize: 13),
                              ),
                              const SizedBox(height: 12),
                              TextButton.icon(
                                onPressed: () {
                                  ref
                                      .read(carrerControllerProvider.notifier)
                                      .refresh();
                                },
                                icon:
                                  Icon(Icons.refresh_rounded, size: 16),
                                label:
                                  Text('Spin the Servers to fetch latest data..'),
                                style: TextButton.styleFrom(
                                  foregroundColor: _ui(context).accent,
                                ),
                              ),
                            ]),
                      ),
                    ),
                  ],
                ),
                data: (data) {
                  if (data.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: 320,
                          child: Center(
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                      width: 56,
                                      height: 56,
                                      color: _ui(context).surfaceCard,
                                      child: Icon(
                                          Icons.psychology_outlined,
                                          color: _ui(context).textMuted,
                                          size: 26)),
                                  const SizedBox(height: 14),
                                  Text('No templates found',
                                      style: TextStyle(
                                        color: _ui(context).textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      )),
                                  const SizedBox(height: 6),
                                  Text('Try a different domain',
                                      style: TextStyle(
                                        color: _ui(context).textSecondary,
                                        fontSize: 12,
                                      )),
                                ]),
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                    itemCount: data.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final template = data[index];
                      return TemplateCard(
                        logo: template.icon,
                        heading: template.title,
                        topics: template.topics,
                        coinPrice: template.coinPrice,
                        onTap: () {
                          ref.read(selectedTemplateProvider.notifier).state =
                              template;
                          Routemaster.of(context).push('/startInterviewScreen');
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TEMPLATE CARD  — NeoPop elevated
// ─────────────────────────────────────────────────────────────────────────────
class TemplateCard extends StatelessWidget {
  const TemplateCard({
    super.key,
    required this.logo,
    required this.heading,
    required this.topics,
    required this.coinPrice,
    required this.onTap,
  });

  final String logo;
  final String heading;
  final List<String> topics;
  final int coinPrice;
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
          Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: _ui(context).backgroundSecondary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _ui(context).border),
            ),
            child: CachedNetworkImage(
              imageUrl: logo,
              fit: BoxFit.contain,
                  placeholder: (_, __) => SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 1.5, color: _ui(context).textMuted)),
                errorWidget: (_, __, ___) => Icon(Icons.psychology_outlined,
                  color: _ui(context).textMuted, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(heading,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _ui(context).textPrimary,
                    letterSpacing: -0.2,
                  )),
              const SizedBox(height: 5),
              Text(topics.take(4).join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: _ui(context).textSecondary,
                    height: 1.4,
                  )),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _ui(context).accentSoft,
                  borderRadius: BorderRadius.circular(6),
                  border:
                      Border.all(color: _ui(context).accent.withOpacity(0.3)),
                ),
                child: Text(
                  '$coinPrice coins',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _ui(context).accent,
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  INFO DIALOG POINT
// ─────────────────────────────────────────────────────────────────────────────
class _InfoPoint extends StatelessWidget {
  const _InfoPoint({
    required this.icon,
    required this.title,
    required this.body,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _ui(context).surfaceCard,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: _ui(context).borderSubtle),
          ),
          child: Icon(icon, size: 14, color: _ui(context).accent),
        ),
        const SizedBox(width: 11),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                  color: _ui(context).textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 3),
            Text(body,
              style: TextStyle(
                  color: _ui(context).textSecondary,
                  fontSize: 12,
                  height: 1.45,
                )),
          ],
        )),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DOMAIN FILTER BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _DomainFilterSheet extends StatefulWidget {
  const _DomainFilterSheet({
    required this.availableDomains,
    required this.initialSelected,
  });

  final List<String> availableDomains;
  final List<String> initialSelected;

  @override
  State<_DomainFilterSheet> createState() => _DomainFilterSheetState();
}

class _DomainFilterSheetState extends State<_DomainFilterSheet> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelected.toSet();
  }

  void _toggle(String d) => setState(
      () => _selected.contains(d) ? _selected.remove(d) : _selected.add(d));

  void _selectAll() =>
      setState(() => _selected = widget.availableDomains.toSet());

  void _clearAll() => setState(() => _selected.clear());

  @override
  Widget build(BuildContext context) {
    final allSelected = _selected.length == widget.availableDomains.length;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, ctrl) => Column(children: [
        const SizedBox(height: 10),
        Center(
            child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: _ui(context).border,
                    borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 14),

        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('#Technologies',
                  style: TextStyle(
                      color: _ui(context).accent,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8)),
              const SizedBox(height: 2),
                RichText(
                  text: TextSpan(children: [
                TextSpan(
                    text: 'Filter ',
                    style: TextStyle(
                        color: _ui(context).textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3)),
                TextSpan(
                    text: 'by tech',
                    style: TextStyle(
                        color: _ui(context).accent,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3)),
              ])),
            ]),
            const Spacer(),
            GestureDetector(
              onTap: allSelected ? _clearAll : _selectAll,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: _ui(context).surfaceCard,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _ui(context).border)),
                child: Text(allSelected ? 'Clear all' : 'Select all',
                  style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _ui(context).textSecondary)),
              ),
            ),
          ]),
        ),

        const SizedBox(height: 12),
        Container(height: 0.8, color: _ui(context).divider),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Text(
              '${_selected.length} of ${widget.availableDomains.length} selected',
                style: TextStyle(
                  color: _ui(context).textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ),

        Expanded(
          child: SingleChildScrollView(
            controller: ctrl,
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: widget.availableDomains.map((domain) {
                final active = _selected.contains(domain);
                return GestureDetector(
                  onTap: () => _toggle(domain),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: active
                          ? _ui(context).accent.withOpacity(0.12)
                          : _ui(context).surfaceCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: active
                            ? _ui(context).accent.withOpacity(0.5)
                            : _ui(context).border,
                        width: active ? 1.5 : 1,
                      ),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                            color: active
                                ? _ui(context).accent
                                : _ui(context).border,
                            shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(domain,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                active ? FontWeight.w600 : FontWeight.w400,
                            color: active
                                ? _ui(context).accent
                                : _ui(context).textSecondary,
                          )),
                    ]),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        Container(
          color: _ui(context).backgroundSecondary,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: NeoPopButton(
            color: _ui(context).accent,
            bottomShadowColor: _ui(context).backgroundPrimary,
            rightShadowColor: _ui(context).backgroundPrimary,
            depth: 4,
            buttonPosition: Position.fullBottom,
            onTapUp: () =>
                Navigator.of(context).pop(_selected.toList()..sort()),
            onTapDown: () {},
            child: SizedBox(
                height: 48,
                child: Center(
                    child: Text('Add These Filters',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _ui(context).buttonPrimaryFg,
                            letterSpacing: 0.2)))),
          ),
        ),
      ]),
    );
  }
}






