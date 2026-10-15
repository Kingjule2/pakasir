<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('store_settings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('business_id')->nullable()->constrained('businesses')->onDelete('cascade');
            $table->string('store_name')->default('Vault Retail & Lifestyle');
            $table->string('store_tagline')->default('SaaS Smart Inventory & POS Management');
            $table->string('email')->default('owner@vault-retail.id');
            $table->string('phone')->default('+62 821-8899-7766');
            $table->string('address')->default('Jl. Jenderal Sudirman No. 52, SCBD Jakarta Selatan 12190');
            $table->string('currency_symbol')->default('Rp');
            $table->string('currency_code')->default('IDR');
            $table->decimal('tax_rate', 5, 2)->default(11.00);
            $table->boolean('tax_enabled')->default(true);
            $table->decimal('service_fee_rate', 5, 2)->default(5.00);
            $table->boolean('service_fee_enabled')->default(false);
            $table->string('printer_name')->default('Epson TM-T82X (Thermal)');
            $table->string('paper_width')->default('80mm');
            $table->boolean('auto_print_receipt')->default(true);
            $table->boolean('sound_alerts')->default(true);
            $table->integer('low_stock_threshold')->default(20);
            $table->boolean('low_stock_notification')->default(true);
            $table->boolean('daily_report_email')->default(true);
            $table->boolean('two_factor_auth_enabled')->default(true);
            $table->boolean('biometric_login_enabled')->default(true);
            $table->boolean('customer_data_anonymized')->default(false);
            $table->string('language')->default('Bahasa Indonesia');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('store_settings');
    }
};
