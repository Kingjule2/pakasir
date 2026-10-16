<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('store_subscriptions', function (Blueprint $table) {
            $table->unsignedInteger('id')->primary();
            $table->string('plan')->nullable();
            $table->string('status')->default('inactive');
            $table->timestamp('starts_at')->nullable();
            $table->timestamp('ends_at')->nullable();
            $table->unsignedInteger('prompt_limit')->nullable();
            $table->unsignedBigInteger('billing_invoice_id')->nullable();
            $table->timestamps();
        });
        DB::table('store_subscriptions')->insert(['id' => 1, 'status' => 'inactive', 'created_at' => now(), 'updated_at' => now()]);
        Schema::create('billing_invoices', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->restrictOnDelete();
            $table->uuid('idempotency_key');
            $table->string('order_id')->unique();
            $table->string('plan');
            $table->unsignedInteger('amount');
            $table->string('status')->default('creating');
            $table->text('redirect_url')->nullable();
            $table->timestamp('paid_at')->nullable();
            $table->timestamps();
            $table->unique(['user_id', 'idempotency_key']);
        });
        Schema::create('subscription_usages', function (Blueprint $table) {
            $table->id();
            $table->timestamp('period_start')->unique();
            $table->timestamp('period_end');
            // Includes in-flight reservations; failed provider calls release them.
            $table->unsignedInteger('prompts_used')->default(0);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('subscription_usages');
        Schema::dropIfExists('billing_invoices');
        Schema::dropIfExists('store_subscriptions');
    }
};
