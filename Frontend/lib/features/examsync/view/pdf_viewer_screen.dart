import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:UniSync/features/examsync/theme/es_theme.dart';
import 'package:UniSync/features/examsync/view/widgets/es_scope.dart';
import 'package:UniSync/features/examsync/widgets/es_toast.dart';
import 'package:UniSync/features/examsync/widgets/es_widgets.dart';

/// Full-screen PDF viewer for notes and PYQs. The web app needs a CORS
/// proxy for this; a native download doesn't.
class PdfViewerScreen extends StatefulWidget {
  const PdfViewerScreen({
    super.key,
    required this.url,
    required this.title,
    required this.isPyq,
  });

  final String url;
  final String title;
  final bool isPyq;

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  PdfControllerPinch? _controller;
  bool _failed = false;
  int _page = 1;
  int _pages = 0;
  CancelToken? _cancel;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _cancel?.cancel();
    final cancel = _cancel = CancelToken();
    setState(() {
      _failed = false;
      _controller?.dispose();
      _controller = null;
    });
    try {
      final uri = Uri.parse(widget.url);
      if (!uri.hasScheme) throw const FormatException('bad url');
      final res = await Dio().get<List<int>>(
        widget.url,
        cancelToken: cancel,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = Uint8List.fromList(res.data ?? const []);
      if (bytes.isEmpty) throw const FormatException('empty');
      if (!mounted || cancel.isCancelled) return;
      setState(() {
        _controller = PdfControllerPinch(document: PdfDocument.openData(bytes));
      });
    } catch (_) {
      if (mounted && !cancel.isCancelled) setState(() => _failed = true);
    }
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.tryParse(widget.url);
    final ok = uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      showEsToast(context, 'Couldn’t open the browser.',
          type: EsToastType.error);
    }
  }

  @override
  void dispose() {
    _cancel?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExamSyncScope(
      child: Scaffold(
        backgroundColor: EsColors.bg,
        body: SafeArea(
          child: Column(
            children: [
              _bar(),
              Expanded(child: _viewer()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: EsColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Row(
        children: [
          EsIconButton(
            icon: Icons.arrow_back_rounded,
            semanticLabel: 'Back',
            onPressed: () => examSyncBack(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: EsText.body(size: 15, weight: FontWeight.w800),
                ),
                if (_pages > 0)
                  Text('Page $_page of $_pages',
                      style: EsText.mono(size: 11, color: EsColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          EsChip(
            widget.isPyq ? 'PYQ' : 'Notes',
            variant: EsChipVariant.ghost,
          ),
          const SizedBox(width: 8),
          EsIconButton(
            icon: Icons.open_in_new_rounded,
            semanticLabel: 'Open in browser',
            onPressed: _openInBrowser,
          ),
        ],
      ),
    );
  }

  Widget _fallback() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf_outlined,
                size: 40, color: EsColors.error),
            const SizedBox(height: 12),
            Text('Couldn’t open this PDF here',
                style: EsText.body(size: 16, weight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              'Try again, or open it in your browser instead.',
              textAlign: TextAlign.center,
              style: EsText.body(size: 13, color: EsColors.textMuted),
            ),
            const SizedBox(height: 18),
            EsButton(
              label: 'Open in browser',
              icon: Icons.open_in_new_rounded,
              onPressed: _openInBrowser,
            ),
            const SizedBox(height: 12),
            EsButton(
              label: 'Try again',
              variant: EsButtonVariant.secondary,
              size: EsButtonSize.sm,
              onPressed: _load,
            ),
          ],
        ),
      ),
    );
  }

  Widget _viewer() {
    if (_failed) return _fallback();
    final controller = _controller;
    if (controller == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return PdfViewPinch(
      controller: controller,
      backgroundDecoration: const BoxDecoration(color: EsColors.bg),
      onDocumentLoaded: (doc) => setState(() => _pages = doc.pagesCount),
      onPageChanged: (page) => setState(() => _page = page),
      builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
        options: const DefaultBuilderOptions(),
        documentLoaderBuilder: (_) =>
            const Center(child: CircularProgressIndicator()),
        pageLoaderBuilder: (_) =>
            const Center(child: CircularProgressIndicator()),
        errorBuilder: (_, __) => _fallback(),
      ),
    );
  }
}
