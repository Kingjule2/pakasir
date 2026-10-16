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
                'tags' => ['Fast Moving', 'New Arrival', 'Low Stock', 'Over Stock'],
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

    public function batchRestock(Request $request): JsonResponse
    {
        $products = Product::where('stock_in', '<', 30)->orWhere('is_out_of_stock', true)->get();
        $count = 0;

        foreach ($products as $p) {
            $p->stock_in = (int) round($p->total_qty * 0.85);
            $p->is_out_of_stock = false;
            $p->save();
            $count += 60;
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
                'restocked_products_count' => $products->count(),
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
