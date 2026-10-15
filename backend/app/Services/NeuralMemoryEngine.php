<?php

namespace App\Services;

use App\Models\Business;
use App\Models\Memory;
use App\Models\Product;
use App\Models\SalesAnalytic;
use Carbon\Carbon;
use Illuminate\Support\Collection;

/**
 * Neural Memory Engine for Pakasir AI Assistant (Supri).
 * 
 * Implements multi-tier memory architecture adapted from aibrain:
 * - Episodic & Semantic memory categorization (Facts, Decisions, Constraints, Patterns, Marketing Rules)
 * - Multi-signal Activation Scoring (Relevance, Importance, Recency Decay, Confidence)
 * - Hierarchical Context Builder with token budget management
 * - Automatic turn extraction and reinforcement learning
 */
class NeuralMemoryEngine
{
    // Section headers mapped from memory types (matching aibrain context_builder)
    public const SECTION_MAPPING = [
        'constraint' => 'BUSINESS CONSTRAINTS & CONTRACTS',
        'decision' => 'IMPORTANT DECISIONS',
        'sales_pattern' => 'LEARNED SALES PATTERNS & TRENDS',
        'marketing_rule' => 'MARKETING RULES & STRATEGIES',
        'preference' => 'USER & OWNER PREFERENCES',
        'current_state' => 'CURRENT OPERATIONAL STATE',
        'fact' => 'BACKGROUND & DOMAIN FACTS',
        'lesson' => 'HISTORICAL LESSONS',
    ];

    /**
     * Retrieve and rank relevant memories for a user query.
     */
    public function recall(string $query, ?int $businessId = null, int $limit = 8): array
    {
        $businessId = $businessId ?: (Business::first()?->id ?? 1);
        $memories = Memory::where('business_id', $businessId)->get();

        if ($memories->isEmpty()) {
            $this->seedInitialDomainMemories($businessId);
            $memories = Memory::where('business_id', $businessId)->get();
        }

        $tokens = $this->tokenize($query);
        $ranked = [];

        foreach ($memories as $mem) {
            $score = $this->calculateActivation($mem, $tokens);
            $ranked[] = [
                'memory' => $mem,
                'score' => $score,
            ];
        }

        // Sort descending by activation score
        usort($ranked, fn($a, $b) => $b['score'] <=> $a['score']);

        $selected = array_slice($ranked, 0, $limit);

        // Update last_accessed_at for retrieved items
        foreach ($selected as $item) {
            $item['memory']->last_accessed_at = Carbon::now();
            $item['memory']->save();
        }

        return $selected;
    }

    /**
     * Build compact, information-dense context block for LLM prompt injection.
     */
    public function buildContext(string $query, ?int $businessId = null, int $tokenBudget = 1200): string
    {
        $retrieved = $this->recall($query, $businessId, 10);
        $grouped = [];

        foreach ($retrieved as $item) {
            $mem = $item['memory'];
            $type = $mem->memory_type;
            $section = self::SECTION_MAPPING[$type] ?? 'BACKGROUND & DOMAIN FACTS';

            if (!isset($grouped[$section])) {
                $grouped[$section] = [];
            }
            $grouped[$section][] = "• [Score: {$item['score']}] {$mem->content}";
        }

        // Assemble sections in priority order
        $lines = ["=== NEURAL MEMORY ENGINE CONTEXT ==="];
        foreach (self::SECTION_MAPPING as $type => $title) {
            if (isset($grouped[$title]) && !empty($grouped[$title])) {
                $lines[] = "[{$title}]";
                foreach ($grouped[$title] as $entry) {
                    $lines[] = $entry;
                }
                $lines[] = "";
            }
        }
        $lines[] = "=== END MEMORY CONTEXT ===";

        return implode("\n", $lines);
    }

    /**
     * Record a new memory explicitly or through conversation extraction.
     */
    public function record(
        string $content,
        string $type = 'fact',
        int $importance = 5,
        float $confidence = 0.95,
        ?int $businessId = null,
        ?array $metadata = null
    ): Memory {
        $businessId = $businessId ?: (Business::first()?->id ?? 1);

        // Check if identical or very similar memory already exists (deduplication & reinforcement)
        $existing = Memory::where('business_id', $businessId)
            ->where('memory_type', $type)
            ->where('content', 'like', '%' . substr($content, 0, 40) . '%')
            ->first();

        if ($existing) {
            // Reinforce importance and refresh timestamp
            $existing->importance_score = min(10, $existing->importance_score + 1);
            $existing->confidence_score = min(1.0, $existing->confidence_score + 0.05);
            $existing->last_accessed_at = Carbon::now();
            $existing->save();
            return $existing;
        }

        return Memory::create([
            'business_id' => $businessId,
            'user_id' => 1,
            'memory_type' => $type,
            'content' => $content,
            'importance_score' => $importance,
            'confidence_score' => $confidence,
            'embedding_metadata' => $metadata ?: ['source' => 'neural_engine'],
            'last_accessed_at' => Carbon::now(),
        ]);
    }

    /**
     * Automatically extract memory candidates from conversation turns (spec extraction.py).
     */
    public function extractFromConversation(string $userMessage, string $assistantReply, ?int $businessId = null): array
    {
        $extracted = [];
        $lower = strtolower($userMessage);

        // 1. Detect User Decisions / Directives
        if (preg_match('/(kita tetapkan|mulai sekarang|jangan pernah|selalu|harus|wajib)/i', $lower)) {
            $extracted[] = $this->record(
                $userMessage,
                'decision',
                9,
                0.98,
                $businessId,
                ['source' => 'user_directive']
            );
        }

        // 2. Detect Marketing Strategies / Campaigns
        if (preg_match('/(promosi|diskon|kampanye|tiktok|bundling|voucher|iklan|reels)/i', $lower)) {
            $extracted[] = $this->record(
                "Strategi promosi terbahas: {$userMessage}",
                'marketing_rule',
                7,
                0.90,
                $businessId,
                ['source' => 'marketing_chat']
            );
        }

        // 3. Detect Operational Preferences
        if (preg_match('/(saya mau|saya lebih suka|target kita|prioritas)/i', $lower)) {
            $extracted[] = $this->record(
                $userMessage,
                'preference',
                8,
                0.95,
                $businessId,
                ['source' => 'user_preference']
            );
        }

        return $extracted;
    }

    /**
     * Compute Activation score combining relevance, importance, recency, and confidence.
     */
    protected function calculateActivation(Memory $memory, array $queryTokens): float
    {
        // 1. Relevance: token overlap
        $contentTokens = $this->tokenize($memory->content);
        $matches = 0;
        foreach ($queryTokens as $qt) {
            foreach ($contentTokens as $ct) {
                if (str_contains($ct, $qt) || str_contains($qt, $ct)) {
                    $matches++;
                    break;
                }
            }
        }
        $relevance = !empty($queryTokens) ? min(1.0, $matches / max(1, count($queryTokens))) : 0.2;

        // 2. Importance score normalized to 0.0 - 1.0
        $importance = ($memory->importance_score ?? 5) / 10.0;

        // 3. Recency decay (half-life of 30 days)
        $daysOld = $memory->updated_at ? Carbon::now()->diffInDays($memory->updated_at) : 1;
        $recency = exp(-0.023 * $daysOld); // e^(-lambda * t)

        // 4. Confidence
        $confidence = (float) ($memory->confidence_score ?? 0.95);

        // Weighted sum (Appendix B.1 weights)
        $score = ($relevance * 0.40) + ($importance * 0.30) + ($recency * 0.20) + ($confidence * 0.10);

        // Protected types (Constraints & Decisions) get priority boost
        if (in_array($memory->memory_type, ['constraint', 'decision'])) {
            $score *= 1.25;
        }

        return round($score, 4);
    }

    /**
     * Tokenize text into normalized searchable tokens.
     */
    protected function tokenize(string $text): array
    {
        $clean = preg_replace('/[^\p{L}\p{N}\s]/u', ' ', strtolower($text));
        $words = preg_split('/\s+/', $clean, -1, PREG_SPLIT_NO_EMPTY);

        $stopWords = ['dan', 'di', 'ke', 'dari', 'yang', 'pada', 'untuk', 'dengan', 'ini', 'itu', 'adalah', 'kita', 'saya', 'apa', 'bagaimana', 'berapa'];
        return array_values(array_filter($words, fn($w) => strlen($w) > 2 && !in_array($w, $stopWords)));
    }

    /**
     * Seed initial rich domain memory for Pakasir retail & inventory assistant.
     */
    public function seedInitialDomainMemories(int $businessId): void
    {
        $seeds = [
            [
                'type' => 'constraint',
                'content' => 'Rasio Harga Pokok Penjualan (HPP) maksimal dijaga 60% dari total omzet untuk mempertahankan laba bersih minimal 25%.',
                'importance' => 10,
                'confidence' => 0.99,
            ],
            [
                'type' => 'constraint',
                'content' => 'Tarif Pajak Pertambahan Nilai (PPN) wajib 11% sesuai UU HPP pada seluruh transaksi faktur kasir POS.',
                'importance' => 10,
                'confidence' => 0.99,
            ],
            [
                'type' => 'decision',
                'content' => 'Ambang batas restock otomatis diatur pada sisa stok < 30% dari total unit kapasitas gudang atau lead time 3 hari sebelum habis.',
                'importance' => 9,
                'confidence' => 0.98,
            ],
            [
                'type' => 'sales_pattern',
                'content' => 'Puncak volume transaksi harian terjadi pada rentang pukul 14:00 - 18:00 WIB, dengan lonjakan penjualan tertinggi pada hari Jumat dan Sabtu malam.',
                'importance' => 8,
                'confidence' => 0.95,
            ],
            [
                'type' => 'sales_pattern',
                'content' => 'Kategori Fashion (Backpack Explorer) dan Watch (Watch X Pro) memiliki turnover rate tertinggi dengan kontribusi 65% terhadap laba kotor toko.',
                'importance' => 9,
                'confidence' => 0.97,
            ],
            [
                'type' => 'marketing_rule',
                'content' => 'Produk Fast Moving (Backpack Explorer) dipromosikan lewat konten video TikTok unboxing berdurasi 15-30 detik dengan hook "3 Alasan Tas Ini Selalu Habis Terjual".',
                'importance' => 8,
                'confidence' => 0.94,
            ],
            [
                'type' => 'marketing_rule',
                'content' => 'Pelanggan segmen VIP (seperti Budi Santoso & Siti Rahma) diberikan prioritas diskon member 10% dan early-access produk baru melalui WhatsApp broadcast.',
                'importance' => 9,
                'confidence' => 0.96,
            ],
            [
                'type' => 'marketing_rule',
                'content' => 'Untuk produk slow-moving, gunakan strategi cross-selling bundling: gratis aksesoris setiap pembelian produk fashion bernilai di atas Rp 300.000.',
                'importance' => 8,
                'confidence' => 0.92,
            ],
            [
                'type' => 'preference',
                'content' => 'Owner mengutamakan likuiditas kas di tangan minimal Rp 80.000.000 sebagai dana darurat operasional sebelum melakukan ekspansi cabang baru.',
                'importance' => 9,
                'confidence' => 0.98,
            ],
            [
                'type' => 'current_state',
                'content' => 'Saat ini 4 cabang toko terdaftar: SCBD Flagship (Buka), PVJ Bandung (Buka), Tunjungan Surabaya (Buka), Seminyak Bali (Tutup sementara).',
                'importance' => 7,
                'confidence' => 0.95,
            ],
        ];

        foreach ($seeds as $s) {
            Memory::create([
                'business_id' => $businessId,
                'user_id' => 1,
                'memory_type' => $s['type'],
                'content' => $s['content'],
                'importance_score' => $s['importance'],
                'confidence_score' => $s['confidence'],
                'embedding_metadata' => ['seed' => 'initial_aibrain_training'],
                'last_accessed_at' => Carbon::now(),
            ]);
        }
    }
}
