// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neopop/neopop.dart';
import 'package:routemaster/routemaster.dart';
import 'package:unisync/app/providers.dart';
import 'package:unisync/constants/constant.dart';
import 'package:unisync/features/auth/auth_repository.dart';
import 'package:unisync/features/interview/controllers/carrer_controller.dart';
import 'package:unisync/features/interview/repository/carrer_repository.dart';
import 'package:unisync/models/template_model.dart';
import 'package:unisync/sockets/socket_methods.dart';

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
    final latest = await ref.read(AuthRepositoryProvider).loadCurrentUserProfile();
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
      backgroundColor: UniSyncColors.backgroundSecondary,
      shape: const Border(
          top: BorderSide(color: UniSyncColors.divider, width: 0.8)),
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
        backgroundColor: UniSyncColors.backgroundSecondary,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child:
              Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: UniSyncColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(9),
                  border:
                      Border.all(color: UniSyncColors.accent.withOpacity(0.3)),
                ),
                child: const Icon(Icons.psychology_outlined,
                    size: 18, color: UniSyncColors.accent),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Why Uni interviews?',
                    style: TextStyle(
                      color: UniSyncColors.textPrimary,
                      fontSize: 15, fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    )),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close_rounded,
                    size: 18, color: UniSyncColors.textMuted),
              ),
            ]),
            const SizedBox(height: 16),
            const Divider(color: UniSyncColors.divider, height: 1),
            const SizedBox(height: 14),
            ...[
              _InfoPoint(icon: Icons.record_voice_over_rounded,
                  title: 'Real back-and-forth',
                  body: 'Uni listens, follows up and challenges you — like a real interviewer.'),
              _InfoPoint(icon: Icons.analytics_outlined,
                  title: 'Scored on what matters',
                  body: 'Responses are scored on domain-specific rubrics, not just keywords.'),
              _InfoPoint(icon: Icons.track_changes_rounded,
                  title: 'Tracks your growth',
                  body: 'Past sessions and scores are saved so you can see improvement over time.'),
              _InfoPoint(icon: Icons.not_interested_rounded,
                  title: 'Not just ChatGPT',
                  body: 'GPT gives generic tips. Uni simulates pressure, evaluates depth and gives structured feedback.',
                  isLast: true),
            ],
          ]),
        ),
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? UniSyncColors.error : null,
        ),
      );
  }

  Future<void> _openManageDataSheet({
    required List<TemplateModel> allTemplates,
    required List<String> allDomains,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: UniSyncColors.backgroundSecondary,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Manage Domains & Templates',
                  style: TextStyle(
                    color: UniSyncColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                _manageTile(
                  icon: Icons.add_circle_outline_rounded,
                  title: 'Add Domain',
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await _openAddDomainDialog();
                  },
                ),
                _manageTile(
                  icon: Icons.remove_circle_outline_rounded,
                  title: 'Remove Domain',
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await _openRemoveDomainDialog(allDomains);
                  },
                ),
                _manageTile(
                  icon: Icons.note_add_outlined,
                  title: 'Add Template',
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await _openAddTemplateDialog(allDomains);
                  },
                ),
                _manageTile(
                  icon: Icons.delete_outline_rounded,
                  title: 'Remove Template',
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await _openRemoveTemplateDialog(allTemplates);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _manageTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(icon, color: UniSyncColors.accent),
      title: Text(
        title,
        style: const TextStyle(
          color: UniSyncColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
      onTap: onTap,
    );
  }

  Future<void> _openAddDomainDialog() async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: UniSyncColors.backgroundSecondary,
        title: const Text('Add Domain', style: TextStyle(color: UniSyncColors.textPrimary)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: UniSyncColors.textPrimary),
          decoration: const InputDecoration(hintText: 'e.g. flutter'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final domain = ctrl.text.trim();
              if (domain.isEmpty) return;
              Navigator.pop(context);
              try {
                await ref.read(carrerRepositoryProvider).createDomain(domain);
                await ref.read(carrerControllerProvider.notifier).refresh();
                _showMessage('Domain added successfully.');
              } catch (_) {
                _showMessage('Failed to add domain.', isError: true);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _openRemoveDomainDialog(List<String> allDomains) async {
    String? selected = allDomains.isNotEmpty ? allDomains.first : null;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: UniSyncColors.backgroundSecondary,
        title: const Text('Remove Domain', style: TextStyle(color: UniSyncColors.textPrimary)),
        content: allDomains.isEmpty
            ? const Text('No domains available.', style: TextStyle(color: UniSyncColors.textSecondary))
            : StatefulBuilder(
                builder: (context, setStateDialog) => DropdownButtonFormField<String>(
                  value: selected,
                  dropdownColor: UniSyncColors.surfaceCard,
                  items: allDomains
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (val) => setStateDialog(() => selected = val),
                ),
              ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: allDomains.isEmpty
                ? null
                : () async {
                    final domain = selected;
                    if (domain == null || domain.isEmpty) return;
                    Navigator.pop(context);
                    try {
                      await ref.read(carrerRepositoryProvider).deleteDomain(domain);
                      await ref.read(carrerControllerProvider.notifier).refresh();
                      _showMessage('Domain removed successfully.');
                    } catch (_) {
                      _showMessage('Failed to remove domain.', isError: true);
                    }
                  },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddTemplateDialog(List<String> allDomains) async {
    final titleCtrl = TextEditingController();
    final iconCtrl = TextEditingController();
    final topicsCtrl = TextEditingController();
    final coinCtrl = TextEditingController(text: '10');
    String? selectedDomain = allDomains.isNotEmpty ? allDomains.first : null;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: UniSyncColors.backgroundSecondary,
        title: const Text('Add Template', style: TextStyle(color: UniSyncColors.textPrimary)),
        content: StatefulBuilder(
          builder: (context, setStateDialog) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: UniSyncColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 8),
                if (allDomains.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: selectedDomain,
                    dropdownColor: UniSyncColors.surfaceCard,
                    items: allDomains
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (val) => setStateDialog(() => selectedDomain = val),
                    decoration: const InputDecoration(labelText: 'Domain'),
                  ),
                if (allDomains.isEmpty)
                  const Text(
                    'No domains found. Add a domain first.',
                    style: TextStyle(color: UniSyncColors.textMuted, fontSize: 12),
                  ),
                const SizedBox(height: 8),
                TextField(
                  controller: iconCtrl,
                  style: const TextStyle(color: UniSyncColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Icon URL/Text'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: topicsCtrl,
                  style: const TextStyle(color: UniSyncColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Topics (comma separated)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: coinCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: UniSyncColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Coin Price'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final title = titleCtrl.text.trim();
              final domain = selectedDomain?.trim() ?? '';
              final icon = iconCtrl.text.trim();
              final topics = topicsCtrl.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
              final coinPrice = int.tryParse(coinCtrl.text.trim()) ?? -1;

              if (title.isEmpty || domain.isEmpty || icon.isEmpty || topics.isEmpty || coinPrice < 0) {
                _showMessage('Please enter valid template details.', isError: true);
                return;
              }

              Navigator.pop(context);
              try {
                await ref.read(carrerRepositoryProvider).createTemplate(
                      title: title,
                      domain: domain,
                      icon: icon,
                      topics: topics,
                      coinPrice: coinPrice,
                    );
                await ref.read(carrerControllerProvider.notifier).refresh();
                _showMessage('Template added successfully.');
              } catch (_) {
                _showMessage('Failed to add template.', isError: true);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _openRemoveTemplateDialog(List<TemplateModel> allTemplates) async {
    TemplateModel? selected = allTemplates.isNotEmpty ? allTemplates.first : null;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: UniSyncColors.backgroundSecondary,
        title: const Text('Remove Template', style: TextStyle(color: UniSyncColors.textPrimary)),
        content: allTemplates.isEmpty
            ? const Text('No templates available.', style: TextStyle(color: UniSyncColors.textSecondary))
            : StatefulBuilder(
                builder: (context, setStateDialog) => DropdownButtonFormField<String>(
                  value: selected?.id,
                  dropdownColor: UniSyncColors.surfaceCard,
                  items: allTemplates
                      .map((t) => DropdownMenuItem(value: t.id, child: Text(t.title)))
                      .toList(),
                  onChanged: (val) {
                    setStateDialog(() {
                      final idx = allTemplates.indexWhere((t) => t.id == val);
                      selected = idx >= 0 ? allTemplates[idx] : null;
                    });
                  },
                ),
              ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: allTemplates.isEmpty
                ? null
                : () async {
                    if (selected == null) return;
                    Navigator.pop(context);
                    try {
                      await ref.read(carrerRepositoryProvider).deleteTemplate(selected!.id);
                      await ref.read(carrerControllerProvider.notifier).refresh();
                      _showMessage('Template removed successfully.');
                    } catch (_) {
                      _showMessage('Failed to remove template.', isError: true);
                    }
                  },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final templates = ref.watch(carrerControllerProvider);
    final user = ref.watch(userProvider);
    final currentCoins = user?.coins ?? 0;
    final allDomains = ref.read(carrerControllerProvider.notifier).AvailableDomains;
    final allTemplates = ref.read(carrerControllerProvider.notifier).allTemplates;

    return Scaffold(
      backgroundColor: UniSyncColors.backgroundPrimary,
      // floatingActionButton: FloatingActionButton.extended(
      //   backgroundColor: UniSyncColors.accent,
      //   foregroundColor: UniSyncColors.buttonPrimaryFg,
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
            color: UniSyncColors.backgroundSecondary,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('#INTERVIEWS', style: TextStyle(
                        color: UniSyncColors.accent, fontSize: 9,
                        fontWeight: FontWeight.w700, letterSpacing: 1.8,
                      )),
                      const SizedBox(height: 4),
                      RichText(text: const TextSpan(children: [
                        TextSpan(text: 'Mock ',
                            style: TextStyle(
                              color: UniSyncColors.textPrimary, fontSize: 24,
                              fontWeight: FontWeight.w800, letterSpacing: -0.5,
                            )),
                        TextSpan(text: 'interviews',
                            style: TextStyle(
                              color: UniSyncColors.accent, fontSize: 24,
                              fontWeight: FontWeight.w800, letterSpacing: -0.5,
                            )),
                      ])),
                      const SizedBox(height: 2),
                      const Text('Pick a template and get started',
                          style: TextStyle(
                            color: UniSyncColors.textMuted, fontSize: 12,
                          )),
                    ],
                  ),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      GestureDetector(
                        onTap: () => Routemaster.of(context).push('/userInterviewDetails'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: UniSyncColors.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: UniSyncColors.accent.withOpacity(0.35)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: const [
                            Icon(Icons.bar_chart_rounded,
                                size: 14, color: UniSyncColors.accent),
                            SizedBox(width: 5),
                            Text('My Reports', style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700,
                              color: UniSyncColors.accent,
                            )),
                          ]),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showInfoDialog(context),
                        child: Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(
                            color: UniSyncColors.surfaceCard,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: UniSyncColors.border),
                          ),
                          child: const Center(
                            child: Icon(Icons.info_outline_rounded,
                                size: 17, color: UniSyncColors.textMuted),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: UniSyncColors.accentSoft,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: UniSyncColors.accent.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.monetization_on_rounded,
                              size: 14, color: UniSyncColors.accent),
                          const SizedBox(width: 4),
                          Text(
                            '$currentCoins',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: UniSyncColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Container(height: 0.8, color: UniSyncColors.divider),

          // ── Filter bar ──────────────────────────────────────────────
          // Shows: active domain chips (removable) + filter pill button
          // If nothing selected: just the filter button with hint text
          templates.when(
            loading: () => const SizedBox.shrink(),
            error:   (_, __) => const SizedBox.shrink(),
            data:    (data) {
              final allDomains = ref
                  .read(carrerControllerProvider.notifier)
                  .AvailableDomains;
              _syncSelectedDomainsWithAvailable(allDomains);

              final hasActive = _selectedDomainFilters.isNotEmpty;

              return Container(
                color: UniSyncColors.backgroundSecondary,
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
                                  ref.read(carrerControllerProvider.notifier)
                                      .filterByDomain('All');
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _activeDomain == 'All'
                                        ? UniSyncColors.accent
                                        : UniSyncColors.surfaceCard,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: _activeDomain == 'All'
                                          ? UniSyncColors.accent
                                          : UniSyncColors.border,
                                    ),
                                  ),
                                  child: Text('All',
                                      style: TextStyle(
                                        fontSize: 12, fontWeight: FontWeight.w600,
                                        color: _activeDomain == 'All'
                                            ? UniSyncColors.buttonPrimaryFg
                                            : UniSyncColors.textSecondary,
                                      )),
                                ),
                              ),
                              // Active domain chips
                              ..._selectedDomainFilters.map((domain) {
                                final isActive = _activeDomain == domain;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() => _activeDomain = domain);
                                    ref.read(carrerControllerProvider.notifier)
                                        .filterByDomain(domain);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.fromLTRB(
                                        11, 6, 6, 6),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? UniSyncColors.accent
                                          : UniSyncColors.surfaceCard,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isActive
                                            ? UniSyncColors.accent
                                            : UniSyncColors.border,
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
                                                ? UniSyncColors.buttonPrimaryFg
                                                : UniSyncColors.textSecondary,
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
                                                  .read(carrerControllerProvider
                                                      .notifier)
                                                  .filterByDomain('All');
                                            }
                                          });
                                        },
                                        child: Container(
                                          width: 16, height: 16,
                                          decoration: BoxDecoration(
                                            color: isActive
                                                ? Colors.white.withOpacity(0.2)
                                                : UniSyncColors.backgroundPrimary,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Icon(Icons.close_rounded,
                                              size: 10,
                                              color: isActive
                                                  ? UniSyncColors.buttonPrimaryFg
                                                  : UniSyncColors.textMuted),
                                        ),
                                      ),
                                    ]),
                                  ),
                                );
                              }),
                            ]),
                          )
                        // Empty: hint text
                        : const Text(
                            'No domain selected — showing all templates',
                            style: TextStyle(
                              color: UniSyncColors.textMuted,
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
                            ? UniSyncColors.accent.withOpacity(0.1)
                            : UniSyncColors.surfaceCard,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: hasActive
                              ? UniSyncColors.accent.withOpacity(0.45)
                              : UniSyncColors.border,
                        ),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(
                          hasActive ? Icons.tune_rounded : Icons.add_rounded,
                          size: 14,
                          color: hasActive
                              ? UniSyncColors.accent
                              : UniSyncColors.textMuted,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          hasActive
                              ? '${_selectedDomainFilters.length} domain${_selectedDomainFilters.length > 1 ? 's' : ''}'
                              : 'Filter',
                          style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600,
                            color: hasActive
                                ? UniSyncColors.accent
                                : UniSyncColors.textMuted,
                          ),
                        ),
                      ]),
                    ),
                  ),
                ]),
              );
            },
          ),

          Container(height: 0.8, color: UniSyncColors.divider),

          // ── Template list ───────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              color: UniSyncColors.accent,
              onRefresh: _refreshTemplatesAndCoins,
              child: templates.when(
              loading: () => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(
                    height: 300,
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: UniSyncColors.accent,
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
                          mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.error_outline_rounded,
                            color: UniSyncColors.textMuted, size: 36),
                        const SizedBox(height: 12),
                        const Text(
                          'Unable to load interview templates right now.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: UniSyncColors.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () {
                            ref.read(carrerControllerProvider.notifier).refresh();
                          },
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Try again'),
                          style: TextButton.styleFrom(
                            foregroundColor: UniSyncColors.accent,
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
                            Container(width: 56, height: 56,
                                color: UniSyncColors.surfaceCard,
                                child: const Icon(Icons.psychology_outlined,
                                    color: UniSyncColors.textMuted, size: 26)),
                            const SizedBox(height: 14),
                            const Text('No templates found',
                                style: TextStyle(
                                  color: UniSyncColors.textPrimary, fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                )),
                            const SizedBox(height: 6),
                            const Text('Try a different domain',
                                style: TextStyle(
                                  color: UniSyncColors.textSecondary, fontSize: 12,
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
                      logo:    template.icon,
                      heading: template.title,
                      topics:  template.topics,
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
      color: UniSyncColors.surfaceCard,
      bottomShadowColor: UniSyncColors.accent,
      rightShadowColor: UniSyncColors.accent,
      depth: 4,
      onTapUp: onTap,
      onTapDown: () {},
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Container(
            width: 48, height: 48,
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: UniSyncColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: UniSyncColors.border),
            ),
            child: CachedNetworkImage(
              imageUrl: logo, fit: BoxFit.contain,
              placeholder: (_, __) => const SizedBox(width: 14, height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 1.5, color: UniSyncColors.textMuted)),
              errorWidget: (_, __, ___) => const Icon(Icons.psychology_outlined,
                  color: UniSyncColors.textMuted, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(heading,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: UniSyncColors.textPrimary, letterSpacing: -0.2,
                  )),
              const SizedBox(height: 5),
              Text(topics.take(4).join(' · '),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12, color: UniSyncColors.textSecondary,
                    height: 1.4,
                  )),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: UniSyncColors.accentSoft,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: UniSyncColors.accent.withOpacity(0.3)),
                ),
                child: Text(
                  '$coinPrice coins',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: UniSyncColors.accent,
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
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: UniSyncColors.surfaceCard,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: UniSyncColors.borderSubtle),
          ),
          child: Icon(icon, size: 14, color: UniSyncColors.accent),
        ),
        const SizedBox(width: 11),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(
              color: UniSyncColors.textPrimary,
              fontSize: 13, fontWeight: FontWeight.w700,
            )),
            const SizedBox(height: 3),
            Text(body, style: const TextStyle(
              color: UniSyncColors.textSecondary,
              fontSize: 12, height: 1.45,
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

  void _toggle(String d) => setState(() =>
      _selected.contains(d) ? _selected.remove(d) : _selected.add(d));

  void _selectAll() =>
      setState(() => _selected = widget.availableDomains.toSet());

  void _clearAll() => setState(() => _selected.clear());

  @override
  Widget build(BuildContext context) {
    final allSelected = _selected.length == widget.availableDomains.length;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4, maxChildSize: 0.92,
      builder: (_, ctrl) => Column(children: [
        const SizedBox(height: 10),
        Center(child: Container(width: 36, height: 4,
            decoration: BoxDecoration(color: UniSyncColors.border,
                borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 14),

        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('#DOMAINS', style: TextStyle(
                color: UniSyncColors.accent, fontSize: 9,
                fontWeight: FontWeight.w700, letterSpacing: 1.8)),
              const SizedBox(height: 2),
              RichText(text: const TextSpan(children: [
                TextSpan(text: 'Filter ',
                    style: TextStyle(color: UniSyncColors.textPrimary,
                        fontSize: 17, fontWeight: FontWeight.w800,
                        letterSpacing: -0.3)),
                TextSpan(text: 'by domain',
                    style: TextStyle(color: UniSyncColors.accent,
                        fontSize: 17, fontWeight: FontWeight.w800,
                        letterSpacing: -0.3)),
              ])),
            ]),
            const Spacer(),
            GestureDetector(
              onTap: allSelected ? _clearAll : _selectAll,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: UniSyncColors.surfaceCard,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: UniSyncColors.border)),
                child: Text(allSelected ? 'Clear all' : 'Select all',
                    style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: UniSyncColors.textSecondary)),
              ),
            ),
          ]),
        ),

        const SizedBox(height: 12),
        Container(height: 0.8, color: UniSyncColors.divider),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Text(
            '${_selected.length} of ${widget.availableDomains.length} selected',
            style: const TextStyle(
              color: UniSyncColors.textMuted,
              fontSize: 11, fontWeight: FontWeight.w500)),
        ),

        Expanded(
          child: SingleChildScrollView(
            controller: ctrl,
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            child: Wrap(spacing: 10, runSpacing: 10,
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
                          ? UniSyncColors.accent.withOpacity(0.12)
                          : UniSyncColors.surfaceCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: active
                            ? UniSyncColors.accent.withOpacity(0.5)
                            : UniSyncColors.border,
                        width: active ? 1.5 : 1,
                      ),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 7, height: 7,
                        decoration: BoxDecoration(
                          color: active
                              ? UniSyncColors.accent
                              : UniSyncColors.border,
                          shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(domain, style: TextStyle(
                        fontSize: 13,
                        fontWeight: active
                            ? FontWeight.w600 : FontWeight.w400,
                        color: active
                            ? UniSyncColors.accent
                            : UniSyncColors.textSecondary,
                      )),
                    ]),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        Container(
          color: UniSyncColors.backgroundSecondary,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: NeoPopButton(
            color: UniSyncColors.accent,
            bottomShadowColor: UniSyncColors.backgroundPrimary,
            rightShadowColor: UniSyncColors.backgroundPrimary,
            depth: 4,
            buttonPosition: Position.fullBottom,
            onTapUp: () =>
                Navigator.of(context).pop(_selected.toList()..sort()),
            onTapDown: () {},
            child: const SizedBox(height: 48,
              child: Center(child: Text('Apply',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                      color: UniSyncColors.buttonPrimaryFg,
                      letterSpacing: 0.2)))),
          ),
        ),
      ]),
    );
  }
}