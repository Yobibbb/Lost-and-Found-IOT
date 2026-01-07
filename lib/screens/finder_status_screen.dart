import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_database_service.dart';
import '../models/request_model.dart';
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
                  Card(
                    color: Colors.green[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[700]),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Great news! Your request has been approved. You can now retrieve your item.',
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
                        // Show the scanned QR code data
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('QR Code Scanned'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Successfully scanned:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  scannedData,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  '✅ You can now retrieve your item!',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
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
      ),
    );
  }

  String _getStatusTitle(String status) {
    switch (status) {
      case 'approved':
        return 'Request Approved!';
      case 'rejected':
        return 'Request Rejected';
      default:
        return 'Request Pending';
    }
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'approved':
        return 'The founder has approved your request';
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
        icon = Icons.check_circle;
        color = Colors.green;
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
