<?php

namespace App\Filament\Widgets;

use Filament\Widgets\Widget;

class LiveClockWidget extends Widget
{
    protected string $view = 'filament.widgets.live-clock-widget';
    
    protected int | string | array $columnSpan = 1;
    
    protected static ?int $sort = 0;
}
