<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('products', function (Blueprint $table) {
            $table->id();
            $table->foreignId('business_id')->nullable()->constrained('businesses')->onDelete('cascade');
            $table->foreignId('category_id')->nullable()->constrained('categories')->onDelete('set null');
            $table->string('name');
            $table->string('sku')->unique();
            $table->text('description')->nullable();
            $table->string('category')->default('General');
            $table->decimal('price', 14, 2)->default(0);
            $table->decimal('cost_price', 14, 2)->default(0);
            $table->integer('total_qty')->default(100);
            $table->integer('stock_in')->default(0);
            $table->string('priority')->default('low'); // high, medium, low
            $table->string('tag')->default('Regular'); // Fast Moving, New Arrival, Low Stock
            $table->string('image_asset')->default('default');
            $table->boolean('is_out_of_stock')->default(false);
            $table->boolean('is_active')->default(true);
            $table->timestamp('deleted_at')->nullable();
            $table->timestamp('delete_after')->nullable();
            $table->string('deleted_reason')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('products');
    }
};
