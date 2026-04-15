<!DOCTYPE html>
<html>
<head>
    <title>Struk Belanja</title>
    <style>
        @page { 
            margin: 0;
            size: 80mm auto;
        }
        * { box-sizing: border-box; }
        body { 
            font-family: 'Helvetica', 'Arial', sans-serif; 
            font-size: 12px; 
            color: #000; 
            margin: 0; 
            padding: 0;
        }
        .receipt {
            width: 100%;
            padding: 5mm 3mm;
        }
        .text-center { text-align: center; }
        .text-right { text-align: right; }
        .bold { font-weight: bold; }
        .dashed-line { border-top: 2px dashed #999; margin: 8px 0; }
        
        .header { margin-bottom: 8px; }
        .logo { margin-bottom: 5px; }
        .store-name { font-size: 18px; font-weight: 900; letter-spacing: 2px; color: #3E2723; }
        .store-info { font-size: 11px; margin-bottom: 3px; color: #555; }
        
        .meta-table { width: 100%; font-size: 12px; }
        .meta-table td { padding: 2px 0; }
        
        .items-table { width: 100%; border-collapse: collapse; font-size: 12px; }
        .item-name { font-weight: bold; font-size: 13px; }
        .item-qty { font-size: 11px; color: #555; }
        .item-extra { font-size: 10px; color: #888; font-style: italic; }
        .item-price { text-align: right; font-weight: bold; font-size: 13px; vertical-align: bottom; }
        .item-row td { padding: 5px 0; border-bottom: 1px dotted #ddd; }
        
        .totals-table { width: 100%; font-size: 13px; margin-top: 5px; }
        .totals-table td { padding: 3px 0; }
        .grand-total td { 
            font-size: 16px; 
            font-weight: 900; 
            padding-top: 8px;
            border-top: 2px solid #000; 
        }
        
        .footer { margin-top: 15px; font-size: 11px; color: #777; }
    </style>
</head>
<body>
    <div class="receipt">
        <div class="header text-center">
            @if($logoBase64)
                <div class="logo">
                    <img src="{{ $logoBase64 }}" style="width: 60px; height: 60px;">
                </div>
            @endif
            <div class="store-name">SUDUT KOPI</div>
            <div class="store-info">Jl. Keruang, RT.15/RW.No 35, Gn. Bahagia</div>
            <div class="store-info">Kec. Balikpapan Selatan, Kota Balikpapan</div>
            <div class="store-info">Telp: 085245436632</div>
        </div>

        <div class="dashed-line"></div>

        <div>
            <table class="meta-table">
                @php
                    $custName = $transaction->customer_name ?? 'Guest';
                    $tableNum = '-';
                    if (str_contains($custName, ' - Meja ')) {
                        $parts = explode(' - Meja ', $custName);
                        $custName = $parts[0];
                        $tableNum = $parts[1];
                    }
                @endphp
                <tr>
                    <td>No. INV</td>
                    <td class="text-right bold">#{{ $transaction->id }}</td>
                </tr>
                <tr>
                    <td>Tanggal</td>
                    <td class="text-right">{{ $transaction->created_at->format('d/m/Y H:i') }}</td>
                </tr>
                <tr>
                    <td>Kasir</td>
                    <td class="text-right">{{ $transaction->user->name ?? 'Staff' }}</td>
                </tr>
                <tr>
                    <td>Pelanggan</td>
                    <td class="text-right">{{ $custName }}</td>
                </tr>
                @if($tableNum !== '-')
                <tr>
                    <td>Meja</td>
                    <td class="text-right">{{ $tableNum }}</td>
                </tr>
                @endif
            </table>
        </div>

        <div class="dashed-line"></div>

        <table class="items-table">
            @foreach($transaction->items as $index => $item)
            <tr class="item-row">
                <td>
                    <div class="item-name">{{ $item->product->name }}</div>
                    <div class="item-qty">{{ $item->quantity }} x Rp {{ number_format($item->unit_price, 0, ',', '.') }}</div>
                    @if($item->extra_charge > 0)
                    <div class="item-extra">+ Extra Rp {{ number_format($item->extra_charge, 0, ',', '.') }}/item</div>
                    @endif
                </td>
                <td class="item-price">
                    Rp {{ number_format($item->subtotal, 0, ',', '.') }}
                </td>
            </tr>
            @endforeach
        </table>

        <div class="dashed-line"></div>

        <table class="totals-table">
            <tr>
                <td>Sub Total</td>
                <td class="text-right">Rp {{ number_format($transaction->subtotal, 0, ',', '.') }}</td>
            </tr>
            @if($transaction->tax > 0)
            <tr>
                <td>Pajak (PPN)</td>
                <td class="text-right">Rp {{ number_format($transaction->tax, 0, ',', '.') }}</td>
            </tr>
            @endif
            <tr class="grand-total">
                <td>TOTAL</td>
                <td class="text-right">Rp {{ number_format($transaction->total, 0, ',', '.') }}</td>
            </tr>
            <tr>
                <td>Bayar ({{ strtoupper($transaction->payment_method) }})</td>
                <td class="text-right">Rp {{ number_format($transaction->amount_received ?? $transaction->total, 0, ',', '.') }}</td>
            </tr>
            <tr>
                <td>Kembali</td>
                <td class="text-right bold">Rp {{ number_format($transaction->change_amount ?? 0, 0, ',', '.') }}</td>
            </tr>
        </table>

        <div class="dashed-line"></div>

        <div class="footer text-center">
            <div class="bold" style="color: #3E2723; font-size: 13px;">Terima Kasih!</div>
            <div style="margin-top: 5px;">Kritik & Saran: farisatsal@gmail.com</div>
        </div>
    </div>
</body>
</html>
