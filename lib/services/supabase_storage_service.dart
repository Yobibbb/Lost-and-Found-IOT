import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  /// Upload image to Supabase Storage and return the public URL
  /// 
  /// Images are stored in the 'chat-images' bucket
  /// Returns the public URL if successful, null otherwise
  Future<String?> uploadChatImage(XFile imageFile, String chatRoomId) async {
    try {
      print('📤 Uploading image to Supabase Storage...');
      
      // Read image bytes
      final bytes = await imageFile.readAsBytes();
      
      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '$chatRoomId/$timestamp.jpg';
      
      // Upload to Supabase Storage
      await _supabase.storage
          .from('chat-images')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );
      
      // Get public URL
      final publicUrl = _supabase.storage
          .from('chat-images')
          .getPublicUrl(fileName);
      
      print('✅ Image uploaded successfully: $publicUrl');
      return publicUrl;
      
    } catch (e) {
      print('❌ Error uploading image to Supabase: $e');
      return null;
    }
  }
  
  /// Delete image from Supabase Storage
  Future<bool> deleteImage(String imageUrl) async {
    try {
      // Extract file path from URL
      final uri = Uri.parse(imageUrl);
      final path = uri.pathSegments.last;
      
      await _supabase.storage
          .from('chat-images')
          .remove([path]);
      
      print('✅ Image deleted successfully');
      return true;
      
    } catch (e) {
      print('❌ Error deleting image: $e');
      return false;
    }
  }
}
