# Dokumentasi Alur Pengiriman Parameter `qParam` dari UI ke Backend

## 1) Struktur Parameter yang Dikirim

- Parameter utama: `qParam`
  - Tipe data: `string`
  - Kegunaan: Menjadi nilai pencarian (`search`) untuk memfilter daftar dokumen di backend
- Format pengiriman: Query string pada HTTP GET (bukan JSON/FormData)
- Payload contoh (query parameters):
  - Base URL: `https://backend-siap.yalwash9.org`
  - Endpoint: `/api/documents`
  - Contoh lengkap:
    - `GET https://backend-siap.yalwash9.org/api/documents?page=1&per_page=20&search=Menunggu`
    - Parameter tambahan yang didukung: `role`, `user_id`, `departemen_id`, `status`, `status_rapat`, `dibaca`

## 2) Alur Pemrosesan di Frontend

- Lokasi pembuatan parameter:
  - UI grid pada `lib/presentation/screens/main/tabs/home_tab.dart:120-122`
    ```dart
    onTap: () {
      Get.to(() => DataTab(qParam: stat.qParam));
    }
    ```
    Catatan: Di beberapa variasi implementasi, properti dapat berupa `stat.qParam`. Intinya nilai string dari item grid diteruskan sebagai `qParam`.
- Penerimaan dan pengiriman parameter:
  - `lib/presentation/screens/main/tabs/data_tab.dart:23-27`
    ```dart
    final qp = qParam ?? ((Get.arguments is Map) ? (Get.arguments as Map)['qParam'] as String? : null);
    if (qp != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        dashboardController.loadDocuments(refresh: true, search: null, dibaca: qParam);
      });
    }
    ```
  - Metode yang menangani pemanggilan: `DashboardController.loadDocuments`
    - `lib/presentation/controllers/dashboard_controller.dart:29`
    - Parameter `search` diteruskan ke repository sebagai `null`
    - Parameter `dibaca` diteruskan ke repository sebagai `qParam`
  - Library/package untuk HTTP request: `ApiService.get` yang digunakan oleh `DocumentRepository`
    - `lib/data/repositories/document_repository.dart:64-67`
    - Endpoint dan base URL diatur di `lib/core/constants/api_constants.dart:1-23`

## 3) Endpoint Backend yang Menerima

- URL lengkap:
  - Base URL: `https://backend-siap.yalwash9.org`
  - Endpoint: `/api/documents`
- Metode HTTP: `GET`
- Routing dan middleware:

  - `backend-laravel/routes/api.php:29-50`
    - `Route::middleware('auth:sanctum')->group(function () { Route::get('/documents', [DocumentController::class, 'index']); ... })`
  - `backend-laravel/bootstrap/app.php:11-18`

  - Middleware API menyertakan `\Laravel\Sanctum\Http\Middleware\EnsureFrontendRequestsAreStateful::class`

  - `backend-laravel/app/Http/Controllers/Api/DocumentController.php:69-71`
    if ($request->filled('dibaca')) {
    $query->where('dibaca', $request->dibaca);
    }

## 4) Diagram Alur

Mermaid:

```mermaid
flowchart TD
  A[HomeTab: onTap] -->|qParam:String| B[DataTab: build]
  B -->|post-frame| C[DashboardController.loadDocuments(search)]
  C --> D[DocumentRepository.getDocuments(queryParameters)]
  D --> E[ApiService GET /api/documents?search=...]
  E --> F[Laravel Route: auth:sanctum]
  F --> G[DocumentController@index]
  G -->|apply filters incl. search| H[DB Query + Pagination]
  H --> I[JSON Response: status,data,meta]
  I --> J[Flutter: Obx render list]
  I --> K[Error: snackbar if failure]
```

ASCII:

```
HomeTab (tap) --> DataTab (qParam) --> DashboardController.loadDocuments(search)
    --> DocumentRepository.getDocuments(queryParameters)
    --> ApiService GET /api/documents?search=...
    --> Laravel Route (auth:sanctum) --> DocumentController@index
    --> Query filters (search, dibaca, dsb) + paginate --> JSON response
    --> Flutter UI render / error snackbar
```

## 5) Contoh Kasus Penggunaan Nyata

- Input user:
  - Pengguna mengetuk kartu grid bertuliskan "Menunggu" pada HomeTab
- Validasi parameter di frontend:
  - `qParam` bertipe `string` dan diteruskan apa adanya ke `search`
  - Tidak ada trimming/pembersihan khusus; disarankan konten aman karena dikirim sebagai query param dan dibind oleh framework backend
- Respons backend yang diharapkan:
  - `200 OK` dengan payload:
    ```json
    {
      "status": 200,
      "data": [
        /* array dokumen terfilter */
      ],
      "meta": {
        "current_page": 1,
        "per_page": 20,
        "total": 42,
        "last_page": 3
      },
      "timestamp": "2025-12-16T10:10:10Z"
    }
    ```
  - Jika terjadi error autentikasi: `401 Unauthenticated`
  - Jika terjadi kesalahan server: `500` dengan pesan error

## 6) Catatan Penting

- Batasan/limitasi parameter:
  - `search` di-backend diproses melalui scope pencarian dan aman sebagai parameter terikat (prepared statements)
  - Panjang string yang terlalu besar dapat mempengaruhi performa pencarian; disarankan ≤ 255 karakter
- Dependensi modul lain:
  - Frontend: `GetX` untuk navigasi dan state (`Get.to`, `Obx`, `DashboardController`)
  - HTTP: `ApiService.get` dan `ApiConstants` untuk endpoint
  - Backend: `auth:sanctum` serta model `Document` beserta query scopes (`search`, `status`, dll.)
- Persyaratan autentikasi:
  - Semua endpoint `/api/documents` berada dalam group `auth:sanctum`; token Bearer harus valid
  - Header yang digunakan oleh client: `Authorization: Bearer <token>` dan `Accept: application/json`

## Referensi Kode

- Sumber parameter UI: `lib/presentation/screens/main/tabs/home_tab.dart:120-122`
- Pengiriman ke controller: `lib/presentation/screens/main/tabs/data_tab.dart:23-27`
- Controller pemuatan data: `lib/presentation/controllers/dashboard_controller.dart:29`
- HTTP client dan endpoint: `lib/data/repositories/document_repository.dart:52-67`, `lib/core/constants/api_constants.dart:12-23`
- Backend route: `backend-laravel/routes/api.php:29-50`
- Backend controller: `backend-laravel/app/Http/Controllers/Api/DocumentController.php:53-71`
