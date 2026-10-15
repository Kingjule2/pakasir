<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AiRecommendation extends Model
{
    use HasFactory;

    protected $fillable = [
        'business_id',
        'insight_id',
        'recommendation_type',
        'recommendation',
        'status',
        'outcome',
    ];

    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    public function insight(): BelongsTo
    {
        return $this->belongsTo(AiInsight::class, 'insight_id');
    }
}
