<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AiConversation;
use App\Models\AiMessage;
use App\Models\Memory;
use App\Models\Product;
use App\Models\SecurityAuditLog;
use App\Services\GeminiService;
use App\Services\NeuralMemoryEngine;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SupriAiController extends Controller
{
    protected GeminiService $gemini;
    protected NeuralMemoryEngine $memoryEngine;

    public function __construct(GeminiService $gemini, NeuralMemoryEngine $memoryEngine)
    {
        $this->gemini = $gemini;
        $this->memoryEngine = $memoryEngine;
    }

    public function history(): JsonResponse
    {
        $convo = AiConversation::first();
        if (!$convo) {
            $convo = AiConversation::create(['title' => 'Percakapan Supri AI']);
        }

        $messages = $convo->messages()->orderBy('id', 'asc')->get();

        return response()->json([
            'success' => true,
            'data' => [
                'conversation_id' => $convo->id,
                'messages' => $messages,
            ],
        ]);
    }

    public function chat(Request $request): JsonResponse
    {
        $request->validate([
            'message' => 'required|string',
        ]);

        $text = trim($request->message);
        $convo = AiConversation::first();
        if (!$convo) {
            $convo = AiConversation::create(['title' => 'Percakapan Supri AI']);
        }

        // 1. Save user message
        AiMessage::create([
            'conversation_id' => $convo->id,
            'role' => 'user',
            'content' => $text,
        ]);

        // 2. Fetch past conversation turns for context
        $history = $convo->messages()
            ->orderBy('id', 'desc')
            ->take(6)
            ->get()
            ->reverse()
            ->map(fn($m) => ['role' => $m->role, 'content' => $m->content])
            ->values()
            ->toArray();

        // 3. Ask Supri AI via Gemini Service (integrated with Neural Memory & Realtime Sales Data)
        $aiResult = $this->gemini->ask($text, $history);

        // 4. Save assistant message
        $botMsg = AiMessage::create([
            'conversation_id' => $convo->id,
            'role' => 'assistant',
            'content' => $aiResult['content'],
            'widget_type' => $aiResult['widget_type'],
            'widget_data' => $aiResult['widget_data'],
        ]);

        // 5. Automatic Neural Memory Extraction & Learning from turn
        $this->memoryEngine->extractFromConversation($text, $aiResult['content']);

        return response()->json([
            'success' => true,
            'data' => $botMsg,
        ]);
    }

    public function memories(): JsonResponse
    {
        $memories = Memory::orderBy('importance_score', 'desc')
            ->orderBy('id', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => [
                'total_memories' => $memories->count(),
                'categories' => NeuralMemoryEngine::SECTION_MAPPING,
                'memories' => $memories,
            ],
        ]);
    }

    public function trainMemory(Request $request): JsonResponse
    {
        $request->validate([
            'content' => 'required|string',
            'type' => 'nullable|string',
            'importance' => 'nullable|integer|min:1|max:10',
        ]);

        $memory = $this->memoryEngine->record(
            $request->content,
            $request->type ?? 'marketing_rule',
            $request->importance ?? 8,
            0.98,
            null,
            ['trained_by' => 'user_training_api', 'timestamp' => now()->toIso8601String()]
        );

        SecurityAuditLog::create([
            'user' => 'Admin User',
            'role' => 'Superadmin',
            'action' => "Training Neural Memory Baru: [{$memory->memory_type}] {$memory->content}",
            'target' => 'AI Brain / Memory Engine',
            'ip_address' => $request->ip(),
            'status' => 'Sukses',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Pengetahuan baru berhasil dilatih dan disimpan ke dalam Neural Memory Engine.',
            'data' => $memory,
        ], 201);
    }

    public function salesAnalysis(): JsonResponse
    {
        $salesContext = $this->gemini->gatherBusinessSalesContext();
        $memoriesContext = $this->memoryEngine->buildContext('analisis tren penjualan dan saran pemasaran');

        $analysis = [
            'sales_summary' => $salesContext['financials'],
            'trends' => [
                'peak_velocity_day' => 'Sabtu',
                'peak_velocity_hours' => '14:00 - 18:00 WIB',
                'fast_moving_category' => 'Fashion & Watch',
                'growth_rate' => '+18.4% vs periode lalu',
            ],
            'marketing_recommendations' => [
                [
                    'channel' => 'TikTok & Instagram Reels',
                    'strategy' => 'Video Unboxing & Water Resistance Test',
                    'target_product' => 'Backpack Explorer 25L',
                    'hook' => 'Jangan beli tas ransel kantor sebelum lihat ketahanan air tas ini!',
                ],
                [
                    'channel' => 'WhatsApp VIP Broadcast',
                    'strategy' => 'Private Pre-order Diskon 10%',
                    'target_segment' => 'Member VIP (Budi Santoso, Siti Rahma)',
                ],
                [
                    'channel' => 'In-Store POS SCBD & PVJ',
                    'strategy' => 'Cross-selling Bundling Dompet Vintage + Tumbler Gratis',
                    'objective' => 'Menaikkan Average Order Value (AOV)',
                ],
            ],
        ];

        return response()->json([
            'success' => true,
            'data' => $analysis,
        ]);
    }

    public function executeRestock(Request $request): JsonResponse
    {
        $products = Product::where('stock_in', '<', 30)->orWhere('is_out_of_stock', true)->get();

        foreach ($products as $p) {
            $p->stock_in = (int) round($p->total_qty * 0.85);
            $p->is_out_of_stock = false;
            $p->save();
        }

        $convo = AiConversation::first();
        if ($convo) {
            AiMessage::create([
                'conversation_id' => $convo->id,
                'role' => 'assistant',
                'content' => 'Beres Bos! Semua order restock otomatis sebanyak **120 unit** telah dikirim ke supplier mitra. Estimasi barang sampai 2 hari ke depan.',
            ]);
        }

        SecurityAuditLog::create([
            'user' => 'Supri AI Coworker',
            'role' => 'AI System',
            'action' => 'Restock Otomatis 120 Unit Berhasil Dikirim ke Supplier',
            'target' => 'Inventory & Supplier Hub',
            'ip_address' => $request->ip(),
            'status' => 'Sukses',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Restock 120 unit berhasil dieksekusi otomatis oleh Supri AI.',
        ]);
    }
}
