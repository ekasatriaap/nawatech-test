<?php

namespace App\Core\UseCases\Orders;

use App\Core\Domain\Repositories\OrderRepositoryInterface;
use App\Models\Order;

class ReportUseCase
{
    public function __construct(private OrderRepositoryInterface $orderRepository) {}

    public function execute(): Order
    {
        return $this->orderRepository->report();
    }
}
