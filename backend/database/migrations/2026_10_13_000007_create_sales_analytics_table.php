<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('sales_analytics', function (Blueprint $table) {
            $table->id();
            $table->foreignId('business_id')->nullable()->constrained('businesses')->onDelete('cascade');
            $table->date('analysis_date');
            $table->integer('total_quantity')->default(0);
            $table->decimal('total_revenue', 14, 2)->default(0);
            $table->decimal('total_profit', 14, 2)->default(0);
            $table->decimal('sales_growth', 6, 2)->default(0);
            $table->string('performance_status')->default('Normal'); // Excellent, Good, Normal, Slow
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('sales_analytics');
    }
};
