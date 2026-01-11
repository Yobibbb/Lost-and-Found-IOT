-- MariaDB dump 10.19  Distrib 10.4.32-MariaDB, for Win64 (AMD64)
--
-- Host: localhost    Database: lostandfound_db
-- ------------------------------------------------------
-- Server version	10.4.32-MariaDB

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `boxes`
--

DROP TABLE IF EXISTS `boxes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `boxes` (
  `box_id` varchar(20) NOT NULL COMMENT 'Unique box identifier (e.g., BOX_A1)',
  `box_name` varchar(100) NOT NULL COMMENT 'Display name of box',
  `location` text NOT NULL COMMENT 'Physical location description',
  `status` enum('available','occupied') DEFAULT 'available' COMMENT 'Box availability status',
  `current_item_id` varchar(50) DEFAULT NULL COMMENT 'Currently stored item ID (if occupied)',
  `command` enum('unlock','lock') DEFAULT NULL COMMENT 'Pending command for Arduino',
  `command_timestamp` timestamp NULL DEFAULT NULL COMMENT 'When command was issued',
  `command_issued_by` varchar(50) DEFAULT NULL COMMENT 'User who issued the command',
  `last_ping` timestamp NULL DEFAULT NULL COMMENT 'Last heartbeat from Arduino',
  `is_online` tinyint(1) DEFAULT 0 COMMENT 'Arduino connection status',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'Box registration timestamp',
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'Last update timestamp',
  PRIMARY KEY (`box_id`),
  KEY `idx_status` (`status`),
  KEY `idx_command` (`command`,`command_timestamp`),
  KEY `idx_is_online` (`is_online`),
  KEY `idx_current_item` (`current_item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Smart boxes table';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `boxes`
--

LOCK TABLES `boxes` WRITE;
/*!40000 ALTER TABLE `boxes` DISABLE KEYS */;
INSERT INTO `boxes` VALUES ('BOX_A1','Box A1','Building A, Floor 1, Near Main Entrance','available',NULL,NULL,NULL,NULL,NULL,0,'2026-01-11 06:15:15','2026-01-11 06:15:15'),('BOX_A2','Box A2','Building A, Floor 2, Near Cafeteria','available',NULL,NULL,NULL,NULL,NULL,0,'2026-01-11 06:15:15','2026-01-11 06:25:46');
/*!40000 ALTER TABLE `boxes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `items`
--

DROP TABLE IF EXISTS `items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `items` (
  `item_id` varchar(50) NOT NULL COMMENT 'Unique item identifier (UUID)',
  `title` varchar(150) NOT NULL COMMENT 'Item title/name',
  `description` text NOT NULL COMMENT 'Detailed item description',
  `device_id` varchar(100) DEFAULT NULL COMMENT 'Optional device identifier (e.g., phone IMEI)',
  `image_url` varchar(500) DEFAULT NULL COMMENT 'Optional item image URL',
  `founder_id` varchar(50) NOT NULL COMMENT 'User who found the item',
  `box_id` varchar(20) NOT NULL COMMENT 'Assigned storage box',
  `status` enum('pending_storage','waiting','to_collect','claimed') DEFAULT 'pending_storage' COMMENT 'Item lifecycle status',
  `date_found` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'When item was found',
  `date_stored` timestamp NULL DEFAULT NULL COMMENT 'When item was stored in box',
  `date_claimed` timestamp NULL DEFAULT NULL COMMENT 'When item was claimed',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'Record creation timestamp',
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'Last update timestamp',
  PRIMARY KEY (`item_id`),
  KEY `idx_status` (`status`),
  KEY `idx_founder` (`founder_id`),
  KEY `idx_box` (`box_id`),
  KEY `idx_date_found` (`date_found`),
  KEY `idx_items_status_date` (`status`,`date_found`),
  FULLTEXT KEY `idx_search` (`title`,`description`) COMMENT 'Full-text search on title and description',
  CONSTRAINT `items_ibfk_1` FOREIGN KEY (`founder_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `items_ibfk_2` FOREIGN KEY (`box_id`) REFERENCES `boxes` (`box_id`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Found items table';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `items`
--

LOCK TABLES `items` WRITE;
/*!40000 ALTER TABLE `items` DISABLE KEYS */;
/*!40000 ALTER TABLE `items` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_item_stored
BEFORE UPDATE ON items
FOR EACH ROW
BEGIN
    IF NEW.status = 'waiting' AND OLD.status = 'pending_storage' THEN
        SET NEW.date_stored = NOW();
    END IF;
    
    IF NEW.status = 'claimed' AND OLD.status = 'to_collect' THEN
        SET NEW.date_claimed = NOW();
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_update_box_on_item_storage
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
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `messages`
--

DROP TABLE IF EXISTS `messages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `messages` (
  `message_id` varchar(50) NOT NULL COMMENT 'Unique message identifier (UUID)',
  `request_id` varchar(50) NOT NULL COMMENT 'Associated retrieval request',
  `sender_id` varchar(50) NOT NULL COMMENT 'Message sender',
  `receiver_id` varchar(50) NOT NULL COMMENT 'Message receiver',
  `message_text` text NOT NULL COMMENT 'Message content',
  `is_read` tinyint(1) DEFAULT 0 COMMENT 'Read status',
  `read_at` timestamp NULL DEFAULT NULL COMMENT 'When message was read',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'Message sent timestamp',
  PRIMARY KEY (`message_id`),
  KEY `idx_request_created` (`request_id`,`created_at`),
  KEY `idx_sender` (`sender_id`),
  KEY `idx_receiver` (`receiver_id`),
  KEY `idx_is_read` (`is_read`),
  KEY `idx_messages_request_unread` (`request_id`,`is_read`,`created_at`),
  CONSTRAINT `messages_ibfk_1` FOREIGN KEY (`request_id`) REFERENCES `retrieval_requests` (`request_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `messages_ibfk_2` FOREIGN KEY (`sender_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `messages_ibfk_3` FOREIGN KEY (`receiver_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Chat messages table';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `messages`
--

LOCK TABLES `messages` WRITE;
/*!40000 ALTER TABLE `messages` DISABLE KEYS */;
/*!40000 ALTER TABLE `messages` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_message_read
BEFORE UPDATE ON messages
FOR EACH ROW
BEGIN
    IF NEW.is_read = TRUE AND OLD.is_read = FALSE THEN
        SET NEW.read_at = NOW();
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `retrieval_requests`
--

DROP TABLE IF EXISTS `retrieval_requests`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `retrieval_requests` (
  `request_id` varchar(50) NOT NULL COMMENT 'Unique request identifier (UUID)',
  `item_id` varchar(50) NOT NULL COMMENT 'Requested item',
  `finder_id` varchar(50) NOT NULL COMMENT 'User requesting the item',
  `founder_id` varchar(50) NOT NULL COMMENT 'User who found the item',
  `proof_description` text NOT NULL COMMENT 'Ownership proof provided by finder',
  `status` enum('pending','approved','rejected','completed') DEFAULT 'pending' COMMENT 'Request status',
  `approved_at` timestamp NULL DEFAULT NULL COMMENT 'When request was approved',
  `rejected_at` timestamp NULL DEFAULT NULL COMMENT 'When request was rejected',
  `completed_at` timestamp NULL DEFAULT NULL COMMENT 'When item was successfully collected',
  `rejection_reason` text DEFAULT NULL COMMENT 'Optional reason for rejection',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'Request creation timestamp',
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'Last update timestamp',
  PRIMARY KEY (`request_id`),
  KEY `idx_item` (`item_id`),
  KEY `idx_finder` (`finder_id`),
  KEY `idx_founder` (`founder_id`),
  KEY `idx_status` (`status`),
  KEY `idx_created_at` (`created_at`),
  KEY `idx_requests_status_created` (`status`,`created_at`),
  CONSTRAINT `retrieval_requests_ibfk_1` FOREIGN KEY (`item_id`) REFERENCES `items` (`item_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `retrieval_requests_ibfk_2` FOREIGN KEY (`finder_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `retrieval_requests_ibfk_3` FOREIGN KEY (`founder_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Item retrieval requests table';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `retrieval_requests`
--

LOCK TABLES `retrieval_requests` WRITE;
/*!40000 ALTER TABLE `retrieval_requests` DISABLE KEYS */;
/*!40000 ALTER TABLE `retrieval_requests` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_request_status_update
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
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users` (
  `user_id` varchar(50) NOT NULL COMMENT 'Unique user identifier (UUID)',
  `name` varchar(100) NOT NULL COMMENT 'User full name',
  `email` varchar(150) NOT NULL COMMENT 'User email (unique login)',
  `password_hash` varchar(255) NOT NULL COMMENT 'Bcrypt hashed password',
  `phone` varchar(20) DEFAULT NULL COMMENT 'Optional phone number',
  `role` enum('founder','finder','both') DEFAULT 'both' COMMENT 'User role in system',
  `fcm_token` varchar(255) DEFAULT NULL COMMENT 'Firebase Cloud Messaging token for push notifications',
  `is_active` tinyint(1) DEFAULT 1 COMMENT 'Account active status',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'Account creation timestamp',
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'Last update timestamp',
  `last_login` timestamp NULL DEFAULT NULL COMMENT 'Last login timestamp',
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `email` (`email`),
  KEY `idx_email` (`email`),
  KEY `idx_role` (`role`),
  KEY `idx_is_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='User accounts table';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES ('user_001','John Doe','john@example.com','$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi','+1234567890','both',NULL,1,'2026-01-11 06:15:15','2026-01-11 06:15:15',NULL),('user_002','Jane Smith','jane@example.com','$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi','+1234567891','both',NULL,1,'2026-01-11 06:15:15','2026-01-11 06:15:15',NULL),('user_003','Bob Wilson','bob@example.com','$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi','+1234567892','founder',NULL,1,'2026-01-11 06:15:15','2026-01-11 06:15:15',NULL),('user_004','Alice Brown','alice@example.com','$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi','+1234567893','finder',NULL,1,'2026-01-11 06:15:15','2026-01-11 06:15:15',NULL);
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary table structure for view `view_available_boxes`
--

DROP TABLE IF EXISTS `view_available_boxes`;
/*!50001 DROP VIEW IF EXISTS `view_available_boxes`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `view_available_boxes` AS SELECT
 1 AS `box_id`,
  1 AS `box_name`,
  1 AS `location`,
  1 AS `is_online`,
  1 AS `last_ping`,
  1 AS `connection_status` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `view_pending_requests`
--

DROP TABLE IF EXISTS `view_pending_requests`;
/*!50001 DROP VIEW IF EXISTS `view_pending_requests`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `view_pending_requests` AS SELECT
 1 AS `request_id`,
  1 AS `item_id`,
  1 AS `item_title`,
  1 AS `item_description`,
  1 AS `proof_description`,
  1 AS `request_date`,
  1 AS `founder_id`,
  1 AS `founder_name`,
  1 AS `founder_email`,
  1 AS `finder_id`,
  1 AS `finder_name`,
  1 AS `finder_email`,
  1 AS `box_id`,
  1 AS `box_name`,
  1 AS `box_location` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `view_waiting_items`
--

DROP TABLE IF EXISTS `view_waiting_items`;
/*!50001 DROP VIEW IF EXISTS `view_waiting_items`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `view_waiting_items` AS SELECT
 1 AS `item_id`,
  1 AS `title`,
  1 AS `description`,
  1 AS `device_id`,
  1 AS `date_found`,
  1 AS `box_id`,
  1 AS `box_name`,
  1 AS `box_location`,
  1 AS `founder_name`,
  1 AS `founder_email`,
  1 AS `pending_requests` */;
SET character_set_client = @saved_cs_client;

--
-- Final view structure for view `view_available_boxes`
--

/*!50001 DROP VIEW IF EXISTS `view_available_boxes`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `view_available_boxes` AS select `boxes`.`box_id` AS `box_id`,`boxes`.`box_name` AS `box_name`,`boxes`.`location` AS `location`,`boxes`.`is_online` AS `is_online`,`boxes`.`last_ping` AS `last_ping`,case when `boxes`.`last_ping` is null then 'Never Connected' when `boxes`.`last_ping` > current_timestamp() - interval 1 minute then 'Online' else 'Offline' end AS `connection_status` from `boxes` where `boxes`.`status` = 'available' order by `boxes`.`box_name` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `view_pending_requests`
--

/*!50001 DROP VIEW IF EXISTS `view_pending_requests`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `view_pending_requests` AS select `r`.`request_id` AS `request_id`,`r`.`item_id` AS `item_id`,`i`.`title` AS `item_title`,`i`.`description` AS `item_description`,`r`.`proof_description` AS `proof_description`,`r`.`created_at` AS `request_date`,`founder`.`user_id` AS `founder_id`,`founder`.`name` AS `founder_name`,`founder`.`email` AS `founder_email`,`finder`.`user_id` AS `finder_id`,`finder`.`name` AS `finder_name`,`finder`.`email` AS `finder_email`,`b`.`box_id` AS `box_id`,`b`.`box_name` AS `box_name`,`b`.`location` AS `box_location` from ((((`retrieval_requests` `r` join `items` `i` on(`r`.`item_id` = `i`.`item_id`)) join `users` `founder` on(`r`.`founder_id` = `founder`.`user_id`)) join `users` `finder` on(`r`.`finder_id` = `finder`.`user_id`)) join `boxes` `b` on(`i`.`box_id` = `b`.`box_id`)) where `r`.`status` = 'pending' order by `r`.`created_at` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `view_waiting_items`
--

/*!50001 DROP VIEW IF EXISTS `view_waiting_items`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `view_waiting_items` AS select `i`.`item_id` AS `item_id`,`i`.`title` AS `title`,`i`.`description` AS `description`,`i`.`device_id` AS `device_id`,`i`.`date_found` AS `date_found`,`i`.`box_id` AS `box_id`,`b`.`box_name` AS `box_name`,`b`.`location` AS `box_location`,`u`.`name` AS `founder_name`,`u`.`email` AS `founder_email`,(select count(0) from `retrieval_requests` where `retrieval_requests`.`item_id` = `i`.`item_id` and `retrieval_requests`.`status` = 'pending') AS `pending_requests` from ((`items` `i` join `users` `u` on(`i`.`founder_id` = `u`.`user_id`)) join `boxes` `b` on(`i`.`box_id` = `b`.`box_id`)) where `i`.`status` = 'waiting' order by `i`.`date_found` desc */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-01-11 14:27:54
