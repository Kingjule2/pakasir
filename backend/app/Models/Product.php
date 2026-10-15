<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Product extends Model
{
    use HasFactory;

    protected $fillable = [
        'business_id',
        'category_id',
        'name',
        'sku',
        'description',
        'category',
        'price',
        'cost_price',
        'total_qty',
        'stock_in',
        'priority',
        'tag',
        'image_asset',
        'is_out_of_stock',
        'is_active',
    ];

    protected $casts = [
        'price' => 'float',
        'cost_price' => 'float',
        'total_qty' => 'integer',
        'stock_in' => 'integer',
        'is_out_of_stock' => 'boolean',
        'is_active' => 'boolean',
    ];

    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    public function categoryRel(): BelongsTo
    {
        return $this->belongsTo(Category::class, 'category_id');
    }

    public function transactionItems(): HasMany
    {
        return $this->hasMany(TransactionItem::class);
    }
}
