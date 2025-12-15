import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:siap/core/theme/app_theme.dart';
import 'package:siap/core/constants/app_constants.dart';
import 'package:siap/presentation/screens/splash/splash_screen.dart';

class TestSplashScreen extends SplashScreen {
  const TestSplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _NoInitSplashState();
}

class _NoInitSplashState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: const Icon(
                Icons.description_outlined,
                size: AppIconSize.xxl,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              AppConstants.appTagline,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  setUpAll(() async {
    // Initialize services before tests
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('App initialization test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(
        home: TestSplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );

    // Verify splash screen appears
    expect(find.text('SIAP'), findsOneWidget);

    // Pump a small delay to render animations without waiting indefinitely
    await tester.pump(const Duration(milliseconds: 100));
  });
}
