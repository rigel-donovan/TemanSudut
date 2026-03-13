<!DOCTYPE html>
<html>
<head>
    <title>Transaction History Export</title>
    <style>
        @page { margin: 40px; }
        body { font-family: 'Helvetica', 'Arial', sans-serif; font-size: 11px; color: #3E2723; line-height: 1.5; padding-top: 10px; }
        
        /* Table Layout for Header and Info */
        .layout-table { width: 100%; border-collapse: collapse; margin-bottom: 20px; table-layout: fixed; }
        .layout-table td { vertical-align: top; border: none; padding: 0; }
        
        /* Decorative Header */
        .header-cell { border-bottom: 4px double #8D6E63 !important; padding-bottom: 10px !important; }
        .header-title { font-size: 32px; font-weight: 900; color: #5D4037; letter-spacing: 1px; font-family: 'Times New Roman', serif; }
        .header-subtitle { font-size: 11px; color: #8D6E63; text-transform: uppercase; letter-spacing: 3px; }
        
        /* Info Boxes */
        .info-box { padding: 12px; background: #FFFBF0; border-radius: 6px; border: 1px solid #E0D4B8; min-height: 70px; }
        .info-box.right { background: #6F4E37; color: #FFFFFF; border: none; text-align: right; }
        
        .label { color: #8D6E63; font-size: 9px; text-transform: uppercase; font-weight: bold; display: block; margin-bottom: 4px; }
        .info-box.right .label { color: #D7CCC8; }
        .value { font-weight: bold; font-size: 12px; color: #3E2723; }
        .info-box.right .value { color: #FFFFFF; }
        .total-label { font-size: 10px; text-transform: uppercase; font-weight: bold; }
        .total-value-large { font-size: 22px; font-weight: 900; margin-top: 5px; }
        
        /* Main Transaction Table */
        table.data-table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        table.data-table th { 
            background-color: #5D4037; 
            color: #FFF; 
            padding: 10px 8px; 
            text-align: left; 
            font-size: 9px; 
            text-transform: uppercase; 
            letter-spacing: 1px;
            border: 1px solid #4E342E;
        }
        table.data-table td { padding: 10px 8px; border: 1px solid #EFEBE9; vertical-align: middle; }
        table.data-table tr:nth-child(even) { background-color: #FAF9F6; }
        
        .status-pill { padding: 3px 8px; border-radius: 12px; font-size: 8px; font-weight: 900; text-transform: uppercase; background: #E8F5E9; color: #2E7D32; }
        .amount-col { text-align: right; font-weight: bold; }
        .staff-note { font-size: 9px; color: #8D6E63; font-style: italic; margin-top: 2px; }
        
        /* Bottom Summary */
        .summary-table { width: 300px; margin-left: auto; border-collapse: collapse; margin-top: 30px; }
        .summary-table td { padding: 8px 0; border-bottom: 1px solid #D7CCC8; }
        .summary-label { font-weight: bold; color: #795548; font-size: 11px; }
        .summary-val { text-align: right; font-weight: bold; color: #3E2723; }
        
        .grand-total-box { background: #5D4037; color: white; padding: 15px; border-radius: 6px; text-align: right; margin-top: 10px; }
        .grand-total-text { font-size: 11px; text-transform: uppercase; opacity: 0.8; }
        .grand-total-num { font-size: 18px; font-weight: 900; margin-top: 5px; }
        
        /* Footer */
        .footer { 
            position: fixed; 
            bottom: -30px; 
            left: 0;
            right: 0;
            border-top: 1px solid #E0E0E0; 
            padding-top: 8px; 
            text-align: center; 
            font-size: 9px; 
            color: #9E9E9E;
            background: #FFFFFF;
        }
    </style>
</head>
<body>
    <div style="position: absolute; top: -50px; left: -40px; right: -40px; height: 10px; background: #6F4E37;"></div>

    <!-- Header Table -->
    <table class="layout-table">
        <tr>
            <td class="header-cell">
                <div class="header-title">s u d u t k o p i.</div>
                <div class="header-subtitle">Laporan Transaksi</div>
            </td>
            <td class="header-cell" style="text-align: right; width: 80px;">
                @if($logoBase64)
                    <img src="{{ $logoBase64 }}" style="height: 60px; width: auto;">
                @else
                    <div style="padding: 10px; background: #6F4E37; color: #FFF; font-weight: 900; border-radius: 5px; display: inline-block;">SK</div>
                @endif
            </td>
        </tr>
    </table>

    <!-- Info Section Table -->
    <table class="layout-table" style="margin-top: 15px;">
        <tr>
            <td style="width: 50%; padding-right: 15px;">
                <div class="info-box">
                    <span class="label">Periode Transaksi</span>
                    <span class="value">
                        @if($startDate && $endDate)
                            {{ $startDate->translatedFormat('d F Y') }} — {{ $endDate->translatedFormat('d F Y') }}
                        @else
                            Semua Transaksi
                        @endif
                    </span>
                    <div style="margin-top: 8px;">
                        <span class="label">Generated On</span>
                        <span class="value" style="font-size: 10px;">{{ $generatedOn->translatedFormat('l, d M Y | h:i A') }}</span>
                    </div>
                </div>
            </td>
            <td style="width: 50%;">
                <div class="info-box right">
                    <span class="total-label">Total Revenue Collected</span>
                    <div class="total-value-large">Rp {{ number_format($totalProcessed, 0, ',', '.') }}</div>
                </div>
            </td>
        </tr>
    </table>

    <!-- Data Table -->
    <table class="data-table">
        <thead>
            <tr>
                <th style="width: 15%">Date</th>
                <th style="width: 15%">Order Type</th>
                <th style="width: 15%">Staff</th>
                <th style="width: 25%">Customer</th>
                <th style="width: 10%">Method</th>
                <th style="width: 20%">Amount</th>
            </tr>
        </thead>
        <tbody>
            @foreach($transactions as $trx)
            <tr>
                <td>
                    <span style="font-weight: bold;">{{ $trx->created_at->format('d/m/Y') }}</span><br>
                    <span style="font-size: 8px; color: #999;">{{ $trx->created_at->format('H:i') }}</span>
                </td>
                <td><span class="status-pill">{{ str_replace('_', ' ', $trx->order_type) }}</span></td>
                <td>{{ $trx->user->name ?? 'N/A' }}</td>
                <td>
                    <span style="font-weight: bold;">{{ $trx->customer_name ?? 'Guest' }}</span>
                    <div class="staff-note">Ref #{{ $trx->id }}</div>
                </td>
                <td style="text-align: center; font-weight: bold; color: #6F4E37;">{{ strtoupper($trx->payment_method) }}</td>
                <td class="amount-col">Rp {{ number_format($trx->total, 0, ',', '.') }}</td>
            </tr>
            @endforeach
        </tbody>
    </table>

    <!-- Bottom Summary -->
    <div style="page-break-inside: avoid;">
        <table class="summary-table">
            <tr>
                <td class="summary-label" style="border:none;">Total Transactions</td>
                <td class="summary-val" style="border:none;">{{ $totalCount }} items</td>
            </tr>
            <tr>
                <td colspan="2" style="border:none;">
                    <div class="grand-total-box">
                        <div class="grand-total-text">Grand Total Revenue</div>
                        <div class="grand-total-num">Rp {{ number_format($totalProcessed, 0, ',', '.') }}</div>
                    </div>
                </td>
            </tr>
        </table>
    </div>

    <!-- Fixed Footer -->
    <div class="footer">
        Sudut Kopi - Powered by TemanSudut
    </div>
</body>
</html>
