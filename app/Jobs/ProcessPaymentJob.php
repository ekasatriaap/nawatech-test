<?php

namespace App\Jobs;

use App\Models\Order;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

class ProcessPaymentJob implements ShouldQueue
{
    use Queueable;

    /**
     * Create a new job instance.
     */
    private $order;
    public function __construct(Order $order)
    {
        $this->order = $order;
    }

    /**
     * Execute the job.
     */
    public function handle(): void
    {
        $status = rand(0, 1);
        $status_order = $status == 1 ? "completed" : "canceled";
        $payment_status = $status == 1 ? "paid" : "failed";

        $this->order->update([
            "status" => $status_order,
            "payment_status" => $payment_status
        ]);
    }
}
