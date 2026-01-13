import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../models/chat_model.dart';
import '../models/item_model.dart';
import '../services/firebase_database_service.dart';
import '../services/auth_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  
  const ChatScreen({super.key, required this.chatRoomId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  XFile? _pickedImage;

  @override
  void initState() {
    super.initState();
    // Mark messages as read when opening chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dbService = Provider.of<FirebaseDatabaseService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUserId = authService.currentUser!.uid;
      dbService.markChatMessagesAsRead(widget.chatRoomId, currentUserId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _pickedImage = null;
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty && _pickedImage == null) return;

    final dbService = Provider.of<FirebaseDatabaseService>(context, listen: false);
    
    // If there's an image, send it
    if (_pickedImage != null) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        final bytes = await _pickedImage!.readAsBytes();
        
        await dbService.sendImageMessage(
          chatRoomId: widget.chatRoomId,
          imageBytes: bytes,
          fileName: _pickedImage!.name,
        );

        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog
        setState(() {
          _pickedImage = null;
        });
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send image: $e'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }
    
    // If there's text, send it
    if (_messageController.text.trim().isNotEmpty) {
      final message = _messageController.text.trim();
      _messageController.clear();

      await dbService.sendMessage(
        chatRoomId: widget.chatRoomId,
        message: message,
      );
    }

    _scrollToBottom();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _pickedImage = image;
      });
    }
  }

  void _showItemDetailsModal(BuildContext context, ItemModel item, ChatRoomModel chatRoom) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser!.uid;
    final isFounder = chatRoom.founderId == currentUserId;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              // Title
              Row(
                children: [
                  Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  const Text(
                    'Item Details',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Item Title
              _DetailRow(
                icon: Icons.label,
                label: 'Item',
                value: item.title,
              ),
              
              // Description
              _DetailRow(
                icon: Icons.description,
                label: 'Description',
                value: item.description,
              ),
              
              // Status
              _DetailRow(
                icon: Icons.info,
                label: 'Status',
                value: _getStatusText(item.status),
                valueColor: _getStatusColor(item.status),
              ),
              
              const Divider(height: 32),
              
              // Location Info
              Text(
                'Location Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              
              _DetailRow(
                icon: Icons.location_on,
                label: 'Box Location',
                value: item.location,
              ),
              
              _DetailRow(
                icon: Icons.inventory_2,
                label: 'Box ID',
                value: item.boxId,
              ),
              
              if (item.deviceId != null)
                _DetailRow(
                  icon: Icons.devices,
                  label: 'Device ID',
                  value: item.deviceId!,
                ),
              
              const Divider(height: 32),
              
              // People Info
              Text(
                'People',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              
              _DetailRow(
                icon: Icons.person,
                label: 'Founder',
                value: chatRoom.founderName,
              ),
              
              _DetailRow(
                icon: Icons.person_search,
                label: 'Finder',
                value: chatRoom.finderName,
              ),
              
              const Divider(height: 32),
              
              // Timestamps
              Text(
                'Timeline',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              
              _DetailRow(
                icon: Icons.calendar_today,
                label: 'Item Found',
                value: DateFormat('MMM dd, yyyy • hh:mm a').format(item.createdAt),
              ),
              
              _DetailRow(
                icon: Icons.chat,
                label: 'Chat Started',
                value: DateFormat('MMM dd, yyyy • hh:mm a').format(chatRoom.createdAt),
              ),
              
              const SizedBox(height: 24),
              
              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending_storage':
        return 'Pending Storage';
      case 'waiting':
        return 'Waiting for Finder';
      case 'to_collect':
        return 'Ready to Collect';
      case 'claimed':
        return 'Claimed';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending_storage':
        return Colors.orange;
      case 'waiting':
        return Colors.blue;
      case 'to_collect':
        return Colors.green;
      case 'claimed':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<FirebaseDatabaseService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: StreamBuilder<List<ChatRoomModel>>(
          stream: dbService.streamUserChatRooms(currentUserId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Text('Chat');
            }
            
            // Find the current chat room
            final chatRoom = snapshot.data!.firstWhere(
              (room) => room.id == widget.chatRoomId,
              orElse: () => snapshot.data!.first,
            );
            
            // Determine the other person's name
            final otherPersonName = chatRoom.founderId == currentUserId 
                ? chatRoom.finderName 
                : chatRoom.founderName;
            
            return Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  child: Text(
                    otherPersonName[0].toUpperCase(),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    otherPersonName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          // Device info section
          FutureBuilder<ItemModel?>(
            future: dbService.getItemById(widget.chatRoomId.split('_').first),
            builder: (context, itemSnapshot) {
              return StreamBuilder<List<ChatRoomModel>>(
                stream: dbService.streamUserChatRooms(currentUserId),
                builder: (context, roomSnapshot) {
                  if (!roomSnapshot.hasData) return const SizedBox.shrink();
                  
                  final chatRoom = roomSnapshot.data!.firstWhere(
                    (room) => room.id == widget.chatRoomId,
                    orElse: () => roomSnapshot.data!.first,
                  );
                  
                  return FutureBuilder<ItemModel?>(
                    future: dbService.getItemById(chatRoom.itemId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data == null) {
                        return const SizedBox.shrink();
                      }
                      
                      final item = snapshot.data!;
                      
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          border: Border(
                            bottom: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 16, color: Colors.grey[700]),
                                const SizedBox(width: 6),
                                Text(
                                  'Box: ${item.boxId}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: () => _showItemDetailsModal(context, item, chatRoom),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Show details',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            if (item.deviceId != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.devices, size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Device: ${item.deviceId}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
          Expanded(
            child: StreamBuilder<List<ChatMessageModel>>(
              stream: dbService.streamChatMessages(widget.chatRoomId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start the conversation!',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;
                    return _MessageBubble(message: message, isMe: isMe);
                  },
                );
              },
            ),
          ),
          // Image preview section
          if (_pickedImage != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: FutureBuilder<Uint8List>(
                          future: _pickedImage!.readAsBytes(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Image.memory(
                                snapshot.data!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              );
                            }
                            return Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[300],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _pickedImage = null;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _pickedImage!.name,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, -2),
                  blurRadius: 4,
                  color: Colors.black.withOpacity(0.1),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.image, color: Theme.of(context).primaryColor),
                      onPressed: _pickImage,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('hh:mm a');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              child: Text(message.senderName[0].toUpperCase()),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 4),
                    child: Text(
                      message.senderName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? Theme.of(context).primaryColor : Colors.grey[300],
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.imageUrl != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            message.imageUrl!,
                            width: 200,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return SizedBox(
                                width: 200,
                                height: 200,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 200,
                                height: 200,
                                color: Colors.grey[400],
                                child: const Icon(Icons.broken_image, size: 50),
                              );
                            },
                          ),
                        ),
                        if (message.message.isNotEmpty) const SizedBox(height: 8),
                      ],
                      if (message.message.isNotEmpty)
                        Text(
                          message.message,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(message.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              child: Text(message.senderName[0].toUpperCase()),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    color: valueColor ?? Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
