<?php
/**
 * CORS Configuration
 * Lost & Found IoT System
 * 
 * Handles Cross-Origin Resource Sharing for Flutter app
 */

// ============================================
// CORS Headers
// ============================================

// Allow Flutter app to access API from different origins
header('Access-Control-Allow-Origin: *'); // Change to specific domain in production
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Access-Control-Max-Age: 86400'); // Cache preflight for 24 hours

// Set content type
header('Content-Type: application/json; charset=UTF-8');

// Handle OPTIONS preflight request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// ============================================
// Security Headers
// ============================================

// Prevent clickjacking
header('X-Frame-Options: DENY');

// Prevent MIME sniffing
header('X-Content-Type-Options: nosniff');

// XSS Protection
header('X-XSS-Protection: 1; mode=block');

// Referrer Policy
header('Referrer-Policy: strict-origin-when-cross-origin');

// ============================================
// Production CORS Configuration (Recommended)
// ============================================

/**
 * For production, replace the wildcard (*) with specific origins:
 * 
 * $allowedOrigins = [
 *     'https://yourdomain.com',
 *     'https://yourapp.000webhostapp.com',
 *     'http://localhost:8080', // For local Flutter testing
 * ];
 * 
 * $origin = isset($_SERVER['HTTP_ORIGIN']) ? $_SERVER['HTTP_ORIGIN'] : '';
 * 
 * if (in_array($origin, $allowedOrigins)) {
 *     header("Access-Control-Allow-Origin: $origin");
 * } else {
 *     http_response_code(403);
 *     echo json_encode(['error' => 'Forbidden origin']);
 *     exit;
 * }
 */

?>
