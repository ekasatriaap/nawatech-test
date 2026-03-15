<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Product extends Model
{
    protected $table = "products";

    public function orderItems()
    {
        return $this->hasMany(OrderItem::class, "product_id", "id");
    }
}
