<?php
declare(strict_types=1);
require dirname(__DIR__) . '/inc/auth.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    header('Allow: POST');
    http_response_code(405);
    exit('Method Not Allowed');
}
csrf_check();

if (!is_local_kiosk_session()) {
    http_response_code(403);
    exit('This action is available only from the Raspberry Pi kiosk.');
}

$lock = ROOT . '/var/bean_sorter.lock';
$request = ROOT . '/var/exit-kiosk.request';
if (!is_file($lock)) {
    http_response_code(503);
    exit('The kiosk controller is not running. Close this browser manually.');
}
if (file_put_contents($request, (string)time(), LOCK_EX) === false) {
    http_response_code(500);
    exit('Could not request kiosk exit. Check file permissions.');
}

$_SESSION = [];
session_destroy();
http_response_code(202);
header('Content-Type: text/plain; charset=utf-8');
echo 'Returning to the Raspberry Pi desktop.';
