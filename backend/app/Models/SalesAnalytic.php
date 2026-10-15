<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SalesAnalytic extends Model
{
    use HasFactory;

    protected $fillable = [
        'business_id',
        'analysis_date',
        'total_quantity',
        'total_revenue',
        'total_profit',
        'sales_growth',
        'performance_status',
    ];

    protected $casts = [
        'analysis_date' => 'date',
        'total_quantity' => 'integer',
        'total_revenue' => 'float',
        'total_profit' => 'float',
        'sales_growth' => 'float',
    ];

    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }
}
