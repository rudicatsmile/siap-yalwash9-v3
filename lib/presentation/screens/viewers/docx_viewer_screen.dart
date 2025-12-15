import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/theme/app_theme.dart';

class DocxViewerScreen extends StatefulWidget {
  final String url;
  final String title;
  const DocxViewerScreen({super.key, required this.url, required this.title});

  @override
  State<DocxViewerScreen> createState() => _DocxViewerScreenState();
}

class _DocxViewerScreenState extends State<DocxViewerScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  String? _error;

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
            });
          },
          onWebResourceError: (err) {
            setState(() {
              _loading = false;
              _error = err.description;
            });
            Get.snackbar(
              'Error',
              'Gagal memuat DOCX: ${err.description}',
              backgroundColor: AppTheme.errorColor,
              colorText: Colors.white,
            );
          },
        ),
      );

    final viewerUrl =
        'https://docs.google.com/gview?embedded=1&url=${Uri.encodeComponent(widget.url)}';
    _controller.loadRequest(Uri.parse(viewerUrl));
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
              setState(() {
                _loading = true;
                _error = null;
              });
              _controller.reload();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) const Center(child: CircularProgressIndicator()),
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
        ],
      ),
    );
  }
}
