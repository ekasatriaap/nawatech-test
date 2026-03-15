<?php

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

class CheckoutRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'user_id' => 'required|exists:users,id',
            'items' => 'required|array|min:1',
            'items.*.product_id' => 'required|exists:products,id',
            'items.*.quantity' => 'required|integer|min:1',
        ];
    }

    public function messages(): array
    {
        return [
            "user_id.required" => "User ID is required",
            "user_id.exists" => "User ID does not exist",
            "items.required" => "Items is required",
            "items.array" => "Items must be an array",
            "items.min" => "Items must be at least 1",
            "items.product_id.required" => "Product ID is required",
            "items.product_id.exists" => "Product ID does not exist",
            "items.quantity.required" => "Quantity is required",
            "items.quantity.integer" => "Quantity must be an integer",
            "items.quantity.min" => "Quantity must be at least 1"
        ];
    }
}
