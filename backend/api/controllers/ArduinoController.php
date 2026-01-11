<?php
/**
 * Arduino Controller
 * Lost & Found IoT System
 * 
 * Simple HTTP endpoints for Arduino Uno R3 + ESP8266
 * No authentication required (or simple API key)
 */

require_once __DIR__ . '/../config/db_config.php';
require_once __DIR__ . '/../utils/response.php';
require_once __DIR__ . '/../utils/validator.php';

class ArduinoController {
    private $pdo;
    
    public function __construct() {
        $this->pdo = getDBConnection();
    }
    
    /**
     * Get pending command for a box
     * Arduino polls this endpoint every 3 seconds
     * 
     * GET /api/arduino/command?box_id=BOX_A1
     * 
     * Response: {"success":true,"data":{"command":"unlock","timestamp":"2026-01-11 12:00:00"}}
     *          or {"success":true,"data":{"command":null}} if no command
     */
    public function getCommand() {
        $boxId = getParam('box_id');
        
        if (!$boxId) {
            sendError('box_id parameter is required', 400);
        }
        
        if (!validateBoxID($boxId)) {
            sendError('Invalid box_id format', 400);
        }
        
        try {
            // Get command if exists and not expired
            $sql = "SELECT box_id, command, command_timestamp, 
                           TIMESTAMPDIFF(SECOND, command_timestamp, NOW()) as age_seconds
                    FROM boxes 
                    WHERE box_id = ? AND command IS NOT NULL";
            
            $stmt = $this->pdo->prepare($sql);
            $stmt->execute([$boxId]);
            $box = $stmt->fetch();
            
            if (!$box) {
                // No command or box doesn't exist
                sendSuccess(['command' => null], 'No pending command');
            }
            
            // Check if command expired (older than 60 seconds)
            if ($box['age_seconds'] > COMMAND_EXPIRY) {
                // Command expired, clear it
                $this->clearCommandInternal($boxId);
                sendSuccess(['command' => null], 'No pending command');
            }
            
            // Return command
            sendSuccess([
                'command' => $box['command'],
                'timestamp' => $box['command_timestamp'],
                'age_seconds' => (int)$box['age_seconds']
            ], 'Command found');
            
        } catch (PDOException $e) {
            error_log("Arduino getCommand error: " . $e->getMessage());
            sendServerError();
        }
    }
    
    /**
     * Clear processed command
     * Arduino calls this after successfully executing a command
     * 
     * POST /api/arduino/clear?box_id=BOX_A1
     * 
     * Response: {"success":true,"message":"Command cleared"}
     */
    public function clearCommand() {
        $boxId = getParam('box_id');
        
        if (!$boxId) {
            sendError('box_id parameter is required', 400);
        }
        
        if (!validateBoxID($boxId)) {
            sendError('Invalid box_id format', 400);
        }
        
        try {
            $result = $this->clearCommandInternal($boxId);
            
            if ($result) {
                sendSuccess(null, 'Command cleared successfully');
            } else {
                sendError('Failed to clear command or no command exists', 400);
            }
            
        } catch (PDOException $e) {
            error_log("Arduino clearCommand error: " . $e->getMessage());
            sendServerError();
        }
    }
    
    /**
     * Update box status (for debugging/monitoring)
     * 
     * POST /api/arduino/status
     * Body: {"box_id":"BOX_A1","status":"available"}
     */
    public function updateStatus() {
        $data = getAllParams();
        
        $errors = validateRequired($data, ['box_id', 'status']);
        if (!empty($errors)) {
            sendValidationError($errors);
        }
        
        if (!validateBoxID($data['box_id'])) {
            sendError('Invalid box_id format', 400);
        }
        
        if (!validateBoxStatus($data['status'])) {
            sendError('Invalid status. Must be: available or occupied', 400);
        }
        
        try {
            $sql = "UPDATE boxes SET status = ?, updated_at = NOW() WHERE box_id = ?";
            $stmt = $this->pdo->prepare($sql);
            $result = $stmt->execute([$data['status'], $data['box_id']]);
            
            if ($result) {
                sendSuccess(['box_id' => $data['box_id'], 'status' => $data['status']], 'Status updated');
            } else {
                sendError('Box not found', 404);
            }
            
        } catch (PDOException $e) {
            error_log("Arduino updateStatus error: " . $e->getMessage());
            sendServerError();
        }
    }
    
    /**
     * Heartbeat ping from Arduino
     * Updates last_ping timestamp and is_online status
     * 
     * POST /api/arduino/ping?box_id=BOX_A1
     * 
     * Response: {"success":true,"message":"Ping received"}
     */
    public function ping() {
        $boxId = getParam('box_id');
        
        if (!$boxId) {
            sendError('box_id parameter is required', 400);
        }
        
        if (!validateBoxID($boxId)) {
            sendError('Invalid box_id format', 400);
        }
        
        try {
            $sql = "UPDATE boxes SET last_ping = NOW(), is_online = TRUE WHERE box_id = ?";
            $stmt = $this->pdo->prepare($sql);
            $result = $stmt->execute([$boxId]);
            
            if ($result && $stmt->rowCount() > 0) {
                sendSuccess([
                    'box_id' => $boxId,
                    'timestamp' => date('Y-m-d H:i:s')
                ], 'Ping received');
            } else {
                sendError('Box not found', 404);
            }
            
        } catch (PDOException $e) {
            error_log("Arduino ping error: " . $e->getMessage());
            sendServerError();
        }
    }
    
    /**
     * Get box information (for Arduino setup/debugging)
     * 
     * GET /api/arduino/info?box_id=BOX_A1
     */
    public function getInfo() {
        $boxId = getParam('box_id');
        
        if (!$boxId) {
            sendError('box_id parameter is required', 400);
        }
        
        try {
            $stmt = $this->pdo->prepare("SELECT box_id, box_name, location, status, is_online, last_ping FROM boxes WHERE box_id = ?");
            $stmt->execute([$boxId]);
            $box = $stmt->fetch();
            
            if ($box) {
                sendSuccess($box, 'Box information');
            } else {
                sendNotFound('Box');
            }
            
        } catch (PDOException $e) {
            error_log("Arduino getInfo error: " . $e->getMessage());
            sendServerError();
        }
    }
    
    /**
     * Health check endpoint
     * 
     * GET /api/arduino/health
     */
    public function health() {
        try {
            // Test database connection
            $stmt = $this->pdo->query("SELECT 1");
            $dbOk = $stmt !== false;
            
            // Get system stats
            $stats = $this->pdo->query("
                SELECT 
                    (SELECT COUNT(*) FROM boxes WHERE is_online = TRUE) as online_boxes,
                    (SELECT COUNT(*) FROM boxes WHERE is_online = FALSE) as offline_boxes,
                    (SELECT COUNT(*) FROM boxes WHERE command IS NOT NULL) as pending_commands
            ")->fetch();
            
            sendSuccess([
                'status' => 'healthy',
                'database' => $dbOk ? 'connected' : 'disconnected',
                'timestamp' => date('Y-m-d H:i:s'),
                'stats' => $stats
            ], 'System healthy');
            
        } catch (PDOException $e) {
            error_log("Arduino health check error: " . $e->getMessage());
            sendError('System unhealthy', 500, ['database' => 'disconnected']);
        }
    }
    
    /**
     * Internal method to clear command
     */
    private function clearCommandInternal($boxId) {
        $sql = "UPDATE boxes SET command = NULL, command_timestamp = NULL, command_issued_by = NULL WHERE box_id = ?";
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute([$boxId]);
        return $stmt->rowCount() > 0;
    }
}

// ============================================
// Handle Request (if called directly)
// ============================================

if (php_sapi_name() !== 'cli') {
    // Get action from URL
    $action = $_GET['action'] ?? 'getCommand';
    
    $controller = new ArduinoController();
    
    switch ($action) {
        case 'getCommand':
        case 'command':
            $controller->getCommand();
            break;
            
        case 'clear':
        case 'clearCommand':
            $controller->clearCommand();
            break;
            
        case 'ping':
            $controller->ping();
            break;
            
        case 'status':
        case 'updateStatus':
            $controller->updateStatus();
            break;
            
        case 'info':
        case 'getInfo':
            $controller->getInfo();
            break;
            
        case 'health':
            $controller->health();
            break;
            
        default:
            sendError('Invalid action', 400);
    }
}

?>
