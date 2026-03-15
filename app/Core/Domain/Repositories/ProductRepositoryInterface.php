<?php

namespace App\Core\Domain\Repositories;

use App\Models\Product;

interface ProductRepositoryInterface
{
    public function findByIdForUpdate(int $id): ?Product;

    public function decrementStock(int $id, int $quantity): bool;
}
