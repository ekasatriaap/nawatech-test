<?php

use App\Http\Controllers\Api\OrderController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::prefix("v1")->group(function () {
    Route::prefix("orders")->group(function () {
        Route::get("/", [OrderController::class, "index"]);
        Route::post("/checkout", [OrderController::class, "checkout"]);
        Route::post("/{order_id}/payment", [OrderController::class, "payment"]);
        Route::get("/report", [OrderController::class, "report"]);
    });
});
