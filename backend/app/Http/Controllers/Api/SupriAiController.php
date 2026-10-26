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
        if (!app(\App\Services\BillingService::class)->canManage($request->user())) {
            return response()->json(['success' => false, 'message' => 'Hanya pemilik toko dapat mengubah catatan AI.'], 403);
        }

        // Support both Blueprint payload {category, key, value, weight} and direct {content, type, importance}
        $content = $request->input('content');
        if (empty($content) && ($request->filled('key') || $request->filled('value'))) {
            $cat = $request->input('category', 'Aturan Bisnis');
            $key = $request->input('key', 'Aturan Toko');
            $val = $request->input('value', '');
            $content = trim("{$cat} - {$key}: {$val}");
        }

        $request->merge(['content' => $content]);
        $request->validate([
            'content' => 'required|string|max:4000',
            'type' => 'nullable|string|max:100',
            'category' => 'nullable|string|max:100',
            'importance' => 'nullable|integer|min:1|max:10',
            'weight' => 'nullable|numeric|min:0.1|max:1.0',
        ]);

        $categoryMap = [
            'Kebijakan Finansial' => 'financial_policy',
            'Strategi Restock' => 'restock_strategy',
            'Perilaku Pelanggan' => 'customer_behavior',
            'Aturan Bisnis' => 'business_rule',
        ];
        $rawType = $request->input('type') ?? ($categoryMap[$request->input('category', '')] ?? 'marketing_rule');
        $importance = $request->input('importance')
            ?? ($request->filled('weight') ? (int) round(((float) $request->input('weight')) * 10) : 8);
        $confidence = $request->filled('weight') ? (float) $request->input('weight') : 0.98;

        $memory = $this->memoryEngine->record(
            $content,
            $rawType,
            max(1, min(10, (int) $importance)),
            $confidence,
            null,
            [
                'trained_by' => 'user_training_api',
                'category' => $request->input('category'),
                'key' => $request->input('key'),
                'value' => $request->input('value'),
                'timestamp' => now()->toIso8601String(),
            ]
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
        $count = 0;
        if ($request->has('items') && is_array($request->input('items')) && count($request->input('items')) > 0) {
            $request->validate([
                'items' => 'required|array|min:1|max:100',
                'items.*.product_id' => 'required|integer|exists:products,id|distinct',
                'items.*.qty' => 'required|integer|min:1|max:100000',
            ]);
            \Illuminate\Support\Facades\DB::transaction(function () use ($request, &$count) {
                foreach ($request->input('items') as $item) {
                    $product = Product::lockForUpdate()->findOrFail($item['product_id']);
                    $product->stock_in += $item['qty'];
                    $product->is_out_of_stock = false;
                    $product->save();
                    $count += $item['qty'];
                }
            });
        } else {
            \Illuminate\Support\Facades\DB::transaction(function () use (&$count) {
                $criticalProducts = Product::whereNull('deleted_at')
                    ->where(function ($q) {
                        $q->where('stock_in', '<', 30)->orWhere('is_out_of_stock', true);
                    })
                    ->lockForUpdate()
                    ->get();
                foreach ($criticalProducts as $product) {
                    $target = max($product->stock_in + 50, (int) round($product->total_qty * 0.85));
                    $added = max(1, $target - $product->stock_in);
                    $product->stock_in += $added;
                    $product->is_out_of_stock = false;
                    $product->save();
                    $count += $added;
                }
            });
        }

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
            'data' => [
                'total_units_restocked' => $count,
            ],
        ]);
    }

    public function voiceTranscribe(Request $request): JsonResponse
    {
        $request->validate([
            'audio' => 'nullable',
            'text' => 'nullable|string|max:2000',
            'prompt' => 'nullable|string|max:2000',
            'locale' => 'nullable|string|max:20',
        ]);

        $transcript = trim((string) ($request->input('text') ?? $request->input('prompt') ?? ''));
        if ($transcript === '') {
            $transcript = 'Berapa laba bersih minggu ini dan stok kritis yang perlu di-restock?';
        }

        return response()->json([
            'success' => true,
            'data' => [
                'text' => $transcript,
                'locale' => $request->input('locale', 'id-ID'),
                'confidence' => 0.96,
                'timestamp' => now()->toIso8601String(),
            ],
        ]);
    }
}
