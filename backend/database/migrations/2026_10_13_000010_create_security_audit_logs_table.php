<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('security_audit_logs', function (Blueprint $table) {
            $table->id();
            $table->string('user');
            $table->string('role');
            $table->string('action');
            $table->string('target');
            $table->string('ip_address')->nullable();
            $table->string('status')->default('Sukses'); // Sukses, Peringatan, Diblokir
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('security_audit_logs');
    }
};
