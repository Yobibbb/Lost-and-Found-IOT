-- ============================================
-- Lost & Found IoT System - MySQL Database Schema
-- ============================================
-- Version: 1.0
-- Description: Complete database schema for Flutter app with Arduino integration
-- ============================================

-- Set charset and collation
SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;

-- Drop tables if exist (for clean setup)
DROP TABLE IF EXISTS messages;
DROP TABLE IF EXISTS retrieval_requests;
DROP TABLE IF EXISTS items;
DROP TABLE IF EXISTS boxes;
DROP TABLE IF EXISTS users;

-- ============================================
-- Users Table
-- ============================================
CREATE TABLE users (
    user_id VARCHAR(50) PRIMARY KEY COMMENT 'Unique user identifier (UUID)',
    name VARCHAR(100) NOT NULL COMMENT 'User full name',
    email VARCHAR(150) UNIQUE NOT NULL COMMENT 'User email (unique login)',
    password_hash VARCHAR(255) NOT NULL COMMENT 'Bcrypt hashed password',
    phone VARCHAR(20) DEFAULT NULL COMMENT 'Optional phone number',
    role ENUM('founder', 'finder', 'both') DEFAULT 'both' COMMENT 'User role in system',
    fcm_token VARCHAR(255) DEFAULT NULL COMMENT 'Firebase Cloud Messaging token for push notifications',
    is_active BOOLEAN DEFAULT TRUE COMMENT 'Account active status',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Account creation timestamp',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Last update timestamp',
    last_login TIMESTAMP NULL DEFAULT NULL COMMENT 'Last login timestamp',
    INDEX idx_email (email),
    INDEX idx_role (role),
    INDEX idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='User accounts table';

-- ============================================
-- Boxes Table
-- ============================================
CREATE TABLE boxes (
    box_id VARCHAR(20) PRIMARY KEY COMMENT 'Unique box identifier (e.g., BOX_A1)',
    box_name VARCHAR(100) NOT NULL COMMENT 'Display name of box',
    location TEXT NOT NULL COMMENT 'Physical location description',
    status ENUM('available', 'occupied') DEFAULT 'available' COMMENT 'Box availability status',
    current_item_id VARCHAR(50) DEFAULT NULL COMMENT 'Currently stored item ID (if occupied)',
    command ENUM('unlock', 'lock') DEFAULT NULL COMMENT 'Pending command for Arduino',
    command_timestamp TIMESTAMP NULL DEFAULT NULL COMMENT 'When command was issued',
    command_issued_by VARCHAR(50) DEFAULT NULL COMMENT 'User who issued the command',
    last_ping TIMESTAMP NULL DEFAULT NULL COMMENT 'Last heartbeat from Arduino',
    is_online BOOLEAN DEFAULT FALSE COMMENT 'Arduino connection status',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Box registration timestamp',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Last update timestamp',
    INDEX idx_status (status),
    INDEX idx_command (command, command_timestamp),
    INDEX idx_is_online (is_online),
    INDEX idx_current_item (current_item_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Smart boxes table';

-- ============================================
-- Items Table
-- ============================================
CREATE TABLE items (
    item_id VARCHAR(50) PRIMARY KEY COMMENT 'Unique item identifier (UUID)',
    title VARCHAR(150) NOT NULL COMMENT 'Item title/name',
    description TEXT NOT NULL COMMENT 'Detailed item description',
    device_id VARCHAR(100) DEFAULT NULL COMMENT 'Optional device identifier (e.g., phone IMEI)',
    image_url VARCHAR(500) DEFAULT NULL COMMENT 'Optional item image URL',
    founder_id VARCHAR(50) NOT NULL COMMENT 'User who found the item',
    box_id VARCHAR(20) NOT NULL COMMENT 'Assigned storage box',
    status ENUM('pending_storage', 'waiting', 'to_collect', 'claimed') DEFAULT 'pending_storage' COMMENT 'Item lifecycle status',
    date_found TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'When item was found',
    date_stored TIMESTAMP NULL DEFAULT NULL COMMENT 'When item was stored in box',
    date_claimed TIMESTAMP NULL DEFAULT NULL COMMENT 'When item was claimed',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Record creation timestamp',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Last update timestamp',
    FOREIGN KEY (founder_id) REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (box_id) REFERENCES boxes(box_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_status (status),
    INDEX idx_founder (founder_id),
    INDEX idx_box (box_id),
    INDEX idx_date_found (date_found),
    FULLTEXT INDEX idx_search (title, description) COMMENT 'Full-text search on title and description'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Found items table';

-- ============================================
-- Retrieval Requests Table
-- ============================================
CREATE TABLE retrieval_requests (
    request_id VARCHAR(50) PRIMARY KEY COMMENT 'Unique request identifier (UUID)',
    item_id VARCHAR(50) NOT NULL COMMENT 'Requested item',
    finder_id VARCHAR(50) NOT NULL COMMENT 'User requesting the item',
    founder_id VARCHAR(50) NOT NULL COMMENT 'User who found the item',
    proof_description TEXT NOT NULL COMMENT 'Ownership proof provided by finder',
    status ENUM('pending', 'approved', 'rejected', 'completed') DEFAULT 'pending' COMMENT 'Request status',
    approved_at TIMESTAMP NULL DEFAULT NULL COMMENT 'When request was approved',
    rejected_at TIMESTAMP NULL DEFAULT NULL COMMENT 'When request was rejected',
    completed_at TIMESTAMP NULL DEFAULT NULL COMMENT 'When item was successfully collected',
    rejection_reason TEXT DEFAULT NULL COMMENT 'Optional reason for rejection',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Request creation timestamp',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Last update timestamp',
    FOREIGN KEY (item_id) REFERENCES items(item_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (finder_id) REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (founder_id) REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_item (item_id),
    INDEX idx_finder (finder_id),
    INDEX idx_founder (founder_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Item retrieval requests table';

-- ============================================
-- Messages Table
-- ============================================
CREATE TABLE messages (
    message_id VARCHAR(50) PRIMARY KEY COMMENT 'Unique message identifier (UUID)',
    request_id VARCHAR(50) NOT NULL COMMENT 'Associated retrieval request',
    sender_id VARCHAR(50) NOT NULL COMMENT 'Message sender',
    receiver_id VARCHAR(50) NOT NULL COMMENT 'Message receiver',
    message_text TEXT NOT NULL COMMENT 'Message content',
    is_read BOOLEAN DEFAULT FALSE COMMENT 'Read status',
    read_at TIMESTAMP NULL DEFAULT NULL COMMENT 'When message was read',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Message sent timestamp',
    FOREIGN KEY (request_id) REFERENCES retrieval_requests(request_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (sender_id) REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (receiver_id) REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_request_created (request_id, created_at),
    INDEX idx_sender (sender_id),
    INDEX idx_receiver (receiver_id),
    INDEX idx_is_read (is_read)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Chat messages table';

-- ============================================
-- Sample Data for Testing
-- ============================================

-- Insert sample boxes (matching Firebase configuration)
INSERT INTO boxes (box_id, box_name, location, status, is_online) VALUES
('BOX_A1', 'Box A1', 'Building A, Floor 1, Near Main Entrance', 'available', FALSE),
('BOX_A2', 'Box A2', 'Building A, Floor 2, Near Cafeteria', 'available', FALSE);

-- Insert sample users (password is 'password123' for all - hashed with bcrypt)
-- Note: In production, use proper password_hash() in PHP
INSERT INTO users (user_id, name, email, password_hash, phone, role) VALUES
('user_001', 'John Doe', 'john@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '+1234567890', 'both'),
('user_002', 'Jane Smith', 'jane@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '+1234567891', 'both'),
('user_003', 'Bob Wilson', 'bob@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '+1234567892', 'founder'),
('user_004', 'Alice Brown', 'alice@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '+1234567893', 'finder');

-- ============================================
-- Stored Procedures (Optional but useful)
-- ============================================

DELIMITER $$

-- Procedure to clean expired commands (older than 60 seconds)
CREATE PROCEDURE clean_expired_commands()
BEGIN
    UPDATE boxes 
    SET command = NULL, 
        command_timestamp = NULL,
        command_issued_by = NULL
    WHERE command IS NOT NULL 
    AND command_timestamp < DATE_SUB(NOW(), INTERVAL 60 SECOND);
END$$

-- Procedure to get box statistics
CREATE PROCEDURE get_box_statistics()
BEGIN
    SELECT 
        COUNT(*) as total_boxes,
        SUM(CASE WHEN status = 'available' THEN 1 ELSE 0 END) as available_boxes,
        SUM(CASE WHEN status = 'occupied' THEN 1 ELSE 0 END) as occupied_boxes,
        SUM(CASE WHEN is_online = TRUE THEN 1 ELSE 0 END) as online_boxes,
        SUM(CASE WHEN is_online = FALSE THEN 1 ELSE 0 END) as offline_boxes
    FROM boxes;
END$$

-- Procedure to get item statistics
CREATE PROCEDURE get_item_statistics()
BEGIN
    SELECT 
        COUNT(*) as total_items,
        SUM(CASE WHEN status = 'pending_storage' THEN 1 ELSE 0 END) as pending_storage,
        SUM(CASE WHEN status = 'waiting' THEN 1 ELSE 0 END) as waiting_retrieval,
        SUM(CASE WHEN status = 'to_collect' THEN 1 ELSE 0 END) as ready_to_collect,
        SUM(CASE WHEN status = 'claimed' THEN 1 ELSE 0 END) as claimed_items
    FROM items;
END$$

DELIMITER ;

-- ============================================
-- Views for Common Queries
-- ============================================

-- View: Available boxes with details
CREATE VIEW view_available_boxes AS
SELECT 
    box_id,
    box_name,
    location,
    is_online,
    last_ping,
    CASE 
        WHEN last_ping IS NULL THEN 'Never Connected'
        WHEN last_ping > DATE_SUB(NOW(), INTERVAL 1 MINUTE) THEN 'Online'
        ELSE 'Offline'
    END as connection_status
FROM boxes
WHERE status = 'available'
ORDER BY box_name;

-- View: Items waiting for retrieval with founder info
CREATE VIEW view_waiting_items AS
SELECT 
    i.item_id,
    i.title,
    i.description,
    i.device_id,
    i.date_found,
    i.box_id,
    b.box_name,
    b.location as box_location,
    u.name as founder_name,
    u.email as founder_email,
    (SELECT COUNT(*) FROM retrieval_requests WHERE item_id = i.item_id AND status = 'pending') as pending_requests
FROM items i
JOIN users u ON i.founder_id = u.user_id
JOIN boxes b ON i.box_id = b.box_id
WHERE i.status = 'waiting'
ORDER BY i.date_found DESC;

-- View: Pending requests with all details
CREATE VIEW view_pending_requests AS
SELECT 
    r.request_id,
    r.item_id,
    i.title as item_title,
    i.description as item_description,
    r.proof_description,
    r.created_at as request_date,
    founder.user_id as founder_id,
    founder.name as founder_name,
    founder.email as founder_email,
    finder.user_id as finder_id,
    finder.name as finder_name,
    finder.email as finder_email,
    b.box_id,
    b.box_name,
    b.location as box_location
FROM retrieval_requests r
JOIN items i ON r.item_id = i.item_id
JOIN users founder ON r.founder_id = founder.user_id
JOIN users finder ON r.finder_id = finder.user_id
JOIN boxes b ON i.box_id = b.box_id
WHERE r.status = 'pending'
ORDER BY r.created_at ASC;

-- ============================================
-- Indexes for Performance
-- ============================================
-- Most indexes are created with table definitions
-- Additional composite indexes for common queries:

CREATE INDEX idx_items_status_date ON items(status, date_found DESC);
CREATE INDEX idx_requests_status_created ON retrieval_requests(status, created_at DESC);
CREATE INDEX idx_messages_request_unread ON messages(request_id, is_read, created_at DESC);

-- ============================================
-- Triggers for Audit and Automation
-- ============================================

DELIMITER $$

-- Trigger: Update item date_stored when status changes to 'waiting'
CREATE TRIGGER trg_item_stored
BEFORE UPDATE ON items
FOR EACH ROW
BEGIN
    IF NEW.status = 'waiting' AND OLD.status = 'pending_storage' THEN
        SET NEW.date_stored = NOW();
    END IF;
    
    IF NEW.status = 'claimed' AND OLD.status = 'to_collect' THEN
        SET NEW.date_claimed = NOW();
    END IF;
END$$

-- Trigger: Update box status when item is stored
CREATE TRIGGER trg_update_box_on_item_storage
AFTER UPDATE ON items
FOR EACH ROW
BEGIN
    IF NEW.status = 'waiting' AND OLD.status = 'pending_storage' THEN
        UPDATE boxes SET 
            status = 'occupied',
            current_item_id = NEW.item_id
        WHERE box_id = NEW.box_id;
    END IF;
    
    IF NEW.status = 'claimed' AND OLD.status = 'to_collect' THEN
        UPDATE boxes SET 
            status = 'available',
            current_item_id = NULL
        WHERE box_id = NEW.box_id;
    END IF;
END$$

-- Trigger: Update request timestamps on status change
CREATE TRIGGER trg_request_status_update
BEFORE UPDATE ON retrieval_requests
FOR EACH ROW
BEGIN
    IF NEW.status = 'approved' AND OLD.status = 'pending' THEN
        SET NEW.approved_at = NOW();
    END IF;
    
    IF NEW.status = 'rejected' AND OLD.status = 'pending' THEN
        SET NEW.rejected_at = NOW();
    END IF;
    
    IF NEW.status = 'completed' AND OLD.status = 'approved' THEN
        SET NEW.completed_at = NOW();
    END IF;
END$$

-- Trigger: Mark message as read with timestamp
CREATE TRIGGER trg_message_read
BEFORE UPDATE ON messages
FOR EACH ROW
BEGIN
    IF NEW.is_read = TRUE AND OLD.is_read = FALSE THEN
        SET NEW.read_at = NOW();
    END IF;
END$$

DELIMITER ;

-- ============================================
-- Event Scheduler (for automatic cleanup)
-- ============================================

-- Enable event scheduler
SET GLOBAL event_scheduler = ON;

-- Event: Clean expired commands every 30 seconds
CREATE EVENT evt_clean_expired_commands
ON SCHEDULE EVERY 30 SECOND
DO
    CALL clean_expired_commands();

-- Event: Mark boxes as offline if no ping for 2 minutes
CREATE EVENT evt_check_arduino_status
ON SCHEDULE EVERY 1 MINUTE
DO
    UPDATE boxes 
    SET is_online = FALSE 
    WHERE last_ping < DATE_SUB(NOW(), INTERVAL 2 MINUTE) 
    AND is_online = TRUE;

-- ============================================
-- Database Information
-- ============================================

-- Display schema version
SELECT 'Lost & Found IoT Database Schema v1.0 - Successfully Created!' as message;

-- Display table counts
SELECT 
    (SELECT COUNT(*) FROM users) as users_count,
    (SELECT COUNT(*) FROM boxes) as boxes_count,
    (SELECT COUNT(*) FROM items) as items_count,
    (SELECT COUNT(*) FROM retrieval_requests) as requests_count,
    (SELECT COUNT(*) FROM messages) as messages_count;

-- ============================================
-- End of Schema
-- ============================================
