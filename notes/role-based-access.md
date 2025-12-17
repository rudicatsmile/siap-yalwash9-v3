# Role-Based Access Overview

## Role Enum (Frontend)

- Sumber: `lib/core/constants/app_constants.dart:54`
- Enum: `UserRole` dengan properti:
  - `code`: kode string (`'user'`, `'dept_head'`, `'protocol_head'`, `'general_head'`, `'coordinator'`, `'main_leader'`)
  - `displayName`: nama tampilan
  - `level`: level numerik (1–6)
- Helper methods:
  - `canSubmitDocuments`: `level <= 4`
  - `canApproveDocuments`: `level >= 4`
  - `canManageMeetings`: khusus `'protocol_head'` atau `'general_head'`
  - `canForwardToCoordinator`: `'general_head'`
  - `canForwardToMainLeader`: `'coordinator'`
  - `canReturnDocuments`: `'general_head'`

## Sumber Data Role (Backend)

- Endpoint login: `backend-laravel/app/Http/Controllers/Api/AuthController.php:85–106`
  - Mengembalikan `role` dan `level` dalam objek `user`
- Endpoint user info: `backend-laravel/app/Http/Controllers/Api/AuthController.php:134–153`
  - Mengembalikan `role`, `level`, `kode_user`, dll.
- Role tersedia di table `tbl_user.role`

## Alur Ambil Role (Frontend)

- Login: `lib/data/services/auth_service.dart:23–75`
  - Kirim kredensial ke `POST /api/login`
  - Simpan `token` dan `userData` ke storage
- Ambil user berjalan: `lib/data/services/auth_service.dart:102–133`
  - `GET /api/user`, lalu cache ulang `userData`
- Parsing ke model: `lib/data/models/user_model.dart:74–85`
  - `json['role']` → `UserRole.fromCode(...)`
- Penyimpanan lokal:
  - `lib/data/services/storage_service.dart:58–74` simpan `userData`
  - `lib/data/services/storage_service.dart:68–76` baca `userData`

## Mengakses Role di Aplikasi

- Dari Controller:
  - `lib/presentation/controllers/auth_controller.dart:1–15`
  - `Get.find<AuthController>().currentUser.value?.role`
- Dari cache:
  - `AuthService().getCachedUser()?.role` (`lib/data/services/auth_service.dart:135–151`)
- Penggunaan di Repository:
  - Kirim `role.code` sebagai filter query
  - `lib/data/repositories/document_repository.dart:47–66` dan `:230–239`

## Daftar Role (Kode → Level)

- `user` → 1
- `dept_head` → 2
- `protocol_head` → 3
- `general_head` → 4
- `coordinator` → 5
- `main_leader` → 6
- `super_admin` → 7

## Contoh Pemakaian

- Gate UI:
  - `final role = Get.find<AuthController>().currentUser.value?.role;`
  - `if (role?.canApproveDocuments == true) { /* tampilkan tombol approve */ }`
- Filter API:
  - `documentRepository.getDocuments(role: role, ...)` → mengirim `role.code` di query

## Catatan Penting

- Otentikasi diperlukan untuk mendapatkan `role` (`Sanctum`).
- Pastikan sinkronisasi `role.code` backend dengan enum `UserRole` di frontend.
- Jika struktur role berubah, update `UserRole` dan helper permission di `app_constants.dart`.
- UI harus fail-safe: jika `role` null, fallback ke `UserRole.user`.
