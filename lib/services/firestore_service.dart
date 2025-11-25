import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  CollectionReference get _users => _firestore.collection('users');
  
  Future<void> createUserDocument(User user, {String? displayName}) async {
    await _users.doc(user.uid).set({
      'email': user.email,
      'displayName': displayName ?? user.email?.split('@')[0] ?? 'User',
      'createdAt': FieldValue.serverTimestamp(),
      'contacts': <String, bool>{},
      'pinnedChats': <String, bool>{},
    }, SetOptions(merge: true));
  }
  
  Future<Map<String, dynamic>?> getUserDocument(String userId) async {
    final doc = await _users.doc(userId).get();
    return doc.data() as Map<String, dynamic>?;
  }
  
  Stream<List<Map<String, dynamic>>> getAllUsers() {
    return _users.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => {
                'userId': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    });
  }
  
  Future<void> addContact(String contactUserId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    final currentUserDoc = await _users.doc(currentUserId).get();
    if (!currentUserDoc.exists) {
      await _users.doc(currentUserId).set({
        'email': _auth.currentUser?.email ?? '',
        'displayName': _auth.currentUser?.email?.split('@')[0] ?? 'User',
        'createdAt': FieldValue.serverTimestamp(),
        'contacts': <String, bool>{},
      });
    }
    
    try {
      await _users.doc(currentUserId).update({
        'contacts.$contactUserId': true,
      });
    } catch (e) {
      await _users.doc(currentUserId).set({
        'contacts': <String, bool>{contactUserId: true},
      }, SetOptions(merge: true));
    }
    
    final chatId = generateChatId(currentUserId, contactUserId);
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    
    if (!chatDoc.exists) {
      await _firestore.collection('chats').doc(chatId).set({
        'participants': [currentUserId, contactUserId],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    } else {
      await _firestore.collection('chats').doc(chatId).set({
        'participants': [currentUserId, contactUserId],
      }, SetOptions(merge: true));
    }
  }
  
  Stream<List<Map<String, dynamic>>> getUserContacts() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return Stream.value([]);
    }
    
    return _users.doc(currentUserId).snapshots().map((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      final contacts = data?['contacts'] as Map<String, dynamic>? ?? {};
      return contacts.keys.toList();
    }).asyncMap((contactIds) async {
      final List<Map<String, dynamic>> contacts = [];
      for (final id in contactIds) {
        final userDoc = await _users.doc(id).get();
        if (userDoc.exists) {
          contacts.add({
            'userId': id,
            ...userDoc.data() as Map<String, dynamic>,
          });
        }
      }
      return contacts;
    });
  }
  
  String generateChatId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }
  
  Stream<List<Map<String, dynamic>>> getChatMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => {
                'messageId': doc.id,
                ...doc.data(),
              })
          .toList();
    });
  }
  
  Future<void> sendMessage(String chatId, String text) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;
    
    final parts = chatId.split('_');
    final otherUserId = parts.first == currentUserId ? parts.last : parts.first;
    
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    if (!chatDoc.exists) {
      await _firestore.collection('chats').doc(chatId).set({
        'participants': [currentUserId, otherUserId],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    }
    
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': currentUserId,
      'text': text,
      'type': 'text',
      'timestamp': FieldValue.serverTimestamp(),
      'seenBy': <String>[],
    });
    
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'participants': [currentUserId, otherUserId],
    });
  }
  
  Future<void> sendImageMessage(String chatId, String imageHash, String? caption) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;
    
    final parts = chatId.split('_');
    final otherUserId = parts.first == currentUserId ? parts.last : parts.first;
    
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    if (!chatDoc.exists) {
      await _firestore.collection('chats').doc(chatId).set({
        'participants': [currentUserId, otherUserId],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    }
    
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': currentUserId,
      'imageHash': imageHash,
      'text': caption ?? '',
      'type': 'image',
      'timestamp': FieldValue.serverTimestamp(),
      'seenBy': <String>[],
    });
    
    final lastMessage = caption != null && caption.isNotEmpty 
        ? caption 
        : '📷 Image';
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': lastMessage,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'participants': [currentUserId, otherUserId],
    });
  }
  
  Future<void> markMessageAsSeen(String chatId, String messageId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;
    
    final messageRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);
    
    final messageDoc = await messageRef.get();
    if (!messageDoc.exists) return;
    
    final messageData = messageDoc.data();
    final seenBy = (messageData?['seenBy'] as List<dynamic>?) ?? [];
    
    if (!seenBy.contains(currentUserId)) {
      await messageRef.update({
        'seenBy': FieldValue.arrayUnion([currentUserId]),
      });
    }
  }
  
  Future<void> markChatAsSeen(String chatId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;
    
    final messagesSnapshot = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('senderId', isNotEqualTo: currentUserId)
        .get();
    
    final batch = _firestore.batch();
    for (final doc in messagesSnapshot.docs) {
      final messageData = doc.data();
      final seenBy = (messageData['seenBy'] as List<dynamic>?) ?? [];
      
      if (!seenBy.contains(currentUserId)) {
        batch.update(doc.reference, {
          'seenBy': FieldValue.arrayUnion([currentUserId]),
        });
      }
    }
    
    await batch.commit();
  }
  
  Stream<List<Map<String, dynamic>>> getAllChats() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return Stream.value([]);
    }
    
    return _firestore
        .collection('chats')
        .snapshots()
        .asyncMap((snapshot) async {
      final userDoc = await _users.doc(currentUserId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      final pinnedChatsRaw = userData?['pinnedChats'];
      final Map<String, bool> pinnedChats = {};
      
      if (pinnedChatsRaw != null && pinnedChatsRaw is Map) {
        pinnedChatsRaw.forEach((key, value) {
          if (value is bool) {
            pinnedChats[key.toString()] = value;
          }
        });
      }
      
      final chats = snapshot.docs
          .map((doc) {
                final data = doc.data();
                return {
                  'chatId': doc.id,
                  'isPinned': pinnedChats[doc.id] == true,
                  ...data,
                };
              })
          .toList();
      
      chats.sort((a, b) {
        final aPinned = a['isPinned'] as bool? ?? false;
        final bPinned = b['isPinned'] as bool? ?? false;
        
        if (aPinned && !bPinned) return -1;
        if (!aPinned && bPinned) return 1;
        
        final aTime = a['lastMessageTime'] as Timestamp? ?? a['createdAt'] as Timestamp?;
        final bTime = b['lastMessageTime'] as Timestamp? ?? b['createdAt'] as Timestamp?;
        
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        
        return bTime.compareTo(aTime);
      });
      
      return chats;
    });
  }
  
  Future<void> togglePinChat(String chatId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;
    
    final userDoc = await _users.doc(currentUserId).get();
    final userData = userDoc.data() as Map<String, dynamic>?;
    final pinnedChatsRaw = userData?['pinnedChats'];
    bool isPinned = false;
    
    if (pinnedChatsRaw != null && pinnedChatsRaw is Map) {
      final pinnedValue = pinnedChatsRaw[chatId];
      isPinned = pinnedValue == true;
    }
    
    await _users.doc(currentUserId).update({
      'pinnedChats.$chatId': !isPinned,
    });
  }
}

