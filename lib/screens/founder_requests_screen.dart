import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_database_service.dart';
import '../services/auth_service.dart';
import '../models/request_model.dart';
import 'chat_screen.dart';

class FounderRequestsScreen extends StatefulWidget {
  final String itemId;
  
  const FounderRequestsScreen({
    super.key,
    required this.itemId,
  });

  @override
  State<FounderRequestsScreen> createState() => _FounderRequestsScreenState();
}

class _FounderRequestsScreenState extends State<FounderRequestsScreen> {
  Future<void> _handleApprove(String requestId) async {
    final dbService = Provider.of<FirebaseDatabaseService>(context, listen: false);
    final result = await dbService.updateRequestStatus(requestId, 'approved');
    
    if (!mounted) return;
    
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request approved! Finder can now retrieve the item.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Failed to approve')),
      );
    }
  }

  Future<void> _handleReject(String requestId) async {
    final dbService = Provider.of<FirebaseDatabaseService>(context, listen: false);
    final result = await dbService.updateRequestStatus(requestId, 'rejected');
    
    if (!mounted) return;
    
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request rejected.'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Failed to reject')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<FirebaseDatabaseService>(context, listen: false);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Retrieval Requests'),
      ),
      body: StreamBuilder<List<RequestModel>>(
        stream: dbService.streamItemRequests(widget.itemId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          
          final requests = snapshot.data ?? [];
          
          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No requests yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Waiting for people to request this item...',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            child: Text(request.finderName[0].toUpperCase()),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  request.finderName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  request.finderEmail,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _StatusChip(status: request.status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      Text(
                        'Description:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(request.finderDescription),
                      const SizedBox(height: 12),
                      
                      // Chat button
                      OutlinedButton.icon(
                        onPressed: () async {
                          final dbService = Provider.of<FirebaseDatabaseService>(context, listen: false);
                          final authService = Provider.of<AuthService>(context, listen: false);
                          final item = await dbService.getFounderItems(authService.currentUser!.uid)
                              .then((items) => items.firstWhere((i) => i.id == widget.itemId));
                          
                          final chatRoomId = await dbService.createOrGetChatRoom(
                            itemId: widget.itemId,
                            founderId: item.founderId,
                            founderName: item.founderName,
                            finderId: request.finderId,
                            finderName: request.finderName,
                            itemTitle: item.title,
                          );
                          
                          if (context.mounted) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(chatRoomId: chatRoomId),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.chat),
                        label: const Text('Chat with Finder'),
                      ),
                      
                      if (request.status == 'pending') ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _handleApprove(request.id),
                                icon: const Icon(Icons.check),
                                label: const Text('Approve'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _handleReject(request.id),
                                icon: const Icon(Icons.close),
                                label: const Text('Reject'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    
    switch (status) {
      case 'approved':
        color = const Color(0xFF3B82F6); // Blue color
        label = 'To Collect';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Rejected';
        break;
      default:
        color = Colors.orange;
        label = 'Pending';
    }
    
    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
      padding: EdgeInsets.zero,
    );
  }
}
