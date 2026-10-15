<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Memory extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'business_id',
        'memory_type',
        'content',
        'embedding_metadata',
        'confidence_score',
        'importance_score',
        'last_accessed_at',
    ];

    protected $casts = [
        'embedding_metadata' => 'array',
        'confidence_score' => 'float',
        'importance_score' => 'integer',
        'last_accessed_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }
}
