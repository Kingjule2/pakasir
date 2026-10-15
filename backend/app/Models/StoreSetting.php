<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class StoreSetting extends Model
{
    use HasFactory;

    protected $fillable = [
        'business_id',
        'store_name',
        'store_tagline',
        'email',
        'phone',
        'address',
        'currency_symbol',
        'currency_code',
        'tax_rate',
        'tax_enabled',
        'service_fee_rate',
        'service_fee_enabled',
        'printer_name',
        'paper_width',
        'auto_print_receipt',
        'sound_alerts',
        'low_stock_threshold',
        'low_stock_notification',
        'daily_report_email',
        'two_factor_auth_enabled',
        'biometric_login_enabled',
        'customer_data_anonymized',
        'language',
    ];

    protected $casts = [
        'tax_rate' => 'float',
        'tax_enabled' => 'boolean',
        'service_fee_rate' => 'float',
        'service_fee_enabled' => 'boolean',
        'auto_print_receipt' => 'boolean',
        'sound_alerts' => 'boolean',
        'low_stock_threshold' => 'integer',
        'low_stock_notification' => 'boolean',
        'daily_report_email' => 'boolean',
        'two_factor_auth_enabled' => 'boolean',
        'biometric_login_enabled' => 'boolean',
        'customer_data_anonymized' => 'boolean',
    ];

    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }
}
