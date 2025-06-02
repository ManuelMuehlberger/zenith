import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class CompletionPage extends StatelessWidget {
  final String name;
  final bool isLoading;
  final VoidCallback onComplete;

  const CompletionPage({
    super.key,
    required this.name,
    required this.isLoading,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.check,
              size: 60,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 32),
          
          Text(
            'Welcome, $name!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'You\'re all set to start your fitness journey with a privacy-respecting, fully offline workout logger.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[400],
              height: 1.4,
            ),
          ),
          
          const SizedBox(height: 32),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.security, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Privacy First',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'All your data stays on your device. No cloud, no tracking, no ads.',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: isLoading ? null : onComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: isLoading
                ? const CupertinoActivityIndicator(color: Colors.white)
                : const Text(
                    'Start Logging Workouts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
