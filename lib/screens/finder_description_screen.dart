import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_database_service.dart';
import 'finder_results_screen.dart';

class FinderDescriptionScreen extends StatefulWidget {
  const FinderDescriptionScreen({super.key});

  @override
  State<FinderDescriptionScreen> createState() => _FinderDescriptionScreenState();
}

class _FinderDescriptionScreenState extends State<FinderDescriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchItems() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final dbService = Provider.of<FirebaseDatabaseService>(context, listen: false);
    final results = await dbService.searchItems(_searchController.text.trim());

    setState(() => _isLoading = false);

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FinderResultsScreen(
          searchResults: results,
          searchQuery: _searchController.text.trim(),
        ),
      ),
    );
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
            // Modern search icon with gradient
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 64,
                    color: Colors.white,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Find Your Lost Item',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Search for items that have been found',
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
            
            // Search Field
            TextFormField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Describe your lost item',
                hintText: 'e.g., Blue iPhone 13, brown leather wallet',
                prefixIcon: Icon(Icons.edit_outlined),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a search description';
                }
                if (value.trim().length < 3) {
                  return 'Please enter at least 3 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            // Tips Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF6366F1).withOpacity(0.2),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        color: Color(0xFF6366F1),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Tips for better results',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  _TipItem('Include color, brand, or model'),
                  _TipItem('Mention distinctive features'),
                  _TipItem('Use multiple keywords'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Search Button
            FilledButton.icon(
              onPressed: _isLoading ? null : _searchItems,
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
                  : const Icon(Icons.search_rounded),
              label: Text(
                _isLoading ? 'Searching...' : 'Search Items',
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

class _TipItem extends StatelessWidget {
  final String text;
  
  const _TipItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: Color(0xFF10B981),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
