import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider = StreamProvider<bool>((ref) {
  final connectivity = Connectivity();
  return connectivity.onConnectivityChanged.map((results) {
    return results.any((r) => r != ConnectivityResult.none);
  });
});

class ConnectivityBanner extends ConsumerWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(connectivityProvider).valueOrNull ?? true;
    if (isOnline) return const SizedBox.shrink();

    return MaterialBanner(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      content: const Text(
        'You are offline. Call recordings will be queued and uploaded when connection restores.',
      ),
      leading: const Icon(Icons.wifi_off, color: Colors.orange),
      backgroundColor: Colors.orange.shade50,
      actions: [
        TextButton(
          onPressed: () {},
          child: const Text('DISMISS'),
        ),
      ],
    );
  }
}
