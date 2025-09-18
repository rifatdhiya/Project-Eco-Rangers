<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\ReportController;
use App\Http\Controllers\AuthController;

Route::get('/reports', [ReportController::class, 'index']);
Route::get('/reports/{report}', [ReportController::class, 'show']);
Route::get('/ping', fn () => response()->json(['ok' => true]));
Route::post('/reports', [ReportController::class, 'store']);
Route::patch('/reports/{report}/status', [ReportController::class, 'updateStatus']);
Route::delete('/reports/{report}', [ReportController::class, 'destroy']);
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login',    [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/me',      [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);
});
