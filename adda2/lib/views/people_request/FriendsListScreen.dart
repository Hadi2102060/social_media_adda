// FriendsListScreen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendsListScreen extends StatelessWidget {
  final String userId;

  const FriendsListScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
                  final profileImage = userData['profileImage'];

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          profileImage != null && profileImage.isNotEmpty
                          ? (profileImage.startsWith('data:image/')
                                ? MemoryImage(
                                    base64Decode(profileImage.split(',').last),
                                  )
                                : NetworkImage(profileImage) as ImageProvider)
                          : null,
                      child: profileImage == null ? Icon(Icons.person) : null,
                    ),
                    title: Text(name),
                    subtitle: Text('@$username'),
                    trailing: IconButton(
                      icon: Icon(Icons.message),
                      onPressed: () {
                        // Navigate to chat with this friend
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
}
