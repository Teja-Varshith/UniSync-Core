import 'dart:convert';
import 'package:UniSync/constants/constant.dart';
import 'package:UniSync/models/portifolo_model.dart';
import 'package:UniSync/app/providers.dart';
import 'package:UniSync/features/Carrer_Mode/providers/portfolio_provider.dart';
import 'package:UniSync/features/Carrer_Mode/services/portfolio_repository.dart';
import 'package:UniSync/features/Carrer_Mode/services/resume_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

// ── Entry widget ──────────────────────────────────────────────────────────────
class PortfolioBuilder extends ConsumerStatefulWidget {
  const PortfolioBuilder({super.key});

  @override
  ConsumerState<PortfolioBuilder> createState() => _PortfolioBuilderState();
}

class _PortfolioBuilderState extends ConsumerState<PortfolioBuilder> {
  bool _saving = false;

  Future<void> _onRefresh() async {
    ref.invalidate(portfolioProvider);
    await ref.read(portfolioProvider.future);
  }

  Future<void> _save(PortifoloModel updated) async {
    final user = ref.read(userProvider);
    if (user == null || user.id == null) return;

    setState(() => _saving = true);
    try {
      final repo = ref.read(portfolioRepositoryProvider);
      await repo.savePortfolio(user.id!, updated);
      ref.invalidate(portfolioProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Edit helpers ────────────────────────────────────────────────────────────

  void _editProfile(PortifoloModel data) {
    final roleCtrl = TextEditingController(text: data.role);
    final taglineCtrl = TextEditingController(text: data.tagline);
    final phoneCtrl = TextEditingController(text: data.phone);

    _showSheet(
      title: 'Edit Profile',
      children: [
        _SheetField(controller: roleCtrl, label: 'Role / Title'),
        _SheetField(controller: taglineCtrl, label: 'Tagline'),
        _SheetField(controller: phoneCtrl, label: 'Phone'),
      ],
      onSave: () {
        Navigator.pop(context);
        _save(data.copyWith(
          role: roleCtrl.text.trim(),
          tagline: taglineCtrl.text.trim(),
          phone: phoneCtrl.text.trim(),
        ));
      },
    );
  }

  void _editAbout(PortifoloModel data) {
    final ctrl = TextEditingController(text: data.about);

    _showSheet(
      title: 'Edit About',
      children: [
        _SheetField(controller: ctrl, label: 'About', maxLines: 5),
      ],
      onSave: () {
        Navigator.pop(context);
        _save(data.copyWith(about: ctrl.text.trim()));
      },
    );
  }

  void _editProject(PortifoloModel data, {int? index}) {
    final isNew = index == null;
    final project = isNew ? const ProjectItem(name: '', description: '') : data.projects[index];

    final nameCtrl = TextEditingController(text: project.name);
    final descCtrl = TextEditingController(text: project.description);
    final tagsCtrl = TextEditingController(text: project.tags.join(', '));

    _showSheet(
      title: isNew ? 'Add Project' : 'Edit Project',
      children: [
        _SheetField(controller: nameCtrl, label: 'Project Name'),
        _SheetField(controller: descCtrl, label: 'Description', maxLines: 3),
        _SheetField(controller: tagsCtrl, label: 'Tags (comma separated)'),
      ],
      onSave: () {
        Navigator.pop(context);
        final updated = ProjectItem(
          name: nameCtrl.text.trim(),
          description: descCtrl.text.trim(),
          tags: tagsCtrl.text
              .split(',')
              .map((t) => t.trim())
              .where((t) => t.isNotEmpty)
              .toList(),
        );
        final projects = List<ProjectItem>.from(data.projects);
        if (isNew) {
          projects.add(updated);
        } else {
          projects[index] = updated;
        }
        _save(data.copyWith(projects: projects));
      },
    );
  }

  void _editSkills(PortifoloModel data) {
    final skillsText = data.skills.map((s) => s.name).join(', ');
    final ctrl = TextEditingController(text: skillsText);
    final highlightCtrl = TextEditingController(
      text: data.skills.where((s) => s.isHighlighted).map((s) => s.name).join(', '),
    );

    _showSheet(
      title: 'Edit Skills',
      children: [
        _SheetField(controller: ctrl, label: 'All Skills (comma separated)', maxLines: 3),
        _SheetField(controller: highlightCtrl, label: 'Highlighted Skills (comma separated)'),
      ],
      onSave: () {
        Navigator.pop(context);
        final highlighted = highlightCtrl.text
            .split(',')
            .map((t) => t.trim().toLowerCase())
            .where((t) => t.isNotEmpty)
            .toSet();

        final skills = ctrl.text
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .map((name) => SkillItem(
                  name: name,
                  isHighlighted: highlighted.contains(name.toLowerCase()),
                ))
            .toList();

        _save(data.copyWith(skills: skills));
      },
    );
  }

  void _editExperience(PortifoloModel data, {int? index}) {
    final isNew = index == null;
    final exp = isNew
        ? const ExperienceItem(role: '', org: '')
        : data.experience[index];

    final roleCtrl = TextEditingController(text: exp.role);
    final orgCtrl = TextEditingController(text: exp.org);
    final dateCtrl = TextEditingController(text: exp.date);
    bool isActive = exp.isActive;

    _showSheet(
      title: isNew ? 'Add Experience' : 'Edit Experience',
      children: [
        _SheetField(controller: roleCtrl, label: 'Role'),
        _SheetField(controller: orgCtrl, label: 'Organisation'),
        _SheetField(controller: dateCtrl, label: 'Date Range (e.g. Jan 2025 – Present)'),
        StatefulBuilder(
          builder: (ctx, setInner) => SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            activeColor: UniSyncColors.accent,
            title: const Text('Currently Active',
                style: TextStyle(fontSize: 13, color: UniSyncColors.textSecondary)),
            value: isActive,
            onChanged: (v) => setInner(() => isActive = v),
          ),
        ),
      ],
      onSave: () {
        Navigator.pop(context);
        final updated = ExperienceItem(
          role: roleCtrl.text.trim(),
          org: orgCtrl.text.trim(),
          date: dateCtrl.text.trim(),
          isActive: isActive,
        );
        final list = List<ExperienceItem>.from(data.experience);
        if (isNew) {
          list.add(updated);
        } else {
          list[index] = updated;
        }
        _save(data.copyWith(experience: list));
      },
    );
  }

  void _editAchievement(PortifoloModel data, {int? index}) {
    final isNew = index == null;
    final item = isNew
        ? const AchievementItem(title: '')
        : data.achievements[index];

    final titleCtrl = TextEditingController(text: item.title);
    final descCtrl = TextEditingController(text: item.description);
    final dateCtrl = TextEditingController(text: item.date);

    _showSheet(
      title: isNew ? 'Add Achievement' : 'Edit Achievement',
      children: [
        _SheetField(controller: titleCtrl, label: 'Title'),
        _SheetField(controller: descCtrl, label: 'Description', maxLines: 3),
        _SheetField(controller: dateCtrl, label: 'Date (e.g. Mar 2025)'),
      ],
      onSave: () {
        Navigator.pop(context);
        final updated = AchievementItem(
          title: titleCtrl.text.trim(),
          description: descCtrl.text.trim(),
          date: dateCtrl.text.trim(),
        );
        final list = List<AchievementItem>.from(data.achievements);
        if (isNew) {
          list.add(updated);
        } else {
          list[index] = updated;
        }
        _save(data.copyWith(achievements: list));
      },
    );
  }

  void _editCertification(PortifoloModel data, {int? index}) {
    final isNew = index == null;
    final item = isNew
        ? const CertificationItem(name: '', issuer: '')
        : data.certifications[index];

    final nameCtrl = TextEditingController(text: item.name);
    final issuerCtrl = TextEditingController(text: item.issuer);
    final dateCtrl = TextEditingController(text: item.date);
    final urlCtrl = TextEditingController(text: item.credentialUrl ?? '');

    _showSheet(
      title: isNew ? 'Add Certification' : 'Edit Certification',
      children: [
        _SheetField(controller: nameCtrl, label: 'Certification Name'),
        _SheetField(controller: issuerCtrl, label: 'Issuing Organisation'),
        _SheetField(controller: dateCtrl, label: 'Date (e.g. Jan 2025)'),
        _SheetField(controller: urlCtrl, label: 'Credential URL (optional)'),
      ],
      onSave: () {
        Navigator.pop(context);
        final updated = CertificationItem(
          name: nameCtrl.text.trim(),
          issuer: issuerCtrl.text.trim(),
          date: dateCtrl.text.trim(),
          credentialUrl: urlCtrl.text.trim().isEmpty
              ? null
              : urlCtrl.text.trim(),
        );
        final list = List<CertificationItem>.from(data.certifications);
        if (isNew) {
          list.add(updated);
        } else {
          list[index] = updated;
        }
        _save(data.copyWith(certifications: list));
      },
    );
  }

  // ── Resume upload & auto-fill ───────────────────────────────────────────────

  Future<void> _uploadResume(PortifoloModel data) async {
    setState(() => _saving = true);
    try {
      // 1. Pick PDF & extract text
      final text = await ResumeService.pickAndExtractText();
      if (text == null || text.isEmpty) {
        if (mounted) setState(() => _saving = false);
        return;
      }

      // 2. Parse with Groq
      final parsed = await ResumeService.parseWithGroq(text);

      if (!mounted) return;
      setState(() => _saving = false);

      // 3. Show confirmation dialog
      final shouldApply = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: UniSyncColors.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Auto-fill from Resume?',
            style: TextStyle(
              fontFamily: 'Syne',
              fontWeight: FontWeight.w700,
              color: UniSyncColors.textPrimary,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'We extracted the following from your resume. '
                  'This will replace your current portfolio data.',
                  style: TextStyle(
                    fontSize: 13,
                    color: UniSyncColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                _PreviewRow('Role', parsed.role),
                _PreviewRow('About',
                    parsed.about.length > 80
                        ? '${parsed.about.substring(0, 80)}…'
                        : parsed.about),
                _PreviewRow('Skills',
                    parsed.skills.map((s) => s.name).join(', ')),
                _PreviewRow('Projects',
                    '${parsed.projects.length} found'),
                _PreviewRow('Experience',
                    '${parsed.experience.length} found'),
                _PreviewRow('Achievements',
                    '${parsed.achievements.length} found'),
                _PreviewRow('Certifications',
                    '${parsed.certifications.length} found'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Auto-fill'),
            ),
          ],
        ),
      );

      if (shouldApply == true) {
        // Merge: keep userId/name/email from current, apply everything else
        final merged = data.copyWith(
          role: parsed.role.isNotEmpty ? parsed.role : data.role,
          tagline: parsed.tagline.isNotEmpty ? parsed.tagline : data.tagline,
          phone: parsed.phone.isNotEmpty ? parsed.phone : data.phone,
          about: parsed.about.isNotEmpty ? parsed.about : data.about,
          projects:
              parsed.projects.isNotEmpty ? parsed.projects : data.projects,
          skills: parsed.skills.isNotEmpty ? parsed.skills : data.skills,
          experience: parsed.experience.isNotEmpty
              ? parsed.experience
              : data.experience,
          achievements: parsed.achievements.isNotEmpty
              ? parsed.achievements
              : data.achievements,
          certifications: parsed.certifications.isNotEmpty
              ? parsed.certifications
              : data.certifications,
          resumeText: text,
        );
        await _save(merged);

        // 4. Ask if user wants to generate a portfolio website
        if (mounted) {
          _generateWebsite(merged);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resume parsing failed: $e')),
        );
      }
    }
  }

  /// Auto-generate portfolio website using name as slug.
  Future<void> _generateWebsite(PortifoloModel data) async {
    final user = ref.read(userProvider);
    if (user == null || user.id == null) return;

    if (data.resumeText.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload a resume first')),
        );
      }
      return;
    }

    // Derive slug from name: "Teja Varshith" → "teja-varshith"
    final slug = data.name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-');

    if (slug.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name is required to generate portfolio')),
        );
      }
      return;
    }

    setState(() => _saving = true);
    try {
      final response = await http.post(
        Uri.parse('$BASE_URI/portifolio2/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': user.id,
          'resumeText': data.resumeText,
          'slug': slug,
        }),
      );

      // Guard: if server returns HTML instead of JSON (e.g. 404 page)
      if (response.body.trimLeft().startsWith('<')) {
        throw Exception('Server returned HTML — is the backend running?');
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && body['success'] == true) {
        final portfolioUrl = '$BACKEND_ORIGIN/me/$slug';
        await _save(data.copyWith(
          slug: slug,
          portfolioUrl: portfolioUrl,
        ));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Portfolio live at $portfolioUrl'),
              action: SnackBarAction(
                label: 'Copy',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: portfolioUrl));
                },
              ),
            ),
          );
        }
      } else {
        throw Exception(body['message'] ?? 'Generation failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Website generation failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSheet({
    required String title,
    required List<Widget> children,
    required VoidCallback onSave,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: UniSyncColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: UniSyncColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: UniSyncColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ...children,
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: UniSyncColors.accent,
                    foregroundColor: UniSyncColors.buttonPrimaryFg,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      fontFamily: 'Syne',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final portfolioAsync = ref.watch(portfolioProvider);

    return Scaffold(
      backgroundColor: UniSyncColors.backgroundPrimary,
      body: SafeArea(
        child: Stack(
          children: [
            portfolioAsync.when(
              loading: () => const _LoadingState(),
              error: (err, _) => _ErrorState(
                message: err.toString(),
                onRetry: () => ref.invalidate(portfolioProvider),
              ),
              data: (portfolio) {
                final data = portfolio ?? const PortifoloModel();
                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: UniSyncColors.accent,
                  backgroundColor: UniSyncColors.surfaceCard,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeroCard(
                          name: data.name,
                          role: data.role,
                          tagline: data.tagline,
                          email: data.email,
                          phone: data.phone,
                          completionPct: data.completionPct,
                          portfolioUrl: data.portfolioUrl,
                          slug: data.slug,
                          onEdit: () => _editProfile(data),
                          onGenerateWebsite: () => _generateWebsite(data),
                          onUploadResume: () => _uploadResume(data),
                        ),
                        const SizedBox(height: 12),
                        _CompletionBar(pct: data.completionPct),
                        const SizedBox(height: 24),
                        _SectionLabel(label: 'Profile Sections'),
                        const SizedBox(height: 12),
                        _AboutCard(
                          about: data.about,
                          onEdit: () => _editAbout(data),
                        ),
                        const SizedBox(height: 10),
                        _ProjectsCard(
                          projects: data.projects,
                          onEdit: data.projects.isNotEmpty
                              ? () => _editProject(data, index: 0)
                              : () => _editProject(data),
                          onAdd: () => _editProject(data),
                          onEditAt: (i) => _editProject(data, index: i),
                        ),
                        const SizedBox(height: 10),
                        _SkillsCard(
                          skills: data.skills,
                          onEdit: () => _editSkills(data),
                        ),
                        const SizedBox(height: 10),
                        _ExperienceCard(
                          experience: data.experience,
                          onEdit: data.experience.isNotEmpty
                              ? () => _editExperience(data, index: 0)
                              : () => _editExperience(data),
                          onAdd: () => _editExperience(data),
                          onEditAt: (i) => _editExperience(data, index: i),
                        ),
                        const SizedBox(height: 10),
                        _AchievementsCard(
                          achievements: data.achievements,
                          onEdit: data.achievements.isNotEmpty
                              ? () => _editAchievement(data, index: 0)
                              : () => _editAchievement(data),
                          onAdd: () => _editAchievement(data),
                          onEditAt: (i) => _editAchievement(data, index: i),
                        ),
                        const SizedBox(height: 10),
                        _CertificationsCard(
                          certifications: data.certifications,
                          onEdit: data.certifications.isNotEmpty
                              ? () => _editCertification(data, index: 0)
                              : () => _editCertification(data),
                          onAdd: () => _editCertification(data),
                          onEditAt: (i) => _editCertification(data, index: i),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Saving overlay
            if (_saving)
              Container(
                color: Colors.black38,
                child: const Center(
                  child: CircularProgressIndicator(color: UniSyncColors.accent),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Sheet text field ──────────────────────────────────────────────────────────
class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;

  const _SheetField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(
          fontSize: 14,
          color: UniSyncColors.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontSize: 12,
            color: UniSyncColors.textMuted,
          ),
          filled: true,
          fillColor: UniSyncColors.surfaceElevated,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: UniSyncColors.borderSubtle),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: UniSyncColors.borderSubtle),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: UniSyncColors.accent),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}

// ── Loading shimmer state ─────────────────────────────────────────────────────
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          4,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: UniSyncColors.surfaceCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: UniSyncColors.borderSubtle),
              ),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: UniSyncColors.accent,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: UniSyncColors.textDisabled),
            const SizedBox(height: 12),
            const Text(
              'Unable to load portfolio',
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: UniSyncColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: UniSyncColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: UniSyncColors.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: UniSyncColors.buttonPrimaryFg,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hero Card ─────────────────────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final String name, role, tagline, email, phone;
  final int completionPct;
  final String portfolioUrl;
  final String slug;
  final VoidCallback onEdit;
  final VoidCallback onGenerateWebsite;
  final VoidCallback onUploadResume;

  const _HeroCard({
    required this.name,
    required this.role,
    required this.tagline,
    required this.email,
    required this.phone,
    required this.completionPct,
    required this.onEdit,
    required this.onGenerateWebsite,
    required this.onUploadResume,
    this.portfolioUrl = '',
    this.slug = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: UniSyncColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: UniSyncColors.borderSubtle),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AvatarRing(
                  initials: _initials(name),
                  pct: completionPct,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? '—' : name,
                        style: const TextStyle(
                          fontFamily: 'Syne',
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: UniSyncColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              role.isEmpty ? 'Tap edit to set role' : role,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: role.isEmpty
                                    ? UniSyncColors.textDisabled
                                    : UniSyncColors.accent,
                                fontStyle: role.isEmpty
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _AiBadge(),
                        ],
                      ),
                      if (tagline.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          tagline,
                          style: const TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: UniSyncColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Edit icon top-right
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: UniSyncColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: UniSyncColors.border),
                    ),
                    child: const Icon(Icons.edit_outlined,
                        size: 14, color: UniSyncColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: UniSyncColors.divider),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                _MetaRow(
                    icon: Icons.email_outlined,
                    label: email.isEmpty ? '—' : email),
                const SizedBox(height: 6),
                _MetaRow(
                    icon: Icons.phone_outlined,
                    label: phone.isEmpty ? '—' : phone),
                if (portfolioUrl.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.parse(portfolioUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.language,
                            size: 14, color: UniSyncColors.accent),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            portfolioUrl,
                            style: const TextStyle(
                              fontSize: 12,
                              color: UniSyncColors.accent,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: onGenerateWebsite,
                          child: const Icon(Icons.refresh,
                              size: 14, color: UniSyncColors.accent),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(
                                ClipboardData(text: portfolioUrl));
                          },
                          child: const Icon(Icons.copy,
                              size: 13, color: UniSyncColors.textDisabled),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: onUploadResume,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: UniSyncColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: UniSyncColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.upload_file, size: 13,
                              color: UniSyncColors.textSecondary),
                          SizedBox(width: 6),
                          Text(
                            'Upload PDF & Recreate',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: UniSyncColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: onGenerateWebsite,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: UniSyncColors.accentSoft,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: UniSyncColors.accent.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.web, size: 13,
                              color: UniSyncColors.accent),
                          SizedBox(width: 6),
                          Text(
                            'Generate Portfolio Website',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: UniSyncColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    if (name.trim().isEmpty) return '??';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }
}

// ── Avatar with conic progress ring ──────────────────────────────────────────
class _AvatarRing extends StatelessWidget {
  final String initials;
  final int pct;

  const _AvatarRing({required this.initials, required this.pct});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(72, 72),
            painter: _RingPainter(progress: pct / 100),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: UniSyncColors.surfaceElevated,
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                fontFamily: 'Syne',
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: UniSyncColors.accent,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: UniSyncColors.accent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$pct%',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: UniSyncColors.buttonPrimaryFg,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  const _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    const strokeWidth = 3.0;
    const startAngle = -1.5707963;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = UniSyncColors.border,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      6.2831853 * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = UniSyncColors.accent,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ── AI badge ──────────────────────────────────────────────────────────────────
class _AiBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: UniSyncColors.accentSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: UniSyncColors.accent.withOpacity(0.35)),
      ),
      child: const Text(
        'AI',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: UniSyncColors.accent,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Meta row ──────────────────────────────────────────────────────────────────
class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: UniSyncColors.textDisabled),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: UniSyncColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Completion bar ────────────────────────────────────────────────────────────
class _CompletionBar extends StatelessWidget {
  final int pct;
  const _CompletionBar({required this.pct});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: UniSyncColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: UniSyncColors.borderSubtle),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_outlined,
              size: 16, color: UniSyncColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: pct / 100,
                minHeight: 4,
                backgroundColor: UniSyncColors.border,
                valueColor: const AlwaysStoppedAnimation(UniSyncColors.accent),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$pct% complete',
            style: const TextStyle(
              fontSize: 11,
              color: UniSyncColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: UniSyncColors.textDisabled,
        letterSpacing: 1.5,
      ),
    );
  }
}

// ── Reusable section card ─────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final String emoji;
  final VoidCallback onEdit;
  final VoidCallback onAiImprove;
  final Widget body;

  const _SectionCard({
    required this.title,
    required this.emoji,
    required this.onEdit,
    required this.onAiImprove,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: UniSyncColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: UniSyncColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: UniSyncColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(emoji, style: const TextStyle(fontSize: 14)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: UniSyncColors.textPrimary,
                    ),
                  ),
                ),
                _ActionButton(
                  label: 'Edit',
                  icon: Icons.edit_outlined,
                  onTap: onEdit,
                  isAccent: false,
                ),
                const SizedBox(width: 6),
                _ActionButton(
                  label: 'Improve',
                  icon: Icons.auto_awesome,
                  onTap: onAiImprove,
                  isAccent: true,
                ),
              ],
            ),
          ),
          body,
        ],
      ),
    );
  }
}

// ── Small action button ───────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isAccent;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.isAccent,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isAccent
              ? UniSyncColors.accentSoft
              : UniSyncColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isAccent
                ? UniSyncColors.accent.withOpacity(0.3)
                : UniSyncColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 11,
              color: isAccent ? UniSyncColors.accent : UniSyncColors.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isAccent
                    ? UniSyncColors.accent
                    : UniSyncColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add more button ───────────────────────────────────────────────────────────
class _AddMoreButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AddMoreButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 14),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: UniSyncColors.border,
            style: BorderStyle.solid,
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, size: 14, color: UniSyncColors.textDisabled),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: UniSyncColors.textDisabled,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── About Card ────────────────────────────────────────────────────────────────
class _AboutCard extends StatelessWidget {
  final String about;
  final VoidCallback onEdit;
  const _AboutCard({required this.about, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'About',
      emoji: '👤',
      onEdit: onEdit,
      onAiImprove: () {},
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Text(
          about.isEmpty ? 'Tap Edit to add an about section.' : about,
          style: TextStyle(
            fontSize: 13,
            color: about.isEmpty
                ? UniSyncColors.textDisabled
                : UniSyncColors.textSecondary,
            height: 1.6,
            fontStyle: about.isEmpty ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ),
    );
  }
}

// ── Projects Card ─────────────────────────────────────────────────────────────
class _ProjectsCard extends StatelessWidget {
  final List<ProjectItem> projects;
  final VoidCallback onEdit;
  final VoidCallback onAdd;
  final ValueChanged<int> onEditAt;

  const _ProjectsCard({
    required this.projects,
    required this.onEdit,
    required this.onAdd,
    required this.onEditAt,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Projects',
      emoji: '🗂️',
      onEdit: projects.isNotEmpty ? onEdit : onAdd,
      onAiImprove: () {},
      body: Column(
        children: [
          if (projects.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Text(
                'No projects added yet.',
                style: const TextStyle(
                  fontSize: 13,
                  color: UniSyncColors.textDisabled,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ...List.generate(projects.length, (i) {
            final project = projects[i];
            return GestureDetector(
              onTap: () => onEditAt(i),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: UniSyncColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: UniSyncColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: UniSyncColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        project.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: UniSyncColors.textMuted,
                          height: 1.5,
                        ),
                      ),
                      if (project.tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: project.tags
                              .map(
                                (tag) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: UniSyncColors.surfaceCard,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: UniSyncColors.borderSubtle),
                                  ),
                                  child: Text(
                                    tag,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: UniSyncColors.textDisabled,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
          _AddMoreButton(label: 'Add Project', onTap: onAdd),
        ],
      ),
    );
  }
}

// ── Skills Card ───────────────────────────────────────────────────────────────
class _SkillsCard extends StatelessWidget {
  final List<SkillItem> skills;
  final VoidCallback onEdit;
  const _SkillsCard({required this.skills, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Skills',
      emoji: '💡',
      onEdit: onEdit,
      onAiImprove: () {},
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: skills.isEmpty
            ? const Text(
                'No skills added yet.',
                style: TextStyle(
                  fontSize: 13,
                  color: UniSyncColors.textDisabled,
                  fontStyle: FontStyle.italic,
                ),
              )
            : Wrap(
                spacing: 6,
                runSpacing: 6,
                children: skills
                    .map(
                      (s) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: s.isHighlighted
                              ? UniSyncColors.accentSoft
                              : UniSyncColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: s.isHighlighted
                                ? UniSyncColors.accent.withOpacity(0.3)
                                : UniSyncColors.border,
                          ),
                        ),
                        child: Text(
                          s.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: s.isHighlighted
                                ? UniSyncColors.accent
                                : UniSyncColors.textSecondary,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
      ),
    );
  }
}

// ── Experience Card ───────────────────────────────────────────────────────────
class _ExperienceCard extends StatelessWidget {
  final List<ExperienceItem> experience;
  final VoidCallback onEdit;
  final VoidCallback onAdd;
  final ValueChanged<int> onEditAt;

  const _ExperienceCard({
    required this.experience,
    required this.onEdit,
    required this.onAdd,
    required this.onEditAt,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Experience',
      emoji: '🏢',
      onEdit: experience.isNotEmpty ? onEdit : onAdd,
      onAiImprove: () {},
      body: Column(
        children: [
          const SizedBox(height: 4),
          if (experience.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                'No experience added yet.',
                style: TextStyle(
                  fontSize: 13,
                  color: UniSyncColors.textDisabled,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ...List.generate(experience.length, (i) {
            final exp = experience[i];
            return GestureDetector(
              onTap: () => onEditAt(i),
              child: _ExpRow(
                role: exp.role,
                org: exp.org,
                date: exp.date,
                isActive: exp.isActive,
              ),
            );
          }),
          _AddMoreButton(label: 'Add Experience', onTap: onAdd),
        ],
      ),
    );
  }
}

class _ExpRow extends StatelessWidget {
  final String role, org, date;
  final bool isActive;

  const _ExpRow({
    required this.role,
    required this.org,
    required this.date,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      isActive ? UniSyncColors.accent : UniSyncColors.border,
                ),
              ),
              if (isActive)
                Container(
                  width: 1,
                  height: 28,
                  color: UniSyncColors.border,
                  margin: const EdgeInsets.only(top: 2),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isActive
                        ? UniSyncColors.textPrimary
                        : UniSyncColors.textMuted,
                  ),
                ),
                Text(
                  org,
                  style: const TextStyle(
                    fontSize: 12,
                    color: UniSyncColors.textMuted,
                  ),
                ),
                if (date.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 11,
                      color: UniSyncColors.textDisabled,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Achievements Card ─────────────────────────────────────────────────────────
class _AchievementsCard extends StatelessWidget {
  final List<AchievementItem> achievements;
  final VoidCallback onEdit;
  final VoidCallback onAdd;
  final ValueChanged<int> onEditAt;

  const _AchievementsCard({
    required this.achievements,
    required this.onEdit,
    required this.onAdd,
    required this.onEditAt,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Achievements',
      emoji: '🏆',
      onEdit: achievements.isNotEmpty ? onEdit : onAdd,
      onAiImprove: () {},
      body: Column(
        children: [
          if (achievements.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Text(
                'No achievements added yet.',
                style: TextStyle(
                  fontSize: 13,
                  color: UniSyncColors.textDisabled,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ...List.generate(achievements.length, (i) {
            final item = achievements[i];
            return GestureDetector(
              onTap: () => onEditAt(i),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: UniSyncColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: UniSyncColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.emoji_events_outlined,
                              size: 14, color: UniSyncColors.accent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: UniSyncColors.textPrimary,
                              ),
                            ),
                          ),
                          if (item.date.isNotEmpty)
                            Text(
                              item.date,
                              style: const TextStyle(
                                fontSize: 11,
                                color: UniSyncColors.textDisabled,
                              ),
                            ),
                        ],
                      ),
                      if (item.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: UniSyncColors.textMuted,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
          _AddMoreButton(label: 'Add Achievement', onTap: onAdd),
        ],
      ),
    );
  }
}

// ── Certifications Card ───────────────────────────────────────────────────────
class _CertificationsCard extends StatelessWidget {
  final List<CertificationItem> certifications;
  final VoidCallback onEdit;
  final VoidCallback onAdd;
  final ValueChanged<int> onEditAt;

  const _CertificationsCard({
    required this.certifications,
    required this.onEdit,
    required this.onAdd,
    required this.onEditAt,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Certifications',
      emoji: '📜',
      onEdit: certifications.isNotEmpty ? onEdit : onAdd,
      onAiImprove: () {},
      body: Column(
        children: [
          if (certifications.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Text(
                'No certifications added yet.',
                style: TextStyle(
                  fontSize: 13,
                  color: UniSyncColors.textDisabled,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ...List.generate(certifications.length, (i) {
            final item = certifications[i];
            return GestureDetector(
              onTap: () => onEditAt(i),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: UniSyncColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: UniSyncColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.workspace_premium_outlined,
                              size: 14, color: UniSyncColors.accent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: UniSyncColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.issuer,
                        style: const TextStyle(
                          fontSize: 12,
                          color: UniSyncColors.textMuted,
                        ),
                      ),
                      if (item.date.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.date,
                          style: const TextStyle(
                            fontSize: 11,
                            color: UniSyncColors.textDisabled,
                          ),
                        ),
                      ],
                      if (item.credentialUrl != null &&
                          item.credentialUrl!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.link,
                                size: 12, color: UniSyncColors.accent),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'View Credential',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: UniSyncColors.accent,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
          _AddMoreButton(label: 'Add Certification', onTap: onAdd),
        ],
      ),
    );
  }
}

// ── Upload Resume button ──────────────────────────────────────────────────────
class _UploadResumeButton extends StatelessWidget {
  final VoidCallback onTap;
  const _UploadResumeButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [UniSyncColors.accent, Color(0xFFF3CB21)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.upload_file, size: 18, color: UniSyncColors.darkBase),
            SizedBox(width: 8),
            Text(
              'Upload Resume & Auto-fill',
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: UniSyncColors.darkBase,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Preview row (used in auto-fill confirmation dialog) ───────────────────────
class _PreviewRow extends StatelessWidget {
  final String label;
  final String value;
  const _PreviewRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: UniSyncColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: UniSyncColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}