import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/chat_model.dart';
import '../services/firebase_database_service.dart';
import '../services/auth_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<FirebaseDatabaseService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: StreamBuilder<List<ChatRoomModel>>(
        stream: dbService.streamUserChatRooms(authService.currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          final chatRooms = snapshot.data ?? [];
          
          if (chatRooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start chatting when you have requests',
                    style: TextStyle(color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              final chatRoom = chatRooms[index];
              final isFounder = chatRoom.founderId == authService.currentUser!.uid;
              final otherPersonName = isFounder ? chatRoom.finderName : chatRoom.founderName;
              
              return _ChatRoomTile(
                chatRoom: chatRoom,
                otherPersonName: otherPersonName,
              );
            },
          );
        },
      ),
    );
  }
}

class _ChatRoomTile extends StatelessWidget {
  final ChatRoomModel chatRoom;
  final String otherPersonName;
  
  const _ChatRoomTile({
    required this.chatRoom,
    required this.otherPersonName,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, hh:mm a');
    final displayTime = chatRoom.lastMessageAt ?? chatRoom.createdAt;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(otherPersonName[0].toUpperCase()),
        ),
        title: Text(
          otherPersonName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Item: ${chatRoom.itemTitle}',
              style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),
            if (chatRoom.lastMessage != null) ...[
              const SizedBox(height: 4),
              Text(
                chatRoom.lastMessage!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
            Text(
              dateFormat.format(displayTime),
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatScreen(chatRoomId: chatRoom.id),
            ),
          );
        },
        isThreeLine: true,
      ),
    );
  }
}
