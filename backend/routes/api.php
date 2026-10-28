<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CustomerController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\HelpController;
use App\Http\Controllers\Api\InventoryController;
use App\Http\Controllers\Api\PrivacyController;
use App\Http\Controllers\Api\ReportController;
use App\Http\Controllers\Api\SettingController;
use App\Http\Controllers\Api\StoreOutletController;
use App\Http\Controllers\Api\SupriAiController;
use App\Http\Controllers\Api\TransactionController;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\BillingController;
use App\Http\Middleware\ApiTokenAuth;

// Health Check
Route::get('/health', function () {
    return response()->json([
        'status' => 'OK',
        'service' => 'Vault Pakasir API Backend',
        'timestamp' => now()->toIso8601String(),
    ]);
});

// Supri AI Edge TTS Voice Stream (Public Audio Access)
Route::get('/tts', [SupriAiController::class, 'tts']);

// 1. Authentication Routes
Route::prefix('auth')->group(function () {
    Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:10,1');
    Route::get('/me', [AuthController::class, 'me'])->middleware(ApiTokenAuth::class);
    Route::post('/logout', [AuthController::class, 'logout'])->middleware(ApiTokenAuth::class);
});

Route::get('/billing/plans', [BillingController::class, 'plans']);
Route::post('/billing/webhook', [BillingController::class, 'webhook']);
Route::middleware(ApiTokenAuth::class)->group(function () {
    Route::get('/billing/subscription', [BillingController::class, 'subscription']);
    Route::get('/billing/invoices', [BillingController::class, 'invoices']);
    Route::post('/billing/checkout', [BillingController::class, 'checkout'])->middleware('throttle:10,1');
    Route::get('/billing/invoices/{id}', [BillingController::class, 'refresh'])->middleware('throttle:20,1');

// 2. Executive Dashboard
Route::get('/dashboard', [DashboardController::class, 'index']);

// 3. Inventory Management
Route::prefix('inventory')->group(function () {
    Route::get('/', [InventoryController::class, 'index']);
    Route::post('/', [InventoryController::class, 'store']);
    Route::get('/categories', [InventoryController::class, 'categories']);
    Route::get('/recently-deleted', [InventoryController::class, 'recentlyDeleted']);
    Route::post('/batch-restock', [InventoryController::class, 'batchRestock']);
    Route::post('/purge-expired', [InventoryController::class, 'purgeExpired']);
    Route::get('/{id}', [InventoryController::class, 'show']);
    Route::put('/{id}', [InventoryController::class, 'update']);
    Route::delete('/{id}', [InventoryController::class, 'destroy']);
    Route::post('/{id}/restock', [InventoryController::class, 'restock']);
    Route::post('/{id}/soft-delete', [InventoryController::class, 'softDelete']);
    Route::post('/{id}/restore', [InventoryController::class, 'restore']);
});

// 4. Customer CRM
Route::prefix('customers')->group(function () {
    Route::get('/', [CustomerController::class, 'index']);
    Route::post('/', [CustomerController::class, 'store']);
    Route::get('/{id}', [CustomerController::class, 'show']);
    Route::put('/{id}', [CustomerController::class, 'update']);
    Route::delete('/{id}', [CustomerController::class, 'destroy']);
});

// 5. Store Multi-Outlet Management
Route::prefix('stores')->group(function () {
    Route::get('/', [StoreOutletController::class, 'index']);
    Route::post('/', [StoreOutletController::class, 'store']);
    Route::patch('/{id}/toggle-status', [StoreOutletController::class, 'toggleStatus']);
});

// 6. Reports & Financial Tracking
Route::prefix('reports')->group(function () {
    Route::get('/', [ReportController::class, 'index']);
    Route::get('/export', [ReportController::class, 'export']);
});

// 7. Help Center & Support Tickets
Route::prefix('help')->group(function () {
    Route::get('/faqs', [HelpController::class, 'faqs']);
    Route::get('/tickets', [HelpController::class, 'tickets']);
    Route::post('/tickets', [HelpController::class, 'submitTicket']);
});

// 8. System & Store Settings
Route::prefix('settings')->group(function () {
    Route::get('/', [SettingController::class, 'index']);
    Route::put('/', [SettingController::class, 'update']);
});

// 9. Privacy, Security & Audit Logs
Route::prefix('privacy')->group(function () {
    Route::get('/', [PrivacyController::class, 'index']);
    Route::get('/audit-logs', [PrivacyController::class, 'auditLogs']);
    Route::post('/toggle-security', [PrivacyController::class, 'toggleSecurity']);
    Route::post('/backup', [PrivacyController::class, 'backupDatabase']);
});

// 10. POS Transactions (Cashier Checkout)
Route::prefix('transactions')->group(function () {
    Route::get('/', [TransactionController::class, 'index']);
    Route::post('/', [TransactionController::class, 'store']);
    Route::get('/{id}', [TransactionController::class, 'show']);
});

// 11. Supri AI Assistant & Neural Memory Engine
Route::post('/voice-transcribe', [SupriAiController::class, 'voiceTranscribe']);
Route::prefix('supri')->group(function () {
    Route::get('/history', [SupriAiController::class, 'history']);
    Route::post('/chat', [SupriAiController::class, 'chat']);
    Route::post('/voice-transcribe', [SupriAiController::class, 'voiceTranscribe']);
    Route::post('/restock-now', [SupriAiController::class, 'executeRestock']);
    Route::get('/memories', [SupriAiController::class, 'memories']);
    Route::post('/train-memory', [SupriAiController::class, 'trainMemory']);
    Route::get('/sales-analysis', [SupriAiController::class, 'salesAnalysis']);
    Route::get('/tts', [SupriAiController::class, 'tts']);
});
});
