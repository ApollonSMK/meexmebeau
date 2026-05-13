import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'config/constants.dart';
import 'services/share_intent_service.dart';
import 'services/update_service.dart';
import 'widgets/update_dialog.dart';
import 'providers/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFFFFBF9),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Load env
  await dotenv.load(fileName: '.env');

  // Init Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  runApp(const ProviderScope(child: MeAppBootstrap()));
}

class MeAppBootstrap extends ConsumerStatefulWidget {
  const MeAppBootstrap({super.key});

  @override
  ConsumerState<MeAppBootstrap> createState() => _MeAppBootstrapState();
}

class _MeAppBootstrapState extends ConsumerState<MeAppBootstrap> {
  late ShareIntentService _shareIntentService;

  @override
  void initState() {
    super.initState();
    _shareIntentService = ShareIntentService(
      onDataReceived: (data) {
        debugPrint('Received shared data: $data');
        ref.read(sharedDataProvider.notifier).set(data);

        // Auto-trigger analysis based on data type
        final notifier = ref.read(analysisNotifierProvider.notifier);
        if (data.isPdf && data.filePath != null) {
          notifier.analyzePdf(data.filePath!);
        } else if (data.isImage && data.base64Content != null) {
          notifier.analyzeImage(data.base64Content!);
        } else if (data.content != null && data.content!.isNotEmpty) {
          notifier.analyzeRapport(data.content!);
        }
      },
    );
    _shareIntentService.initialize();
    // Check for OTA updates a bit after the UI is ready
    _scheduleUpdateCheck();
  }

  void _scheduleUpdateCheck() {
    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;
      final update = await UpdateService.checkForUpdate();
      if (update != null && mounted) {
        await UpdateDialog.show(context, update);
      }
    });
  }

  @override
  void dispose() {
    _shareIntentService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const MeApp();
  }
}
