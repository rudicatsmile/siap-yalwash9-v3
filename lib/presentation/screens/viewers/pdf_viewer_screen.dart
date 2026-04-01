import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../data/services/api_service.dart';
import '../../../core/theme/app_theme.dart';

class PdfViewerScreen extends StatefulWidget {
  final String url;
  final String title;
  const PdfViewerScreen({super.key, required this.url, required this.title});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  bool _loading = true;
  String? _error;
  late final WebViewController _controller;
  bool _usingGoogleViewer = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            setState(() {
              _loading = false;
              _error = null;
            });
          },
          onWebResourceError: (err) {
            setState(() {
              _loading = false;
              _error = err.description;
            });
            Get.snackbar(
              'Error',
              'Gagal memuat PDF: ${err.description}',
              backgroundColor: AppTheme.errorColor,
              colorText: Colors.white,
            );
          },
        ),
      );
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _usingGoogleViewer = false;
    });

    try {
      await _loadViaPdfJs();
    } catch (e) {
      final uri = Uri.tryParse(widget.url);
      final scheme = (uri?.scheme ?? '').toLowerCase();
      if (scheme == 'https') {
        final viewerUrl =
            'https://docs.google.com/gview?embedded=1&url=${Uri.encodeComponent(widget.url)}';
        _usingGoogleViewer = true;
        await _controller.loadRequest(Uri.parse(viewerUrl));
      } else {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
        Get.snackbar(
          'Error',
          'Gagal memuat PDF: $e',
          backgroundColor: AppTheme.errorColor,
          colorText: Colors.white,
        );
      }
    }
  }

  Future<void> _loadViaPdfJs() async {
    final api = ApiService();
    final resp = await api.get(
      widget.url,
      options: dio.Options(responseType: dio.ResponseType.bytes),
    );

    final status = resp.statusCode ?? 0;
    if (status < 200 || status >= 300) {
      throw Exception('HTTP $status');
    }

    final data = resp.data;
    final bytes = data is List<int> ? Uint8List.fromList(data) : data;
    if (bytes is! Uint8List) {
      throw Exception('Format PDF tidak valid');
    }

    final contentType = resp.headers.value('content-type') ?? '';
    final looksLikePdf = bytes.length >= 4 &&
        bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46;
    if (!looksLikePdf) {
      final previewBytes = bytes.length > 300 ? bytes.sublist(0, 300) : bytes;
      String previewText;
      try {
        previewText = utf8.decode(previewBytes, allowMalformed: true);
      } catch (_) {
        previewText = previewBytes.toString();
      }
      throw Exception(
        'Respons bukan PDF. content-type="$contentType". Preview: $previewText',
      );
    }

    final b64 = base64Encode(bytes);
    final html = _buildPdfJsHtml(b64: b64, title: widget.title);
    await _controller.loadHtmlString(html);
  }

  String _buildPdfJsHtml({required String b64, required String title}) {
    final safeTitle = title.replaceAll("'", "\\'");
    return '''
<!doctype html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>$safeTitle</title>
    <style>
      html, body { margin: 0; padding: 0; background: #111; color: #fff; font-family: sans-serif; }
      #topbar { position: sticky; top: 0; background: #111; padding: 10px 12px; z-index: 2; border-bottom: 1px solid rgba(255,255,255,0.12); }
      #status { opacity: 0.8; font-size: 12px; }
      #viewer { padding: 12px; }
      .page { margin: 0 0 12px 0; background: #fff; border-radius: 6px; overflow: hidden; }
      canvas { display: block; width: 100%; height: auto; }
      #error { color: #ff6b6b; white-space: pre-wrap; }
    </style>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/pdf.js/4.0.379/pdf.min.js"></script>
  </head>
  <body>
    <div id="topbar">
      <div id="status">Memuat PDF...</div>
      <div id="error"></div>
    </div>
    <div id="viewer"></div>
    <script>
      const b64 = '$b64';
      const raw = atob(b64);
      const bytes = new Uint8Array(raw.length);
      for (let i = 0; i < raw.length; i++) bytes[i] = raw.charCodeAt(i);

      pdfjsLib.GlobalWorkerOptions.workerSrc = 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/4.0.379/pdf.worker.min.js';

      const statusEl = document.getElementById('status');
      const errorEl = document.getElementById('error');
      const viewerEl = document.getElementById('viewer');

      function clearViewer() {
        while (viewerEl.firstChild) viewerEl.removeChild(viewerEl.firstChild);
      }

      async function renderAll(pdf) {
        clearViewer();
        statusEl.textContent = 'Total halaman: ' + pdf.numPages;
        for (let pageNum = 1; pageNum <= pdf.numPages; pageNum++) {
          const page = await pdf.getPage(pageNum);
          const baseViewport = page.getViewport({ scale: 1 });
          const desiredWidth = Math.max(300, document.documentElement.clientWidth - 24);
          const scale = desiredWidth / baseViewport.width;
          const viewport = page.getViewport({ scale: scale });

          const canvas = document.createElement('canvas');
          const context = canvas.getContext('2d');
          canvas.width = Math.floor(viewport.width);
          canvas.height = Math.floor(viewport.height);

          const pageWrap = document.createElement('div');
          pageWrap.className = 'page';
          pageWrap.appendChild(canvas);
          viewerEl.appendChild(pageWrap);

          await page.render({ canvasContext: context, viewport: viewport }).promise;
        }
      }

      pdfjsLib.getDocument({ data: bytes }).promise
        .then((pdf) => renderAll(pdf))
        .catch((err) => {
          statusEl.textContent = 'Gagal memuat PDF';
          errorEl.textContent = String(err && err.message ? err.message : err);
        });
    </script>
  </body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Muat Ulang',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _load();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(child: CircularProgressIndicator()),
          if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.errorColor),
                ),
              ),
            ),
          if (_usingGoogleViewer)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: const Text(
                  'Mode Google Viewer aktif. Jika URL lampiran berada di jaringan lokal (192.168.x.x), mode ini bisa gagal.',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
