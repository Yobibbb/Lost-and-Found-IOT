<?php
/**
 * Response Utility Functions
 * Lost & Found IoT System
 * 
 * Standardized JSON response functions
 */

/**
 * Send success response
 * 
 * @param mixed $data Response data
 * @param string $message Success message
 * @param int $httpCode HTTP status code (default 200)
 */
function sendSuccess($data = null, $message = 'Success', $httpCode = 200) {
    http_response_code($httpCode);
    
    $response = [
        'success' => true,
        'message' => $message,
        'timestamp' => date('Y-m-d H:i:s')
    ];
    
    if ($data !== null) {
        $response['data'] = $data;
    }
    
    echo json_encode($response, JSON_PRETTY_PRINT);
    exit;
}

/**
 * Send error response
 * 
 * @param string $error Error message
 * @param int $httpCode HTTP status code (default 400)
 * @param array $details Optional additional error details
 */
function sendError($error, $httpCode = 400, $details = null) {
    http_response_code($httpCode);
    
    $response = [
        'success' => false,
        'error' => $error,
        'code' => $httpCode,
        'timestamp' => date('Y-m-d H:i:s')
    ];
    
    if ($details !== null) {
        $response['details'] = $details;
    }
    
    // Log error if in debug mode
    if (defined('DEBUG_MODE') && DEBUG_MODE) {
        error_log("API Error [$httpCode]: $error");
        if ($details) {
            error_log("Details: " . json_encode($details));
        }
    }
    
    echo json_encode($response, JSON_PRETTY_PRINT);
    exit;
}

/**
 * Send validation error response
 * 
 * @param array $errors Array of validation errors ['field' => 'error message']
 */
function sendValidationError($errors) {
    sendError('Validation failed', 422, ['validation_errors' => $errors]);
}

/**
 * Send unauthorized response
 * 
 * @param string $message Optional custom message
 */
function sendUnauthorized($message = 'Unauthorized. Please login.') {
    sendError($message, 401);
}

/**
 * Send forbidden response
 * 
 * @param string $message Optional custom message
 */
function sendForbidden($message = 'Access forbidden.') {
    sendError($message, 403);
}

/**
 * Send not found response
 * 
 * @param string $resource Resource type that was not found
 */
function sendNotFound($resource = 'Resource') {
    sendError("$resource not found.", 404);
}

/**
 * Send internal server error
 * 
 * @param string $message Optional custom message
 */
function sendServerError($message = 'Internal server error. Please try again later.') {
    sendError($message, 500);
}

/**
 * Send created response (for POST requests)
 * 
 * @param mixed $data Created resource data
 * @param string $message Success message
 */
function sendCreated($data, $message = 'Resource created successfully.') {
    sendSuccess($data, $message, 201);
}

/**
 * Send paginated response
 * 
 * @param array $items Array of items
 * @param int $total Total count of items
 * @param int $page Current page
 * @param int $pageSize Items per page
 * @param string $message Optional message
 */
function sendPaginated($items, $total, $page, $pageSize, $message = 'Success') {
    $totalPages = ceil($total / $pageSize);
    
    $data = [
        'items' => $items,
        'pagination' => [
            'total' => (int)$total,
            'page' => (int)$page,
            'page_size' => (int)$pageSize,
            'total_pages' => $totalPages,
            'has_next' => $page < $totalPages,
            'has_prev' => $page > 1
        ]
    ];
    
    sendSuccess($data, $message);
}

/**
 * Handle exceptions and send error response
 * 
 * @param Exception $e Exception object
 */
function handleException($e) {
    // Log the full exception
    error_log("Exception: " . $e->getMessage());
    error_log("Stack trace: " . $e->getTraceAsString());
    
    // Send generic error to client (don't expose internal details)
    if (defined('DEBUG_MODE') && DEBUG_MODE) {
        sendServerError('Error: ' . $e->getMessage());
    } else {
        sendServerError();
    }
}

/**
 * Sanitize output to prevent XSS
 * 
 * @param mixed $data Data to sanitize
 * @return mixed Sanitized data
 */
function sanitizeOutput($data) {
    if (is_array($data)) {
        return array_map('sanitizeOutput', $data);
    }
    
    if (is_string($data)) {
        return htmlspecialchars($data, ENT_QUOTES, 'UTF-8');
    }
    
    return $data;
}

/**
 * Log API request for debugging
 * 
 * @param string $endpoint Endpoint called
 * @param string $method HTTP method
 * @param array $params Request parameters
 */
function logRequest($endpoint, $method, $params = []) {
    if (!defined('DEBUG_MODE') || !DEBUG_MODE) {
        return;
    }
    
    $logMessage = sprintf(
        "[%s] %s %s - Params: %s",
        date('Y-m-d H:i:s'),
        $method,
        $endpoint,
        json_encode($params)
    );
    
    error_log($logMessage);
}

/**
 * Get request body as JSON
 * 
 * @return array|null Decoded JSON data or null on error
 */
function getRequestBody() {
    $input = file_get_contents('php://input');
    
    if (empty($input)) {
        return [];
    }
    
    $data = json_decode($input, true);
    
    if (json_last_error() !== JSON_ERROR_NONE) {
        sendError('Invalid JSON in request body', 400);
    }
    
    return $data;
}

/**
 * Get request parameter (GET/POST/JSON body)
 * 
 * @param string $key Parameter key
 * @param mixed $default Default value if not found
 * @return mixed Parameter value or default
 */
function getParam($key, $default = null) {
    // Check GET parameters
    if (isset($_GET[$key])) {
        return $_GET[$key];
    }
    
    // Check POST parameters
    if (isset($_POST[$key])) {
        return $_POST[$key];
    }
    
    // Check JSON body
    $body = getRequestBody();
    if (isset($body[$key])) {
        return $body[$key];
    }
    
    return $default;
}

/**
 * Get all request parameters merged from GET, POST, and JSON body
 * 
 * @return array All parameters
 */
function getAllParams() {
    $params = array_merge($_GET, $_POST);
    $body = getRequestBody();
    
    if (is_array($body)) {
        $params = array_merge($params, $body);
    }
    
    return $params;
}

/**
 * Check if parameter exists
 * 
 * @param string $key Parameter key
 * @return bool True if parameter exists
 */
function hasParam($key) {
    return isset($_GET[$key]) || isset($_POST[$key]) || 
           (is_array(getRequestBody()) && isset(getRequestBody()[$key]));
}

/**
 * Get request method
 * 
 * @return string HTTP method (GET, POST, PUT, DELETE, etc.)
 */
function getRequestMethod() {
    return $_SERVER['REQUEST_METHOD'];
}

/**
 * Get client IP address
 * 
 * @return string Client IP address
 */
function getClientIP() {
    if (!empty($_SERVER['HTTP_CLIENT_IP'])) {
        return $_SERVER['HTTP_CLIENT_IP'];
    } elseif (!empty($_SERVER['HTTP_X_FORWARDED_FOR'])) {
        return $_SERVER['HTTP_X_FORWARDED_FOR'];
    } else {
        return $_SERVER['REMOTE_ADDR'];
    }
}

/**
 * Generate UUID v4
 * 
 * @return string UUID
 */
function generateUUID() {
    return sprintf(
        '%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
        mt_rand(0, 0xffff),
        mt_rand(0, 0xffff),
        mt_rand(0, 0xffff),
        mt_rand(0, 0x0fff) | 0x4000,
        mt_rand(0, 0x3fff) | 0x8000,
        mt_rand(0, 0xffff),
        mt_rand(0, 0xffff),
        mt_rand(0, 0xffff)
    );
}

/**
 * Format timestamp for API response
 * 
 * @param string $timestamp Database timestamp
 * @return string Formatted timestamp (ISO 8601)
 */
function formatTimestamp($timestamp) {
    if (empty($timestamp)) {
        return null;
    }
    
    return date('c', strtotime($timestamp));
}

?>
