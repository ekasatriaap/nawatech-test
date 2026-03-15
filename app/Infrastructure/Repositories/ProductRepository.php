<?php

namespace App\Infrastructure\Repositories;

use App\Core\Domain\Repositories\ProductRepositoryInterface;
use App\Models\Product;

class ProductRepository implements ProductRepositoryInterface
{
    public function findByIdForUpdate(int $id): ?Product
    {
        return Product::where('id', $id)->lockForUpdate()->first();
    }

    public function decrementStock(int $id, int $quantity): bool
    {
        return Product::where('id', $id)->decrement('stock', $quantity);
    }
}
