<?php

namespace App\Core\UseCases\Orders;

use App\Jobs\ProcessPaymentJob;
use App\Models\Order;

class PaymentUseCase
{
    public function execute(int $order_id)
    {
        $order = Order::find($order_id);
        if (!$order) {
            return [
                "success" => false,
                "message" => "Order not found",
                "code" => 404
            ];
        }

        ProcessPaymentJob::dispatch($order);

        return [
            "success" => true,
            "message" => "Payment processed successfully",
        ];
    }
}
