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
            'message' => 'required|string|max:4000',
        ]);

        $text = trim($request->message);
        if (strlen($text) > 4000) {
            return response()->json(['success' => false, 'message' => 'Pesan maksimal 4000 byte.'], 422);
        }
        $billing = app(\App\Services\BillingService::class);
        $reservation = $billing->reservePrompt();
        try {
            $convo = AiConversation::firstOrCreate([], ['title' => 'Percakapan Supri AI']);
            $history = $convo->messages()->orderByDesc('id')->take(6)->get()->reverse()
                ->map(fn ($m) => ['role' => $m->role, 'content' => $m->content])->values()->toArray();
            $aiResult = $this->gemini->ask($text, $history);
            $botMsg = \Illuminate\Support\Facades\DB::transaction(function () use ($convo, $text, $aiResult, $billing, $request) {
                AiMessage::create(['conversation_id' => $convo->id, 'role' => 'user', 'content' => $text]);
                if ($billing->canManage($request->user())) {
                    $this->memoryEngine->extractFromConversation($text, $aiResult['content']);
                }
                return AiMessage::create([
                    'conversation_id' => $convo->id, 'role' => 'assistant',
                    'content' => $aiResult['content'], 'widget_type' => $aiResult['widget_type'],
                    'widget_data' => $aiResult['widget_data'],
                ]);
            });
        } catch (\Throwable $e) {
            $billing->releasePrompt($reservation);
            throw $e;
        }

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
            'content' => 'required|string|max:4000',
            'type' => 'nullable|string|max:100',
            'importance' => 'nullable|integer|min:1|max:10',
        ]);
        if (!app(\App\Services\BillingService::class)->canManage($request->user())) {
            return response()->json(['success' => false, 'message' => 'Hanya pemilik toko dapat mengubah catatan AI.'], 403);
        }

        $memory = $this->memoryEngine->record(
            $request->content,
            $request->type ?? 'marketing_rule',
            $request->importance ?? 8,
            0.98,
            null,
            ['trained_by' => 'user_training_api', 'timestamp' => now()->toIso8601String()]
        );

        SecurityAuditLog::create([
            'user' => $request->user()->name,
            'role' => $request->user()->role,
            'action' => "Catatan konteks toko disimpan: [{$memory->memory_type}] {$memory->content}",
            'target' => 'Catatan Supri AI',
            'ip_address' => $request->ip(),
            'status' => 'Sukses',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Catatan toko tersimpan sebagai konteks AI, bukan pelatihan atau fine-tuning model.',
            'data' => $memory,
        ], 201);
    }

    public function salesAnalysis(): JsonResponse
    {
        $salesContext = $this->gemini->gatherBusinessSalesContext();
        $analysis = [
            'sales_summary' => $salesContext['financials'],
            'trends' => [
                'peak_velocity_day' => null,
                'peak_velocity_hours' => null,
                'fast_moving_category' => null,
                'growth_rate' => null,
            ],
            'marketing_recommendations' => [],
            'message' => 'Ringkasan database lokal. Analisis generatif tersedia melalui chat dengan langganan aktif.',
        ];

        return response()->json([
            'success' => true,
            'data' => $analysis,
        ]);
    }

    public function executeRestock(Request $request): JsonResponse
    {
        $request->validate(['items' => 'required|array|min:1|max:100', 'items.*.product_id' => 'required|integer|exists:products,id|distinct', 'items.*.qty' => 'required|integer|min:1|max:100000']);
        $count = 0;
        \Illuminate\Support\Facades\DB::transaction(function () use ($request, &$count) {
            foreach ($request->input('items') as $item) {
                $product = Product::lockForUpdate()->findOrFail($item['product_id']);
                $product->stock_in += $item['qty'];
                $product->is_out_of_stock = false;
                $product->save();
                $count += $item['qty'];
            }
        });
        SecurityAuditLog::create([
            'user' => $request->user()->name,
            'role' => $request->user()->role,
            'action' => "Penerimaan stok manual {$count} unit; tidak mengirim pesanan supplier",
            'target' => 'Inventory',
            'ip_address' => $request->ip(),
            'status' => 'Sukses',
        ]);
        return response()->json([
            'success' => true,
            'message' => "{$count} unit stok diterima dan dicatat. Tidak ada pesanan supplier yang dikirim.",
        ]);
    }
}
