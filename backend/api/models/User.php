<?php
/**
 * User Model
 * Lost & Found IoT System
 */

require_once __DIR__ . '/../config/db_config.php';
require_once __DIR__ . '/../utils/response.php';

class User {
    private $pdo;
    
    public function __construct() {
        $this->pdo = getDBConnection();
    }
    
    /**
     * Create new user
     */
    public function create($userData) {
        $sql = "INSERT INTO users (user_id, name, email, password_hash, phone, role) 
                VALUES (:user_id, :name, :email, :password_hash, :phone, :role)";
        
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute([
            'user_id' => $userData['user_id'],
            'name' => $userData['name'],
            'email' => $userData['email'],
            'password_hash' => $userData['password_hash'],
            'phone' => $userData['phone'] ?? null,
            'role' => $userData['role'] ?? 'both'
        ]);
        
        return $this->getById($userData['user_id']);
    }
    
    /**
     * Get user by ID
     */
    public function getById($userId) {
        $stmt = $this->pdo->prepare("SELECT user_id, name, email, phone, role, fcm_token, is_active, created_at, updated_at, last_login FROM users WHERE user_id = ?");
        $stmt->execute([$userId]);
        return $stmt->fetch();
    }
    
    /**
     * Get user by email
     */
    public function getByEmail($email) {
        $stmt = $this->pdo->prepare("SELECT * FROM users WHERE email = ?");
        $stmt->execute([$email]);
        return $stmt->fetch();
    }
    
    /**
     * Update user
     */
    public function update($userId, $data) {
        $fields = [];
        $params = [];
        
        foreach ($data as $key => $value) {
            if (in_array($key, ['name', 'phone', 'role', 'fcm_token'])) {
                $fields[] = "$key = ?";
                $params[] = $value;
            }
        }
        
        if (empty($fields)) {
            return false;
        }
        
        $params[] = $userId;
        $sql = "UPDATE users SET " . implode(', ', $fields) . " WHERE user_id = ?";
        
        $stmt = $this->pdo->prepare($sql);
        return $stmt->execute($params);
    }
    
    /**
     * Check if email exists
     */
    public function emailExists($email) {
        $stmt = $this->pdo->prepare("SELECT COUNT(*) FROM users WHERE email = ?");
        $stmt->execute([$email]);
        return $stmt->fetchColumn() > 0;
    }
}
?>
