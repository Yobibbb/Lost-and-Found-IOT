import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/item_model.dart';
import '../models/notification_model.dart';
import '../services/firebase_database_service.dart';
import '../services/auth_service.dart';
import 'founder_description_screen.dart';
import 'founder_requests_screen.dart';
import 'founder_storage_screen.dart';
import 'notifications_screen.dart';
import 'chat_list_screen.dart';
import 'package:intl/intl.dart';

class FounderHomeScreen extends StatefulWidget {
  const FounderHomeScreen({super.key});

  @override
  State<FounderHomeScreen> createState() => _FounderHomeScreenState();
}

class _FounderHomeScreenState extends State<FounderHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final dbService = Provider.of<FirebaseDatabaseService>(context, listen: false);
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          _currentIndex == 0 ? '🔍 My Found Items' : '➕ Submit New Item',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            tooltip: 'Chats',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChatListScreen()),
              );
            },
          ),
          StreamBuilder<List<NotificationModel>>(
            stream: dbService.streamUserNotifications(authService.currentUser!.uid),
            builder: (context, snapshot) {
              final notifications = snapshot.data ?? [];
              final unreadNotifCount = notifications.where((n) => !n.isRead).length;
              
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    tooltip: 'Notifications',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                      );
                    },
                  ),
                  if (unreadNotifCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadNotifCount > 9 ? '9+' : '$unreadNotifCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                // Navigate back to the main screen (which will show AuthScreen)
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          ),
        ],
      ),
      body: _currentIndex == 0 ? const _MyItemsTab() : const _SubmitItemTab(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
          },
          selectedItemColor: const Color(0xFF6366F1),
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.transparent,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.list_rounded),
              label: 'My Items',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline_rounded),
              label: 'Submit Item',
            ),
          ],
        ),
      ),
    );
  }
}

class _MyItemsTab extends StatefulWidget {
  const _MyItemsTab();

  @override
  State<_MyItemsTab> createState() => _MyItemsTabState();
}

class _MyItemsTabState extends State<_MyItemsTab> {
  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<FirebaseDatabaseService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    
    return FutureBuilder<List<ItemModel>>(
      key: ValueKey(DateTime.now().millisecondsSinceEpoch), // Force refresh
      future: dbService.getFounderItems(authService.currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final items = snapshot.data ?? [];
        
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No items submitted yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap "Submit Item" to add a found item',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }
        
        return RefreshIndicator(
          onRefresh: () async {
            setState(() {}); // Trigger rebuild to refetch data
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _ItemCard(item: item);
            },
          ),
        );
      },
    );
  }
}

class _ItemCard extends StatelessWidget {
  final ItemModel item;
  
  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: item.status == 'claimed' ? null : () {
          // If item is still pending storage, go back to storage screen
          if (item.status == 'pending_storage') {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => FounderStorageScreen(
                  itemId: item.id,
                  boxId: item.boxId,
                  boxLocation: item.location,
                ),
              ),
            );
          } else {
            // Otherwise go to requests screen
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => FounderRequestsScreen(itemId: item.id),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBBF24).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.inventory_2_rounded,
                      color: Color(0xFFFBBF24),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded, 
                              size: 14, 
                              color: Colors.grey[600]
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${dateFormat.format(item.timestamp)} • ${timeFormat.format(item.timestamp)}',
                              style: TextStyle(
                                fontSize: 12, 
                                color: Colors.grey[600]
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: item.status),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              
              // Box Location Info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      size: 16,
                      color: Color(0xFF6366F1),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Box: ${item.boxId}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 12,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item.location,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[700],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              if (item.deviceId != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.qr_code_2_rounded, 
                        size: 16, 
                        color: Colors.grey[700]
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Device: ${item.deviceId}',
                        style: TextStyle(
                          fontSize: 12, 
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    item.status == 'pending_storage' 
                        ? Icons.qr_code_scanner
                        : Icons.touch_app_rounded, 
                    size: 16, 
                    color: item.status == 'pending_storage'
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF6366F1)
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.status == 'pending_storage'
                          ? 'Tap to scan QR & store item'
                          : 'Tap to view requests',
                      style: TextStyle(
                        color: item.status == 'pending_storage'
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF6366F1), 
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (item.status == 'pending_storage')
                    TextButton.icon(
                      onPressed: () => _showDeleteDialog(context, item),
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text('Delete'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, ItemModel item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item?'),
        content: Text(
          'Are you sure you want to delete "${item.title}"?\n\nThis will release ${item.boxId} and remove the item permanently.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final dbService = Provider.of<FirebaseDatabaseService>(context, listen: false);
      final result = await dbService.deleteItem(item.id);

      if (context.mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.title} deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          // Refresh by navigating to the same screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const FounderHomeScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to delete item'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String label;
    
    switch (status) {
      case 'pending_storage':
        color = const Color(0xFFEF4444);
        icon = Icons.upload_rounded;
        label = 'Pending Storage';
        break;
      case 'to_collect':
        color = const Color(0xFF3B82F6); // Blue color
        icon = Icons.schedule_rounded;
        label = 'To Collect';
        break;
      case 'claimed':
        color = const Color(0xFF10B981);
        icon = Icons.check_circle_rounded;
        label = 'Claimed';
        break;
      case 'waiting':
      default:
        color = const Color(0xFFF59E0B);
        icon = Icons.pending_rounded;
        label = 'Waiting';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitItemTab extends StatelessWidget {
  const _SubmitItemTab();

  @override
  Widget build(BuildContext context) {
    return const FounderDescriptionScreen();
  }
}
