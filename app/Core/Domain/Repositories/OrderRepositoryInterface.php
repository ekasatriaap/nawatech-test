<?php

namespace App\Core\Domain\Repositories;

use App\Models\Order;

interface OrderRepositoryInterface
{
    public function getAllOrders(): iterable;

    public function create(array $data): Order;

    public function report(): Order;
}
