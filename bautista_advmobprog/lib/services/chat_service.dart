import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection('Users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final user = doc.data();
        return {...user, 'uid': user['uid'] ?? doc.id};
      }).toList();
    });
  }

  Future<void> sendMessage(String receiverId, message) async {
    final String currentUserId = _firebaseAuth.currentUser!.uid;
    final String? currentUserEmail = _firebaseAuth.currentUser!.email;
    final Timestamp timestamp = Timestamp.now();
    Message newMessage = Message(
      senderId: currentUserId,
      senderEmail: currentUserEmail ?? '',
      receiverId: receiverId,
      message: message,
      timestamp: timestamp,
    );

    List<String> ids = [currentUserId, receiverId];
    ids.sort();

    String chatRoomId = ids.join('_');

    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(newMessage.toMap());
  }

  Stream<QuerySnapshot> getMessage(String userID, otherUserID) {
    List<String> ids = [userID, otherUserID];
    ids.sort();

    String chatRoomID = ids.join('_');

    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomID)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots(includeMetadataChanges: true);
  }

  Future<void> markMessagesAsSeen(
    List<QueryDocumentSnapshot> messages,
    String currentUserId,
  ) async {
    final batch = _firestore.batch();
    var hasUpdates = false;

    for (final message in messages) {
      final data = message.data() as Map<String, dynamic>;
      final receiverId = (data['receiverId'] ?? '').toString();
      final seenBy = data['seenBy'] is List ? data['seenBy'] as List : const [];

      if (receiverId == currentUserId && !seenBy.contains(currentUserId)) {
        batch.update(message.reference, {
          'seenBy': FieldValue.arrayUnion([currentUserId]),
        });
        hasUpdates = true;
      }
    }

    if (hasUpdates) {
      await batch.commit();
    }
  }

  Future<String?> getUidByEmail(String email) async {
    final q = await _firestore
        .collection('Users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    return (q.docs.first.data()['uid'] ?? '').toString();
  }

  Future<void> saveUserProfile({
    required String username,
    required String firstName,
    required String lastName,
    required String email,
    String? age,
    String? contactNo,
  }) async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      throw StateError('No Firebase user is signed in');
    }

    final Map<String, dynamic> profile = {
      'uid': firebaseUser.uid,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
    };

    if (age != null) profile['age'] = age;
    if (contactNo != null) profile['contactNo'] = contactNo;

    await _firestore
        .collection('Users')
        .doc(firebaseUser.uid)
        .set(profile, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;

    final document = await _firestore
        .collection('Users')
        .doc(firebaseUser.uid)
        .get();

    return document.data();
  }

  Future<void> updateUsername(String username) async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      throw StateError('No Firebase user is signed in');
    }

    await _firestore.collection('Users').doc(firebaseUser.uid).set({
      'username': username,
    }, SetOptions(merge: true));
  }
}
