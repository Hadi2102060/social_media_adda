// FriendsListScreen.dart
import 'dart:convert';

import 'package:adda2/views/social/chat_screen.dart'; // আপনার আসল ChatScreen import করুন
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendsListScreen extends StatelessWidget {
  final String userId;

  const FriendsListScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final FirebaseAuth _auth = FirebaseAuth.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text('Friends'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .doc(userId)
            .collection('friends')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading friends'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No Friends Yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add friends to see them here',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final friends = snapshot.data!.docs;

          return ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friend = friends[index];

              return FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('users').doc(friend.id).get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return ListTile(
                      leading: CircleAvatar(child: Icon(Icons.person)),
                      title: Text('Loading...'),
                    );
                  }

                  if (userSnapshot.hasError || !userSnapshot.hasData) {
                    return ListTile(
                      leading: CircleAvatar(child: Icon(Icons.error)),
                      title: Text('User not found'),
                    );
                  }

                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
                  final name = userData['name'] ?? 'Unknown User';
                  final username = userData['username'] ?? '';
                  final profileImage = userData['profileImage'] ?? '';
                  final isOnline = userData['isOnline'] ?? false;

                  return ListTile(
                    leading: Stack(
                      children: [
                        _buildUserAvatar(profileImage),
                        if (isOnline)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Text(name),
                    subtitle: Text('@$username'),
                    trailing: _buildMessageImageIcon(
                      onTap: () {
                        _startChatWithFriend(
                          context: context,
                          friendId: friend.id,
                          friendName: name,
                          friendImage: profileImage,
                          isOnline: isOnline,
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // User avatar widget
  Widget _buildUserAvatar(String profileImage) {
    return CircleAvatar(
      backgroundImage: profileImage.isNotEmpty
          ? (profileImage.startsWith('data:image/')
                ? MemoryImage(base64Decode(profileImage.split(',').last))
                : NetworkImage(profileImage) as ImageProvider)
          : null,
      child: profileImage.isEmpty ? Icon(Icons.person) : null,
    );
  }

  // Custom image icon widget
  Widget _buildMessageImageIcon({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: _buildMessageIconImage(),
        ),
      ),
    );
  }

  // Image icon
  Widget _buildMessageIconImage() {
    try {
      return Image.asset(
        'assets/messenger.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback if image fails to load
          return Icon(Icons.chat_rounded, color: Colors.blue, size: 20);
        },
      );
    } catch (e) {
      // Fallback if any error occurs
      return Icon(Icons.chat_rounded, color: Colors.blue, size: 20);
    }
  }

  // Start chat with friend function
  void _startChatWithFriend({
    required BuildContext context,
    required String friendId,
    required String friendName,
    required String friendImage,
    required bool isOnline,
  }) async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      // Create or get conversation ID
      final participants = [currentUser.uid, friendId]..sort();
      final conversationId = participants.join('_');

      // Check if conversation exists
      final conversationDoc = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .get();

      if (!conversationDoc.exists) {
        // Create new conversation
        await _firestore.collection('conversations').doc(conversationId).set({
          'participants': participants,
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastMessageSender': '',
          'unreadCount': {currentUser.uid: 0, friendId: 0},
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Close loading dialog
      Navigator.pop(context);

      // Navigate to your actual ChatScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            username: friendName,
            userImage: friendImage,
            isOnline: isOnline,
            userId: friendId,
          ),
        ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
