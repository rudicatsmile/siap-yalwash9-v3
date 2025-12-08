# SIAP - Sistem Informasi Administrasi Protokoler

A Flutter mobile application for managing administrative document workflows with hierarchical role-based approval process.

## Features

### ✅ Implemented

- **6-Level Role Hierarchy**: User, Department Head, Protocol Head, General Affairs Head, Coordinator, Main Leader
- **Document Status Management**: 7 status codes (0, 1, 2, 3, 8, 9, 20) with workflow logic
- **Meeting Status**: Separate meeting status tracking (status_rapat)
- **Authentication**: Login with username/password, session management, logout
- **Role-Based Dashboards**: Different views and actions based on user role
- **4-Tab Bottom Navigation**: Home, Data, History, Profile
- **Splash Screen**: Brand intro with authentication check
- **Profile Management**: View user information and logout
- **Document Management**: Create, edit, delete, and view document details
- **Document Detail Screen**: Comprehensive view with role-based actions
- **Meeting Management**: Meeting list and decision screens for authorized roles
- **Theme System**: Complete UI theme with status colors
- **State Management**: GetX for reactive state management
- **API Integration**: Dio-based HTTP client with auto token injection
- **Local Storage**: GetStorage for caching user data and tokens
- **Pull-to-Refresh**: Refresh data on all list screens
- **Status Color Coding**: Visual indicators for all document statuses
- **Loading & Empty States**: User-friendly loading and empty state widgets
- **Confirmation Dialogs**: Reusable dialogs for critical actions

### 🚀 Pending Implementation

- History Tab with date range filtering
- Document attachments upload/download
- Push notifications (FCM integration)
- Offline mode with local caching
- Dark mode support

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Framework | Flutter 3.38.4 |
| State Management | GetX 4.7.3 |
| HTTP Client | Dio 5.9.0 |
| Local Storage | GetStorage 2.1.1 |
| Authentication | Laravel Sanctum (Backend) |

## Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_constants.dart      # App-wide constants & enums
│   │   └── api_constants.dart      # API endpoints & configuration
│   └── theme/
│       └── app_theme.dart          # UI theme & colors
├── data/
│   ├── models/
│   │   ├── user_model.dart         # User data model
│   │   ├── document_model.dart     # Document data model
│   │   └── department_model.dart   # Department & status history models
│   ├── repositories/
│   │   ├── document_repository.dart # Document operations
│   │   └── user_repository.dart    # User operations
│   └── services/
│       ├── api_service.dart        # HTTP client
│       ├── auth_service.dart       # Authentication
│       └── storage_service.dart    # Local persistence
├── presentation/
│   ├── controllers/
│   │   ├── auth_controller.dart         # Authentication state
│   │   ├── dashboard_controller.dart    # Dashboard state
│   │   └── navigation_controller.dart   # Navigation state
│   └── screens/
│       ├── splash/
│       │   └── splash_screen.dart       # Splash screen
│       ├── auth/
│       │   └── login_screen.dart        # Login screen
│       └── main/
│           ├── main_screen.dart         # Main container
│           └── tabs/
│               ├── home_tab.dart        # Home tab
│               ├── data_tab.dart        # Dashboard tab
│               ├── history_tab.dart     # History tab
│               └── profile_tab.dart     # Profile tab
└── routes/
    └── app_routes.dart                  # Route definitions
```

## Role Hierarchy & Permissions

| Role | Level | Submit Docs | View Scope | Approve | Forward | Meetings |
|------|-------|-------------|------------|---------|---------|----------|
| User | 1 | ✓ | Own docs | ✗ | ✗ | ✗ |
| Dept Head | 2 | ✓ | Department | ✗ | ✗ | ✗ |
| Protocol Head | 3 | ✓ | Department | ✗ | ✗ | ✓ |
| General Head | 4 | ✓ | All pending | ✓ | To Coordinator | ✓ |
| Coordinator | 5 | ✗ | Forwarded | ✓ | To Main Leader | ✗ |
| Main Leader | 6 | ✗ | Escalated | ✓ | ✗ | ✗ |

## Document Status Codes

| Code | Name | Description |
|------|------|-------------|
| 0 | Rejected | Document rejected |
| 1 | Pending/Submitted | Initial submission or in progress |
| 2 | Forwarded to Coordinator | Escalated to coordinator level |
| 3 | Approved | Document approved |
| 8 | Coordinator Meeting | Meeting scheduled at coordinator level |
| 9 | Forwarded to Main Leader | Escalated to highest authority |
| 20 | Returned | Sent back for revision |

## Installation & Setup

1. **Prerequisites**:
   ```bash
   flutter --version  # Flutter 3.38.4 or higher
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure API Endpoint**:
   Edit `lib/core/constants/api_constants.dart`:
   ```dart
   static String get apiBaseUrl {
     switch (current) {
       case dev:
         return 'http://your-api-url:8000';  // Update this
       // ...
     }
   }
   ```

4. **Run the App**:
   ```bash
   flutter run
   ```

## API Integration

The app expects Laravel Sanctum API with these endpoints:

### Authentication
- `POST /api/login` - Login with username & password
- `POST /api/logout` - Invalidate token
- `GET /api/user` - Get current user data

### Documents
- `GET /api/documents` - Get documents list (with filters)
- `POST /api/documents` - Create new document
- `GET /api/documents/{id}` - Get document detail
- `PUT /api/documents/{id}` - Update document
- `DELETE /api/documents/{id}` - Delete document
- `PUT /api/documents/{id}/status` - Update document status

### Meetings
- `GET /api/meetings` - Get meeting documents
- `POST /api/meetings/{id}/decision` - Record meeting decision

### History & Profile
- `GET /api/history` - Get user history
- `GET /api/profile` - Get user profile
- `PUT /api/profile` - Update user profile

### Expected Response Format

**Success Response**:
```json
{
  "success": true,
  "data": { ... },
  "message": "Success message"
}
```

**Error Response**:
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Error description"
  }
}
```

## User Table Schema

The app uses `tbl_user` table with these fields:

| Field | Type | Description |
|-------|------|-------------|
| id_user | Integer | Primary key |
| username | String | Login username |
| password | String | Hashed password |
| nama_lengkap | String | Full name |
| jabatan | String | Position/role |
| instansi | String | Institution/department |
| email | String | Email address |
| telp | String | Phone number |
| level_pimpinan | Integer | Leadership level |
| level_tu | Integer | Administrative level |
| level_manajemen | Integer | Management level |
| status | Integer | Account status |
| token | String | Auth token |
| fcm_token | String | FCM token for notifications |

## Development

### Adding New Screens

1. Create screen file in `lib/presentation/screens/`
2. Create controller if needed in `lib/presentation/controllers/`
3. Add route in `lib/routes/app_routes.dart`
4. Register route in `lib/main.dart`

### State Management with GetX

```dart
// Define controller
class MyController extends GetxController {
  final RxString data = ''.obs;
  
  void updateData(String newData) {
    data.value = newData;
  }
}

// Use in UI
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MyController());
    
    return Obx(() => Text(controller.data.value));
  }
}
```

### API Calls

```dart
// In repository
final response = await apiService.get('/api/documents');
final documents = (response.data['data'] as List)
    .map((json) => DocumentModel.fromJson(json))
    .toList();
```

## Testing

Run the app in development mode:
```bash
flutter run
```

For production build:
```bash
flutter build apk --release  # Android
flutter build ios --release  # iOS
```

## Troubleshooting

**Issue**: Login fails
- Check API base URL configuration
- Verify backend is running
- Check network connectivity

**Issue**: Token not persisting
- Ensure StorageService is initialized
- Check token storage in app data

**Issue**: UI not updating
- Verify Obx() widget usage
- Check if values are .obs reactive

## Contributing

This is a private project for SIAP organization.

## License

Proprietary - All rights reserved.

## Contact

For support and questions, contact the development team.
