<?php

namespace App\Exports;

use App\Models\Transaction;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithMapping;

class HistoryExport implements FromCollection, WithHeadings, WithMapping
{
    protected $transactions;

    public function __construct($transactions)
    {
        $this->transactions = $transactions;
    }

    public function collection()
    {
        return $this->transactions;
    }

    public function headings(): array
    {
        return [
            'ID',
            'Tanggal',
            'Pelanggan',
            'Tipe Pesanan',
            'Jumlah Item',
            'Total Pembayaran',
            'Status'
        ];
    }

    public function map($transaction): array
    {
        $itemsCount = $transaction->items->count();

        return [
            $transaction->id,
            $transaction->created_at->format('Y-m-d H:i:s'),
            $transaction->customer_name ?? 'Guest',
            $transaction->order_type,
            $itemsCount,
            $transaction->total,
            $transaction->kitchen_status,
        ];
    }
}
