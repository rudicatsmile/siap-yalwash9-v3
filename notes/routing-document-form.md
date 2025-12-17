# Sistem Routing Document Form (GetX)

Dokumen ini menjelaskan implementasi routing untuk layar formulir dokumen (`DocumentFormScreen`) menggunakan library GetX.

## 1. Definisi Route
Lokasi: `lib/routes/app_routes.dart`
```dart
class AppRoutes {
  // ...
  static const String documentForm = '/document/form';
  // ...
}
```

## 2. Konfigurasi Halaman (GetPage)
Lokasi: `lib/main.dart`
Konfigurasi ini menangani ekstraksi argumen sebelum halaman dibangun, sehingga widget `DocumentFormScreen` menerima data bersih melalui konstruktornya.

```dart
GetPage(
  name: AppRoutes.documentForm,
  page: () {
    // 1. Ambil argumen dari Get.arguments
    final args = Get.arguments;
    String? noSurat;
    String? qParam;

    // 2. Logika parsing argumen fleksibel (Map atau String)
    if (args is Map<String, dynamic>) {
      noSurat = args['no_surat']?.toString();
      qParam = args['qParam']?.toString();
    } else if (args is String) {
      noSurat = args; // Support legacy single argument
    }

    // 3. Inject ke konstruktor widget
    return DocumentFormScreen(noSurat: noSurat, qParam: qParam);
  },
),
```

## 3. Cara Penggunaan (Navigasi)
Lokasi: `lib/presentation/screens/main/tabs/data_tab.dart` (dan tempat lain)

Menggunakan `Get.toNamed` dengan parameter `arguments` berupa Map untuk mengirim multiple values.

```dart
final result = await Get.toNamed(
  AppRoutes.documentForm,
  arguments: {
    'no_surat': doc.documentNumber, 
    'qParam': qp
  },
);
```

## 4. Keuntungan Pendekatan Ini
1. **Decoupling**: `DocumentFormScreen` tidak perlu bergantung pada `Get.arguments` di dalam metode `build`-nya. Ia hanya menerima parameter standar Dart.
2. **Fleksibilitas**: Logika parsing di `main.dart` memungkinkan route menerima berbagai format argumen (misal: String tunggal untuk backward compatibility atau Map untuk multiple args) tanpa mengubah kode widget.
3. **Type Safety**: Konversi tipe data (casting ke String) dilakukan di satu tempat sebelum masuk ke widget.