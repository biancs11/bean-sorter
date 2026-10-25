<?php
declare(strict_types=1);
require dirname(__DIR__) . '/inc/auth.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    header('Allow: POST');
    http_response_code(405);
    exit('Method Not Allowed');
}
csrf_check();

$_SESSION = [];
session_destroy();
header('Location: /admin/login.php');
exit;
