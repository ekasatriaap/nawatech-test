<?php

namespace App\Services;

use App\Repository\OrderRepository;

class OrderService
{
    public function getOrders(): iterable
    {
        return (new OrderRepository())->getOrders();
    }
}
