<?php

namespace App\Infrastructure\Repositories;

use App\Core\Domain\Repositories\OrderItemRepositoryInterface;
use App\Models\OrderItem;

class OrderItemRepository implements OrderItemRepositoryInterface
{
    public function create(int $order_id, array $data): OrderItem
    {
        return OrderItem::create([
            'order_id' => $order_id,
            ...$data
        ]);
    }
}
