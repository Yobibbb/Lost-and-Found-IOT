import 'package:flutter/material.dart';
import '../services/box_service.dart';

class BoxConfirmationScreen extends StatefulWidget {
  final String boxId;
  final String boxName;
  final String boxLocation;

  const BoxConfirmationScreen({
    super.key,
    required this.boxId,
    required this.boxName,
    required this.boxLocation,
  });

  @override
  State<BoxConfirmationScreen> createState() => _BoxConfirmationScreenState();
}

class _BoxConfirmationScreenState extends State<BoxConfirmationScreen> {
  bool _isClosing = false;

  Future<void> _confirmItemPlaced() async {
    setState(() => _isClosing = true);

    final boxService = BoxService();

    // Lock the box (close status)
    final success = await boxService.updateBoxLockStatus(widget.boxId, true);

    if (!mounted) return;

    if (success) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Box closed successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate back to previous screen
      Navigator.of(context).pop(true);
    } else {
      setState(() => _isClosing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Failed to close box. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent going back without confirming
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('⚠️ Warning'),
            content: const Text(
              'The box is still open. Are you sure you want to go back without confirming?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No, Stay Here'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes, Go Back'),
              ),
            ],
          ),
        );
        return shouldPop ?? false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text('Box Status'),
          backgroundColor: Colors.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Success Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_open_rounded,
                  size: 80,
                  color: Colors.green[700],
                ),
              ),

              const SizedBox(height: 32),

              // Box Opened Message
              Text(
                'Box Opened!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Status info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Database Status: OPEN',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.inventory_2, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Box: ${widget.boxName}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.boxLocation,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Instructions Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6366F1).withOpacity(0.1),
                      const Color(0xFF4F46E5).withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                  ),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.info_rounded,
                      size: 40,
                      color: Color(0xFF6366F1),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Did you place the item inside?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please confirm after placing your found item in the box',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Confirm Button
              FilledButton.icon(
                onPressed: _isClosing ? null : _confirmItemPlaced,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF6366F1),
                  disabledBackgroundColor: Colors.grey,
                ),
                icon: _isClosing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_rounded),
                label: Text(
                  _isClosing
                      ? 'Closing Box...'
                      : 'Yes, Item Placed - Close Box',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Cancel/Back info
              TextButton(
                onPressed: _isClosing
                    ? null
                    : () async {
                        final shouldGoBack = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Go Back?'),
                            content: const Text(
                              'The box will remain open. You should only go back if you haven\'t placed the item yet.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('Go Back'),
                              ),
                            ],
                          ),
                        );

                        if (shouldGoBack == true && mounted) {
                          Navigator.of(context).pop(false);
                        }
                      },
                child: const Text(
                  'I haven\'t placed it yet',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
