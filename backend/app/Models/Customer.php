<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Customer extends Model
{
    use HasFactory;

    protected $fillable = [
        'business_id',
        'name',
        'email',
        'phone',
        'tier',
        'total_orders',
        'total_spent',
        'city',
        'last_active',
        'status',
        'notes',
    ];

    protected $casts = [
        'total_orders' => 'integer',
        'total_spent' => 'float',
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
