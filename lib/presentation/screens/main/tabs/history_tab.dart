import 'package:flutter/material.dart';

/// History tab with document history
class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: const Center(
        child: Text('History akan ditampilkan di sini'),
      ),
    );
  }
}
