import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/data/api_service.dart';
import 'package:leavego_app/data/data_service.dart';
import 'package:leavego_app/ui/screens/splash_screen.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(DataService(), permanent: true);
  Get.put(ApiService(Get.find<DataService>()), permanent: true);
  Get.put(AppController(Get.find<ApiService>()), permanent: true);
  runApp(const LeaveProApp());
}

class LeaveProApp extends StatelessWidget {
  const LeaveProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DevBulls',
      theme: AppTheme.light(),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
