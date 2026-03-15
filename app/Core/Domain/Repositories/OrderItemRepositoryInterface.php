<?php

namespace App\Core\Domain\Repositories;

use App\Models\OrderItem;

interface OrderItemRepositoryInterface
{
    public function create(int $order_id, array $data): OrderItem;
}
