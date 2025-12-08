# SIAP Backend API - Laravel 12

## Overview

Laravel 12 backend API for the SIAP (Sistem Informasi Administrasi Perkantoran) document management system. This API provides authentication, document management, meeting management, and activity history tracking functionalities.

## Features

- **API-Only Architecture**: Pure RESTful JSON API
- **Laravel Sanctum Authentication**: Token-based stateless authentication
- **Role-Based Access Control**: Three roles (User, Admin, Pimpinan)
- **Document Management**: CRUD operations with workflow status
- **Meeting Management**: Meeting scheduling and decision tracking
- **Activity History**: Comprehensive audit trail
- **Rate Limiting**: Protection against brute force attacks
- **Consistent Error Handling**: Standardized JSON error responses

## Technology Stack

- **Framework**: Laravel 12 (latest version)
- **PHP Version**: 8.2+
- **Database**: SQLite (default) / MySQL compatible
- **Authentication**: Laravel Sanctum
- **API Design**: RESTful

## Installation

### Prerequisites

- PHP 8.2 or higher
- Composer
- SQLite or MySQL

### Setup Steps

1. Navigate to the backend directory:
```bash
cd backend-laravel
```

2. Install dependencies:
```bash
composer install
```

3. Configure environment (the .env file is already configured for SQLite):
```bash
# Database is already set to SQLite
# No additional configuration needed for development
```

4. Run migrations and seed data:
```bash
php artisan migrate:fresh --seed --seeder=InitialDataSeeder
```

5. Start the development server:
```bash
php artisan serve
```

The API will be available at `http://localhost:8000`

## API Endpoints

### Base URL
```
http://localhost:8000/api
```

### Authentication Endpoints

#### POST /api/login
Authenticate user and issue access token.

**Request Body:**
```json
{
  "username": "admin",
  "password": "admin123",
  "fcm_token": "optional_firebase_token"
}
```

**Success Response (200):**
```json
{
  "status": 200,
  "message": "Login successful",
  "data": {
    "token": "1|xxxxxxxxxxxxx",
    "user": {
      "id_user": 1,
      "username": "admin",
      "nama_lengkap": "Administrator",
      "email": "admin@siap.local",
      "jabatan": "System Administrator",
      "role": "admin",
      "level": "admin",
      "instansi": "10",
      "kode_user": "ADMIN-001"
    }
  },
  "timestamp": "2025-12-07T14:30:00+00:00"
}
```

**Rate Limit:** 5 attempts per 15 minutes per IP address

#### POST /api/logout
Revoke current access token (requires authentication).

**Headers:**
```
Authorization: Bearer {token}
```

**Success Response (200):**
```json
{
  "status": 200,
  "message": "Logout successful",
  "timestamp": "2025-12-07T14:30:00+00:00"
}
```

#### GET /api/user
Get current authenticated user basic information (requires authentication).

**Success Response (200):**
```json
{
  "status": 200,
  "data": {
    "id_user": 1,
    "username": "admin",
    "nama_lengkap": "Administrator",
    "role": "admin",
    "level": "admin",
    "kode_user": "ADMIN-001"
  },
  "timestamp": "2025-12-07T14:30:00+00:00"
}
```

#### GET /api/profile
Get complete user profile (requires authentication).

**Success Response (200):**
```json
{
  "status": 200,
  "data": {
    "id_user": 1,
    "username": "admin",
    "nama_lengkap": "Administrator",
    "email": "admin@siap.local",
    "telp": "08123456789",
    "jabatan": "System Administrator",
    "role": "admin",
    "instansi": "10",
    "level": "admin",
    "kode_user": "ADMIN-001",
    "terakhir_login": "2025-12-07T14:30:00+00:00"
  },
  "timestamp": "2025-12-07T14:30:00+00:00"
}
```

### Document Endpoints

#### GET /api/documents
Get paginated list of documents with role-based filtering (requires authentication).

**Query Parameters:**
- `page`: Page number (default: 1)
- `per_page`: Items per page (default: 15, max: 100)
- `status`: Filter by status (Dokumen, Rapat, Selesai)
- `sifat`: Filter by priority (Segera, Biasa, Rahasia)
- `search`: Search in no_surat, pengirim, perihal
- `date_from`: Filter from date (YYYY-MM-DD)
- `date_to`: Filter to date (YYYY-MM-DD)
- `kategori_surat`: Filter by category

**Success Response (200):**
```json
{
  "status": 200,
  "data": [...],
  "meta": {
    "current_page": 1,
    "per_page": 15,
    "total": 50,
    "last_page": 4
  },
  "timestamp": "2025-12-07T14:30:00+00:00"
}
```

#### GET /api/documents/{id}
Get single document detail (requires authentication).

**Success Response (200):**
```json
{
  "status": 200,
  "data": {
    "id_sm": 1,
    "no_surat": "00725",
    "tgl_surat": "2025-10-01",
    "pengirim": "SMP Al Wathoniyah 9",
    "penerima": "Surat Edaran Kegiatan LDKPDB",
    "perihal": "Surat Edaran Kegiatan LDKPDB Tahun Pelajaran 2025/2026",
    "status": "Dokumen",
    "sifat": "Segera",
    "kategori_surat": "B-CC",
    ...
  },
  "timestamp": "2025-12-07T14:30:00+00:00"
}
```

#### POST /api/documents
Create new document (requires authentication).

**Request Body:**
```json
{
  "no_asal": "017.007/SMP AL W-9/X/2025",
  "tgl_surat": "2025-10-01",
  "pengirim": "SMP Al Wathoniyah 9",
  "penerima": "Recipient Name",
  "perihal": "Document subject matter",
  "sifat": "Segera",
  "kategori_surat": "B-CC",
  "klasifikasi_surat": "SMP AL W-9/X/2025",
  "lampiran": "1 Lampiran",
  "token_lampiran": "optional_token"
}
```

**Success Response (201):**
```json
{
  "status": 201,
  "message": "Document created successfully",
  "data": {...},
  "timestamp": "2025-12-07T14:30:00+00:00"
}
```

#### PUT /api/documents/{id}
Update existing document (requires authentication, document creator or admin).

**Request Body:** Same fields as create, all optional

**Success Response (200):**
```json
{
  "status": 200,
  "message": "Document updated successfully",
  "data": {...},
  "timestamp": "2025-12-07T14:30:00+00:00"
}
```

#### DELETE /api/documents/{id}
Soft delete document (requires authentication, admin only).

**Success Response (200):**
```json
{
  "status": 200,
  "message": "Document deleted successfully",
  "timestamp": "2025-12-07T14:30:00+00:00"
}
```

#### PUT /api/documents/{id}/status
Update document workflow status (requires authentication, admin or pimpinan).

**Request Body:**
```json
{
  "status": "Rapat",
  "disposisi": "Optional disposition text",
  "catatan": "Optional notes"
}
```

**Success Response (200):**
```json
{
  "status": 200,
  "message": "Document status updated successfully",
  "data": {...},
  "timestamp": "2025-12-07T14:30:00+00:00"
}
```

### Meeting Endpoints

#### GET /api/meetings
Get paginated list of meeting documents (status = Rapat) (requires authentication).

**Query Parameters:** Same as GET /api/documents

**Success Response (200):**
```json
{
  "status": 200,
  "data": [...],
  "meta": {...},
  "timestamp": "2025-12-07T14:30:00+00:00"
}
```

#### POST /api/meetings/{id}/decision
Record meeting decision (requires authentication, pimpinan only).

**Request Body:**
```json
{
  "disposisi_rapat": "Meeting decision text (minimum 10 characters)",
  "tgl_hasil_rapat": "2025-10-01",
  "status": "Selesai",
  "catatan": "Optional notes"
}
```

**Success Response (200):**
```json
{
  "status": 200,
  "message": "Meeting decision recorded successfully",
  "data": {...},
  "timestamp": "2025-12-07T14:30:00+00:00"
}
```

### History Endpoint

#### GET /api/history
Get user activity history (requires authentication).

**Query Parameters:**
- `page`: Page number (default: 1)
- `per_page`: Items per page (default: 20, max: 100)
- `action_type`: Filter by action type
- `date_from`: Filter from date
- `date_to`: Filter to date
- `user_id`: Admin only - filter by specific user

**Success Response (200):**
```json
{
  "status": 200,
  "data": [...],
  "meta": {...},
  "timestamp": "2025-12-07T14:30:00+00:00"
}
```

## Default Test Accounts

### Admin Account
- **Username:** `admin`
- **Password:** `admin123`
- **Role:** admin
- **Institution:** 10

### Pimpinan Account
- **Username:** `pimpinan`
- **Password:** `pimpinan123`
- **Role:** pimpinan
- **Institution:** 10

### User Account (from JSON)
- **Username:** `kasubag-data`
- **Password:** `password123`
- **Role:** user
- **Institution:** 03

## Role-Based Access Control

### User Role
- Create documents
- Read documents they created
- Read documents assigned to them
- Update their own documents (if status is "Dokumen")

### Admin Role
- Full CRUD operations within their institution
- Delete documents (if no dispositions)
- Update document status
- View activity history for their institution

### Pimpinan Role
- Read all documents in their institution
- Update document status
- Record meeting decisions
- View all meetings

## Error Handling

All errors follow a consistent JSON structure:

```json
{
  "status": 422,
  "message": "Validation failed",
  "errors": {
    "field_name": ["Error message"]
  },
  "timestamp": "2025-12-07T14:30:00+00:00"
}
```

### Common HTTP Status Codes
- **200 OK**: Successful GET, PUT requests
- **201 Created**: Successful POST creating new resource
- **401 Unauthorized**: Missing or invalid authentication token
- **403 Forbidden**: Insufficient permissions
- **404 Not Found**: Resource does not exist
- **422 Unprocessable Entity**: Validation errors
- **429 Too Many Requests**: Rate limit exceeded
- **500 Internal Server Error**: Server error

## Testing the API

### Using cURL

**Login:**
```bash
curl -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

**Get Documents (with auth token):**
```bash
curl -X GET http://localhost:8000/api/documents \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

**Create Document:**
```bash
curl -X POST http://localhost:8000/api/documents \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "no_asal": "001/TEST/2025",
    "tgl_surat": "2025-12-07",
    "pengirim": "Test Sender",
    "penerima": "Test Recipient",
    "perihal": "This is a test document for API testing",
    "sifat": "Biasa",
    "kategori_surat": "TEST",
    "klasifikasi_surat": "TEST/2025"
  }'
```

### Using Postman

1. Import the endpoints into Postman
2. Set up environment variables:
   - `base_url`: `http://localhost:8000/api`
   - `token`: (will be set after login)
3. Test login endpoint first to get token
4. Use token in Authorization header for protected endpoints

## Security Features

- **Password Hashing**: Bcrypt with 12 rounds
- **Token Authentication**: Laravel Sanctum bearer tokens
- **Rate Limiting**: Login endpoint limited to 5 attempts per 15 minutes
- **Account Lockout**: 30 minutes after 5 failed login attempts
- **Input Validation**: All inputs validated using Form Requests
- **SQL Injection Prevention**: Eloquent ORM with parameter binding
- **CORS Protection**: Configured for API access

## Activity Logging

The system logs the following activities:
- `login`: User login
- `logout`: User logout
- `create_document`: Document creation
- `update_document`: Document update
- `view_document`: Document viewing
- `status_change`: Document status change
- `meeting_decision`: Meeting decision recording
- `delete_document`: Document deletion

## Database Schema

### Users Table
- Primary Key: `id_user`
- Unique Fields: `username`, `email`, `kode_user`
- Soft Deletes: Enabled

### Documents Table (tbl_sm)
- Primary Key: `id_sm`
- Foreign Key: `id_user` → users(id_user)
- Soft Deletes: Enabled
- Indexes: id_user, id_instansi, status, tgl_surat, no_surat

### Activity History Table
- Primary Key: `id`
- Foreign Keys: `user_id` → users(id_user), `document_id` → tbl_sm(id_sm)
- Indexes: user_id, document_id, action, created_at

## Production Deployment

### Environment Configuration

For production, update `.env`:

```env
APP_ENV=production
APP_DEBUG=false
APP_URL=https://your-domain.com

DB_CONNECTION=mysql
DB_HOST=your-db-host
DB_PORT=3306
DB_DATABASE=your-database
DB_USERNAME=your-username
DB_PASSWORD=your-password

SANCTUM_STATEFUL_DOMAINS=your-flutter-app-domain.com
```

### Deployment Steps

1. Run migrations:
```bash
php artisan migrate --force
```

2. Seed initial data (if needed):
```bash
php artisan db:seed --class=InitialDataSeeder
```

3. Clear and cache config:
```bash
php artisan config:cache
php artisan route:cache
```

4. Set proper file permissions
5. Configure web server (Nginx/Apache)
6. Enable HTTPS

## Support

For issues or questions, please refer to the design document at:
`.qoder/quests/backend-api-laravel-12.md`

## License

This project is part of the SIAP document management system.
