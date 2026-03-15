<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class ReportResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            "total_amount" => (int) $this->total_amount,
            "total_order" => (int) $this->total_order,
            "avg_amount" => (int) $this->avg_amount,
            "top_products" => $this->orderItems->map(function ($orderItem) {
                return [
                    "product_id" => $orderItem->product_id,
                    "product_name" => $orderItem->product->name,
                    "total_quantity" => $orderItem->total_quantity
                ];
            })
        ];
    }
}
