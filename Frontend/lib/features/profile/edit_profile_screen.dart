import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neopop/neopop.dart';
import 'package:routemaster/routemaster.dart';
import 'package:UniSync/app/providers.dart';
import 'package:UniSync/constants/constant.dart';
import 'package:UniSync/features/auth/auth_repository.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _collegeController = TextEditingController();
  final _bioController = TextEditingController();
  int? _selectedSemester;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider);
    _nameController.text = user?.name ?? '';
    _collegeController.text = user?.collegeName ?? '';
    _bioController.text = user?.about ?? '';
    _selectedSemester = user?.semester;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _collegeController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  int _calculateYear(int semester) => ((semester + 1) ~/ 2);

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: UniSyncColors.textMuted,
        fontSize: 13,
      ),
      filled: true,
      fillColor: UniSyncColors.surfaceCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: UniSyncColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: UniSyncColors.accent),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: UniSyncColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: UniSyncColors.error),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _selectedSemester == null) return;

    setState(() => _saving = true);
    final repo = ref.read(AuthRepositoryProvider);
    final updatedUser = await repo.updateProfile(
      name: _nameController.text.trim(),
      collegeName: _collegeController.text.trim(),
      semester: _selectedSemester!,
      year: _calculateYear(_selectedSemester!),
      about: _bioController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _saving = false);

    if (updatedUser == null) return;

    ref.read(userProvider.notifier).state = updatedUser;
    Routemaster.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UniSyncColors.backgroundPrimary,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: UniSyncColors.backgroundSecondary,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  NeoPopButton(
                    color: UniSyncColors.surfaceCard,
                    bottomShadowColor: UniSyncColors.border,
                    rightShadowColor: UniSyncColors.border,
                    depth: 3,
                    onTapUp: () => Routemaster.of(context).pop(),
                    onTapDown: () {},
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Center(
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 15,
                          color: UniSyncColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '#PROFILE',
                          style: TextStyle(
                            color: UniSyncColors.accent,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: 'Personal ',
                                style: TextStyle(
                                  color: UniSyncColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              TextSpan(
                                text: 'info',
                                style: TextStyle(
                                  color: UniSyncColors.accent,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Update name, semester, college, and bio',
                          style: TextStyle(
                            color: UniSyncColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _EditLabel('Name'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: UniSyncColors.textPrimary),
                        cursorColor: UniSyncColors.accent,
                        decoration: _inputDecoration('Enter your name'),
                        validator: (value) {
                          if (value == null || value.trim().length < 3) {
                            return 'Enter a valid name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      const _EditLabel('Semester'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: List.generate(8, (index) {
                          final semester = index + 1;
                          final selected = _selectedSemester == semester;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedSemester = semester),
                            child: Container(
                              width: 66,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: selected
                                    ? UniSyncColors.accent
                                    : UniSyncColors.surfaceCard,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected
                                      ? UniSyncColors.accent
                                      : UniSyncColors.border,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '$semester',
                                    style: TextStyle(
                                      color: selected
                                          ? UniSyncColors.buttonPrimaryFg
                                          : UniSyncColors.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    'sem',
                                    style: TextStyle(
                                      color: selected
                                          ? UniSyncColors.buttonPrimaryFg.withOpacity(0.8)
                                          : UniSyncColors.textMuted,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 18),
                      const _EditLabel('College'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _collegeController,
                        style: const TextStyle(color: UniSyncColors.textPrimary),
                        cursorColor: UniSyncColors.accent,
                        decoration: _inputDecoration('Enter your college'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter your college';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      const _EditLabel('Bio'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _bioController,
                        maxLines: 5,
                        style: const TextStyle(color: UniSyncColors.textPrimary),
                        cursorColor: UniSyncColors.accent,
                        decoration: _inputDecoration('Write something about yourself'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: NeoPopButton(
          color: UniSyncColors.accent,
          bottomShadowColor: UniSyncColors.backgroundPrimary,
          rightShadowColor: UniSyncColors.backgroundPrimary,
          depth: 4,
          onTapUp: _saving ? null : _saveProfile,
          onTapDown: () {},
          child: SizedBox(
            height:100,
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: UniSyncColors.buttonPrimaryFg,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          color: UniSyncColors.buttonPrimaryFg,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
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

class _EditLabel extends StatelessWidget {
  const _EditLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: UniSyncColors.textPrimary,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
