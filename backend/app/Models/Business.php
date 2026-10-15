<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Business extends Model
{
    use HasFactory;

    protected $fillable = [
        'owner_id',
        'business_name',
        'business_type',
        'address',
        'phone',
        'currency',
    ];

    public function owner(): BelongsTo
    {
        return $this->belongsTo(User::class, 'owner_id');
    }

    public function categories(): HasMany
    {
        return $this->hasMany(Category::class);
    }

    public function products(): HasMany
    {
        return $this->hasMany(Product::class);
    }

    public function customers(): HasMany
    {
        return $this->hasMany(Customer::class);
    }

    public function outlets(): HasMany
    {
        return $this->hasMany(StoreOutlet::class);
    }

    public function transactions(): HasMany
    {
        return $this->hasMany(Transaction::class);
    }

    public function settings(): HasOne
    {
        return $this->hasOne(StoreSetting::class);
    }

    public function analytics(): HasMany
    {
        return $this->hasMany(SalesAnalytic::class);
    }

    public function insights(): HasMany
    {
        return $this->hasMany(AiInsight::class);
    }

    public function recommendations(): HasMany
    {
        return $this->hasMany(AiRecommendation::class);
    }
}
