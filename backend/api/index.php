<?php
/**
 * API Router
 * Lost & Found IoT System
 * 
 * Main entry point for all API requests
 */

// Enable error reporting (disable in production)
ini_set('display_errors', 1);
error_reporting(E_ALL);

// Load configuration and utilities
require_once __DIR__ . '/config/cors.php';
require_once __DIR__ . '/config/db_config.php';
require_once __DIR__ . '/utils/response.php';
require_once __DIR__ . '/utils/validator.php';
require_once __DIR__ . '/middleware/auth_middleware.php';

// Get request URI and method
$requestUri = $_SERVER['REQUEST_URI'];
$requestMethod = $_SERVER['REQUEST_METHOD'];

// Remove query string and base path
$basePath = '/Lost-and-Found-IOT/backend/api';
$uri = str_replace($basePath, '', parse_url($requestUri, PHP_URL_PATH));
$uri = trim($uri, '/');

// Parse route
$parts = explode('/', $uri);
$endpoint = $parts[0] ?? '';
$action = $parts[1] ?? '';
$param = $parts[2] ?? '';

// Log request (debug mode only)
if (DEBUG_MODE) {
    logRequest($uri, $requestMethod, getAllParams());
}

// Rate limiting (optional - comment out for development)
// checkRateLimit();

// ============================================
// Route Handling
// ============================================

try {
    // Arduino endpoints (no auth required)
    if ($endpoint === 'arduino') {
        require_once __DIR__ . '/controllers/ArduinoController.php';
        $controller = new ArduinoController();
        
        switch ($action) {
            case 'command':
                $controller->getCommand();
                break;
                
            case 'clear':
                $controller->clearCommand();
                break;
                
            case 'ping':
                $controller->ping();
                break;
                
            case 'status':
                $controller->updateStatus();
                break;
                
            case 'info':
                $controller->getInfo();
                break;
                
            case 'health':
                $controller->health();
                break;
                
            default:
                sendError('Arduino endpoint not found', 404);
        }
    }
    
    // Auth endpoints (public)
    elseif ($endpoint === 'auth') {
        require_once __DIR__ . '/controllers/AuthController.php';
        $controller = new AuthController();
        
        switch ($action) {
            case 'register':
                if ($requestMethod !== 'POST') {
                    sendError('Method not allowed', 405);
                }
                $controller->register();
                break;
                
            case 'login':
                if ($requestMethod !== 'POST') {
                    sendError('Method not allowed', 405);
                }
                $controller->login();
                break;
                
            case 'profile':
                if ($requestMethod === 'GET') {
                    $user = authenticate();
                    $controller->getProfile($user['user_id']);
                } elseif ($requestMethod === 'PUT') {
                    $user = authenticate();
                    $controller->updateProfile($user['user_id']);
                } else {
                    sendError('Method not allowed', 405);
                }
                break;
                
            case 'fcm-token':
                if ($requestMethod !== 'PUT') {
                    sendError('Method not allowed', 405);
                }
                $user = authenticate();
                $controller->updateFCMToken($user['user_id']);
                break;
                
            default:
                sendError('Auth endpoint not found', 404);
        }
    }
    
    // Box endpoints (requires auth)
    elseif ($endpoint === 'boxes') {
        $user = authenticate();
        require_once __DIR__ . '/controllers/BoxController.php';
        $controller = new BoxController();
        
        if ($action === '' || $action === 'available') {
            // GET /api/boxes or /api/boxes/available
            if ($requestMethod !== 'GET') {
                sendError('Method not allowed', 405);
            }
            if ($action === 'available') {
                $controller->getAvailable();
            } else {
                $controller->getBoxes();
            }
        } elseif ($action === 'unlock') {
            // POST /api/boxes/unlock
            if ($requestMethod !== 'POST') {
                sendError('Method not allowed', 405);
            }
            $controller->unlockBox($user);
        } elseif ($action === 'lock') {
            // POST /api/boxes/lock
            if ($requestMethod !== 'POST') {
                sendError('Method not allowed', 405);
            }
            $controller->lockBox($user);
        } else {
            // GET /api/boxes/{box_id}
            if ($requestMethod !== 'GET') {
                sendError('Method not allowed', 405);
            }
            $controller->getBoxDetails($action);
        }
    }
    
    // Item endpoints (requires auth)
    elseif ($endpoint === 'items') {
        $user = authenticate();
        require_once __DIR__ . '/controllers/ItemController.php';
        $controller = new ItemController();
        
        if ($action === '') {
            // GET /api/items or POST /api/items
            if ($requestMethod === 'GET') {
                $controller->getItems();
            } elseif ($requestMethod === 'POST') {
                $controller->createItem($user);
            } else {
                sendError('Method not allowed', 405);
            }
        } elseif ($action === 'search') {
            // GET /api/items/search?q=keyword
            if ($requestMethod !== 'GET') {
                sendError('Method not allowed', 405);
            }
            $controller->searchItems();
        } elseif ($action === 'founder') {
            // GET /api/items/founder/{founder_id}
            if ($requestMethod !== 'GET') {
                sendError('Method not allowed', 405);
            }
            $founderId = $param ?: $user['user_id'];
            $controller->getFounderItems($founderId);
        } else {
            // GET /api/items/{item_id} or PUT /api/items/{item_id}
            if ($requestMethod === 'GET') {
                $controller->getItemDetails($action);
            } elseif ($requestMethod === 'PUT') {
                $controller->updateItem($action, $user);
            } else {
                sendError('Method not allowed', 405);
            }
        }
    }
    
    // Request endpoints (requires auth)
    elseif ($endpoint === 'requests') {
        $user = authenticate();
        require_once __DIR__ . '/controllers/RequestController.php';
        $controller = new RequestController();
        
        if ($action === '') {
            // POST /api/requests
            if ($requestMethod !== 'POST') {
                sendError('Method not allowed', 405);
            }
            $controller->createRequest($user);
        } elseif ($action === 'founder') {
            // GET /api/requests/founder/{founder_id}
            if ($requestMethod !== 'GET') {
                sendError('Method not allowed', 405);
            }
            $founderId = $param ?: $user['user_id'];
            $controller->getFounderRequests($founderId);
        } elseif ($action === 'finder') {
            // GET /api/requests/finder/{finder_id}
            if ($requestMethod !== 'GET') {
                sendError('Method not allowed', 405);
            }
            $finderId = $param ?: $user['user_id'];
            $controller->getFinderRequests($finderId);
        } else {
            // GET /api/requests/{request_id} or PUT /api/requests/{request_id}/approve
            if ($param === 'approve') {
                if ($requestMethod !== 'PUT') {
                    sendError('Method not allowed', 405);
                }
                $controller->approveRequest($action, $user);
            } elseif ($param === 'reject') {
                if ($requestMethod !== 'PUT') {
                    sendError('Method not allowed', 405);
                }
                $controller->rejectRequest($action, $user);
            } else {
                if ($requestMethod !== 'GET') {
                    sendError('Method not allowed', 405);
                }
                $controller->getRequestDetails($action);
            }
        }
    }
    
    // Message endpoints (requires auth)
    elseif ($endpoint === 'messages') {
        $user = authenticate();
        require_once __DIR__ . '/controllers/MessageController.php';
        $controller = new MessageController();
        
        if ($action === '') {
            // POST /api/messages
            if ($requestMethod !== 'POST') {
                sendError('Method not allowed', 405);
            }
            $controller->sendMessage($user);
        } elseif ($action === 'unread') {
            // GET /api/messages/unread/{user_id}
            if ($requestMethod !== 'GET') {
                sendError('Method not allowed', 405);
            }
            $userId = $param ?: $user['user_id'];
            $controller->getUnreadCount($userId);
        } else {
            // GET /api/messages/{request_id}
            if ($param === 'read') {
                // PUT /api/messages/{message_id}/read
                if ($requestMethod !== 'PUT') {
                    sendError('Method not allowed', 405);
                }
                $controller->markAsRead($action, $user);
            } else {
                if ($requestMethod !== 'GET') {
                    sendError('Method not allowed', 405);
                }
                $controller->getMessages($action, $user);
            }
        }
    }
    
    // Root endpoint (API info)
    elseif ($endpoint === '' || $endpoint === 'index.php') {
        sendSuccess([
            'name' => APP_NAME,
            'version' => APP_VERSION,
            'api_version' => API_VERSION,
            'timestamp' => date('Y-m-d H:i:s'),
            'endpoints' => [
                'arduino' => '/api/arduino/*',
                'auth' => '/api/auth/*',
                'boxes' => '/api/boxes/*',
                'items' => '/api/items/*',
                'requests' => '/api/requests/*',
                'messages' => '/api/messages/*'
            ]
        ], 'API is running');
    }
    
    // Not found
    else {
        sendError('Endpoint not found', 404);
    }
    
} catch (Exception $e) {
    handleException($e);
}

?>
