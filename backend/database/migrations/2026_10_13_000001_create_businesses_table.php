<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('businesses', function (Blueprint $table) {
            $table->id();
            $table->foreignId('owner_id')->nullable()->constrained('users')->onDelete('cascade');
            $table->string('business_name');
            $table->string('business_type')->default('Retail & Lifestyle');
            $table->string('address')->nullable();
            $table->string('phone')->nullable();
            $table->string('currency')->default('IDR');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('businesses');
    }
};
