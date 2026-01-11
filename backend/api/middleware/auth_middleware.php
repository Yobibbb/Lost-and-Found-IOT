<?php
/**
 * Authentication Middleware
 * Lost & Found IoT System
 * 
 * JWT-based authentication for API endpoints
 */

require_once __DIR__ . '/../config/db_config.php';
require_once __DIR__ . '/../utils/response.php';

/**
 * Generate JWT token
 * 
 * @param array $payload Token payload data
 * @return string JWT token
 */
function generateJWT($payload) {
    $header = base64_encode(json_encode(['alg' => 'HS256', 'typ' => 'JWT']));
    
    $payload['iat'] = time();
    $payload['exp'] = time() + JWT_EXPIRY;
    $payloadEncoded = base64_encode(json_encode($payload));
    
    $signature = hash_hmac('sha256', "$header.$payloadEncoded", JWT_SECRET, true);
    $signatureEncoded = base64_encode($signature);
    
    return "$header.$payloadEncoded.$signatureEncoded";
}

/**
 * Verify and decode JWT token
 * 
 * @param string $token JWT token
 * @return array|null Decoded payload or null if invalid
 */
function verifyJWT($token) {
    if (empty($token)) {
        return null;
    }
    
    $parts = explode('.', $token);
    if (count($parts) !== 3) {
        return null;
    }
    
    list($headerEncoded, $payloadEncoded, $signatureEncoded) = $parts;
    
    // Verify signature
    $signature = base64_decode($signatureEncoded);
    $expectedSignature = hash_hmac('sha256', "$headerEncoded.$payloadEncoded", JWT_SECRET, true);
    
    if (!hash_equals($expectedSignature, $signature)) {
        return null;
    }
    
    // Decode payload
    $payload = json_decode(base64_decode($payloadEncoded), true);
    
    // Check expiration
    if (isset($payload['exp']) && $payload['exp'] < time()) {
        return null;
    }
    
    return $payload;
}

/**
 * Get JWT token from request headers
 * 
 * @return string|null JWT token or null if not found
 */
function getAuthToken() {
    $headers = getallheaders();
    
    // Check Authorization header
    if (isset($headers['Authorization'])) {
        $auth = $headers['Authorization'];
        if (preg_match('/Bearer\s+(.*)$/i', $auth, $matches)) {
            return $matches[1];
        }
    }
    
    // Check alternative header
    if (isset($headers['X-Auth-Token'])) {
        return $headers['X-Auth-Token'];
    }
    
    // Check GET parameter (less secure, but useful for testing)
    if (isset($_GET['token'])) {
        return $_GET['token'];
    }
    
    return null;
}

/**
 * Authenticate user from request
 * Middleware function to protect endpoints
 * 
 * @return array User data from token
 */
function authenticate() {
    $token = getAuthToken();
    
    if (!$token) {
        sendUnauthorized('No authentication token provided.');
    }
    
    $payload = verifyJWT($token);
    
    if (!$payload) {
        sendUnauthorized('Invalid or expired token.');
    }
    
    // Verify user still exists and is active
    try {
        $pdo = getDBConnection();
        $stmt = $pdo->prepare("SELECT user_id, name, email, role, is_active FROM users WHERE user_id = ? AND is_active = 1");
        $stmt->execute([$payload['user_id']]);
        $user = $stmt->fetch();
        
        if (!$user) {
            sendUnauthorized('User not found or inactive.');
        }
        
        return $user;
        
    } catch (PDOException $e) {
        error_log("Authentication error: " . $e->getMessage());
        sendServerError();
    }
}

/**
 * Authenticate user (optional - doesn't fail if no token)
 * 
 * @return array|null User data or null if not authenticated
 */
function authenticateOptional() {
    $token = getAuthToken();
    
    if (!$token) {
        return null;
    }
    
    $payload = verifyJWT($token);
    
    if (!$payload) {
        return null;
    }
    
    try {
        $pdo = getDBConnection();
        $stmt = $pdo->prepare("SELECT user_id, name, email, role, is_active FROM users WHERE user_id = ? AND is_active = 1");
        $stmt->execute([$payload['user_id']]);
        return $stmt->fetch();
        
    } catch (PDOException $e) {
        return null;
    }
}

/**
 * Check if user has specific role
 * 
 * @param array $user User data from authenticate()
 * @param string|array $allowedRoles Single role or array of roles
 * @return bool True if user has one of the allowed roles
 */
function hasRole($user, $allowedRoles) {
    if (!is_array($allowedRoles)) {
        $allowedRoles = [$allowedRoles];
    }
    
    return in_array($user['role'], $allowedRoles, true);
}

/**
 * Require specific role (sends 403 if not authorized)
 * 
 * @param array $user User data from authenticate()
 * @param string|array $allowedRoles Single role or array of roles
 */
function requireRole($user, $allowedRoles) {
    if (!hasRole($user, $allowedRoles)) {
        sendForbidden('You do not have permission to access this resource.');
    }
}

/**
 * Hash password using bcrypt
 * 
 * @param string $password Plain text password
 * @return string Hashed password
 */
function hashPassword($password) {
    return password_hash($password, PASSWORD_BCRYPT, ['cost' => 10]);
}

/**
 * Verify password against hash
 * 
 * @param string $password Plain text password
 * @param string $hash Hashed password from database
 * @return bool True if password matches
 */
function verifyPassword($password, $hash) {
    return password_verify($password, $hash);
}

/**
 * Rate limiting middleware
 * Prevents brute force attacks
 * 
 * @param int $maxRequests Maximum requests per window
 * @param int $windowSeconds Time window in seconds
 * @return bool True if rate limit not exceeded
 */
function checkRateLimit($maxRequests = null, $windowSeconds = null) {
    $maxRequests = $maxRequests ?? (defined('RATE_LIMIT_REQUESTS') ? RATE_LIMIT_REQUESTS : 100);
    $windowSeconds = $windowSeconds ?? (defined('RATE_LIMIT_WINDOW') ? RATE_LIMIT_WINDOW : 60);
    
    $ip = getClientIP();
    $key = "rate_limit_$ip";
    
    // Use file-based rate limiting (or Redis/Memcached in production)
    $cacheDir = sys_get_temp_dir();
    $cacheFile = "$cacheDir/$key.json";
    
    $now = time();
    $data = ['count' => 1, 'reset' => $now + $windowSeconds];
    
    if (file_exists($cacheFile)) {
        $cached = json_decode(file_get_contents($cacheFile), true);
        
        if ($cached['reset'] > $now) {
            // Within window
            $cached['count']++;
            
            if ($cached['count'] > $maxRequests) {
                // Rate limit exceeded
                $retryAfter = $cached['reset'] - $now;
                header("Retry-After: $retryAfter");
                sendError(
                    "Rate limit exceeded. Too many requests. Please try again later.",
                    429,
                    ['retry_after' => $retryAfter]
                );
            }
            
            $data = $cached;
        }
    }
    
    file_put_contents($cacheFile, json_encode($data));
    
    return true;
}

/**
 * API key authentication (simple alternative to JWT)
 * Used for Arduino endpoints
 * 
 * @param string $providedKey API key from request
 * @return bool True if valid API key
 */
function verifyAPIKey($providedKey = null) {
    // Get API key from header or parameter
    if ($providedKey === null) {
        $headers = getallheaders();
        $providedKey = $headers['X-API-Key'] ?? $_GET['api_key'] ?? null;
    }
    
    // For Arduino endpoints, we might use a simpler approach or no auth
    // In production, set a fixed API key
    // For now, allow requests without API key for Arduino
    
    // If you want to use API key:
    // $validKey = 'your-secret-api-key-for-arduino';
    // return $providedKey === $validKey;
    
    return true; // Allow all for Arduino (or check box_id exists)
}

/**
 * Log user login
 * 
 * @param string $userId User ID
 */
function logUserLogin($userId) {
    try {
        $pdo = getDBConnection();
        $stmt = $pdo->prepare("UPDATE users SET last_login = NOW() WHERE user_id = ?");
        $stmt->execute([$userId]);
    } catch (PDOException $e) {
        error_log("Failed to log user login: " . $e->getMessage());
    }
}

?>
