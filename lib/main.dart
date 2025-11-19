import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'screens/home/home_controller.dart';
import 'screens/home/home_screen.dart';
import 'services/local/db_service.dart';
import 'services/local/storage_service.dart';
import 'utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final startupWatch = Stopwatch()..start();
  final dbService = DBService();
  final storageService = StorageService();
  startupWatch.stop();
  AppLogger.info('主进程依赖初始化耗时: ${startupWatch.elapsedMilliseconds}ms');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => HomeController(dbService, storageService),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Breeze',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
