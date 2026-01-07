import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/item_model.dart';
import '../services/firebase_database_service.dart';
import 'finder_status_screen.dart';

class FinderResultsScreen extends StatelessWidget {
  final List<ItemModel> searchResults;
  final String searchQuery;
  
  const FinderResultsScreen({
    super.key,
    required this.searchResults,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Results'),
      ),
      body: searchResults.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No items found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try different keywords or check back later',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                final item = searchResults[index];
                return _ItemCard(item: item);
              },
            ),
    );
  }
}

class _ItemCard extends StatefulWidget {
  final ItemModel item;
  
  const _ItemCard({required this.item});

  @override
  State<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<_ItemCard> {
  bool _isExpanded = false;
  bool _isLoading = false;
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _sendRequest() async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide additional details')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final dbService = Provider.of<FirebaseDatabaseService>(context, listen: false);
    final result = await dbService.createRequest(
      itemId: widget.item.id,
      finderDescription: _descriptionController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => FinderStatusScreen(requestId: result['requestId']),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Failed to send request')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.inventory),
            ),
            title: Text(
              widget.item.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  widget.item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text('Found by: ${widget.item.founderName}'),
                Text(
                  'Found on: ${dateFormat.format(widget.item.timestamp)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () {
                setState(() => _isExpanded = !_isExpanded);
              },
            ),
          ),
          
          if (_isExpanded) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Why do you think this is yours?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      hintText: 'Provide specific details to prove ownership...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _sendRequest,
                    icon: const Icon(Icons.send),
                    label: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Send Request'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
