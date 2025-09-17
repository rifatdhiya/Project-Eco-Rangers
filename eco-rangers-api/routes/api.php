<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\ReportController;

Route::get('/reports', [ReportController::class, 'index']);
Route::get('/reports/{report}', [ReportController::class, 'show']);
Route::get('/ping', fn () => response()->json(['ok' => true]));
Route::post('/reports', [ReportController::class, 'store']);
Route::patch('/reports/{report}/status', [ReportController::class, 'updateStatus']);
Route::delete('/reports/{report}', [ReportController::class, 'destroy']);
