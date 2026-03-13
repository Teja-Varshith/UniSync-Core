import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisync/features/Exam_Mode/repository/exam_repository.dart';

Future<void> showExamAdminOptions(
  BuildContext context, {
  required VoidCallback onAddSubject,
  required VoidCallback onAddAuthor,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFFFDFBF7),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFD6D3D1),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Add Firebase Data',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              tileColor: Colors.white,
              leading: const Icon(Icons.menu_book_rounded),
              title: const Text('Add Subject'),
              subtitle: const Text('Create exam_subjects document'),
              onTap: onAddSubject,
            ),
            const SizedBox(height: 10),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              tileColor: Colors.white,
              leading: const Icon(Icons.person_outline_rounded),
              title: const Text('Add Author'),
              subtitle: const Text('Create authors document'),
              onTap: onAddAuthor,
            ),
          ],
        ),
      );
    },
  );
}

class AddSubjectSheet extends ConsumerStatefulWidget {
  const AddSubjectSheet({super.key});

  @override
  ConsumerState<AddSubjectSheet> createState() => _AddSubjectSheetState();
}

class _AddSubjectSheetState extends ConsumerState<AddSubjectSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _syllabusController = TextEditingController();
  final _pyqController = TextEditingController();
  final _cheatsheetUrlController = TextEditingController();
  int _semester = 1;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    _syllabusController.dispose();
    _pyqController.dispose();
    _cheatsheetUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ExamSheetFrame(
      title: 'Add Subject To Firebase',
      subtitle: 'Use one syllabus item per line. For PYQs, use paperType|pdfUrl per line.',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _SheetInput(
              controller: _titleController,
              label: 'Subject title',
              validator: (value) => _required(value, 'Subject title is required'),
            ),
            const SizedBox(height: 14),
            _SheetInput(
              controller: _codeController,
              label: 'Subject code',
              validator: (value) => _required(value, 'Subject code is required'),
            ),
            const SizedBox(height: 14),
            _SheetInput(
              controller: _descriptionController,
              label: 'Description',
              maxLines: 3,
              validator: (value) => _required(value, 'Description is required'),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<int>(
              value: _semester,
              decoration: _inputDecoration('Semester'),
              items: List.generate(
                8,
                (index) => DropdownMenuItem<int>(
                  value: index + 1,
                  child: Text('Semester ${index + 1}'),
                ),
              ),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _semester = value;
                  });
                }
              },
            ),
            const SizedBox(height: 14),
            _SheetInput(
              controller: _syllabusController,
              label: 'Syllabus units',
              hint: 'Unit 1\nUnit 2',
              maxLines: 5,
            ),
            const SizedBox(height: 14),
            _SheetInput(
              controller: _pyqController,
              label: 'PYQs map',
              hint: 'mid1_2024|https://...\nsem_2023|https://...',
              maxLines: 5,
            ),
            const SizedBox(height: 14),
            _SheetInput(
              controller: _cheatsheetUrlController,
              label: 'Cheatsheet PDF URL',
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: _isSaving ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF18181B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save Subject'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(examRepositoryProvider).addExamSubject(
            title: _titleController.text.trim(),
            code: _codeController.text.trim(),
            description: _descriptionController.text.trim(),
            semester: _semester,
            syllabusUnits: _splitLines(_syllabusController.text),
            pyqs: _parseMapLines(_pyqController.text),
            cheatsheetUrl: _nullable(_cheatsheetUrlController.text),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subject added to Firebase')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add subject: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  List<String> _splitLines(String value) => value
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  Map<String, String> _parseMapLines(String value) {
    final result = <String, String>{};
    for (final line in value.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final parts = trimmed.split('|');
      if (parts.length >= 2) {
        result[parts.first.trim()] = parts.sublist(1).join('|').trim();
      }
    }
    return result;
  }

  String? _required(String? value, String message) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  String? _nullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class AddAuthorSheet extends ConsumerStatefulWidget {
  const AddAuthorSheet({super.key});

  @override
  ConsumerState<AddAuthorSheet> createState() => _AddAuthorSheetState();
}

class _AddAuthorSheetState extends ConsumerState<AddAuthorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _writtenSubjectsController = TextEditingController();
  final _importantQuestionsController = TextEditingController();
  final _productIdController = TextEditingController();
  final _displayPriceController = TextEditingController(text: 'Rs 0');
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _writtenSubjectsController.dispose();
    _importantQuestionsController.dispose();
    _productIdController.dispose();
    _displayPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ExamSheetFrame(
      title: 'Add Author To Firebase',
      subtitle: 'Use SUBJECTCODE|samplePdfUrl per line for written subjects.',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _SheetInput(
              controller: _nameController,
              label: 'Author name',
              validator: (value) => _required(value, 'Author name is required'),
            ),
            const SizedBox(height: 14),
            _SheetInput(
              controller: _writtenSubjectsController,
              label: 'Written subjects map',
              hint: 'CSEN3011|https://sample.pdf',
              maxLines: 6,
              validator: (value) => _required(value, 'At least one subject mapping is required'),
            ),
            const SizedBox(height: 14),
            _SheetInput(
              controller: _importantQuestionsController,
              label: 'Important Q&A',
              hint: 'CSEN3011|What is ACID?|<p>ACID properties...</p>',
              maxLines: 6,
            ),
            const SizedBox(height: 14),
            _SheetInput(
              controller: _productIdController,
              label: 'In-app product ID (optional)',
              hint: 'ex: iq_author_manas_csen3011',
            ),
            const SizedBox(height: 14),
            _SheetInput(
              controller: _displayPriceController,
              label: 'Display price',
              hint: 'Rs 0',
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: _isSaving ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF18181B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save Author'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(examRepositoryProvider).addAuthor(
            name: _nameController.text.trim(),
            writtenSubjects: _parseMapLines(_writtenSubjectsController.text),
            subjectImportantQuestions: _parseImportantQuestionLines(
              _importantQuestionsController.text,
            ),
            productId: _nullable(_productIdController.text),
            displayPrice: _nullable(_displayPriceController.text) ?? 'Rs 0',
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Author added to Firebase')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add author: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Map<String, String> _parseMapLines(String value) {
    final result = <String, String>{};
    for (final line in value.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final parts = trimmed.split('|');
      if (parts.length >= 2) {
        result[parts.first.trim()] = parts.sublist(1).join('|').trim();
      }
    }
    return result;
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

  String? _required(String? value, String message) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  String? _nullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _ExamSheetFrame extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _ExamSheetFrame({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.55,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFDFBF7),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6D3D1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey.shade700, height: 1.35),
              ),
              const SizedBox(height: 20),
              child,
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

class _SheetInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final String? Function(String?)? validator;

  const _SheetInput({
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: maxLines > 1,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE7E5E4)),
        ),
      ),
    );
  }
}

InputDecoration examSheetInputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFE7E5E4)),
    ),
  );
}

InputDecoration _inputDecoration(String label) => examSheetInputDecoration(label);
