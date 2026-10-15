<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class StoreOutlet extends Model
{
    use HasFactory;

    protected $fillable = [
        'business_id',
        'name',
        'code',
        'city',
        'address',
        'manager',
        'phone',
        'operating_hours',
        'is_open',
        'terminals_count',
        'daily_sales',
        'monthly_sales',
        'staff_count',
    ];

    protected $casts = [
        'is_open' => 'boolean',
        'terminals_count' => 'integer',
        'staff_count' => 'integer',
        'daily_sales' => 'float',
        'monthly_sales' => 'float',
    ];

    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    public function transactions(): HasMany
    {
        return $this->hasMany(Transaction::class);
    }
}
