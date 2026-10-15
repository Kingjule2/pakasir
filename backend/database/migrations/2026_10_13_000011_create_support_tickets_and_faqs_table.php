<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('faqs', function (Blueprint $table) {
            $table->id();
            $table->string('category');
            $table->string('question');
            $table->text('answer');
            $table->timestamps();
        });

        Schema::create('support_tickets', function (Blueprint $table) {
            $table->id();
            $table->string('ticket_code')->unique();
            $table->string('subject');
            $table->string('category');
            $table->string('status')->default('Menunggu'); // Menunggu, Diproses, Selesai
            $table->string('priority')->default('Sedang'); // Rendah, Sedang, Tinggi
            $table->text('message')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('support_tickets');
        Schema::dropIfExists('faqs');
    }
};
