<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('memories', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained('users')->onDelete('cascade');
            $table->foreignId('business_id')->nullable()->constrained('businesses')->onDelete('cascade');
            $table->string('memory_type'); // preference, restock_rule, customer_pattern, finance_goal
            $table->text('content');
            $table->json('embedding_metadata')->nullable();
            $table->decimal('confidence_score', 4, 2)->default(0.95);
            $table->integer('importance_score')->default(5);
            $table->timestamp('last_accessed_at')->nullable();
            $table->timestamps();
        });

        Schema::create('ai_insights', function (Blueprint $table) {
            $table->id();
            $table->foreignId('business_id')->nullable()->constrained('businesses')->onDelete('cascade');
            $table->string('insight_type'); // restock, promo, sales_velocity, cashflow
            $table->string('title');
            $table->text('description');
            $table->decimal('confidence_score', 4, 2)->default(0.90);
            $table->json('supporting_data')->nullable();
            $table->timestamps();
        });

        Schema::create('ai_recommendations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('business_id')->nullable()->constrained('businesses')->onDelete('cascade');
            $table->foreignId('insight_id')->nullable()->constrained('ai_insights')->onDelete('set null');
            $table->string('recommendation_type'); // restock_order, price_discount, campaign_tiktok
            $table->text('recommendation');
            $table->string('status')->default('pending'); // pending, executed, dismissed
            $table->text('outcome')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ai_recommendations');
        Schema::dropIfExists('ai_insights');
        Schema::dropIfExists('memories');
    }
};
