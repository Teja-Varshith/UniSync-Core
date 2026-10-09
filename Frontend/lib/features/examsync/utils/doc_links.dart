/// How to show a notes / PYQ link inside the app.
///
/// [pdfUrl] is tried first and rendered natively if it returns a real PDF.
/// If it doesn't (e.g. a Drive file too large for direct download, or a
/// private doc), [previewUrl] is shown in an in-app web view instead.
class DocLink {
  const DocLink({required this.pdfUrl, required this.previewUrl});

  final String pdfUrl;
  final String previewUrl;

  /// Supabase (or any direct) PDF links stay as they are. Google Drive files
  /// and Docs / Slides / Sheets links are rewritten to their PDF download or
  /// export URL, with the clean `/preview` page as the fallback.
  factory DocLink.resolve(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasScheme) {
      return DocLink(pdfUrl: url, previewUrl: url);
    }
    final host = uri.host.toLowerCase();
    final seg = uri.pathSegments;

    String? idAfter(String marker) {
      final i = seg.indexOf(marker);
      return i >= 0 && i + 1 < seg.length ? seg[i + 1] : null;
    }

    if (host == 'drive.google.com') {
      final id = idAfter('d') ?? uri.queryParameters['id'];
      if (id != null && id.isNotEmpty) {
        return DocLink(
          pdfUrl: 'https://drive.google.com/uc?export=download&id=$id',
          previewUrl: 'https://drive.google.com/file/d/$id/preview',
        );
      }
    }

    if (host == 'docs.google.com' && seg.isNotEmpty) {
      final id = idAfter('d');
      if (id != null && id.isNotEmpty) {
        final base = 'https://docs.google.com/${seg.first}/d/$id';
        final export = switch (seg.first) {
          'presentation' => '$base/export/pdf',
          _ => '$base/export?format=pdf',
        };
        return DocLink(pdfUrl: export, previewUrl: '$base/preview');
      }
    }

    return DocLink(pdfUrl: url, previewUrl: url);
  }
}

/// True when [bytes] start with the PDF signature `%PDF`.
bool looksLikePdf(List<int> bytes) =>
    bytes.length > 4 &&
    bytes[0] == 0x25 &&
    bytes[1] == 0x50 &&
    bytes[2] == 0x44 &&
    bytes[3] == 0x46;
