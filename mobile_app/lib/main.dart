import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:salestrack_mobile/core/router.dart';
import 'package:salestrack_mobile/core/theme.dart';
import 'package:salestrack_mobile/features/call_recorder/data/call_log_repository.dart';
import 'package:salestrack_mobile/features/call_recorder/domain/call_recorder_providers.dart';
import 'package:salestrack_mobile/features/drive_upload/data/hive_upload_job.dart';
import 'package:salestrack_mobile/features/drive_upload/data/upload_queue_repository.dart';
import 'package:salestrack_mobile/features/drive_upload/domain/upload_providers.dart';
import 'package:salestrack_mobile/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(HiveUploadStatusAdapter());
  Hive.registerAdapter(HiveUploadJobAdapter());

  // Open repositories
  final uploadQueue = await UploadQueueRepository.open();
  final callLog = await CallLogRepository.open();

  runApp(
    ProviderScope(
      overrides: [
        uploadQueueRepositoryProvider.overrideWithValue(uploadQueue),
        callLogRepositoryProvider.overrideWithValue(callLog),
      ],
      child: const SalesTrackApp(),
    ),
  );
}

class SalesTrackApp extends StatelessWidget {
  const SalesTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SalesTrack',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
