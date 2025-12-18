import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:siap/presentation/screens/documents/document_form_screen.dart';
import 'package:siap/presentation/controllers/auth_controller.dart';
import 'package:siap/data/models/user_model.dart';
import 'package:siap/core/constants/app_constants.dart';
import 'package:siap/presentation/controllers/dropdown_controller.dart';
import 'package:siap/presentation/controllers/last_no_surat_controller.dart';
import 'package:siap/data/models/last_no_surat_response.dart';
import 'package:siap/presentation/widgets/form/api_dropdown_field.dart';
import 'package:siap/presentation/widgets/form/api_multi_select_field.dart';

class MockAuthController extends GetxController implements AuthController {
  @override
  final currentUser = Rx<UserModel?>(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockLastNoSuratController extends GetxController
    implements LastNoSuratController {
  @override
  final isLoading = false.obs;
  @override
  final error = ''.obs;
  @override
  final result = Rx<LastNoSuratResponse?>(null);

  @override
  Future<void> fetch() async {
    // Mock implementation
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockDropdownController extends GetxController
    implements DropdownController {
  @override
  final items = <DropdownItem>[].obs;
  @override
  final selectedKode = ''.obs;
  @override
  final isLoading = false.obs;
  @override
  final error = ''.obs;

  @override
  Future<void> loadTable(String tableName, {int limit = 100}) async {
    // Mock: Do nothing to avoid network calls
  }

  @override
  void select(String? kode) {
    selectedKode.value = (kode ?? '').trim();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockUsersDropdownController extends GetxController
    implements UsersDropdownController {
  @override
  final items = <UserOption>[].obs;
  @override
  final selectedUserId = ''.obs;
  @override
  final isLoading = false.obs;
  @override
  final error = ''.obs;

  @override
  Future<void> loadUsers({bool force = false}) async {}

  @override
  void select(String? id) {
    selectedUserId.value = (id ?? '').trim();
  }

  @override
  Future<void> refreshUsers() async {}

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
      instansiName: 'Instansi A Name',
      status: 1,
    );
    Get.put<AuthController>(authController);

    final lastNoSuratController = MockLastNoSuratController();
    Get.put<LastNoSuratController>(lastNoSuratController, tag: 'last_no_surat');

    // Register mock dropdown controllers
    Get.put<DropdownController>(MockDropdownController(), tag: 'kategori');
    Get.put<DropdownController>(MockDropdownController(), tag: 'jenis');
    Get.put<DropdownController>(MockDropdownController(),
        tag: 'tindakan_manajemen');
    Get.put<DropdownController>(MockDropdownController(),
        tag: 'tindakan_pimpinan');
    Get.put<DropdownController>(MockDropdownController(),
        tag: 'teruskan_pimpinan');
    Get.put<DropdownController>(MockDropdownController(), tag: 'ktu_disposisi');
    Get.put<DropdownController>(MockDropdownController(),
        tag: 'koordinator_disposisi');
    Get.put<DropdownController>(MockDropdownController(),
        tag: 'kategori_laporan');
    Get.put<DropdownController>(MockDropdownController(),
        tag: 'tujuan_disposisi');
    Get.put<DropdownController>(MockDropdownController(), tag: 'ruang_rapat');
    Get.put<DropdownController>(MockDropdownController(), tag: 'peserta_rapat');
    Get.put<DropdownController>(MockDropdownController(),
        tag: 'pimpinan_rapat');

    Get.put<UsersDropdownController>(MockUsersDropdownController(),
        tag: 'users_dropdown');
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets(
      'DocumentFormScreen should have _teruskanPimpinanController initialized',
      (WidgetTester tester) async {
    // Build the DocumentFormScreen
    await tester.pumpWidget(
      GetMaterialApp(
        home: DocumentFormScreen(),
      ),
    );

    // Wait for animations and async operations
    await tester.pumpAndSettle();

    // Verify that the screen is rendered
    expect(find.byType(DocumentFormScreen), findsOneWidget);

    // Verify that the label is hidden by default
    expect(find.text('Teruskan Pimpinan'), findsNothing);

    // Verify that the controller tag is registered
    expect(
        Get.isRegistered<DropdownController>(tag: 'teruskan_pimpinan'), isTrue);
  });

/*
  testWidgets('Toggle SwitchListTile should show/hide Teruskan Pimpinan field',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: DocumentFormScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial state (visible)
    expect(find.text('Tampilkan Teruskan Pimpinan'), findsOneWidget);
    // The dropdown label should be visible
    expect(find.text('Teruskan Pimpinan'), findsOneWidget);

    // Toggle off
    final switchFinder = find.text('Tampilkan Teruskan Pimpinan');
    final scrollableFinder = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      switchFinder,
      500.0,
      scrollable: scrollableFinder,
    );
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    // Verify hidden
    // "Teruskan Pimpinan" matches the label which should be gone.
    // "Tampilkan Teruskan Pimpinan" matches the switch which should remain.
    expect(find.text('Teruskan Pimpinan'), findsNothing);
    expect(find.text('Tampilkan Teruskan Pimpinan'), findsOneWidget);

    // Toggle on
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    // Verify visible again
    expect(find.text('Teruskan Pimpinan'), findsOneWidget);
  });

  testWidgets('KTU Disposisi field should be controllable via toggle',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: DocumentFormScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify controller registration
    expect(Get.isRegistered<DropdownController>(tag: 'ktu_disposisi'), isTrue);

    // Verify initial state (visible)
    expect(find.text('Tampilkan KTU Disposisi'), findsOneWidget);
    expect(find.text('KTU Disposisi'), findsOneWidget);

    // Toggle off
    final switchFinder = find.text('Tampilkan KTU Disposisi');
    final scrollableFinder = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      switchFinder,
      500.0,
      scrollable: scrollableFinder,
    );
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    // Verify hidden
    expect(find.text('KTU Disposisi'), findsNothing);
    expect(find.text('Tampilkan KTU Disposisi'), findsOneWidget);

    // Toggle on
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    // Verify visible again
    expect(find.text('KTU Disposisi'), findsOneWidget);
  });
*/

  testWidgets(
      'KTU Disposisi validation should fail if empty when visible and form is submitted',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: DocumentFormScreen(qParam: '4'),
      ),
    );
    await tester.pumpAndSettle();

    // Make KTU Disposisi visible by selecting 'Teruskan ke Pimpinan' (kode '1')
    final tindakanController =
        Get.find<DropdownController>(tag: 'tindakan_manajemen');
    tindakanController.items.assignAll([
      DropdownItem(kode: '3', deskripsi: 'Di Terima'),
      DropdownItem(kode: '0', deskripsi: 'Koreksi ke Pengirim'),
      DropdownItem(kode: '1', deskripsi: 'Teruskan ke Pimpinan'),
    ]);
    final apiDropdownFinder = find.byWidgetPredicate((widget) =>
        widget is ApiDropdownField &&
        widget.tableName == 'm_tindakan_manajemen');
    final dropdownButtonFinder = find.descendant(
      of: apiDropdownFinder,
      matching: find.byType(DropdownButtonFormField<String>),
    );
    final dropdownWidget =
        tester.widget<DropdownButtonFormField<String>>(dropdownButtonFinder);
    dropdownWidget.onChanged!('1');
    await tester.pumpAndSettle();

    expect(find.text('Disposisi'), findsOneWidget);

    // Find the submit button text
    final submitButtonText = find.text('Ajukan Berkas');

    // Scroll until visible (just in case)
    await tester.scrollUntilVisible(
      submitButtonText,
      500.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(submitButtonText, findsOneWidget);

    // Tap submit
    await tester.tap(submitButtonText);
    await tester.pumpAndSettle();

    // Verify validation error message
    final errorFinder = find.descendant(
      of: find.byKey(const ValueKey('group_tindakan_manajemen')),
      matching: find.text('Minimal pilih 1 disposisi'),
    );
    expect(errorFinder, findsOneWidget);
  });

  testWidgets(
      'Tindakan KTU logic should show/hide fields correctly based on selection',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: DocumentFormScreen(qParam: '4'),
      ),
    );
    await tester.pumpAndSettle();

    // Setup mock items for Tindakan KTU
    final tindakanController =
        Get.find<DropdownController>(tag: 'tindakan_manajemen');
    tindakanController.items.assignAll([
      DropdownItem(kode: '3', deskripsi: 'Di Terima'),
      DropdownItem(kode: '0', deskripsi: 'Koreksi ke Pengirim'),
      DropdownItem(kode: '1', deskripsi: 'Teruskan ke Pimpinan'),
    ]);

    // Verify initial state: fields are hidden
    expect(find.text('Teruskan Pimpinan'), findsNothing);
    expect(find.text('Disposisi'), findsNothing);
    expect(find.text('Catatan'), findsNothing);

    // Find the ApiDropdownField for Tindakan KTU (Manajemen)
    final apiDropdownFinder = find.byWidgetPredicate((widget) =>
        widget is ApiDropdownField &&
        widget.tableName == 'm_tindakan_manajemen');

    final dropdownButtonFinder = find.descendant(
      of: apiDropdownFinder,
      matching: find.byType(DropdownButtonFormField<String>),
    );

    // Helper to select value
    Future<void> selectValue(String code) async {
      final dropdownWidget =
          tester.widget<DropdownButtonFormField<String>>(dropdownButtonFinder);
      dropdownWidget.onChanged!(code);
      await tester.pumpAndSettle();
    }

    // 1. Select 'Di Terima' (kode '3')
    await selectValue('3');
    // Expect: All hidden
    expect(find.text('Teruskan Pimpinan'), findsNothing);
    expect(find.text('Disposisi'), findsNothing);
    expect(find.text('Catatan'), findsNothing);

    // 2. Select 'Koreksi ke Pengirim' (kode '0')
    // We need to re-find the widget because the tree rebuilt
    final dropdownWidget2 = tester.widget<DropdownButtonFormField<String>>(
      find.descendant(
        of: find.byWidgetPredicate((widget) =>
            widget is ApiDropdownField &&
            widget.tableName == 'm_tindakan_manajemen'),
        matching: find.byType(DropdownButtonFormField<String>),
      ),
    );
    dropdownWidget2.onChanged!('0');
    await tester.pumpAndSettle();

    // Expect: Pimpinan & Disposisi hidden, Catatan visible
    expect(find.text('Teruskan Pimpinan'), findsNothing);
    expect(find.text('Disposisi'), findsNothing);
    expect(find.text('Catatan'), findsOneWidget);

    // 3. Select 'Teruskan ke Pimpinan' (kode '1')
    final dropdownWidget3 = tester.widget<DropdownButtonFormField<String>>(
      find.descendant(
        of: find.byWidgetPredicate((widget) =>
            widget is ApiDropdownField &&
            widget.tableName == 'm_tindakan_manajemen'),
        matching: find.byType(DropdownButtonFormField<String>),
      ),
    );
    dropdownWidget3.onChanged!('1');
    await tester.pumpAndSettle();

    // Expect: All visible
    expect(find.text('Teruskan Pimpinan'), findsOneWidget);
    expect(find.text('Disposisi'), findsOneWidget);
    expect(find.text('Catatan'), findsOneWidget);
  });

  testWidgets('Tindakan Pimpinan field should be present and functional',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: DocumentFormScreen(qParam: '7'),
      ),
    );
    await tester.pumpAndSettle();

    // Verify controller registration
    expect(
        Get.isRegistered<DropdownController>(tag: 'tindakan_pimpinan'), isTrue);

    // Find ApiDropdownField for Tindakan Pimpinan
    final tindakanPimpinanFinder = find.byWidgetPredicate((widget) {
      if (widget is ApiDropdownField) {
        return widget.tableName == 'm_tindakan_pimpinan' &&
            widget.label == 'Tindakan';
      }
      return false;
    });

    expect(tindakanPimpinanFinder, findsOneWidget);

    // Verify properties
    final dropdownWidget =
        tester.widget<ApiDropdownField>(tindakanPimpinanFinder);
    expect(dropdownWidget.placeholder, 'Pilih Tindakan');

    // Verify validator
    expect(dropdownWidget.validator!(null), 'Tindakan harus dipilih');
    expect(dropdownWidget.validator!('valid_kode'), null);
  });

  testWidgets('Koordinator Disposisi field should be present and functional',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: DocumentFormScreen(qParam: '7'),
      ),
    );
    await tester.pumpAndSettle();

    // Trigger visibility by selecting a valid Tindakan (e.g. '3')
    // We need to register the controller and mock items first if not already done
    // But DocumentFormScreen registers controllers. We might need to populate items.
    final tindakanController =
        Get.find<DropdownController>(tag: 'tindakan_pimpinan');
    tindakanController.items.assignAll([
      DropdownItem(kode: '3', deskripsi: 'Di Terima'),
    ]);
    tindakanController.select('3'); // Select directly via controller
    await tester.pumpAndSettle();

    // Select '3' via UI to trigger onChanged listener which sets visibility
    final tindakanFinder = find.byWidgetPredicate((widget) =>
        widget is ApiDropdownField &&
        widget.tableName == 'm_tindakan_pimpinan');
    final tindakanDropdownWidget =
        tester.widget<ApiDropdownField>(tindakanFinder);
    tindakanDropdownWidget.onChanged!('3');
    await tester.pumpAndSettle();

    // Verify controller registration
    expect(Get.isRegistered<DropdownController>(tag: 'koordinator_disposisi'),
        isTrue);

    // Find ApiMultiSelectField for Koordinator Disposisi
    final koordinatorFinder = find.byWidgetPredicate((widget) {
      if (widget is ApiMultiSelectField) {
        return widget.tableName == 'm_tujuan_disposisi' &&
            widget.label == 'Disposisi Koordinator';
      }
      return false;
    });

    expect(koordinatorFinder, findsOneWidget);

    // Verify properties
    final dropdownWidget =
        tester.widget<ApiMultiSelectField>(koordinatorFinder);
    expect(dropdownWidget.placeholder, 'Pilih Disposisi Koordinator');

    // Verify validator
    expect(dropdownWidget.validator!(null), 'Minimal pilih 1 disposisi');
    expect(dropdownWidget.validator!(['valid_kode']), null);
  });

  testWidgets('Catatan Koordinator field should be present',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: DocumentFormScreen(qParam: '7'),
      ),
    );
    await tester.pumpAndSettle();

    // Trigger visibility by selecting a valid Tindakan (e.g. '3')
    final tindakanController =
        Get.find<DropdownController>(tag: 'tindakan_pimpinan');
    tindakanController.items.assignAll([
      DropdownItem(kode: '3', deskripsi: 'Di Terima'),
    ]);

    final tindakanFinder = find.byWidgetPredicate((widget) =>
        widget is ApiDropdownField &&
        widget.tableName == 'm_tindakan_pimpinan');
    final dropdownWidget = tester.widget<ApiDropdownField>(tindakanFinder);
    dropdownWidget.onChanged!('3');
    await tester.pumpAndSettle();

    expect(
        find.text('Catatan Koordinator', skipOffstage: false), findsOneWidget);

    // Find the Column that contains the label 'Catatan Koordinator'
    final columnFinder = find.byWidgetPredicate((widget) {
      if (widget is Column) {
        return widget.children.any(
            (child) => child is Text && child.data == 'Catatan Koordinator');
      }
      return false;
    });

    expect(columnFinder, findsOneWidget);

    final textFieldFinder = find.descendant(
      of: columnFinder,
      matching: find.byType(TextFormField),
    );

    expect(textFieldFinder, findsOneWidget);

    await tester.enterText(textFieldFinder, 'Test catatan');
    expect(find.text('Test catatan'), findsOneWidget);
  });

  testWidgets(
      'Tindakan Pimpinan logic should show/hide Koordinator Disposisi and Catatan',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: DocumentFormScreen(qParam: '7'),
      ),
    );
    await tester.pumpAndSettle();

    // Setup mock items for Tindakan Pimpinan
    final tindakanController =
        Get.find<DropdownController>(tag: 'tindakan_pimpinan');
    tindakanController.items.assignAll([
      DropdownItem(kode: '3', deskripsi: 'Option 3'),
      DropdownItem(kode: '8', deskripsi: 'Option 8'),
      DropdownItem(kode: '9', deskripsi: 'Option 9'),
    ]);

    // Helper to trigger selection
    Future<void> selectTindakan(String kode) async {
      final dropdownFinder = find.byWidgetPredicate((widget) =>
          widget is ApiDropdownField &&
          widget.tableName == 'm_tindakan_pimpinan');
      final dropdownWidget = tester.widget<ApiDropdownField>(dropdownFinder);
      dropdownWidget.onChanged!(kode);
      await tester.pumpAndSettle();
    }

    // 1. Select '8' -> Hide Both
    await selectTindakan('8');
    expect(find.text('Disposisi Koordinator'), findsNothing);
    expect(find.text('Catatan Koordinator'), findsNothing);

    // 2. Select '9' -> Hide Koordinator, Show Catatan
    await selectTindakan('9');
    expect(find.text('Disposisi Koordinator'), findsNothing);
    expect(find.text('Catatan Koordinator'), findsOneWidget);

    // 3. Select '3' -> Show Both
    await selectTindakan('3');
    expect(find.text('Disposisi Koordinator'), findsOneWidget);
    expect(
        find.text('Catatan Koordinator', skipOffstage: false), findsOneWidget);
  });

  testWidgets('Group Rapat Manajemen should be visible only when qParam is "4"',
      (WidgetTester tester) async {
    // 1. qParam != '4' (e.g., '1') -> Hidden
    await tester.pumpWidget(
      GetMaterialApp(
        home: DocumentFormScreen(qParam: '1', key: UniqueKey()),
      ),
    );
    await tester.pumpAndSettle();

    // Check if visible (even if offstage)
    expect(find.text('Waktu Rapat', skipOffstage: false), findsNothing);

    // 2. qParam == '4' -> Visible
    await tester.pumpWidget(
      GetMaterialApp(
        home: DocumentFormScreen(qParam: '4', key: UniqueKey()),
      ),
    );
    await tester.pumpAndSettle();

    // Setup mock items for Tindakan Manajemen
    final tindakanController =
        Get.find<DropdownController>(tag: 'tindakan_manajemen');
    tindakanController.items.assignAll([
      DropdownItem(kode: '7', deskripsi: 'Agenda Rapat'),
      DropdownItem(kode: '3', deskripsi: 'Di Terima'),
    ]);

    // Select '7' (Agenda Rapat) to trigger visibility
    final dropdownFinder = find.byWidgetPredicate((widget) =>
        widget is ApiDropdownField &&
        widget.tableName == 'm_tindakan_manajemen');
    final dropdownWidget = tester.widget<ApiDropdownField>(dropdownFinder);
    dropdownWidget.onChanged!('7');
    await tester.pumpAndSettle();

    // Check if visible (even if offstage)
    expect(find.text('Waktu Rapat', skipOffstage: false), findsOneWidget);

    // 3. qParam == null -> Hidden
    await tester.pumpWidget(
      GetMaterialApp(
        home: DocumentFormScreen(qParam: null, key: UniqueKey()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Waktu Rapat', skipOffstage: false), findsNothing);
  });
}
