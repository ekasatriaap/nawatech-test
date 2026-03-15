<?php

namespace App\Http\Controllers\Api;

use App\Core\UseCases\Orders\CheckoutUseCase;
use App\Core\UseCases\Orders\GetOrderUserCase;
use App\Core\UseCases\Orders\PaymentUseCase;
use App\Core\UseCases\Orders\ReportUseCase;
use App\Http\Controllers\Controller;
use App\Http\Resources\ReportResource;
use Illuminate\Http\Request;

class OrderController extends Controller
{
    public function index(GetOrderUserCase $usecase)
    {
        $orders = $usecase->execute();
        return response()->streamJson([
            "success" => true,
            "message" => "Orders fetched successfully",
            "data" => $orders
        ]);
    }

    public function checkout(Request $request, CheckoutUseCase $usecase)
    {
        $result = $usecase->execute($request);
        if (!$result['success']) {
            return $this->sendError($result['message'], $result['code']);
        }
        return $this->sendResponse($result['data'], $result['message']);
    }

    public function payment(int $order_id, PaymentUseCase $usecase)
    {
        $result = $usecase->execute($order_id);
        if (!$result['success']) {
            return $this->sendError($result['message'], $result['code']);
        }
        return $this->sendResponse(message: $result['message']);
    }

    public function report(ReportUseCase $usecase)
    {
        $result = $usecase->execute();
        $data = new ReportResource($result);
        return $this->sendResponse($data, "Report fetched successfully");
    }
}
