<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Transaction extends Model
{
    use HasFactory;

    protected $fillable = [
        'business_id',
        'store_outlet_id',
        'customer_id',
        'invoice_number',
        'subtotal',
        'discount',
        'tax_amount',
        'service_fee',
        'total_amount',
        'payment_method',
        'payment_status',
        'transaction_date',
    ];

    protected $casts = [
        'subtotal' => 'float',
        'discount' => 'float',
        'tax_amount' => 'float',
        'service_fee' => 'float',
        'total_amount' => 'float',
        'transaction_date' => 'datetime',
    ];

    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    public function outlet(): BelongsTo
    {
        return $this->belongsTo(StoreOutlet::class, 'store_outlet_id');
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function items(): HasMany
    {
        return $this->hasMany(TransactionItem::class);
    }
}
