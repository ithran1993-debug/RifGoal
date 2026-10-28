import 'package:flutter/material.dart';

class MatchDetailsScreen extends StatelessWidget {
  final dynamic match;

  const MatchDetailsScreen({super.key, this.match});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل المباراة'),
      ),
      body: const Center(
        child: Text('صفحة تفاصيل المباراة قيد التطوير'),
      ),
    );
  }
}
