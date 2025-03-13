import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'screens/home/home_controller.dart';
import 'screens/home/home_screen.dart';
import 'services/local/db_service.dart';
import 'services/local/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dbService = DBService();
  final storageService = StorageService();

  // 先清理，再初始化本机设备信息
  try {
    // await storageService.cleanLocalDevice(); // 先清理
    await storageService.initLocalDevice(); // 再初始化
  } catch (e) {
    debugPrint('初始化设备信息失败: $e');
  }

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
