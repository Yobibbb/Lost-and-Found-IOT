import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_database_service.dart';
import 'founder_requests_screen.dart';

class FounderDescriptionScreen extends StatefulWidget {
  const FounderDescriptionScreen({super.key});

  @override
  State<FounderDescriptionScreen> createState() => _FounderDescriptionScreenState();
}

class _FounderDescriptionScreenState extends State<FounderDescriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _deviceIdController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _deviceIdController.dispose();
    super.dispose();
  }

  Future<void> _submitItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final dbService = Provider.of<FirebaseDatabaseService>(context, listen: false);
    final result = await dbService.createItem(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      deviceId: _deviceIdController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => FounderRequestsScreen(itemId: result['itemId']),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Failed to submit item')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modern Icon with gradient background
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
                    Icons.add_circle_outline_rounded,
                    size: 64,
                    color: Colors.white,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Describe the Item You Found',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Help reunite lost items with their owners',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Title Field
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Item Title',
                hintText: 'e.g., Blue iPhone 13, Brown Wallet',
                prefixIcon: Icon(Icons.label_outline_rounded),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                if (value.trim().length < 3) {
                  return 'Title must be at least 3 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            
            // Description Field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Where did you find it? What does it look like?',
                prefixIcon: Icon(Icons.description_outlined),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                if (value.trim().length < 10) {
                  return 'Please provide more details (at least 10 characters)';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            
            // Device ID Field
            TextFormField(
              controller: _deviceIdController,
              decoration: const InputDecoration(
                labelText: 'Device/Locker ID (Optional)',
                hintText: 'e.g., LOCKER-001',
                prefixIcon: Icon(Icons.qr_code_2_rounded),
              ),
            ),
            const SizedBox(height: 32),
            
            // Submit Button
            FilledButton.icon(
              onPressed: _isLoading ? null : _submitItem,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF6366F1),
              ),
              icon: _isLoading 
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline_rounded),
              label: Text(
                _isLoading ? 'Submitting...' : 'Submit Item',
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
