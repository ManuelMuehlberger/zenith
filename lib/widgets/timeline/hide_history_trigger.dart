import 'package:flutter/material.dart';

class HideHistoryTrigger extends StatelessWidget {
  final VoidCallback onTrigger;

  const HideHistoryTrigger({super.key, required this.onTrigger});

  @override
  Widget build(BuildContext context) {
    // Completely removed text and arrow as requested.
    // Kept as a 0-height widget to maintain logic structure in HomeScreen.
    return const SizedBox.shrink();
  }
}
