import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'screens/home/home_controller.dart';
import 'screens/home/home_screen.dart';
import 'services/local/db_service.dart';
import 'services/local/storage_service.dart';
import 'utils/logger.dart';
import 'utils/permission_util.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dbService = DBService();
  final storageService = StorageService();

  // 检查所有权限状态
  AppLogger.debug('开始检查所有权限状态');
  await PermissionUtil.checkAllPermissions();
  AppLogger.debug('权限状态检查完成');


  // 先清理之前的设备信息，再初始化本机设备信息
  try {
    // await storageService.cleanLocalDevice(); // 【开发】先清理之前的设备信息
    await storageService.initLocalDevice(); // 【生产】再初始化本机设备信息
  } catch (e) {
    AppLogger.error('初始化设备信息失败: $e');
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
