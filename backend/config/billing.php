<?php

return [
    'server_key' => env('MIDTRANS_SERVER_KEY', ''),
    'production' => env('MIDTRANS_IS_PRODUCTION', false),
    'enterprise_contact' => env('BILLING_ENTERPRISE_CONTACT'),
    // This installation is one shared store, not a tenant platform.
    'owner_id' => env('BILLING_OWNER_ID'),
    'enterprise_sop' => env('ENTERPRISE_SOP', ''),
    'plans' => [
        'basic' => ['id' => 'basic', 'name' => 'Basic', 'price' => 99000, 'currency' => 'IDR', 'sku_limit' => 200, 'user_limit' => 1, 'prompt_limit' => 50, 'best_value' => false, 'contact_only' => false],
        'pro' => ['id' => 'pro', 'name' => 'Pro / Juragan', 'price' => 299000, 'currency' => 'IDR', 'sku_limit' => 2000, 'user_limit' => 3, 'prompt_limit' => 2000, 'best_value' => true, 'contact_only' => false],
        'enterprise' => ['id' => 'enterprise', 'name' => 'Enterprise', 'price' => 999000, 'currency' => 'IDR', 'sku_limit' => null, 'user_limit' => null, 'prompt_limit' => null, 'best_value' => false, 'contact_only' => true],
    ],
];
