import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import 'package:unisync/app/providers.dart';
import 'package:unisync/constants/constant.dart';

class PdfUpload extends ConsumerStatefulWidget {
  const PdfUpload({super.key});

  @override
  ConsumerState<PdfUpload> createState() => _PdfUploadState();
}

class _PdfUploadState extends ConsumerState<PdfUpload> {
  PlatformFile? selectedFile;
  bool uploading = false;

  final TextEditingController slugController = TextEditingController();

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: BASE_URI, // e.g. http://localhost:3000
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  /// Pick PDF
  Future<void> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );

    if (result == null) return;

    setState(() {
      selectedFile = result.files.single;
    });
  }

  /// Upload PDF (THIS IS THE IMPORTANT PART)
  Future<void> uploadPdf() async {
    // 1️⃣ validations
    if (selectedFile == null || selectedFile!.path == null) {
      _toast("Please select a PDF");
      return;
    }

    if (slugController.text.trim().isEmpty) {
      _toast("Please enter a slug");
      return;
    }

    final user = ref.read(userProvider);
    if (user == null || user.id == null) {
      _toast("User not authenticated");
      return;
    }

    final String userId = user.id!; // ✅ EXACTLY what Postman sends

    setState(() => uploading = true);

    try {
      // 2️⃣ build multipart EXACTLY like Postman
      final formData = FormData();

      formData.fields.add(
        MapEntry("slug", slugController.text.trim()),
      );
      formData.fields.add(
        MapEntry("userId", userId),
      );

      formData.files.add(
        MapEntry(
          "file",
          await MultipartFile.fromFile(
            selectedFile!.path!,
            filename: selectedFile!.name,
          ),
        ),
      );

      // 3️⃣ send request
      final response = await dio.post(
        "/api/resume/upload-document",
        data: formData,
        onSendProgress: (sent, total) {
          debugPrint(
            "Upload ${(sent / total * 100).toStringAsFixed(0)}%",
          );
        },
      );

      final data = response.data;
      final message =
          data is Map && data["message"] != null
              ? data["message"]
              : "Uploaded successfully";

      _toast(message, success: true);

      setState(() {
        selectedFile = null;
        slugController.clear();
      });
    } catch (e) {
      _toast("Upload failed: $e");
    } finally {
      setState(() => uploading = false);
    }
  }

  void _toast(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    slugController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Resume"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // slug
            TextField(
              controller: slugController,
              decoration: const InputDecoration(
                labelText: "Portfolio Slug",
                hintText: "eg: teja",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // picked file
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Icon(Icons.picture_as_pdf, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    selectedFile?.name ?? "No file selected",
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // pick button
            OutlinedButton.icon(
              onPressed: uploading ? null : pickPdf,
              icon: const Icon(Icons.file_open),
              label: const Text("Pick PDF"),
            ),

            const SizedBox(height: 12),

            // upload button
            ElevatedButton.icon(
              onPressed: uploading ? null : uploadPdf,
              icon: uploading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.upload),
              label: Text(uploading ? "Uploading..." : "Upload"),
            ),
          ],
        ),
      ),
    );
  }
}
