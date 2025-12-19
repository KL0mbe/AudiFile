import 'package:audio_player/core/services/database_service.dart';
import 'package:audio_player/core/providers/audio_provider.dart';
import 'package:audio_player/core/services/audio_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audio_service/audio_service.dart';
import 'package:get_it/get_it.dart';
import 'dart:io';

GetIt getIt = GetIt.instance;
late Directory libDir;
late Directory mediaDir;
late Directory appDir;
late Directory tempDir;

class AppInit {
  AppInit._();

  static Future<void> init() async {
    libDir = await getLibraryDirectory();
    mediaDir = Directory("${libDir.path}/media");
    appDir = await getApplicationDocumentsDirectory();
    tempDir = await getTemporaryDirectory();
    getIt.registerSingleton<DatabaseService>(DatabaseService());
    await getIt<DatabaseService>().init();
    getIt.registerSingleton<AudioProvider>(AudioProvider());
    getIt.registerSingleton<AudioHandler>(await initAudioHandler());
    await getIt<AudioProvider>().init();
  }
}
