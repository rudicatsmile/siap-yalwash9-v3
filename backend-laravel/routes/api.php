<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\DocumentController;
use App\Http\Controllers\Api\MeetingController;
use App\Http\Controllers\Api\HistoryController;
use App\Http\Controllers\Api\TujuanDisposisiController;
use App\Http\Controllers\Api\RuangRapatController;
use App\Http\Controllers\Api\InstansiController;
use App\Http\Controllers\Api\TipeSuratController;
use App\Http\Controllers\Api\TindakanSegeraController;
use App\Http\Controllers\Api\GeneralDropdownController;
use App\Http\Controllers\Api\UsersController;
use App\Http\Controllers\Api\SuratMasukController;
use Illuminate\Support\Facades\Route;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Cache\RateLimiting\Limit;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. Make something great!
|
*/

// Configure rate limiter for login attempts
RateLimiter::for('login', function (Request $request) {
    return Limit::perMinute(5)->by($request->ip());
});
RateLimiter::for('general_dropdown', function (Request $request) {
    return Limit::perMinute(60)->by(optional($request->user())->id_user ?: $request->ip());
});

// Public routes
Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:login');

// Protected routes
Route::middleware('auth:sanctum')->group(function () {
    // Authentication routes
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/user', [AuthController::class, 'user']);
    Route::get('/profile', [AuthController::class, 'profile']);

    // Document routes
    Route::get('/documents', [DocumentController::class, 'index']);
    Route::get('/documents/{id}', [DocumentController::class, 'show'])->whereNumber('id');
    Route::post('/documents', [DocumentController::class, 'store']);
    Route::put('/documents/{id}', [DocumentController::class, 'update'])->whereNumber('id');
    Route::delete('/documents/{id}', [DocumentController::class, 'destroy'])->whereNumber('id');
    Route::put('/documents/{id}/status', [DocumentController::class, 'updateStatus'])->whereNumber('id');

    // Meeting routes
    Route::get('/meetings', [MeetingController::class, 'index']);
    Route::post('/meetings/{id}/decision', [MeetingController::class, 'decision'])->whereNumber('id');

    // History routes
    Route::get('/history', [HistoryController::class, 'index']);

    // Master Data routes
    Route::get('/tujuan-disposisi', [TujuanDisposisiController::class, 'index']);
    Route::get('/ruang-rapat/dropdown', [RuangRapatController::class, 'dropdown']);
    Route::get('/instansi/dropdown', [InstansiController::class, 'dropdown']);
    Route::get('/dropdown/tipe-surat', [TipeSuratController::class, 'dropdown']);
    Route::get('/tindakan-segera/dropdown', [TindakanSegeraController::class, 'dropdown']);
    Route::get('/users/dropdown', [UsersController::class, 'dropdown']);
    Route::get('/general/dropdown', [GeneralDropdownController::class, 'dropdown'])->middleware('throttle:general_dropdown');
    Route::get('/documents/last-no-surat', [DocumentController::class, 'getLastNoSurat']);

    // Surat Masuk (tbl_sm)
    Route::post('/surat-masuk', [SuratMasukController::class, 'store']);
});
