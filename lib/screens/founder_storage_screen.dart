import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_database_service.dart';
import 'qr_scanner_screen.dart';
import 'founder_requests_screen.dart';

class FounderStorageScreen extends StatefulWidget {
  final String itemId;
  final String boxId;
  final String boxLocation;

  const FounderStorageScreen({
    super.key,
    required this.itemId,
    required this.boxId,
    required this.boxLocation,
  });

  @override
  State<FounderStorageScreen> createState() => _FounderStorageScreenState();
}

class _FounderStorageScreenState extends State<FounderStorageScreen> {
  bool _isScanned = false;
  bool _isStoring = false;

  Future<void> _scanQRCode() async {
    final scannedData = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const QRScannerScreen(),
      ),
    );

    if (scannedData != null && mounted) {
      // Validate that scanned QR matches the selected box
      if (scannedData == widget.boxId) {
        setState(() {
          _isScanned = true;
        });
        
        // TODO: Send unlock command to ESP32
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Box unlocked! Please store your item.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Wrong box! Expected ${widget.boxId} but scanned $scannedData'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _confirmStorage() async {
    setState(() => _isStoring = true);

    final dbService = Provider.of<FirebaseDatabaseService>(context, listen: false);
    
    // Update item status from 'pending_storage' to 'waiting'
    final result = await dbService.updateItemStatus(widget.itemId, 'waiting');

    setState(() => _isStoring = false);

    if (!mounted) return;

    if (result['success']) {
      // TODO: Send lock command to ESP32
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Item stored successfully! Box locked.'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to requests screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => FounderRequestsScreen(itemId: widget.itemId),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Failed to confirm storage'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Your Item'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isScanned
                      ? [Colors.green.shade400, Colors.green.shade600]
                      : [const Color(0xFFFBBF24), const Color(0xFFF59E0B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (_isScanned ? Colors.green : const Color(0xFFFBBF24))
                        .withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    _isScanned ? Icons.lock_open : Icons.qr_code_scanner,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isScanned ? 'Box Unlocked!' : 'Scan QR Code to Unlock',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Box Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Storage Box',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.inventory_2,
                          color: Color(0xFF6366F1),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.boxId,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      widget.boxLocation,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                ],
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
            const SizedBox(height: 24),

            // Instructions
            if (!_isScanned) ...[
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 12),
                          const Text(
                            'Instructions',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _InstructionStep(number: '1', text: 'Go to the box location'),
                      _InstructionStep(number: '2', text: 'Tap "Scan QR Code" below'),
                      _InstructionStep(number: '3', text: 'Scan the QR code on the box'),
                      _InstructionStep(number: '4', text: 'Box will unlock automatically'),
                      _InstructionStep(number: '5', text: 'Put your item inside'),
                      _InstructionStep(number: '6', text: 'Tap "Item Stored" to lock the box'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Scan QR Button
              FilledButton.icon(
                onPressed: _scanQRCode,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF6366F1),
                ),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text(
                  'Scan QR Code',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ] else ...[
              // Success message
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[700], size: 32),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Box is now unlocked! Please place your item inside and confirm below.',
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Item Stored Button
              FilledButton.icon(
                onPressed: _isStoring ? null : _confirmStorage,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                ),
                icon: _isStoring
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.lock),
                label: Text(
                  _isStoring ? 'Storing...' : 'Item Stored - Lock Box',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  final String number;
  final String text;

  const _InstructionStep({
    required this.number,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
