<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('store_outlets', function (Blueprint $table) {
            $table->id();
            $table->foreignId('business_id')->nullable()->constrained('businesses')->onDelete('cascade');
            $table->string('name');
            $table->string('code')->unique();
            $table->string('city');
            $table->string('address');
            $table->string('manager');
            $table->string('phone');
            $table->string('operating_hours')->default('09:00 - 22:00 WIB');
            $table->boolean('is_open')->default(true);
            $table->integer('terminals_count')->default(2);
            $table->decimal('daily_sales', 14, 2)->default(0);
            $table->decimal('monthly_sales', 14, 2)->default(0);
            $table->integer('staff_count')->default(4);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('store_outlets');
    }
};
