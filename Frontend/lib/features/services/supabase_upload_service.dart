import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseUploadService {
  static const String _doubtsBucket = 'prescriptions';

  final SupabaseClient _client;

  SupabaseUploadService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<String> uploadDoubtImage({
    required Uint8List bytes,
    required String fileName,
    required String uid,
  }) async {
    final safeFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path = 'exam_doubts/$uid/${DateTime.now().millisecondsSinceEpoch}_$safeFileName';
    final lower = fileName.toLowerCase();
    final contentType = lower.endsWith('.png')
      ? 'image/png'
      : lower.endsWith('.webp')
        ? 'image/webp'
        : 'image/jpeg';

    await _client.storage.from(_doubtsBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );

    return _client.storage.from(_doubtsBucket).getPublicUrl(path);
  }
}
