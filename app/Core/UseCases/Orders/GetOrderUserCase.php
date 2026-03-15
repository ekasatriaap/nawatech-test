<?php

namespace App\Core\UseCases\Orders;

use App\Core\Domain\Repositories\OrderRepositoryInterface;

class GetOrderUserCase
{
    private $orderRepository;

    public function __construct(OrderRepositoryInterface $orderRepository)
    {
        $this->orderRepository = $orderRepository;
    }

    public function execute()
    {
        return $this->orderRepository->getAllOrders();
    }
}
