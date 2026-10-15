<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class AiInsight extends Model
{
    use HasFactory;

    protected $fillable = [
        'business_id',
        'insight_type',
        'title',
        'description',
        'confidence_score',
        'supporting_data',
    ];

    protected $casts = [
        'confidence_score' => 'float',
        'supporting_data' => 'array',
    ];

    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    public function recommendations(): HasMany
    {
        return $this->hasMany(AiRecommendation::class, 'insight_id');
    }
}
