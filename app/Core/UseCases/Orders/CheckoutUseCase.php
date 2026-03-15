<?php

namespace App\Core\UseCases\Orders;

use App\Core\Domain\Repositories\OrderItemRepositoryInterface;
use App\Core\Domain\Repositories\OrderRepositoryInterface;
use App\Core\Domain\Repositories\ProductRepositoryInterface;
use App\Http\Requests\CheckoutRequest;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class CheckoutUseCase
{
    private $orderRepository;
    private $productRepository;
    private $orderItemRepository;
    public function __construct(OrderRepositoryInterface $orderRepository, ProductRepositoryInterface $productRepository, OrderItemRepositoryInterface $orderItemRepository)
    {
        $this->orderRepository = $orderRepository;
        $this->productRepository = $productRepository;
        $this->orderItemRepository = $orderItemRepository;
    }

    public function execute(Request $request): array
    {
        $checkoutRequest = new CheckoutRequest();
        $validator = Validator::make($request->all(), $checkoutRequest->rules(), $checkoutRequest->messages());
        if ($validator->fails()) {
            return [
                'success' => false,
                "message" => $validator->errors()->first(),
                "code" => 422
            ];
        }
        $data = $validator->validated();
        DB::beginTransaction();
        try {
            $tota_amount = 0;
            $order_items = [];

            foreach ($data['items'] as $item) {
                $product = $this->productRepository->findByIdForUpdate($item['product_id']);
                if (!$product) {
                    return [
                        'success' => false,
                        "message" => "Product not found",
                        "code" => 404
                    ];
                }
                if ($product->stock < $item['quantity']) {
                    return [
                        'success' => false,
                        "message" => "Product {$product->name} stock is not enough",
                        "code" => 422
                    ];
                }
                $this->productRepository->decrementStock($product->id, $item['quantity']);
                $tota_amount += $product->price * $item['quantity'];
                $order_items[] = [
                    'product_id' => $product->id,
                    'quantity' => $item['quantity'],
                    'price' => $product->price
                ];
            }
            $data_order = [
                "user_id" => $data['user_id'],
                "status" => "pending",
                "total_amount" => $tota_amount,
                "payment_status" => "pending"
            ];
            $store_order = $this->orderRepository->create($data_order);
            $store_order_item = [];
            foreach ($order_items as $item) {
                $store_order_item[] = $this->orderItemRepository->create($store_order->id, $item);
            }
            DB::commit();
            return [
                "success" => true,
                "message" => "Order checked out successfully",
                "data" => [
                    "order" => $store_order,
                    "order_items" => $store_order_item
                ]
            ];
        } catch (\Throwable $th) {
            DB::rollBack();
            return [
                "success" => false,
                "message" => "Internal Server Error!",
                "code" => 500
            ];
        }
    }
}
