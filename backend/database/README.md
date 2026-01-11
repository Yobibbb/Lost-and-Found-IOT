# MySQL Database Setup Guide

## 📋 Database Schema Overview

**Database Name:** `lostandfound_db`
**Tables:** 5 main tables + 3 views + 2 stored procedures + 4 triggers + 2 events

### Tables Structure

1. **users** - User accounts (founder/finder)
2. **boxes** - Smart storage boxes with Arduino control
3. **items** - Found items stored in boxes
4. **retrieval_requests** - Requests from finders to claim items
5. **messages** - Chat messages between founders and finders

### Key Features

✅ Full-text search on items (title, description)  
✅ Automatic triggers for status updates  
✅ Event scheduler for command expiration (60 seconds)  
✅ Views for common queries  
✅ Indexes for performance optimization  

---

## 🚀 Quick Setup (Local Development)

### Option 1: XAMPP (Windows - Recommended)

1. **Install XAMPP**
   - Download from: https://www.apachefriends.org/
   - Install to default location: `C:\xampp`

2. **Start MySQL**
   ```powershell
   cd C:\xampp
   .\mysql_start.bat
   # Or use XAMPP Control Panel
   ```

3. **Access phpMyAdmin**
   - Open browser: http://localhost/phpmyadmin
   - Default username: `root`, password: *(empty)*

4. **Create Database**
   - Click "New" in left sidebar
   - Database name: `lostandfound_db`
   - Collation: `utf8mb4_unicode_ci`
   - Click "Create"

5. **Import Schema**
   - Select `lostandfound_db` database
   - Click "Import" tab
   - Choose file: `backend/database/schema.sql`
   - Click "Go"

6. **Verify Installation**
   - Click "SQL" tab
   - Run: `SELECT * FROM boxes;`
   - Should see 5 sample boxes

### Option 2: MySQL Command Line

```bash
# Login to MySQL
mysql -u root -p

# Create database
CREATE DATABASE lostandfound_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

# Use database
USE lostandfound_db;

# Import schema
SOURCE C:/xampp/htdocs/Lost-and-Found-IOT/backend/database/schema.sql;

# Verify
SHOW TABLES;
SELECT * FROM boxes;
```

---

## 🌐 Production Setup (Free Hosting)

### Recommended Free Hosts
- **000webhost.com** (Recommended)
- **InfinityFree.net**
- **Awardspace.com**

### Setup Steps for 000webhost

1. **Create Account**
   - Go to: https://www.000webhost.com/
   - Sign up (free, no credit card)
   - Create new website

2. **Create MySQL Database**
   - Go to dashboard → Database
   - Click "Create Database"
   - Database name: `id12345_lostandfound` (auto-generated)
   - Username: `id12345_admin` (auto-generated)
   - Password: *(set your own)*
   - Click "Create"
   - **SAVE THESE CREDENTIALS!**

3. **Import Schema**
   - Click "Manage" on your database
   - Opens phpMyAdmin
   - Click "Import" tab
   - Upload `schema.sql`
   - Click "Go"

4. **Note Connection Details**
   ```
   Host: localhost (or sql123.000webhost.com)
   Database: id12345_lostandfound
   Username: id12345_admin
   Password: your_password
   ```

---

## 📊 Database Structure Details

### 1. Users Table
```sql
user_id (PK)      - UUID (e.g., "user_001")
name              - Full name
email (UNIQUE)    - Login email
password_hash     - Bcrypt hashed password
phone             - Optional phone number
role              - 'founder' | 'finder' | 'both'
fcm_token         - For push notifications
is_active         - Account status
created_at        - Registration date
updated_at        - Last modification
last_login        - Last login timestamp
```

### 2. Boxes Table
```sql
box_id (PK)           - Box identifier (e.g., "BOX_A1")
box_name              - Display name
location              - Physical location
status                - 'available' | 'occupied'
current_item_id (FK)  - Currently stored item
command               - 'unlock' | 'lock' | NULL
command_timestamp     - When command issued
command_issued_by     - User who issued command
last_ping             - Arduino heartbeat
is_online             - Connection status
```

### 3. Items Table
```sql
item_id (PK)      - UUID
title             - Item name (e.g., "Blue iPhone 13")
description       - Detailed description
device_id         - Optional (IMEI, serial number)
image_url         - Optional image
founder_id (FK)   - Who found it
box_id (FK)       - Where stored
status            - 'pending_storage' | 'waiting' | 'to_collect' | 'claimed'
date_found        - When found
date_stored       - When stored in box
date_claimed      - When retrieved
```

**Item Status Flow:**
```
pending_storage → waiting → to_collect → claimed
```

### 4. Retrieval Requests Table
```sql
request_id (PK)       - UUID
item_id (FK)          - Requested item
finder_id (FK)        - Who wants it
founder_id (FK)       - Who found it
proof_description     - Ownership proof
status                - 'pending' | 'approved' | 'rejected' | 'completed'
approved_at           - Approval timestamp
rejected_at           - Rejection timestamp
completed_at          - Collection timestamp
rejection_reason      - Optional reason
```

### 5. Messages Table
```sql
message_id (PK)   - UUID
request_id (FK)   - Associated request
sender_id (FK)    - Who sent
receiver_id (FK)  - Who receives
message_text      - Content
is_read           - Read status
read_at           - When read
created_at        - Sent timestamp
```

---

## 🔍 Useful Views

### view_available_boxes
```sql
SELECT * FROM view_available_boxes;
-- Shows all available boxes with online status
```

### view_waiting_items
```sql
SELECT * FROM view_waiting_items;
-- Shows items waiting for retrieval with founder info
```

### view_pending_requests
```sql
SELECT * FROM view_pending_requests;
-- Shows all pending requests with full details
```

---

## ⚙️ Stored Procedures

### Clean Expired Commands
```sql
CALL clean_expired_commands();
-- Removes commands older than 60 seconds
```

### Get Statistics
```sql
CALL get_box_statistics();
-- Returns box availability stats

CALL get_item_statistics();
-- Returns item status stats
```

---

## 🔧 Triggers (Automatic)

1. **trg_item_stored** - Sets date_stored when item status changes
2. **trg_update_box_on_item_storage** - Updates box status automatically
3. **trg_request_status_update** - Sets approval/rejection timestamps
4. **trg_message_read** - Sets read_at timestamp

---

## ⏰ Event Scheduler (Background Jobs)

### evt_clean_expired_commands
- Runs every 30 seconds
- Deletes commands older than 60 seconds
- Prevents Arduino from executing stale commands

### evt_check_arduino_status
- Runs every 1 minute
- Marks boxes as offline if no ping for 2 minutes
- Helps detect disconnected Arduinos

---

## 🧪 Testing Queries

### Test Sample Data
```sql
-- Check sample boxes
SELECT * FROM boxes;

-- Check sample users (password: password123)
SELECT user_id, name, email, role FROM users;

-- Test search functionality
SELECT * FROM items WHERE MATCH(title, description) AGAINST('phone' IN NATURAL LANGUAGE MODE);

-- Check box with pending command
SELECT box_id, command, command_timestamp, 
       TIMESTAMPDIFF(SECOND, command_timestamp, NOW()) as age_seconds
FROM boxes
WHERE command IS NOT NULL;
```

### Simulate Founder Flow
```sql
-- 1. Create new item
INSERT INTO items (item_id, title, description, founder_id, box_id, status)
VALUES ('item_test_001', 'Lost Wallet', 'Brown leather wallet', 'user_001', 'BOX_A1', 'pending_storage');

-- 2. Issue unlock command
UPDATE boxes SET command = 'unlock', command_timestamp = NOW() WHERE box_id = 'BOX_A1';

-- 3. Arduino fetches command
SELECT box_id, command, command_timestamp FROM boxes WHERE box_id = 'BOX_A1' AND command IS NOT NULL;

-- 4. Arduino clears command
UPDATE boxes SET command = NULL, command_timestamp = NULL WHERE box_id = 'BOX_A1';

-- 5. Founder confirms storage
UPDATE items SET status = 'waiting' WHERE item_id = 'item_test_001';

-- 6. Issue lock command
UPDATE boxes SET command = 'lock', command_timestamp = NOW() WHERE box_id = 'BOX_A1';

-- 7. Check trigger updated box status
SELECT * FROM boxes WHERE box_id = 'BOX_A1';
-- Should show: status = 'occupied', current_item_id = 'item_test_001'
```

### Simulate Finder Flow
```sql
-- 1. Search for item
SELECT * FROM items WHERE status = 'waiting' AND MATCH(title, description) AGAINST('wallet' IN NATURAL LANGUAGE MODE);

-- 2. Create retrieval request
INSERT INTO retrieval_requests (request_id, item_id, finder_id, founder_id, proof_description, status)
VALUES ('req_test_001', 'item_test_001', 'user_002', 'user_001', 'Its my wallet, has my ID inside', 'pending');

-- 3. Send message
INSERT INTO messages (message_id, request_id, sender_id, receiver_id, message_text)
VALUES ('msg_test_001', 'req_test_001', 'user_002', 'user_001', 'Hi, this is my wallet. I lost it yesterday near the cafeteria.');

-- 4. Founder approves
UPDATE retrieval_requests SET status = 'approved' WHERE request_id = 'req_test_001';

-- 5. Update item status
UPDATE items SET status = 'to_collect' WHERE item_id = 'item_test_001';

-- 6. Finder scans QR and unlocks
UPDATE boxes SET command = 'unlock', command_timestamp = NOW() WHERE box_id = 'BOX_A1';

-- 7. Finder confirms collection
UPDATE items SET status = 'claimed' WHERE item_id = 'item_test_001';
UPDATE retrieval_requests SET status = 'completed' WHERE request_id = 'req_test_001';

-- 8. Lock box
UPDATE boxes SET command = 'lock', command_timestamp = NOW() WHERE box_id = 'BOX_A1';

-- 9. Check trigger freed the box
SELECT * FROM boxes WHERE box_id = 'BOX_A1';
-- Should show: status = 'available', current_item_id = NULL
```

---

## 🔒 Security Considerations

### Production Settings
```sql
-- Create dedicated user with limited privileges
CREATE USER 'lostandfound_app'@'localhost' IDENTIFIED BY 'strong_password_here';

-- Grant only necessary permissions
GRANT SELECT, INSERT, UPDATE ON lostandfound_db.* TO 'lostandfound_app'@'localhost';

-- No DELETE or DROP permissions for app user

-- Flush privileges
FLUSH PRIVILEGES;
```

### Password Hashing
- Never store plain text passwords
- Use PHP `password_hash()` with bcrypt
- Sample hash in database is for 'password123'

---

## 📈 Performance Tuning

### Check Index Usage
```sql
SHOW INDEX FROM items;
SHOW INDEX FROM retrieval_requests;
SHOW INDEX FROM messages;
```

### Analyze Query Performance
```sql
EXPLAIN SELECT * FROM items WHERE status = 'waiting';
EXPLAIN SELECT * FROM messages WHERE request_id = 'req_001' ORDER BY created_at;
```

---

## 🆘 Troubleshooting

### Event Scheduler Not Running
```sql
-- Check status
SHOW VARIABLES LIKE 'event_scheduler';

-- Enable it
SET GLOBAL event_scheduler = ON;

-- Verify events are active
SHOW EVENTS;
```

### Full-Text Search Not Working
```sql
-- Check index exists
SHOW INDEX FROM items WHERE Key_name = 'idx_search';

-- Rebuild index if needed
ALTER TABLE items DROP INDEX idx_search;
ALTER TABLE items ADD FULLTEXT INDEX idx_search (title, description);
```

### Commands Not Expiring
```sql
-- Manually trigger cleanup
CALL clean_expired_commands();

-- Check event scheduler
SELECT * FROM information_schema.events WHERE event_name = 'evt_clean_expired_commands';
```

### Box Always Offline
```sql
-- Check last ping
SELECT box_id, last_ping, is_online, 
       TIMESTAMPDIFF(MINUTE, last_ping, NOW()) as minutes_ago
FROM boxes;

-- Manually mark online
UPDATE boxes SET is_online = TRUE, last_ping = NOW() WHERE box_id = 'BOX_A1';
```

---

## 📝 Maintenance Commands

### Backup Database
```bash
# Local backup
mysqldump -u root -p lostandfound_db > backup_$(date +%Y%m%d).sql

# Free hosting backup (via phpMyAdmin)
# Database → Export → Go
```

### Restore Database
```bash
mysql -u root -p lostandfound_db < backup_20260111.sql
```

### Clean Test Data
```sql
-- Reset database (WARNING: Deletes all data!)
DELETE FROM messages;
DELETE FROM retrieval_requests;
DELETE FROM items;
DELETE FROM boxes WHERE box_id NOT IN ('BOX_A1', 'BOX_A2', 'BOX_B1', 'BOX_B2', 'BOX_C1');
DELETE FROM users WHERE user_id NOT IN ('user_001', 'user_002', 'user_003', 'user_004');

-- Reset auto-increment
ALTER TABLE messages AUTO_INCREMENT = 1;
ALTER TABLE retrieval_requests AUTO_INCREMENT = 1;
ALTER TABLE items AUTO_INCREMENT = 1;
```

---

## ✅ Setup Verification Checklist

- [ ] Database created with correct charset (utf8mb4)
- [ ] All 5 tables created successfully
- [ ] 3 views created
- [ ] 2 stored procedures created
- [ ] 4 triggers created
- [ ] 2 events created and running
- [ ] Sample data inserted (5 boxes, 4 users)
- [ ] Full-text search index working
- [ ] Event scheduler enabled
- [ ] Connection credentials saved securely

---

## 📞 Next Steps

1. ✅ Database schema created
2. ⏭️ Set up PHP backend (see `backend/README.md`)
3. ⏭️ Configure Arduino code (see `arduino/README.md`)
4. ⏭️ Update Flutter app (see `MIGRATION_GUIDE.md`)

---

## 🔗 Related Files

- `schema.sql` - Complete database schema
- `../api/config/db_config.php` - PHP database connection
- `../api/README.md` - API documentation
- `../../arduino/lost_and_found_iot/lost_and_found_iot.ino` - Arduino code

---

**Database Version:** 1.0  
**Last Updated:** January 11, 2026  
**Compatible With:** MySQL 5.7+, MariaDB 10.2+
