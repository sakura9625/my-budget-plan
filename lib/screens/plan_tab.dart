import 'package:flutter/material.dart';
import '../theme.dart';

class PlanTab extends StatelessWidget {
  const PlanTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('計画')),
      body: const Center(child: Text('計画画面（実装予定）')),
    );
  }
}
