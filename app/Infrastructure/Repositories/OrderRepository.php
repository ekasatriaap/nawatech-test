<?php

namespace App\Infrastructure\Repositories;

use App\Core\Domain\Repositories\OrderRepositoryInterface;
use App\Models\Order;
use Illuminate\Support\Facades\Cache;

class OrderRepository implements OrderRepositoryInterface
{
    public function getAllOrders(): iterable
    {
        return \Illuminate\Support\Facades\DB::cursor("
            SELECT json_build_object(
                'id', o.id,
                'user_id', o.user_id,
                'status', o.status,
                'total_amount', o.total_amount,
                'payment_status', o.payment_status,
                'created_at', o.created_at,
                'updated_at', o.updated_at,
                'user', (
                    SELECT json_build_object('id', u.id, 'name', u.name, 'email', u.email)
                    FROM users u WHERE u.id = o.user_id
                ),
                'order_items', (
                    SELECT COALESCE(json_agg(json_build_object(
                        'id', oi.id,
                        'order_id', oi.order_id,
                        'product_id', oi.product_id,
                        'quantity', oi.quantity,
                        'price', oi.price,
                        'product', (
                            SELECT json_build_object('id', p.id, 'name', p.name, 'price', p.price)
                            FROM products p WHERE p.id = oi.product_id
                        )
                    )), '[]'::json)
                    FROM order_items oi WHERE oi.order_id = o.id
                )
            )::text as json_data
            FROM orders o
            ORDER BY o.created_at DESC
        ");
    }

    public function create(array $data): Order
    {
        return Order::create($data);
    }

    public function report(): Order
    {
        return Cache::remember("report", 60, function () {
            $stats = Order::selectRaw("
                COALESCE(SUM(total_amount) FILTER (WHERE status = 'completed'), 0) as total_amount,
                COUNT(id) as total_order,
                COALESCE(AVG(total_amount) FILTER (WHERE status = 'completed'), 0) as avg_amount
            ")->first();

            $topItems = \App\Models\OrderItem::with("product")
                ->selectRaw("product_id, SUM(quantity) as total_quantity")
                ->groupBy("product_id")
                ->orderBy("total_quantity", "desc")
                ->limit(3)
                ->get();

            $order = new Order();
            $order->setRawAttributes($stats->getAttributes());
            $order->setRelation("orderItems", $topItems);
            return $order;
        });
    }
}
