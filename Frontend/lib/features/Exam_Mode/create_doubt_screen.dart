import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisync/app/providers.dart';
import 'package:unisync/features/Exam_Mode/models/exam_doubt_post_model.dart';
import 'package:unisync/features/Exam_Mode/repository/exam_doubts_repository.dart';
import 'package:unisync/features/services/supabase_upload_service.dart';

const _kTeal = Color(0xFF00897B);
const _kDark = Color(0xFF1A1A2E);

class CreateDoubtScreen extends ConsumerStatefulWidget {
  const CreateDoubtScreen({super.key});

  @override
  ConsumerState<CreateDoubtScreen> createState() => _CreateDoubtScreenState();
}

class _CreateDoubtScreenState extends ConsumerState<CreateDoubtScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _tagsController = TextEditingController();

  bool _isAnonymous = false;
  bool _isPosting = false;
  bool _isPickingImage = false;
  Uint8List? _imageBytes;
  String? _imageName;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: _kTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Create Post',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _isPosting ? null : _submit,
              child: _isPosting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Post',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _isAnonymous
                          ? const Color(0xFF78909C).withValues(alpha: 0.1)
                          : _kTeal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _isAnonymous
                          ? Icons.person_off_rounded
                          : Icons.person_rounded,
                      size: 18,
                      color: _isAnonymous ? const Color(0xFF78909C) : _kTeal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Post Anonymously',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kDark,
                          ),
                        ),
                        Text(
                          'Your identity will be hidden',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isAnonymous,
                    onChanged: (v) => setState(() => _isAnonymous = v),
                    activeColor: _kTeal,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _label('Title'),
            const SizedBox(height: 8),
            _textField(
              controller: _titleController,
              hint: 'What doubt do you want help with?',
              maxLines: 1,
            ),
            const SizedBox(height: 16),
            _label('Description'),
            const SizedBox(height: 8),
            _textField(
              controller: _bodyController,
              hint: 'Share more details so peers can help',
              maxLines: 6,
            ),
            const SizedBox(height: 16),
            _label('Tags (optional)'),
            const SizedBox(height: 8),
            _textField(
              controller: _tagsController,
              hint: 'ex: dbms, unit-3, sql (comma separated)',
              maxLines: 1,
            ),
            const SizedBox(height: 16),
            _label('Image (optional)'),
            const SizedBox(height: 8),
            _imagePicker(),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 18, color: Colors.red.shade400),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _kDark,
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14, color: _kDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _imagePicker() {
    if (_imageBytes != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.memory(
              _imageBytes!,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _imageBytes = null;
                  _imageName = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: _isPickingImage
              ? const CircularProgressIndicator(strokeWidth: 2)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _kTeal.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 24,
                        color: _kTeal.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Tap to add an image',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    setState(() {
      _isPickingImage = true;
      _errorMessage = null;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      final file = result?.files.single;
      if (file?.bytes == null) return;
      if (!mounted) return;
      setState(() {
        _imageBytes = file!.bytes;
        _imageName = file.name;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to pick image: $error';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isPickingImage = false;
      });
    }
  }

  Future<void> _submit() async {
    final user = ref.read(userProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login required to post doubts.')),
      );
      return;
    }

    final title = _titleController.text.trim();
    final description = _bodyController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description')),
      );
      return;
    }

    setState(() {
      _isPosting = true;
      _errorMessage = null;
    });

    try {
      String? imageUrl;
      if (_imageBytes != null) {
        imageUrl = await SupabaseUploadService().uploadDoubtImage(
          bytes: _imageBytes!,
          fileName: _imageName ?? 'doubt.jpg',
          uid: uid,
        );
      }

      final tags = _tagsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();

      final postId = DateTime.now().millisecondsSinceEpoch.toString();
      final post = ExamDoubtPost(
        postId: postId,
        uid: uid,
        authorName: _isAnonymous ? 'Anonymous' : user.name,
        authorAvatar: _isAnonymous ? null : user.photoUrl,
        title: title,
        description: description,
        imageUrl: imageUrl,
        tags: tags,
        likedBy: const [],
        commentCount: 0,
        isResolved: false,
        createdAt: DateTime.now(),
      );

      await ref.read(examDoubtsRepositoryProvider).createPost(post);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doubt posted successfully.')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isPosting = false;
        _errorMessage = 'Failed to post doubt: $error';
      });
    }
  }
}
