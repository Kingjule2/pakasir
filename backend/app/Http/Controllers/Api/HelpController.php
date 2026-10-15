<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Faq;
use App\Models\SupportTicket;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class HelpController extends Controller
{
    public function faqs(Request $request): JsonResponse
    {
        $query = Faq::query();

        if ($request->has('category') && $request->category !== 'Semua') {
            $query->where('category', $request->category);
        }

        if ($request->has('search') && !empty($request->search)) {
            $s = $request->search;
            $query->where(function ($q) use ($s) {
                $q->where('question', 'like', "%{$s}%")
                    ->orWhere('answer', 'like', "%{$s}%");
            });
        }

        $faqs = $query->get();

        return response()->json([
            'success' => true,
            'data' => [
                'categories' => [
                    'Semua',
                    'Inventaris & Stok',
                    'AI Supri Assistant',
                    'Kasir & POS',
                    'Pajak & Laporan',
                    'Perangkat & Printer',
                ],
                'faqs' => $faqs,
            ],
        ]);
    }

    public function tickets(): JsonResponse
    {
        $tickets = SupportTicket::orderBy('id', 'desc')->get();

        return response()->json([
            'success' => true,
            'data' => $tickets,
        ]);
    }

    public function submitTicket(Request $request): JsonResponse
    {
        $request->validate([
            'subject' => 'required|string|max:255',
            'category' => 'required|string',
            'message' => 'required|string',
        ]);

        $ticketCode = 'TCK-' . date('Y') . '-' . str_pad((string) (SupportTicket::count() + 1), 3, '0', STR_PAD_LEFT);

        $ticket = SupportTicket::create([
            'ticket_code' => $ticketCode,
            'subject' => $request->subject,
            'category' => $request->category,
            'status' => 'Menunggu',
            'priority' => $request->priority ?? 'Sedang',
            'message' => $request->message,
        ]);

        return response()->json([
            'success' => true,
            'message' => "Tiket #{$ticket->ticket_code} berhasil dibuat dan dikirim ke tim support.",
            'data' => $ticket,
        ], 201);
    }
}
