<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('customers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('business_id')->nullable()->constrained('businesses')->onDelete('cascade');
            $table->string('name');
            $table->string('email')->nullable();
            $table->string('phone')->nullable();
            $table->string('tier')->default('Regular'); // VIP, Wholesale, Regular, Baru
            $table->integer('total_orders')->default(0);
            $table->decimal('total_spent', 14, 2)->default(0);
            $table->string('city')->nullable();
            $table->string('last_active')->nullable();
            $table->string('status')->default('Aktif'); // Aktif, Nonaktif
            $table->text('notes')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('customers');
    }
};
