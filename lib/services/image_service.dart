import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ImageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();
  
  // Generate hash from image bytes
  String _generateHash(List<int> bytes) {
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  // Pick image from gallery or camera
  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      return image;
    } catch (e) {
      return null;
    }
  }
  
  // Upload image with hashing to Firestore
  Future<String?> uploadImageWithHash(XFile imageFile, {String? folder}) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return null;
      
      // Read image bytes
      final bytes = await imageFile.readAsBytes();
      
      // Generate hash from image bytes
      final hash = _generateHash(bytes);
      
      // Convert bytes to base64 for Firestore storage
      final base64Image = base64Encode(bytes);
      
      // Get file extension
      final extension = imageFile.path.split('.').last;
      
      // Create folder path
      final folderPath = folder ?? 'images';
      
      // Check if image with this hash already exists
      final existingDoc = await _firestore.collection('images').doc(hash).get();
      
      if (!existingDoc.exists) {
        // Store image in Firestore with hash as document ID
        await _firestore.collection('images').doc(hash).set({
          'hash': hash,
          'data': base64Image, // Base64 encoded image data
          'extension': extension,
          'uploadedBy': currentUserId,
          'uploadedAt': FieldValue.serverTimestamp(),
          'originalName': imageFile.name,
          'size': bytes.length,
          'folder': folderPath,
        });
      } else {
        // Image already exists, just update metadata
        await _firestore.collection('images').doc(hash).update({
          'uploadedBy': currentUserId,
          'lastAccessed': FieldValue.serverTimestamp(),
        });
      }
      
      // Return hash as identifier
      return hash;
    } catch (e) {
      return null;
    }
  }
  
  // Get image data by hash from Firestore
  Future<String?> getImageDataByHash(String hash) async {
    try {
      final doc = await _firestore.collection('images').doc(hash).get();
      if (doc.exists) {
        final data = doc.data();
        return data?['data'] as String?; // Returns base64 string
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  // Get image metadata by hash
  Future<Map<String, dynamic>?> getImageMetadataByHash(String hash) async {
    try {
      final doc = await _firestore.collection('images').doc(hash).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  // Upload profile picture
  Future<String?> uploadProfilePicture(XFile imageFile) async {
    final hash = await uploadImageWithHash(imageFile, folder: 'profile_pictures');
    if (hash != null) {
      // Update user document with profile picture hash
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId != null) {
        await _firestore.collection('users').doc(currentUserId).update({
          'profilePictureHash': hash,
        });
      }
    }
    return hash;
  }
  
  // Upload chat image
  Future<String?> uploadChatImage(XFile imageFile, String chatId) async {
    return await uploadImageWithHash(imageFile, folder: 'chat_images/$chatId');
  }
  
  // Get user profile picture hash
  Future<String?> getUserProfilePictureHash(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data()?['profilePictureHash'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

