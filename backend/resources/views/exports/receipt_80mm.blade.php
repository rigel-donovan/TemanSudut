<!DOCTYPE html>
<html>
<head>
    <title>Struk Belanja</title>
    <style>
        @page { 
            margin: 0; 
            size: 80mm 200mm; /* Large height, will be cropped if possible by printer or custom size */
        }
        body { 
            font-family: 'Courier', monospace; 
            font-size: 12px; 
            color: #000; 
            margin: 0; 
            padding: 10mm 5mm;
            width: 70mm; /* Safe width for 80mm paper */
        }
        .text-center { text-align: center; }
        .text-right { text-align: right; }
        .bold { font-weight: bold; }
        .dashed-line { border-top: 1px dashed #000; margin: 5px 0; }
        
        .header { margin-bottom: 10px; }
        .logo { margin-bottom: 5px; }
        .store-name { font-size: 16px; font-weight: 900; }
        .store-info { font-size: 10px; margin-bottom: 2px; }
        
        .meta-info { font-size: 11px; margin-bottom: 10px; }
        
        .items-table { width: 100%; border-collapse: collapse; font-size: 11px; }
        .item-row td { padding: 4px 0; vertical-align: top; }
        .item-details { font-size: 10px; color: #333; }
        
        .totals-section { margin-top: 10px; font-size: 12px; }
        .total-row { margin-bottom: 3px; }
        .grand-total { font-size: 14px; margin-top: 5px; border-top: 1px solid #000; padding-top: 5px; }
        
        .footer { margin-top: 20px; font-size: 10px; }
    </style>
</head>
<body>
    <div class="header text-center">
        @if($logoBase64)
            <div class="logo">
                <img src="{{ $logoBase64 }}" style="width: 30mm; height: 30mm; object-fit: cover; border-radius: 50%; border: 1px solid #000;">
            </div>
        @endif
        <div class="store-name">s u d u t  k o p i.</div>
        <div class="store-info">Jl. Keruang, RT.15/RW.No 35, Gn. Bahagia, Kecamatan Balikpapan Selatan, Kota Balikpapan, Kalimantan Timur 76114</div>
        <div class="store-info">No. Telp: 085245436632</div>
    </div>

    <div class="dashed-line"></div>

    <div class="meta-info">
        <table style="width: 100%;">
            <tr>
                <td>No. INV:</td>
                <td class="text-right">#{{ $transaction->id }}</td>
            </tr>
            <tr>
                <td>Tanggal:</td>
                <td class="text-right">{{ $transaction->created_at->format('d/m/Y') }}</td>
            </tr>
            <tr>
                <td>Waktu:</td>
                <td class="text-right">{{ $transaction->created_at->format('H:i:s') }}</td>
            </tr>
            <tr>
                <td>Kasir:</td>
                <td class="text-right">{{ $transaction->user->name ?? 'Staff' }}</td>
            </tr>
            <tr>
                <td>Pelanggan:</td>
                <td class="text-right">{{ $transaction->customer_name ?? 'Guest' }}</td>
            </tr>
        </table>
    </div>

    <div class="dashed-line"></div>

    <table class="items-table">
        @foreach($transaction->items as $index => $item)
        <tr class="item-row">
            <td colspan="2">
                <div class="bold">{{ $index + 1 }}. {{ $item->product->name }}</div>
                <div class="item-details">
                    {{ $item->quantity }} x {{ number_format($item->unit_price, 0, ',', '.') }}
                </div>
            </td>
            <td class="text-right" style="vertical-align: bottom;">
                Rp {{ number_format($item->subtotal, 0, ',', '.') }}
            </td>
        </tr>
        @endforeach
    </table>

    <div class="dashed-line"></div>

    <div class="totals-section">
        <table style="width: 100%;">
            <tr class="total-row">
                <td>Sub Total</td>
                <td class="text-right">Rp {{ number_format($transaction->subtotal, 0, ',', '.') }}</td>
            </tr>
            @if($transaction->tax > 0)
            <tr class="total-row">
                <td>Pajak (PPN)</td>
                <td class="text-right">Rp {{ number_format($transaction->tax, 0, ',', '.') }}</td>
            </tr>
            @endif
            <tr class="total-row bold grand-total">
                <td>TOTAL</td>
                <td class="text-right">Rp {{ number_format($transaction->total, 0, ',', '.') }}</td>
            </tr>
            <tr class="total-row" style="margin-top: 5px;">
                <td>Bayar ({{ strtoupper($transaction->payment_method) }})</td>
                <td class="text-right">Rp {{ number_format($transaction->total, 0, ',', '.') }}</td>
            </tr>
            <tr class="total-row">
                <td>Kembali</td>
                <td class="text-right">Rp 0</td>
            </tr>
        </table>
    </div>

    <div class="dashed-line"></div>

    <div class="footer text-center">
        <div class="bold">Terima Kasih Telah Berbelanja</div>
        <div style="margin-top: 5px;">Link Kritik dan Saran:</div>
        <div style="font-size: 10px;">farisatsal@gmail.com</div>
        <div style="font-size: 10px;">085245436632</div>
    </div>
</body>
</html>
