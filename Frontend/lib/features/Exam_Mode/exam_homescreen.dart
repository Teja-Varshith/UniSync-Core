import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:routemaster/routemaster.dart';
import 'package:unisync/app/providers.dart';
import 'package:unisync/constants/constant.dart';
import 'package:unisync/features/Exam_Mode/controller/exam_controller.dart';
import 'package:unisync/features/Exam_Mode/doubts_screen.dart';
import 'package:unisync/features/Exam_Mode/models/exam_subject_model.dart';
import 'package:unisync/features/Exam_Mode/repository/exam_repository.dart';
import 'package:unisync/features/Exam_Mode/subject_detail_screen.dart';
import 'package:unisync/features/services/appMode.dart';
import 'package:unisync/models/user_model.dart';
import 'package:unisync/storage/secure_storage.dart';

class ExamHomescreen extends ConsumerStatefulWidget {
  const ExamHomescreen({super.key});

  @override
  ConsumerState<ExamHomescreen> createState() => _ExamHomescreenState();
}

class _ExamHomescreenState extends ConsumerState<ExamHomescreen> {
  bool _checkedLogin = false;
  String _searchText = '';
  int? _selectedSemester;
  int _currentNavIndex = 0;
  final GlobalKey<_ExamFlashCardsScreenState> _flashCardsKey =
      GlobalKey<_ExamFlashCardsScreenState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userSemester = ref.read(userProvider)?.semester;
    _selectedSemester ??= (userSemester != null && userSemester > 0)
        ? userSemester
        : 1;
    if (!_checkedLogin) {
      _checkedLogin = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkCampXLogin();
      });
    }
  }

  void _checkCampXLogin() {
    final user = ref.read(userProvider);
    if (user == null) return;
    if (user.campXUsername == null || user.campXPassword == null) {
      _showCampXLoginDialog();
    }
  }

  Future<void> _syncUserToFirebase(UserModel user) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(firebaseUser.uid)
        .set(
      {
        ...user.toMap(),
        'firebaseUid': firebaseUser.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  void _showCampXLoginDialog() {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    bool isPasswordVisible = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> handleLogin() async {
              if (!formKey.currentState!.validate()) return;

              setDialogState(() => isLoading = true);

              try {
                final username = usernameController.text.trim();
                final password = passwordController.text.trim();

                // CampX login API
                final url = Uri.parse(anyUrl);
                final body = {
                  "loginId": username,
                  "password": password,
                  "deviceType": "mobile",
                  "clientName": "Unknown",
                  "os": "Android",
                  "osVersion": "15",
                  "loginType": "USER"
                };

                final response = await http.post(
                  url,
                  headers: {
                    'Content-Type': 'application/json',
                    'user-agent': 'ANDROID',
                    'x-tenant-id': '',
                    'x-institution-code': '',
                  },
                  body: jsonEncode(body),
                );

                final jsonData = jsonDecode(response.body);
                final accessToken = jsonData['session']?['token'];
                if (accessToken == null) {
                  throw Exception("Invalid credentials");
                }

                final institutionCode =
                    jsonData['session']['institutionCode'];
                final tenantId = jsonData['session']['subDomain'];

                await SecureStorageService()
                    .setIds(tenantId, institutionCode);

                // Update local user state
                final currentUser = ref.read(userProvider);
                final updatedUser = currentUser!.copyWith(
                  cookie: accessToken,
                  institutionCode: institutionCode,
                  campXPassword: password,
                  campXUsername: username,
                  tenantId: tenantId,
                );
                ref.read(userProvider.notifier).state = updatedUser;

                // Persist to backend / Firebase
                final dio = Dio();
                final backendRes = await dio.post(
                  "$BASE_URI/auth/updateTenantDetails",
                  data: {
                    "emailId": currentUser.emailId,
                    "accessToken": accessToken,
                    "tenantId": tenantId,
                    "password": password,
                    "institutionCode": institutionCode,
                    "campXUsername": username,
                  },
                );

                  final backendUserMap =
                    backendRes.data is Map<String, dynamic>
                      ? (backendRes.data['user'] as Map<String, dynamic>?)
                      : null;
                  final persistedUser = backendUserMap != null
                    ? UserModel.fromMap(backendUserMap)
                    : updatedUser;

                  ref.read(userProvider.notifier).state = persistedUser;
                  await _syncUserToFirebase(persistedUser);

                if (ctx.mounted) Navigator.of(ctx).pop();

                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('CampX login successful!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                setDialogState(() => isLoading = false);
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text('Login failed: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.school, color: Colors.amber),
                  SizedBox(width: 8),
                  Text(
                    'CampX Login',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Sign in with your CampX credentials to access exam mode.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        labelText: 'JNTU No / Email',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter your username'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: passwordController,
                      obscureText: !isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () {
                            setDialogState(() {
                              isPasswordVisible = !isPasswordVisible;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter your password';
                        }
                        if (v.length < 3) return 'Password too short';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isLoading ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Skip'),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Login'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showAddSubjectForm(int defaultSemester) async {
    final messenger = ScaffoldMessenger.of(this.context);
    final titleController = TextEditingController();
    final codeController = TextEditingController();
    final descriptionController = TextEditingController();
    final syllabusController = TextEditingController();
    final pyqController = TextEditingController();
    final videosController = TextEditingController();
    final cheatsheetController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    int semester = defaultSemester;
    bool isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFFCF7),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
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
                        const Text(
                          'Add New Subject',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: titleController,
                          decoration: _subjectInput('Subject title'),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Subject title is required'
                              : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: codeController,
                          decoration: _subjectInput('Subject code (ex: CSEN3011)'),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Subject code is required'
                              : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: descriptionController,
                          maxLines: 2,
                          decoration: _subjectInput('Description'),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Description is required'
                              : null,
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<int>(
                          value: semester,
                          decoration: _subjectInput('Semester'),
                          items: List.generate(
                            8,
                            (index) => DropdownMenuItem<int>(
                              value: index + 1,
                              child: Text('Semester ${index + 1}'),
                            ),
                          ),
                          onChanged: (value) {
                            if (value != null) {
                              setSheetState(() {
                                semester = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: syllabusController,
                          minLines: 2,
                          maxLines: 4,
                          decoration: _subjectInput('Syllabus units (one per line)'),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: pyqController,
                          minLines: 2,
                          maxLines: 4,
                          decoration: _subjectInput('PYQs (title|pdfUrl per line)'),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: cheatsheetController,
                          decoration: _subjectInput('Cheatsheet URL (optional)'),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: videosController,
                          minLines: 2,
                          maxLines: 4,
                          decoration: _subjectInput('Videos (title|youtubeUrl per line)'),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) return;
                                    setSheetState(() => isSaving = true);
                                    try {
                                      await ref.read(examRepositoryProvider).addExamSubject(
                                            title: titleController.text.trim(),
                                            code: codeController.text.trim(),
                                            description: descriptionController.text.trim(),
                                            semester: semester,
                                            syllabusUnits: _splitLines(syllabusController.text),
                                            pyqs: _parseMapLines(pyqController.text),
                                            videoLinks: _parseMapLines(videosController.text),
                                            cheatsheetUrl: cheatsheetController.text.trim().isEmpty
                                                ? null
                                                : cheatsheetController.text.trim(),
                                          );
                                      if (ctx.mounted) {
                                        Navigator.of(ctx).pop();
                                      }
                                      if (!mounted) return;
                                      messenger.showSnackBar(
                                        const SnackBar(content: Text('Subject added successfully.')),
                                      );
                                    } catch (error) {
                                      if (ctx.mounted) {
                                        setSheetState(() => isSaving = false);
                                      }
                                      if (!mounted) return;
                                      messenger.showSnackBar(
                                        SnackBar(content: Text('Failed to add subject: $error')),
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
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Add Subject'),
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
      },
    );

    titleController.dispose();
    codeController.dispose();
    descriptionController.dispose();
    syllabusController.dispose();
    pyqController.dispose();
    videosController.dispose();
    cheatsheetController.dispose();
  }

  Future<void> _showAddAuthorForm() async {
    final messenger = ScaffoldMessenger.of(this.context);
    final nameController = TextEditingController();
    final writtenSubjectsController = TextEditingController();
    final importantQuestionsController = TextEditingController();
    final productIdController = TextEditingController();
    final displayPriceController = TextEditingController(text: 'Rs 0');
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFFCF7),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
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
                        const Text(
                          'Add New Author',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: nameController,
                          decoration: _subjectInput('Author name'),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Author name is required'
                              : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: writtenSubjectsController,
                          minLines: 3,
                          maxLines: 6,
                          decoration: _subjectInput('Written subjects (SUBJECTCODE|samplePdfUrl per line)'),
                          validator: (v) => (v == null || _parseMapLines(v).isEmpty)
                              ? 'Add at least one subject mapping'
                              : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: importantQuestionsController,
                          minLines: 4,
                          maxLines: 8,
                          decoration: _subjectInput(
                            'Important Q&A (SUBJECTCODE|Question|<p>Answer HTML</p> per line)',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: productIdController,
                          decoration: _subjectInput('Product ID (optional)'),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: displayPriceController,
                          decoration: _subjectInput('Display price (ex: Rs 0)'),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) return;
                                    setSheetState(() => isSaving = true);
                                    try {
                                      final productId = productIdController.text.trim();
                                      final displayPrice = displayPriceController.text.trim();
                                      await ref.read(examRepositoryProvider).addAuthor(
                                            name: nameController.text.trim(),
                                            writtenSubjects: _parseMapLines(
                                              writtenSubjectsController.text,
                                            ),
                                            subjectImportantQuestions:
                                                _parseImportantQuestionLines(
                                              importantQuestionsController.text,
                                            ),
                                            productId: productId.isEmpty ? null : productId,
                                            displayPrice: displayPrice.isEmpty ? 'Rs 0' : displayPrice,
                                          );
                                      if (ctx.mounted) {
                                        Navigator.of(ctx).pop();
                                      }
                                      if (!mounted) return;
                                      messenger.showSnackBar(
                                        const SnackBar(content: Text('Author added successfully.')),
                                      );
                                    } catch (error) {
                                      if (ctx.mounted) {
                                        setSheetState(() => isSaving = false);
                                      }
                                      if (!mounted) return;
                                      messenger.showSnackBar(
                                        SnackBar(content: Text('Failed to add author: $error')),
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
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Add Author'),
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
      },
    );

    nameController.dispose();
    writtenSubjectsController.dispose();
    importantQuestionsController.dispose();
    productIdController.dispose();
    displayPriceController.dispose();
  }

  Map<String, List<Map<String, String>>> _parseImportantQuestionLines(String value) {
    final result = <String, List<Map<String, String>>>{};

    for (final line in value.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final parts = trimmed.split('|');
      if (parts.length < 3) continue;

      final subjectCode = parts[0].trim();
      final question = parts[1].trim();
      final answerHtml = parts.sublist(2).join('|').trim();
      if (subjectCode.isEmpty || question.isEmpty || answerHtml.isEmpty) continue;

      result.putIfAbsent(subjectCode, () => <Map<String, String>>[]);
      result[subjectCode]!.add({
        'question': question,
        'answerHtml': answerHtml,
      });
    }

    return result;
  }

  Future<void> _showAddDataOptions(int defaultSemester) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          decoration: const BoxDecoration(
            color: Color(0xFFFFFCF7),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD6D3D1),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Add Exam Data',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                tileColor: Colors.white,
                leading: const Icon(Icons.menu_book_rounded),
                title: const Text('Add Subject'),
                subtitle: const Text('Create a new exam subject document'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showAddSubjectForm(defaultSemester);
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                tileColor: Colors.white,
                leading: const Icon(Icons.person_outline_rounded),
                title: const Text('Add Author'),
                subtitle: const Text('Create an author with subject mappings'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showAddAuthorForm();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  List<String> _splitLines(String value) {
    return value
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  Map<String, String> _parseMapLines(String value) {
    final result = <String, String>{};
    for (final line in value.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final parts = trimmed.split('|');
      if (parts.length < 2) continue;
      result[parts.first.trim()] = parts.sublist(1).join('|').trim();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final userSemester = (user?.semester ?? 1) <= 0 ? 1 : (user?.semester ?? 1);
    final activeSemester = _selectedSemester ?? userSemester;
    final isLoggedIn =
        user?.campXUsername != null && user?.campXPassword != null;
    final subjectsAsync = ref.watch(examSubjectsProvider(activeSemester));

    return WillPopScope(
      onWillPop: _handleBackPressed,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F4EE),
        // floatingActionButton: isLoggedIn && _currentNavIndex == 0
        //     ? FloatingActionButton.extended(
        //       onPressed: () => _showAddDataOptions(activeSemester),
        //         backgroundColor: const Color(0xFF1C1917),
        //         foregroundColor: Colors.white,
        //         icon: const Icon(Icons.add),
        //         label: const Text('Add Data'),
        //       )
        //     : null,
        body: IndexedStack(
          index: _currentNavIndex,
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  children: [
                    _ExamHomeHeader(user: user, ref: ref),
                    const SizedBox(height: 10),
                    Expanded(
                      child: isLoggedIn
                          ? subjectsAsync.when(
              data: (subjects) {
                final filtered = subjects
                    .where(
                      (subject) =>
                          subject.title
                              .toLowerCase()
                              .contains(_searchText.toLowerCase()) ||
                          subject.code
                              .toLowerCase()
                              .contains(_searchText.toLowerCase()),
                    )
                    .toList();

                final totalResources = _resourceCount(filtered);
                final authorOpportunities = _opportunityCount(filtered);

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(examSubjectsProvider(activeSemester));
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
                    children: [
                      _ExamHero(
                        semester: activeSemester,
                        userName: user?.name ?? 'Student',
                        resourceCount: totalResources,
                        subjectCount: filtered.length,
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE7E5E4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.school_outlined,
                                  color: Color(0xFF57534E),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Select Semester',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1C1917),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'Default: Sem $userSemester',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF78716C),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFDDE3EA)),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x14000000),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: activeSemester,
                                  isExpanded: true,
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Color(0xFF334155),
                                  ),
                                  items: List.generate(
                                    8,
                                    (index) => DropdownMenuItem<int>(
                                      value: index + 1,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 28,
                                            height: 28,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE2E8F0),
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              '${index + 1}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF1E293B),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Semester ${index + 1}',
                                            style: const TextStyle(fontWeight: FontWeight.w700),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() {
                                      _selectedSemester = value;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Search by subject name or code',
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchText = value.trim();
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      if (filtered.isEmpty)
                        const _EmptyStateCard(
                          title: 'No subjects found for this semester',
                          subtitle:
                              'Try another semester or clear search. Ask your admin to add subjects in Firebase.',
                        )
                      else
                        ...filtered.map(
                          (subject) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _SubjectImpactCard(
                              subject: subject,
                              onOpen: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => SubjectDetailScreen(
                                      subjectId: subject.id,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      _AuthorOpportunityCard(
                        opportunities: authorOpportunities,
                        onLearnMore: _showAuthorOpportunityBottomSheet,
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Unable to load subjects: $error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              )
                      : _LoginRequiredView(onLoginTap: _showCampXLoginDialog),
                    ),
                  ],
                ),
              ),
            ),
            const ExamDoubtsScreen(),
            _ExamFlashCardsScreen(
              key: _flashCardsKey,
              isLoggedIn: isLoggedIn,
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            height: 72,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBottomNavItem(
                    icon: Icons.menu_book_rounded,
                    label: 'Exam',
                    index: 0,
                  ),
                  _buildBottomNavItem(
                    icon: Icons.forum_rounded,
                    label: 'Doubts',
                    index: 1,
                  ),
                  _buildBottomNavItem(
                    icon: Icons.style_rounded,
                    label: 'Flash Cards',
                    index: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _handleBackPressed() async {
    if (_currentNavIndex == 2) {
      final shouldLeaveFlashcards =
          await _flashCardsKey.currentState?.handleBack() ?? true;
      if (!shouldLeaveFlashcards) {
        return false;
      }
      setState(() {
        _currentNavIndex = 0;
      });
      return false;
    }

    if (_currentNavIndex != 0) {
      setState(() {
        _currentNavIndex = 0;
      });
      return false;
    }

    return true;
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isActive = _currentNavIndex == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _currentNavIndex = index;
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 26,
            color: isActive ? const Color(0xFF6C5CE7) : Colors.grey.shade400,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? const Color(0xFF6C5CE7) : Colors.grey.shade400,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  int _resourceCount(List<ExamSubjectModel> subjects) {
    var total = 0;
    for (final subject in subjects) {
      total += subject.pyqs.length;
      if ((subject.cheatsheetUrl ?? '').trim().isNotEmpty) {
        total += 1;
      }
    }
    return total;
  }

  int _opportunityCount(List<ExamSubjectModel> subjects) {
    return subjects.where((subject) {
      final hasCheatsheet = (subject.cheatsheetUrl ?? '').trim().isNotEmpty;
      return subject.pyqs.length < 2 || !hasCheatsheet;
    }).length;
  }

  void _showAuthorOpportunityBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6D3D1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Become A Student Author',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              const Text(
                'Publish unit-wise important questions and exam hacks. Build your personal academic brand and earn when students purchase your bundles.',
                style: TextStyle(height: 1.4),
              ),
              const SizedBox(height: 14),
              const _InfoPill(text: 'Step 1: Pick a subject where resources are low'),
              const SizedBox(height: 8),
              const _InfoPill(text: 'Step 2: Upload sample PDF + quality checklist'),
              const SizedBox(height: 8),
              const _InfoPill(text: 'Step 3: Get verified by admin (web panel)'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Author onboarding is managed from the web admin. Keep your samples ready.',
                        ),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1C1917),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Got It'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

InputDecoration _subjectInput(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE7E5E4)),
    ),
  );
}

class _ExamHero extends StatelessWidget {
  final int semester;
  final String userName;
  final int resourceCount;
  final int subjectCount;

  const _ExamHero({
    required this.semester,
    required this.userName,
    required this.resourceCount,
    required this.subjectCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hi $userName',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Semester $semester prep hub: track readiness, open PYQs fast, and focus where gaps are highest.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricBox(
                  label: 'Resources',
                  value: '$resourceCount',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricBox(
                  label: 'Subjects',
                  value: '$subjectCount',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;

  const _MetricBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamHomeHeader extends StatelessWidget {
  final UserModel? user;
  final WidgetRef ref;

  const _ExamHomeHeader({required this.user, required this.ref});

  @override
  Widget build(BuildContext context) {
    final currentUser = user;

    return Row(
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '# Exam',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Get Semester Ready',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const Spacer(),
        AvatarSlideToggle(
          currentMode: ref.read(AppModeProvider),
          menu: const [
            AppMode.exam,
            AppMode.campus,
            AppMode.career,
            AppMode.builder,
          ],
          user: currentUser ??
              UserModel(
                name: 'Student',
                profileComplete: false,
                emailId: 'unknown@unisync.local',
              ),
          onModeChanged: (mode) {
            if (mode == AppMode.career) {
              Routemaster.of(context).replace('/carrer');
              ref.read(AppModeProvider.notifier).state = AppMode.career;
            }
            if (mode == AppMode.builder) {
              Routemaster.of(context).replace('/builderHomeScreen');
              ref.read(AppModeProvider.notifier).state = AppMode.builder;
            }
            if (mode == AppMode.exam) {
              Routemaster.of(context).replace('/examHomescreen');
              ref.read(AppModeProvider.notifier).state = AppMode.exam;
            }
            if (mode == AppMode.campus) {
              Routemaster.of(context).replace('/');
              ref.read(AppModeProvider.notifier).state = AppMode.campus;
            }
          },
        ),
      ],
    );
  }
}

class _AuthorOpportunityCard extends StatelessWidget {
  final int opportunities;
  final VoidCallback onLearnMore;

  const _AuthorOpportunityCard({
    required this.opportunities,
    required this.onLearnMore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F5EE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFC2E5CC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: Color(0xFF166534)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$opportunities subjects need better resources',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Color(0xFF14532D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Great chance for student authors to publish quality notes and important-question packs.',
            style: TextStyle(color: Color(0xFF166534), height: 1.35),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onLearnMore,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF14532D),
              padding: const EdgeInsets.symmetric(horizontal: 0),
            ),
            child: const Text('How student authors earn ->'),
          ),
        ],
      ),
    );
  }
}

class _SubjectImpactCard extends StatelessWidget {
  final ExamSubjectModel subject;
  final VoidCallback onOpen;

  const _SubjectImpactCard({
    required this.subject,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final hasCheatsheet = (subject.cheatsheetUrl ?? '').trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7E5E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1C1917),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subject.code,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF57534E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subject.description.isEmpty
                ? 'No description available yet.'
                : subject.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF57534E), height: 1.3),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TagPill(label: 'Units ${subject.syllabusUnits.length}'),
              _TagPill(label: 'PYQs ${subject.pyqs.length}'),
              _TagPill(label: hasCheatsheet ? 'Cheatsheet Yes' : 'Cheatsheet No'),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onOpen,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1C1917),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Open Study Hub'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  final String label;

  const _TagPill({required this.label});

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
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF44403C),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String text;

  const _InfoPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyStateCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7E5E4)),
      ),
      child: Column(
        children: [
          const Icon(Icons.menu_book_outlined, size: 40, color: Color(0xFF78716C)),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF57534E), height: 1.3),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LoginRequiredView extends StatelessWidget {
  final VoidCallback onLoginTap;

  const _LoginRequiredView({required this.onLoginTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 72, color: Color(0xFF78716C)),
            const SizedBox(height: 14),
            const Text(
              'Connect CampX To Unlock Exam Prep',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'You will get semester-wise PYQs, unit planning, and student author resources tailored to your campus profile.',
              style: TextStyle(color: Color(0xFF57534E), height: 1.35),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onLoginTap,
              icon: const Icon(Icons.login),
              label: const Text('Login To CampX'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1C1917),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExamFlashCardsScreen extends StatefulWidget {
  final bool isLoggedIn;

  const _ExamFlashCardsScreen({
    super.key,
    required this.isLoggedIn,
  });

  @override
  State<_ExamFlashCardsScreen> createState() => _ExamFlashCardsScreenState();
}

class _ExamFlashCardsScreenState extends State<_ExamFlashCardsScreen> {
  static const String _flashCardsUrl = 'https://flashcards-theta-five.vercel.app/';
  late final WebViewController _controller;
  double _progress = 0;

  @override
  void initState() {
    super.initState();

    late final PlatformWebViewControllerCreationParams params;

    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (!mounted) return;
            setState(() {
              _progress = progress / 100;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(_flashCardsUrl));

    if (_controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      final androidController =
          _controller.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);
      androidController.setOnShowFileSelector((_) async {
        final result = await FilePicker.platform.pickFiles(
          allowMultiple: false,
          withData: false,
          type: FileType.any,
        );

        if (result == null || result.files.isEmpty) {
          return <String>[];
        }

        return result.files
            .map((file) => file.path)
            .whereType<String>()
            .toList();
      });
    }
  }

  Future<bool> handleBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoggedIn) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Login to CampX to access semester flash cards.',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    return SafeArea(
      child: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_progress < 1)
            LinearProgressIndicator(value: _progress),
        ],
      ),
    );
  }
}
