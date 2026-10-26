<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Product;
use App\Models\SecurityAuditLog;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class InventoryController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = Product::query();

        if ($request->query('status') === 'deleted') {
            $query->whereNotNull('deleted_at');
        } elseif ($request->query('status') !== 'all') {
            $query->whereNull('deleted_at');
        }

        if ($request->has('tag') && $request->tag !== 'Semua') {
            $query->where('tag', $request->tag);
        }

        if ($request->has('category') && $request->category !== 'Semua') {
            $query->where('category', $request->category);
        }

        if ($request->has('search') && !empty($request->search)) {
            $s = $request->search;
            $query->where(function ($q) use ($s) {
                $q->where('name', 'like', "%{$s}%")
                    ->orWhere('sku', 'like', "%{$s}%")
                    ->orWhere('category', 'like', "%{$s}%");
            });
        }

        $products = $query->orderBy('id', 'desc')->get();

        return response()->json([
            'success' => true,
            'data' => [
                'total_items' => $products->count(),
                'items' => $products,
                'tags' => ['Fast Moving', 'Regular', 'Discounted', 'Low Demand', 'Dead Items', 'Trending', 'New Arrival', 'Low Stock', 'Over Stock'],
            ],
        ]);
    }

    public function recentlyDeleted(): JsonResponse
    {
        $products = Product::whereNotNull('deleted_at')
            ->orderByDesc('deleted_at')
            ->get()
            ->map(function (Product $product) {
                $deleteAfter = $product->delete_after ?? ($product->deleted_at ? $product->deleted_at->copy()->addDays(30) : now()->addDays(30));
                $daysRemaining = max(0, (int) ceil(now()->diffInSeconds($deleteAfter, false) / 86400));
                $payload = $product->toArray();
                $payload['daysRemaining'] = $daysRemaining;
                $payload['days_remaining'] = $daysRemaining;
                $payload['deleteAfter'] = $deleteAfter->toIso8601String();
                $payload['delete_after'] = $deleteAfter->toIso8601String();
                $payload['deletedReason'] = $product->deleted_reason ?? 'Discontinued';
                $payload['deleted_reason'] = $product->deleted_reason ?? 'Discontinued';
                return $payload;
            });

        return response()->json([
            'success' => true,
            'data' => [
                'total_items' => $products->count(),
                'items' => $products,
            ],
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'sku' => 'required|string|unique:products,sku',
            'category' => 'required|string',
            'price' => 'required|numeric|min:0',
            'cost_price' => 'required|numeric|min:0',
            'total_qty' => 'required|integer|min:1',
            'stock_in' => 'required|integer|min:0',
        ]);

        $product = app(\App\Services\BillingService::class)->createProduct([
            'name' => $request->name,
            'sku' => $request->sku,
            'description' => $request->description ?? '',
            'category' => $request->category,
            'price' => $request->price,
            'cost_price' => $request->cost_price,
            'total_qty' => $request->total_qty,
            'stock_in' => $request->stock_in,
            'priority' => $request->priority ?? 'medium',
            'tag' => $request->tag ?? 'New Arrival',
            'image_asset' => $request->image_asset ?? 'default',
            'is_out_of_stock' => $request->stock_in <= 0,
        ]);

        SecurityAuditLog::create([
            'user' => 'Admin User',
            'role' => 'Superadmin',
            'action' => "Tambah Produk Baru: {$product->name} (SKU: {$product->sku})",
            'target' => 'Inventory',
            'ip_address' => $request->ip(),
            'status' => 'Sukses',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Produk berhasil ditambahkan.',
            'data' => $product,
        ], 201);
    }

    public function show(int $id): JsonResponse
    {
        $product = Product::findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => $product,
        ]);
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $product = Product::findOrFail($id);

        $product->update($request->only([
            'name',
            'description',
            'category',
            'price',
            'cost_price',
            'total_qty',
            'stock_in',
            'priority',
            'tag',
            'is_out_of_stock',
        ]));

        if ($product->stock_in <= 0) {
            $product->is_out_of_stock = true;
            $product->save();
        }

        return response()->json([
            'success' => true,
            'message' => 'Produk berhasil diperbarui.',
            'data' => $product,
        ]);
    }

    public function destroy(int $id): JsonResponse
    {
        $product = Product::findOrFail($id);
        $name = $product->name;
        $product->delete();

        return response()->json([
            'success' => true,
            'message' => "Produk {$name} berhasil dihapus.",
        ]);
    }

    public function restock(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'qty' => 'required|integer|min:1',
        ]);

        $product = Product::findOrFail($id);
        $product->stock_in += $request->qty;
        $product->is_out_of_stock = false;
        $product->save();

        SecurityAuditLog::create([
            'user' => 'Admin User',
            'role' => 'Superadmin',
            'action' => "Restock manual {$request->qty} unit untuk {$product->name}",
            'target' => 'Inventory',
            'ip_address' => $request->ip(),
            'status' => 'Sukses',
        ]);

        return response()->json([
            'success' => true,
            'message' => "Restock {$request->qty} unit untuk {$product->name} berhasil.",
            'data' => $product,
        ]);
    }

    public function softDelete(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'reason' => 'nullable|string|max:255',
            'hold_days' => 'nullable|integer|min:1|max:365',
        ]);

        $product = Product::findOrFail($id);
        $reason = $request->input('reason', 'Discontinued');
        $holdDays = (int) $request->input('hold_days', 30);

        $product->deleted_at = now();
        $product->delete_after = now()->addDays($holdDays);
        $product->deleted_reason = $reason;
        $product->is_active = false;
        $product->save();

        SecurityAuditLog::create([
            'user' => $request->user()?->name ?? 'Admin User',
            'role' => $request->user()?->role ?? 'Superadmin',
            'action' => "Soft Delete Produk: {$product->name} (Alasan: {$reason})",
            'target' => 'Inventory Hold',
            'ip_address' => $request->ip(),
            'status' => 'Peringatan',
        ]);

        return response()->json([
            'success' => true,
            'message' => "Produk {$product->name} dipindahkan ke Recently Deleted (masa retensi {$holdDays} hari).",
            'data' => array_merge($product->toArray(), [
                'daysRemaining' => $holdDays,
                'deleteAfter' => $product->delete_after->toIso8601String(),
                'deletedReason' => $reason,
            ]),
        ]);
    }

    public function restore(Request $request, int $id): JsonResponse
    {
        $product = Product::findOrFail($id);
        $product->deleted_at = null;
        $product->delete_after = null;
        $product->deleted_reason = null;
        $product->is_active = true;
        $product->save();

        SecurityAuditLog::create([
            'user' => $request->user()?->name ?? 'Admin User',
            'role' => $request->user()?->role ?? 'Superadmin',
            'action' => "Pulihkan Produk dari Recently Deleted: {$product->name}",
            'target' => 'Inventory',
            'ip_address' => $request->ip(),
            'status' => 'Sukses',
        ]);

        return response()->json([
            'success' => true,
            'message' => "Produk {$product->name} berhasil dipulihkan ke katalog aktif.",
            'data' => $product,
        ]);
    }

    public function purgeExpired(Request $request): JsonResponse
    {
        $force = $request->boolean('force', false);
        $query = Product::whereNotNull('deleted_at');
        if (!$force) {
            $query->where('delete_after', '<=', now());
        }
        $expired = $query->get();
        $count = $expired->count();
        foreach ($expired as $product) {
            $product->delete();
        }

        SecurityAuditLog::create([
            'user' => $request->user()?->name ?? 'Admin User',
            'role' => $request->user()?->role ?? 'Superadmin',
            'action' => "Purge Permanen {$count} Produk Expired dari Recently Deleted",
            'target' => 'Inventory Recycle Bin',
            'ip_address' => $request->ip(),
            'status' => 'Sukses',
        ]);

        return response()->json([
            'success' => true,
            'message' => "{$count} produk yang melewati masa retensi telah dihapus permanen.",
            'data' => [
                'purged_count' => $count,
            ],
        ]);
    }

    public function batchRestock(Request $request): JsonResponse
    {
        if ($request->has('items') && is_array($request->input('items'))) {
            $request->validate([
                'items' => 'required|array|min:1|max:100',
                'items.*.product_id' => 'required|integer|exists:products,id',
                'items.*.qty' => 'required|integer|min:1|max:100000',
            ]);
            $count = 0;
            $restockedProducts = 0;
            foreach ($request->input('items') as $item) {
                $p = Product::findOrFail($item['product_id']);
                $p->stock_in += (int) $item['qty'];
                $p->is_out_of_stock = false;
                $p->save();
                $count += (int) $item['qty'];
                $restockedProducts++;
            }
        } else {
            $products = Product::whereNull('deleted_at')
                ->where(function ($q) {
                    $q->where('stock_in', '<', 30)->orWhere('is_out_of_stock', true);
                })->get();
            $count = 0;
            $restockedProducts = $products->count();

            foreach ($products as $p) {
                $p->stock_in = (int) round($p->total_qty * 0.85);
                $p->is_out_of_stock = false;
                $p->save();
                $count += 60;
            }
        }

        SecurityAuditLog::create([
            'user' => 'Evano (Sales Admin)',
            'role' => 'Superadmin',
            'action' => "Eksekusi Restock Otomatis {$count} Unit via Memory Engine",
            'target' => 'Inventory Database',
            'ip_address' => $request->ip(),
            'status' => 'Sukses',
        ]);

        return response()->json([
            'success' => true,
            'message' => "Restock order sebanyak {$count} unit berhasil dieksekusi otomatis oleh Memory Engine.",
            'data' => [
                'restocked_products_count' => $restockedProducts,
                'total_units_restocked' => $count,
            ],
        ]);
    }

    public function categories(): JsonResponse
    {
        $categories = Category::all();

        return response()->json([
            'success' => true,
            'data' => $categories,
        ]);
    }
}
