import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:siap/presentation/screens/documents/document_detail_screen.dart';
import 'package:siap/presentation/controllers/auth_controller.dart';
import 'package:siap/data/models/user_model.dart';
import 'package:siap/data/models/document_model.dart';
import 'package:siap/core/constants/app_constants.dart';

class MockAuthController extends GetxController implements AuthController {
  @override
  final currentUser = Rx<UserModel?>(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    Get.testMode = true;
    final authController = MockAuthController();
    authController.currentUser.value = UserModel(
      id: 1,
      kodeUser: 'user1',
      username: 'testuser',
      namaLengkap: 'Test User',
      role: UserRole.user,
      jabatan: 'Staff',
      instansi: 'Instansi A',
      status: 1,
    );
    Get.put<AuthController>(authController);
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('DocumentDetailScreen displays KTU Disposisi when present',
      (WidgetTester tester) async {
    final document = DocumentModel(
      id: 1,
      documentNumber: 'DOC-001',
      title: 'Test Document',
      description: 'Test Description',
      status: DocumentStatus.pending,
      statusRapat: MeetingStatus.noMeeting,
      submittedAt: DateTime.now().toIso8601String(),
      userId: 1,
      userName: 'Test User',
      ktuDisposisi: 'Value 1<br>Value 2',
    );

    await tester.pumpWidget(
      GetMaterialApp(
        onGenerateRoute: (settings) {
          return GetPageRoute(
            settings: RouteSettings(arguments: document),
            page: () => const DocumentDetailScreen(),
          );
        },
      ),
    );

    // Verify "KTU Disposisi" label is present
    expect(find.text('KTU Disposisi'), findsOneWidget);

    // Verify value is displayed with replaced newlines
    expect(find.text('Value 1\nValue 2'), findsOneWidget);
  });

  testWidgets('DocumentDetailScreen hides KTU Disposisi when null',
      (WidgetTester tester) async {
    final document = DocumentModel(
      id: 1,
      documentNumber: 'DOC-001',
      title: 'Test Document',
      description: 'Test Description',
      status: DocumentStatus.pending,
      statusRapat: MeetingStatus.noMeeting,
      submittedAt: DateTime.now().toIso8601String(),
      userId: 1,
      userName: 'Test User',
      ktuDisposisi: null,
    );

    await tester.pumpWidget(
      GetMaterialApp(
        onGenerateRoute: (settings) {
          return GetPageRoute(
            settings: RouteSettings(arguments: document),
            page: () => const DocumentDetailScreen(),
          );
        },
      ),
    );

    // Verify "KTU Disposisi" label is NOT present
    expect(find.text('KTU Disposisi'), findsNothing);
  });
}
