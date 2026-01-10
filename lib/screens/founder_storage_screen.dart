import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_database_service.dart';
import '../services/box_service.dart';
import 'qr_scanner_screen.dart';
import 'box_confirmation_screen.dart';
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
        // Update box status to UNLOCKED (OPEN) in database
        final boxService = BoxService();
        final unlocked =
            await boxService.updateBoxLockStatus(widget.boxId, false);

        if (unlocked) {
          // Fetch box details for the confirmation screen
          final box = await boxService.getBoxById(widget.boxId);

          if (!mounted) return;

          // Navigate to confirmation screen
          final confirmed = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => BoxConfirmationScreen(
                boxId: widget.boxId,
                boxName: box?.name ?? widget.boxId,
                boxLocation: box?.location ?? widget.boxLocation,
              ),
            ),
          );

          if (!mounted) return;

          // If confirmed, proceed with storage
          if (confirmed == true) {
            await _confirmStorage();
          } else {
            // If user went back without confirming, show a message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚠️ Item not stored. Box may still be open.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Failed to unlock box in database'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '❌ Wrong box! Expected ${widget.boxId} but scanned $scannedData'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _confirmStorage() async {
    setState(() => _isStoring = true);

    final dbService =
        Provider.of<FirebaseDatabaseService>(context, listen: false);

    // Update item status from 'pending_storage' to 'waiting'
    final result = await dbService.updateItemStatus(widget.itemId, 'waiting');

    // Note: Box is already locked by the BoxConfirmationScreen

    setState(() => _isStoring = false);

    if (!mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Item stored successfully!'),
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
                gradient: const LinearGradient(
                  colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFBBF24).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    size: 64,
                    color: Colors.white,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Scan QR Code to Unlock',
                    style: TextStyle(
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
                    const _InstructionStep(
                        number: '1', text: 'Go to the box location'),
                    const _InstructionStep(
                        number: '2', text: 'Tap "Scan QR Code" below'),
                    const _InstructionStep(
                        number: '3', text: 'Scan the QR code on the box'),
                    const _InstructionStep(
                        number: '4', text: 'Box will unlock automatically'),
                    const _InstructionStep(
                        number: '5', text: 'Put your item inside the box'),
                    const _InstructionStep(
                        number: '6', text: 'Confirm item placement'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Scan QR Button
            FilledButton.icon(
              onPressed: _isStoring ? null : _scanQRCode,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF6366F1),
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
                  : const Icon(Icons.qr_code_scanner),
              label: Text(
                _isStoring ? 'Processing...' : 'Scan QR Code',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
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
