<?php
/**
 * Database Configuration
 * Lost & Found IoT System
 * 
 * Configure database connection settings here
 */

// ============================================
// Database Configuration
// ============================================

// DEVELOPMENT SETTINGS (XAMPP Local)
define('DB_HOST', 'localhost');
define('DB_NAME', 'lostandfound_db');
define('DB_USER', 'root');
define('DB_PASS', ''); // Empty for XAMPP default

// PRODUCTION SETTINGS (000webhost / InfinityFree)
// Uncomment and update these for production:
// define('DB_HOST', 'localhost'); // or sql123.000webhost.com
// define('DB_NAME', 'id12345_lostandfound');
// define('DB_USER', 'id12345_admin');
// define('DB_PASS', 'your_strong_password');

define('DB_CHARSET', 'utf8mb4');

// ============================================
// Application Configuration
// ============================================

define('APP_NAME', 'Lost & Found IoT');
define('APP_VERSION', '1.0.0');
define('API_VERSION', 'v1');

// JWT Secret Key (CHANGE THIS IN PRODUCTION!)
define('JWT_SECRET', 'your-secret-key-change-this-in-production-use-strong-random-string');
define('JWT_EXPIRY', 86400 * 30); // 30 days in seconds

// Command expiration time (seconds)
define('COMMAND_EXPIRY', 60); // Commands expire after 60 seconds

// Arduino ping timeout (seconds)
define('ARDUINO_PING_TIMEOUT', 120); // Mark offline after 2 minutes

// Rate limiting
define('RATE_LIMIT_REQUESTS', 100); // Max requests per minute per IP
define('RATE_LIMIT_WINDOW', 60); // Time window in seconds

// Upload settings
define('MAX_IMAGE_SIZE', 5 * 1024 * 1024); // 5MB
define('ALLOWED_IMAGE_TYPES', ['image/jpeg', 'image/png', 'image/jpg']);

// Pagination defaults
define('DEFAULT_PAGE_SIZE', 20);
define('MAX_PAGE_SIZE', 100);

// ============================================
// Error Reporting
// ============================================

// Development mode (set to false in production)
define('DEBUG_MODE', true);

if (DEBUG_MODE) {
    error_reporting(E_ALL);
    ini_set('display_errors', 1);
} else {
    error_reporting(0);
    ini_set('display_errors', 0);
}

// ============================================
// Timezone
// ============================================

date_default_timezone_set('UTC'); // Or your local timezone

// ============================================
// Database Connection Function
// ============================================

/**
 * Get PDO database connection
 * 
 * @return PDO Database connection object
 * @throws PDOException If connection fails
 */
function getDBConnection() {
    static $pdo = null;
    
    // Return existing connection if available (connection pooling)
    if ($pdo !== null) {
        return $pdo;
    }
    
    try {
        $dsn = sprintf(
            "mysql:host=%s;dbname=%s;charset=%s",
            DB_HOST,
            DB_NAME,
            DB_CHARSET
        );
        
        $options = [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES   => false,
            PDO::ATTR_PERSISTENT         => false, // Set true for persistent connections
            PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES " . DB_CHARSET
        ];
        
        $pdo = new PDO($dsn, DB_USER, DB_PASS, $options);
        
        return $pdo;
        
    } catch (PDOException $e) {
        // Log error (don't expose to client)
        error_log("Database Connection Error: " . $e->getMessage());
        
        // Return generic error to client
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'error' => 'Database connection failed. Please try again later.',
            'code' => 500
        ]);
        exit;
    }
}

/**
 * Test database connection
 * 
 * @return bool True if connected successfully
 */
function testDBConnection() {
    try {
        $pdo = getDBConnection();
        $stmt = $pdo->query("SELECT 1");
        return $stmt !== false;
    } catch (Exception $e) {
        return false;
    }
}

/**
 * Close database connection
 */
function closeDBConnection() {
    global $pdo;
    $pdo = null;
}

// ============================================
// Auto-load configuration complete
// ============================================

// Test connection on first load (only in debug mode)
if (DEBUG_MODE && php_sapi_name() !== 'cli') {
    // Only test if not CLI (avoid testing during migration scripts)
    // Uncomment to test connection on every request:
    // if (!testDBConnection()) {
    //     error_log("Initial database connection test failed");
    // }
}

?>
