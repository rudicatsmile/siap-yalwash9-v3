import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'data/services/storage_service.dart';
import 'data/services/api_service.dart';
import 'presentation/controllers/auth_controller.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/main/main_screen.dart';
import 'presentation/screens/documents/document_detail_screen.dart';
import 'presentation/screens/documents/document_form_screen.dart';
import 'presentation/screens/meetings/meeting_list_screen.dart';
import 'presentation/screens/meetings/meeting_detail_screen.dart';
import 'routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage
  await StorageService().init();

  // Initialize API service
  ApiService().init();

  // Initialize AuthController
  Get.put(AuthController());

  runApp(const SiapApp());
}

class SiapApp extends StatelessWidget {
  const SiapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      getPages: [
        GetPage(
          name: AppRoutes.splash,
          page: () => const SplashScreen(),
        ),
        GetPage(
          name: AppRoutes.login,
          page: () => const LoginScreen(),
        ),
        GetPage(
          name: AppRoutes.main,
          page: () => const MainScreen(),
        ),
        GetPage(
          name: AppRoutes.documentDetail,
          page: () => const DocumentDetailScreen(),
        ),
        GetPage(
          name: AppRoutes.documentForm,
          page: () {
            final args = Get.arguments;
            String? noSurat;
            String? qParam;
            if (args is Map<String, dynamic>) {
              noSurat = args['no_surat']?.toString();
              qParam = args['qParam']?.toString();
            } else if (args is String) {
              noSurat = args;
            }
            return DocumentFormScreen(noSurat: noSurat, qParam: qParam);
          },
        ),
        GetPage(
          name: AppRoutes.meetingList,
          page: () => const MeetingListScreen(),
        ),
        GetPage(
          name: AppRoutes.meetingDetail,
          page: () => const MeetingDetailScreen(),
        ),
      ],
    );
  }
}
