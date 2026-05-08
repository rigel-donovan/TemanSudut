<!DOCTYPE html>
<html>
<head>
    <title>Laporan Transaksi - Sudut Kopi</title>
    <style>
        @page { margin: 36px 40px; }
        body { font-family: 'Helvetica', 'Arial', sans-serif; font-size: 11px; color: #3E2723; line-height: 1.5; }

        /* Header */
        .header-bar { width: 100%; border-collapse: collapse; margin-bottom: 16px; }
        .header-bar td { vertical-align: middle; border: none; padding: 0; }
        .brand { font-size: 26px; font-weight: 900; color: #5D4037; letter-spacing: 1px; font-family: 'Times New Roman', serif; }
        .brand-sub { font-size: 9px; color: #8D6E63; text-transform: uppercase; letter-spacing: 3px; margin-top: 2px; }
        .divider { border: none; border-top: 3px double #8D6E63; margin: 10px 0 14px; }

        /* Info row */
        .info-row { width: 100%; border-collapse: collapse; margin-bottom: 16px; }
        .info-row td { vertical-align: top; border: none; padding: 0; }
        .info-box { padding: 10px 14px; background: #FFFBF0; border: 1px solid #E0D4B8; border-radius: 6px; }
        .info-box-dark { padding: 10px 14px; background: #5D4037; border-radius: 6px; text-align: right; }
        .lbl { display: block; font-size: 8px; text-transform: uppercase; font-weight: bold; color: #8D6E63; margin-bottom: 3px; }
        .lbl-w { display: block; font-size: 8px; text-transform: uppercase; font-weight: bold; color: #D7CCC8; margin-bottom: 3px; }
        .val { font-weight: bold; font-size: 12px; color: #3E2723; }
        .val-w { font-weight: bold; font-size: 12px; color: #fff; }
        .total-big { font-size: 20px; font-weight: 900; color: #fff; margin-top: 4px; }

        /* Summary table */
        .data-table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        .data-table th {
            background: #5D4037; color: #fff;
            padding: 9px 8px; text-align: left;
            font-size: 9px; text-transform: uppercase; letter-spacing: 0.8px;
            border: 1px solid #4E342E;
        }
        .data-table th.right, .data-table td.right { text-align: right; }
        .data-table th.center, .data-table td.center { text-align: center; }
        .data-table td { padding: 8px 8px; border: 1px solid #EFEBE9; vertical-align: middle; }
        .data-table tr:nth-child(even) td { background: #FAF9F6; }
        .data-table tfoot td { background: #3E2723; color: #fff; font-weight: bold; border: 1px solid #4E342E; padding: 9px 8px; }

        /* Footer */
        .footer {
            position: fixed; bottom: -30px; left: 0; right: 0;
            border-top: 1px solid #E0E0E0;
            padding-top: 6px; text-align: center;
            font-size: 8px; color: #9E9E9E; background: #fff;
        }

        .note { font-size: 9px; color: #8D6E63; margin-top: 12px; font-style: italic; }
    </style>
</head>
<body>
    <div style="position:absolute;top:-36px;left:-40px;right:-40px;height:8px;background:#6F4E37;"></div>

    <!-- Brand Header -->
    <table class="header-bar">
        <tr>
            <td>
                <div class="brand">s u d u t &nbsp;k o p i.</div>
                <div class="brand-sub">Laporan Transaksi Harian</div>
            </td>
            <td style="text-align:right;width:80px;">
                @if($logoBase64)
                    <img src="{{ $logoBase64 }}" style="height:54px;width:auto;">
                @else
                    <div style="padding:10px;background:#6F4E37;color:#fff;font-weight:900;border-radius:5px;display:inline-block;">SK</div>
                @endif
            </td>
        </tr>
    </table>
    <hr class="divider">

    <!-- Info Row -->
    <table class="info-row">
        <tr>
            <td style="width:58%;padding-right:12px;">
                <div class="info-box">
                    <span class="lbl">Periode Laporan</span>
                    <span class="val">
                        @if($startDate && $endDate)
                            {{ $startDate->format('d M Y') }}
                            @if($startDate->format('Y-m-d') !== $endDate->format('Y-m-d'))
                                &nbsp;–&nbsp;{{ $endDate->format('d M Y') }}
                            @endif
                        @else
                            Semua Transaksi
                        @endif
                    </span>
                    <div style="margin-top:8px;">
                        <span class="lbl">Dicetak pada</span>
                        <span class="val" style="font-size:10px;">{{ $generatedOn->format('l, d M Y — H:i') }}</span>
                    </div>
                </div>
            </td>
            <td style="width:42%;">
                <div class="info-box-dark">
                    <span class="lbl-w">Total Transaksi</span>
                    <span class="val-w">{{ number_format($totalCount) }} transaksi</span>
                    <div style="margin-top:8px;">
                        <span class="lbl-w">Total Pendapatan</span>
                        <div class="total-big">Rp {{ number_format($totalProcessed, 0, ',', '.') }}</div>
                    </div>
                </div>
            </td>
        </tr>
    </table>

    <!-- Daily Summary Table -->
    <table class="data-table">
        <thead>
            <tr>
                <th style="width:18%">Tanggal</th>
                <th class="center" style="width:14%">Jml Trx</th>
                <th class="center" style="width:12%">Cash</th>
                <th class="center" style="width:12%">QRIS</th>
                <th class="center" style="width:12%">Lainnya</th>
                <th class="right" style="width:32%">Total Hari Ini</th>
            </tr>
        </thead>
        <tbody>
            @foreach($dailySummary as $row)
            <tr>
                <td style="font-weight:bold;">{{ \Carbon\Carbon::parse($row->day)->format('d M Y') }}</td>
                <td class="center">{{ number_format($row->trx_count) }}</td>
                <td class="center">{{ number_format($row->cash_count) }}</td>
                <td class="center">{{ number_format($row->qris_count) }}</td>
                <td class="center">{{ number_format($row->trx_count - $row->cash_count - $row->qris_count) }}</td>
                <td class="right" style="font-weight:bold;color:#5D4037;">Rp {{ number_format($row->day_total, 0, ',', '.') }}</td>
            </tr>
            @endforeach
        </tbody>
        <tfoot>
            <tr>
                <td>TOTAL</td>
                <td class="center">{{ number_format($totalCount) }}</td>
                <td class="center">{{ number_format($dailySummary->sum('cash_count')) }}</td>
                <td class="center">{{ number_format($dailySummary->sum('qris_count')) }}</td>
                <td class="center">{{ number_format($totalCount - $dailySummary->sum('cash_count') - $dailySummary->sum('qris_count')) }}</td>
                <td class="right">Rp {{ number_format($totalProcessed, 0, ',', '.') }}</td>
            </tr>
        </tfoot>
    </table>

    <div class="note">
        * Laporan ini merupakan ringkasan per hari. Untuk detail lengkap tiap transaksi, gunakan fitur Export Excel.
    </div>

    <div class="footer">
        Sudut Kopi &nbsp;|&nbsp; Powered by TemanSudut &nbsp;|&nbsp; {{ $generatedOn->format('d/m/Y H:i') }}
    </div>
</body>
</html>
