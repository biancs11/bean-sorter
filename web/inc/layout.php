<?php
declare(strict_types=1);
require_once __DIR__ . '/auth.php';

function page_head(string $title, string $active = '', bool $scroll = true): void {
    $cls = $scroll ? 'scroll' : 'noscroll';
    echo '<!doctype html><html lang="en"><head><meta charset="utf-8">',
         '<meta name="viewport" content="width=device-width, initial-scale=1">',
         '<title>' . e($title) . ' - Bean Sorter</title>',
         '<link rel="stylesheet" href="/assets/css/app.css"></head>',
         '<body class="' . $cls . '">';
    echo '<nav class="topbar">',
         '<span class="brand">Bean Sorter</span>',
         '<a class="navlink' . ($active === 'operate' ? ' on' : '') . '" href="/operate.php">Operate</a>',
         '<a class="navlink' . ($active === 'admin' ? ' on' : '') . '" href="/admin/index.php">Admin</a>',
         '<span class="chip" id="engine-chip">engine: ...</span>',
         '<span class="clock" id="clock"></span>';
    if (is_logged_in()) {
        echo '<form class="c-topbar-logout" method="post" action="/admin/logout.php">';
        csrf_field();
        echo '<button class="secondary" type="submit">Log out</button></form>';
    }
    echo '</nav><main>';
}

function page_foot(): void {
    echo '</main><script src="/assets/js/admin.js"></script></body></html>';
}
