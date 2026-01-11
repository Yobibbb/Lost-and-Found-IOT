<?php
/**
 * Validator Utility Functions
 * Lost & Found IoT System
 * 
 * Input validation and sanitization functions
 */

/**
 * Validate required fields
 * 
 * @param array $data Input data
 * @param array $required Array of required field names
 * @return array Array of validation errors (empty if valid)
 */
function validateRequired($data, $required) {
    $errors = [];
    
    foreach ($required as $field) {
        if (!isset($data[$field]) || trim($data[$field]) === '') {
            $errors[$field] = ucfirst($field) . ' is required.';
        }
    }
    
    return $errors;
}

/**
 * Validate email format
 * 
 * @param string $email Email address
 * @return bool True if valid email
 */
function validateEmail($email) {
    return filter_var($email, FILTER_VALIDATE_EMAIL) !== false;
}

/**
 * Validate phone number (basic format)
 * 
 * @param string $phone Phone number
 * @return bool True if valid phone
 */
function validatePhone($phone) {
    // Allow international format: +1234567890 or 1234567890
    return preg_match('/^\+?[0-9]{10,15}$/', $phone);
}

/**
 * Validate password strength
 * 
 * @param string $password Password
 * @param int $minLength Minimum length (default 6)
 * @return array Array with 'valid' (bool) and 'error' (string) keys
 */
function validatePassword($password, $minLength = 6) {
    if (strlen($password) < $minLength) {
        return [
            'valid' => false,
            'error' => "Password must be at least $minLength characters long."
        ];
    }
    
    // Optional: Add more complexity requirements
    // if (!preg_match('/[A-Z]/', $password)) {
    //     return ['valid' => false, 'error' => 'Password must contain at least one uppercase letter.'];
    // }
    // if (!preg_match('/[0-9]/', $password)) {
    //     return ['valid' => false, 'error' => 'Password must contain at least one number.'];
    // }
    
    return ['valid' => true, 'error' => null];
}

/**
 * Sanitize string input
 * 
 * @param string $input Input string
 * @return string Sanitized string
 */
function sanitizeString($input) {
    return trim(htmlspecialchars(strip_tags($input), ENT_QUOTES, 'UTF-8'));
}

/**
 * Sanitize integer input
 * 
 * @param mixed $input Input value
 * @return int|null Sanitized integer or null
 */
function sanitizeInt($input) {
    return filter_var($input, FILTER_SANITIZE_NUMBER_INT);
}

/**
 * Sanitize float input
 * 
 * @param mixed $input Input value
 * @return float|null Sanitized float or null
 */
function sanitizeFloat($input) {
    return filter_var($input, FILTER_SANITIZE_NUMBER_FLOAT, FILTER_FLAG_ALLOW_FRACTION);
}

/**
 * Sanitize email input
 * 
 * @param string $email Email address
 * @return string Sanitized email
 */
function sanitizeEmail($email) {
    return filter_var($email, FILTER_SANITIZE_EMAIL);
}

/**
 * Validate UUID format
 * 
 * @param string $uuid UUID string
 * @return bool True if valid UUID
 */
function validateUUID($uuid) {
    $pattern = '/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i';
    return preg_match($pattern, $uuid) === 1;
}

/**
 * Validate enum value
 * 
 * @param mixed $value Value to check
 * @param array $allowedValues Array of allowed values
 * @return bool True if value is in allowed list
 */
function validateEnum($value, $allowedValues) {
    return in_array($value, $allowedValues, true);
}

/**
 * Validate string length
 * 
 * @param string $string Input string
 * @param int $min Minimum length
 * @param int $max Maximum length
 * @return bool True if length is within range
 */
function validateLength($string, $min = 0, $max = PHP_INT_MAX) {
    $length = strlen($string);
    return $length >= $min && $length <= $max;
}

/**
 * Validate URL format
 * 
 * @param string $url URL string
 * @return bool True if valid URL
 */
function validateURL($url) {
    return filter_var($url, FILTER_VALIDATE_URL) !== false;
}

/**
 * Validate date format (YYYY-MM-DD)
 * 
 * @param string $date Date string
 * @return bool True if valid date
 */
function validateDate($date) {
    $d = DateTime::createFromFormat('Y-m-d', $date);
    return $d && $d->format('Y-m-d') === $date;
}

/**
 * Validate datetime format (YYYY-MM-DD HH:MM:SS)
 * 
 * @param string $datetime Datetime string
 * @return bool True if valid datetime
 */
function validateDatetime($datetime) {
    $d = DateTime::createFromFormat('Y-m-d H:i:s', $datetime);
    return $d && $d->format('Y-m-d H:i:s') === $datetime;
}

/**
 * Validate JSON string
 * 
 * @param string $json JSON string
 * @return bool True if valid JSON
 */
function validateJSON($json) {
    json_decode($json);
    return json_last_error() === JSON_ERROR_NONE;
}

/**
 * Validate image file
 * 
 * @param array $file $_FILES array element
 * @param int $maxSize Maximum file size in bytes
 * @return array Array with 'valid' (bool) and 'error' (string) keys
 */
function validateImage($file, $maxSize = null) {
    if (!isset($file['tmp_name']) || !is_uploaded_file($file['tmp_name'])) {
        return ['valid' => false, 'error' => 'No file uploaded.'];
    }
    
    // Check file size
    $maxSize = $maxSize ?? (defined('MAX_IMAGE_SIZE') ? MAX_IMAGE_SIZE : 5 * 1024 * 1024);
    if ($file['size'] > $maxSize) {
        $maxMB = round($maxSize / (1024 * 1024), 2);
        return ['valid' => false, 'error' => "File size must not exceed {$maxMB}MB."];
    }
    
    // Check MIME type
    $allowedTypes = defined('ALLOWED_IMAGE_TYPES') ? ALLOWED_IMAGE_TYPES : ['image/jpeg', 'image/png', 'image/jpg'];
    $finfo = finfo_open(FILEINFO_MIME_TYPE);
    $mimeType = finfo_file($finfo, $file['tmp_name']);
    finfo_close($finfo);
    
    if (!in_array($mimeType, $allowedTypes)) {
        return ['valid' => false, 'error' => 'Invalid image format. Only JPEG and PNG allowed.'];
    }
    
    // Check if actual image
    $imageInfo = getimagesize($file['tmp_name']);
    if ($imageInfo === false) {
        return ['valid' => false, 'error' => 'File is not a valid image.'];
    }
    
    return ['valid' => true, 'error' => null];
}

/**
 * Validate box ID format (e.g., BOX_A1)
 * 
 * @param string $boxId Box ID
 * @return bool True if valid format
 */
function validateBoxID($boxId) {
    return preg_match('/^BOX_[A-Z][0-9]+$/', $boxId) === 1;
}

/**
 * Validate user role
 * 
 * @param string $role User role
 * @return bool True if valid role
 */
function validateUserRole($role) {
    $validRoles = ['founder', 'finder', 'both'];
    return in_array($role, $validRoles, true);
}

/**
 * Validate item status
 * 
 * @param string $status Item status
 * @return bool True if valid status
 */
function validateItemStatus($status) {
    $validStatuses = ['pending_storage', 'waiting', 'to_collect', 'claimed'];
    return in_array($status, $validStatuses, true);
}

/**
 * Validate request status
 * 
 * @param string $status Request status
 * @return bool True if valid status
 */
function validateRequestStatus($status) {
    $validStatuses = ['pending', 'approved', 'rejected', 'completed'];
    return in_array($status, $validStatuses, true);
}

/**
 * Validate box status
 * 
 * @param string $status Box status
 * @return bool True if valid status
 */
function validateBoxStatus($status) {
    $validStatuses = ['available', 'occupied'];
    return in_array($status, $validStatuses, true);
}

/**
 * Validate box command
 * 
 * @param string $command Box command
 * @return bool True if valid command
 */
function validateBoxCommand($command) {
    $validCommands = ['unlock', 'lock'];
    return in_array($command, $validCommands, true);
}

/**
 * Sanitize search query
 * 
 * @param string $query Search query
 * @return string Sanitized query
 */
function sanitizeSearchQuery($query) {
    // Remove special characters that could cause SQL issues
    $query = sanitizeString($query);
    // Remove excessive whitespace
    $query = preg_replace('/\s+/', ' ', $query);
    return trim($query);
}

/**
 * Validate pagination parameters
 * 
 * @param int $page Page number
 * @param int $pageSize Items per page
 * @return array Array with sanitized 'page' and 'page_size'
 */
function validatePagination($page, $pageSize) {
    $page = max(1, (int)$page);
    $pageSize = max(1, min((int)$pageSize, defined('MAX_PAGE_SIZE') ? MAX_PAGE_SIZE : 100));
    
    return ['page' => $page, 'page_size' => $pageSize];
}

/**
 * Validate and sanitize all input data
 * 
 * @param array $data Input data
 * @param array $rules Validation rules ['field' => 'type|required|min:3|max:100']
 * @return array Array with 'valid' (bool), 'data' (sanitized), 'errors' (array)
 */
function validateData($data, $rules) {
    $errors = [];
    $sanitized = [];
    
    foreach ($rules as $field => $ruleString) {
        $ruleList = explode('|', $ruleString);
        $value = isset($data[$field]) ? $data[$field] : null;
        $isRequired = in_array('required', $ruleList);
        
        // Check required
        if ($isRequired && ($value === null || trim($value) === '')) {
            $errors[$field] = ucfirst($field) . ' is required.';
            continue;
        }
        
        // Skip validation if not required and empty
        if (!$isRequired && ($value === null || trim($value) === '')) {
            $sanitized[$field] = null;
            continue;
        }
        
        // Apply rules
        foreach ($ruleList as $rule) {
            if (strpos($rule, ':') !== false) {
                list($ruleName, $ruleValue) = explode(':', $rule);
            } else {
                $ruleName = $rule;
                $ruleValue = null;
            }
            
            switch ($ruleName) {
                case 'email':
                    if (!validateEmail($value)) {
                        $errors[$field] = 'Invalid email format.';
                    } else {
                        $sanitized[$field] = sanitizeEmail($value);
                    }
                    break;
                    
                case 'phone':
                    if (!validatePhone($value)) {
                        $errors[$field] = 'Invalid phone number format.';
                    } else {
                        $sanitized[$field] = sanitizeString($value);
                    }
                    break;
                    
                case 'min':
                    if (strlen($value) < (int)$ruleValue) {
                        $errors[$field] = ucfirst($field) . " must be at least {$ruleValue} characters.";
                    }
                    break;
                    
                case 'max':
                    if (strlen($value) > (int)$ruleValue) {
                        $errors[$field] = ucfirst($field) . " must not exceed {$ruleValue} characters.";
                    }
                    break;
                    
                case 'string':
                    $sanitized[$field] = sanitizeString($value);
                    break;
                    
                case 'int':
                    $sanitized[$field] = (int)$value;
                    break;
                    
                case 'float':
                    $sanitized[$field] = (float)$value;
                    break;
                    
                case 'uuid':
                    if (!validateUUID($value)) {
                        $errors[$field] = 'Invalid UUID format.';
                    } else {
                        $sanitized[$field] = $value;
                    }
                    break;
                    
                case 'url':
                    if (!validateURL($value)) {
                        $errors[$field] = 'Invalid URL format.';
                    } else {
                        $sanitized[$field] = $value;
                    }
                    break;
                    
                default:
                    // Default sanitization
                    if (!isset($sanitized[$field])) {
                        $sanitized[$field] = sanitizeString($value);
                    }
            }
        }
    }
    
    return [
        'valid' => empty($errors),
        'data' => $sanitized,
        'errors' => $errors
    ];
}

?>
