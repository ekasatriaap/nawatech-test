<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Order extends Model
{
    protected $table = "orders";
    protected $fillable = [
        "user_id",
        "status",
        "total_amount",
        "payment_status"
    ];

    public function orderItems()
    {
        return $this->hasMany(OrderItem::class, "order_id", "id");
    }

    public function user()
    {
        return $this->belongsTo(User::class, "user_id", "id");
    }
}
