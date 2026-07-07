import 'package:flutter/material.dart';

class ReviewTab extends StatelessWidget {
  const ReviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('レビュー')),
      body: const Center(child: Text('レビュー画面（実装予定）')),
    );
  }
}
