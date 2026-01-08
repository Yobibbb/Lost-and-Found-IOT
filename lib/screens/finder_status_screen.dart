import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_database_service.dart';
import '../models/request_model.dart';
import '../models/item_model.dart';
import 'qr_scanner_screen.dart';

class FinderStatusScreen extends StatelessWidget {
  final String requestId;
  
  const FinderStatusScreen({
    super.key,
    required this.requestId,
  });

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<FirebaseDatabaseService>(context, listen: false);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Status'),
      ),
      body: StreamBuilder<RequestModel>(
        stream: dbService.streamRequest(requestId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          
          if (!snapshot.hasData) {
            return const Center(
              child: Text('Request not found'),
            );
          }
          
          final request = snapshot.data!;
          
          // Fetch item data to show box location
          return FutureBuilder<ItemModel?>(
            future: dbService.getItemById(request.itemId),
            builder: (context, itemSnapshot) {
              final item = itemSnapshot.data;
              
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StatusIcon(status: request.status),
                    const SizedBox(height: 24),
                
                Text(
                  _getStatusTitle(request.status),
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                Text(
                  _getStatusMessage(request.status),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Request',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text('To: ${request.finderName}'),
                        const SizedBox(height: 8),
                        const Text(
                          'Your description:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(request.finderDescription),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Item Description Card
                if (item != null)
                  Card(
                    color: Colors.amber[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.inventory_2_outlined, color: Colors.amber[800]),
                              const SizedBox(width: 8),
                              const Text(
                                'Item Details',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Title:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(item.title),
                          const SizedBox(height: 8),
                          const Text(
                            'Description:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(item.description),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                
                if (request.status == 'pending')
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'The founder is reviewing your request. You\'ll be notified when they respond.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                if (request.status == 'approved') ...[
                  // Show box location info
                  if (item != null) ...[
                    Card(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.inventory_2,
                                  color: Color(0xFF6366F1),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Item Location',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF6366F1),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Box: ${item.boxId}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.location,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Your item is ready to collect! Scan the QR code at the box to unlock and retrieve your item.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      // Navigate to QR scanner
                      final scannedData = await Navigator.of(context).push<String>(
                        MaterialPageRoute(
                          builder: (_) => const QRScannerScreen(),
                        ),
                      );
                      
                      if (scannedData != null && context.mounted) {
                        // Validate scanned QR matches the box ID
                        if (item != null && scannedData == item.boxId) {
                          // Show success dialog with "I Got It" button
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (dialogContext) => AlertDialog(
                              title: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green[700]),
                                  const SizedBox(width: 8),
                                  const Text('Box Unlocked!'),
                                ],
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '✅ Box successfully unlocked!',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Box: ${item.boxId}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Please retrieve your item from the box.',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.info_outline, color: Colors.blue, size: 20),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Click "I Got It" after you retrieve your item.',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    // Update item status to 'claimed'
                                    final updateResult = await dbService.updateItemStatus(
                                      item.id,
                                      'claimed',
                                    );
                                    
                                    if (!context.mounted) return;
                                    
                                    Navigator.of(dialogContext).pop(); // Close dialog
                                    
                                    if (updateResult['success']) {
                                      // Show success message
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('✅ Item successfully claimed!'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      
                                      // Navigate back to home
                                      Navigator.of(context).popUntil((route) => route.isFirst);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(updateResult['error'] ?? 'Failed to claim item'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.check_circle),
                                  label: const Text('I Got It!'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else {
                          // Wrong box scanned
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red[700]),
                                  const SizedBox(width: 8),
                                  const Text('Wrong Box'),
                                ],
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '❌ This is not the correct box.',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (item != null) ...[
                                    const Text(
                                      'Expected Box:',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '${item.boxId} - ${item.location}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Text(
                                    'Scanned: $scannedData',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Try Again'),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan QR to Unlock'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
                
                if (request.status == 'rejected') ...[
                  Card(
                    color: Colors.red[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.cancel, color: Colors.red[700]),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Your request was rejected. This might not be your item. Please search for other items.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.search),
                    label: const Text('Search Again'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ],
            ),
          );
            },
          );
        },
      ),
    );
  }

  String _getStatusTitle(String status) {
    switch (status) {
      case 'approved':
        return 'Ready to Collect!';
      case 'rejected':
        return 'Request Rejected';
      default:
        return 'Request Pending';
    }
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'approved':
        return 'Your item is ready to collect';
      case 'rejected':
        return 'The founder has rejected your request';
      default:
        return 'Waiting for founder to respond';
    }
  }
}

class _StatusIcon extends StatelessWidget {
  final String status;
  
  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    
    switch (status) {
      case 'approved':
        icon = Icons.inventory_2;
        color = const Color(0xFF3B82F6); // Blue color
        break;
      case 'rejected':
        icon = Icons.cancel;
        color = Colors.red;
        break;
      default:
        icon = Icons.hourglass_empty;
        color = Colors.orange;
    }
    
    return Center(
      child: Icon(
        icon,
        size: 80,
        color: color,
      ),
    );
  }
}
