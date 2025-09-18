<?php

return [

    'paths' => ['api/*', 'sanctum/csrf-cookie'],

    'allowed_methods' => ['*'],

    // Untuk development boleh '*' dulu. Nanti di production batasi asal domainnya.
    'allowed_origins' => ['*'],

    'allowed_origins_patterns' => [],

    // Boleh pakai ['*'] untuk dev agar simpel.
    'allowed_headers' => ['*'],

    'exposed_headers' => [],

    'max_age' => 0,

    'supports_credentials' => false,

];
