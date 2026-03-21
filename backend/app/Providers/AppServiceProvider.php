<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;

use Illuminate\Support\Facades\URL;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        $host = request()->getHost();
        $forwardedHost = request()->server('HTTP_X_FORWARDED_HOST', '');

        if (request()->server('HTTP_X_FORWARDED_PROTO') == 'https' || 
            str_contains($host, 'trycloudflare.com') ||
            str_contains($forwardedHost, 'trycloudflare.com') ||
            str_contains($host, 'ngrok') ||
            str_contains($forwardedHost, 'ngrok')) {
            
            $activeHost = $forwardedHost ?: $host;
            URL::forceScheme('https');
            URL::forceRootUrl('https://' . $activeHost);
            config(['app.url' => 'https://' . $activeHost]);
        }
    }
}
