import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _auth.currentUser?.uid;
  }

  // Stream for friend requests (users who sent request to current user)
  Stream<QuerySnapshot> _getFriendRequests() {
    if (_currentUserId == null) return Stream<QuerySnapshot>.empty();

    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('friendRequests')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  // Stream for suggested friends (users who are not friends)
  Stream<List<Map<String, dynamic>>> _getSuggestedFriends() {
    if (_currentUserId == null) return Stream.value([]);

    return _firestore.collection('users').snapshots().asyncMap((
      allUsersSnapshot,
    ) async {
      try {
        // Get current user's friends
        final friendsSnapshot = await _firestore
            .collection('users')
            .doc(_currentUserId)
            .collection('friends')
            .get();

        // Get current user's sent requests
        final sentRequestsSnapshot = await _firestore
            .collection('users')
            .doc(_currentUserId)
            .collection('sentRequests')
            .get();

        // Get list of user IDs to exclude
        final friendIds = friendsSnapshot.docs.map((doc) => doc.id).toSet();
        final sentRequestIds = sentRequestsSnapshot.docs
            .map((doc) => doc.id)
            .toSet();

        final excludedIds = {...friendIds, _currentUserId!};

        // Filter and map users with their request status
        final suggestedUsers = allUsersSnapshot.docs
            .where((userDoc) {
              return !excludedIds.contains(userDoc.id);
            })
            .map((userDoc) {
              final userData = userDoc.data() as Map<String, dynamic>;
              final isRequestSent = sentRequestIds.contains(userDoc.id);

              return {
                'id': userDoc.id,
                'data': userData,
                'isRequestSent': isRequestSent,
              };
            })
            .toList();

        return suggestedUsers;
      } catch (e) {
        print('Error getting suggested friends: $e');
        return [];
      }
    });
  }

  // Send friend request
  Future<void> _sendFriendRequest(String targetUserId) async {
    if (_currentUserId == null) return;

    try {
      // Show immediate loading state
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              SizedBox(width: 10),
              Text('Sending request...'),
            ],
          ),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );

      // Add to target user's friendRequests collection
      await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('friendRequests')
          .doc(_currentUserId)
          .set({
            'status': 'pending',
            'timestamp': Timestamp.now(),
            'requesterId': _currentUserId,
          });

      // Also add to current user's sentRequests collection
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('sentRequests')
          .doc(targetUserId)
          .set({
            'status': 'pending',
            'timestamp': Timestamp.now(),
            'targetId': targetUserId,
          });

      // Success message
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Friend request sent successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error sending friend request: $e');
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send request'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Accept friend request
  Future<void> _acceptFriendRequest(String requesterId) async {
    if (_currentUserId == null) return;

    try {
      // Remove from friend requests
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('friendRequests')
          .doc(requesterId)
          .delete();

      // Remove from sent requests
      await _firestore
          .collection('users')
          .doc(requesterId)
          .collection('sentRequests')
          .doc(_currentUserId)
          .delete();

      // Add to friends collection for both users
      final batch = _firestore.batch();

      // Add to current user's friends
      batch.set(
        _firestore
            .collection('users')
            .doc(_currentUserId)
            .collection('friends')
            .doc(requesterId),
        {'friendSince': Timestamp.now()},
      );

      // Add to requester's friends
      batch.set(
        _firestore
            .collection('users')
            .doc(requesterId)
            .collection('friends')
            .doc(_currentUserId),
        {'friendSince': Timestamp.now()},
      );

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Friend request accepted!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error accepting friend request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to accept request'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Delete/Reject friend request
  Future<void> _rejectFriendRequest(String requesterId) async {
    if (_currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('friendRequests')
          .doc(requesterId)
          .delete();

      // Also remove from sent requests
      await _firestore
          .collection('users')
          .doc(requesterId)
          .collection('sentRequests')
          .doc(_currentUserId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Friend request removed'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      print('Error rejecting friend request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove request'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Remove suggested friend (just hide from current view)
  void _removeSuggestedFriend(String userId) {
    // For now, we'll just refresh the UI by setting state
    setState(() {});
  }

  // Cancel sent friend request
  Future<void> _cancelFriendRequest(String targetUserId) async {
    if (_currentUserId == null) return;

    try {
      // Show immediate loading state
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              SizedBox(width: 10),
              Text('Cancelling request...'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );

      // Remove from target user's friendRequests
      await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('friendRequests')
          .doc(_currentUserId)
          .delete();

      // Remove from current user's sentRequests
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('sentRequests')
          .doc(targetUserId)
          .delete();

      // Success message
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Friend request cancelled'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error cancelling friend request: $e');
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel request'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Get mutual friends count
  Future<int> _getMutualFriendsCount(String otherUserId) async {
    if (_currentUserId == null) return 0;

    try {
      // Get current user's friends
      final currentUserFriends = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('friends')
          .get();

      // Get other user's friends
      final otherUserFriends = await _firestore
          .collection('users')
          .doc(otherUserId)
          .collection('friends')
          .get();

      // Find intersection
      final currentFriendsIds = currentUserFriends.docs
          .map((doc) => doc.id)
          .toSet();
      final otherFriendsIds = otherUserFriends.docs
          .map((doc) => doc.id)
          .toSet();

      return currentFriendsIds.intersection(otherFriendsIds).length;
    } catch (e) {
      print('Error getting mutual friends: $e');
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('People'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              child: TabBar(
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blue,
                tabs: const [
                  Tab(text: 'Friend Requests'),
                  Tab(text: 'Suggested Friends'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Friend Requests Section
                  StreamBuilder<QuerySnapshot>(
                    stream: _getFriendRequests(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Error loading requests',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No Friend Requests',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'When someone sends you a friend request, it will appear here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }

                      final requests = snapshot.data!.docs;

                      return ListView.builder(
                        itemCount: requests.length,
                        itemBuilder: (context, index) {
                          final request = requests[index];
                          return FutureBuilder<DocumentSnapshot>(
                            future: _firestore
                                .collection('users')
                                .doc(request.id)
                                .get(),
                            builder: (context, userSnapshot) {
                              if (userSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return _buildLoadingItem();
                              }

                              if (!userSnapshot.hasData ||
                                  !userSnapshot.data!.exists) {
                                return SizedBox();
                              }

                              final userData =
                                  userSnapshot.data!.data()
                                      as Map<String, dynamic>;
                              final name = userData['name'] ?? 'Unknown User';
                              final profileImageUrl = _getProfileImageUrl(
                                userData,
                              );

                              return FutureBuilder<int>(
                                future: _getMutualFriendsCount(request.id),
                                builder: (context, mutualSnapshot) {
                                  final mutualFriends =
                                      mutualSnapshot.data ?? 0;

                                  return FriendRequestItem(
                                    name: name,
                                    mutualFriends: mutualFriends,
                                    isRequest: true,
                                    isRequestSent: false,
                                    onConfirm: () =>
                                        _acceptFriendRequest(request.id),
                                    onDelete: () =>
                                        _rejectFriendRequest(request.id),
                                    onCancel: () {},
                                    profileImageUrl: profileImageUrl,
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  ),

                  // Suggested Friends Section
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _getSuggestedFriends(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Error loading suggestions',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_add,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No Suggested Friends',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Connect with more people to get suggestions.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }

                      final suggestedUsers = snapshot.data!;

                      return ListView.builder(
                        itemCount: suggestedUsers.length,
                        itemBuilder: (context, index) {
                          final userInfo = suggestedUsers[index];
                          final userDocId = userInfo['id'];
                          final userData = userInfo['data'];
                          final isRequestSent = userInfo['isRequestSent'];
                          final name = userData['name'] ?? 'Unknown User';
                          final profileImageUrl = _getProfileImageUrl(userData);

                          return FutureBuilder<int>(
                            future: _getMutualFriendsCount(userDocId),
                            builder: (context, mutualSnapshot) {
                              final mutualFriends = mutualSnapshot.data ?? 0;

                              return FriendRequestItem(
                                name: name,
                                mutualFriends: mutualFriends,
                                isRequest: false,
                                isRequestSent: isRequestSent,
                                onConfirm: () => _sendFriendRequest(userDocId),
                                onDelete: () =>
                                    _removeSuggestedFriend(userDocId),
                                onCancel: () => _cancelFriendRequest(userDocId),
                                profileImageUrl: profileImageUrl,
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to get profile image URL from user data
  String? _getProfileImageUrl(Map<String, dynamic> userData) {
    // Check multiple possible field names for profile image
    final possibleImageFields = [
      'profileImage',
      'photoURL',
      'imageUrl',
      'image',
      'avatar',
      'profilePicture',
      'photoUrl',
      'picture',
    ];

    for (final field in possibleImageFields) {
      if (userData.containsKey(field) &&
          userData[field] != null &&
          userData[field].toString().isNotEmpty) {
        return userData[field].toString();
      }
    }

    return null;
  }

  Widget _buildLoadingItem() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 100, height: 16, color: Colors.grey[300]),
                SizedBox(height: 8),
                Container(width: 80, height: 14, color: Colors.grey[200]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FriendRequestItem extends StatelessWidget {
  final String name;
  final int mutualFriends;
  final bool isRequest;
  final bool isRequestSent;
  final VoidCallback onConfirm;
  final VoidCallback onDelete;
  final VoidCallback onCancel;
  final String? profileImageUrl;

  const FriendRequestItem({
    super.key,
    required this.name,
    required this.mutualFriends,
    required this.isRequest,
    required this.isRequestSent,
    required this.onConfirm,
    required this.onDelete,
    required this.onCancel,
    required this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Profile Avatar with actual image - FIXED for base64 images
              _buildProfileImage(),
              const SizedBox(width: 12),

              // Name and Mutual Friends
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mutualFriends == 0
                          ? 'No mutual friends'
                          : '$mutualFriends mutual friend${mutualFriends > 1 ? 's' : ''}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Buttons - Different states based on request type and status
          if (isRequest)
            _buildRequestButtons()
          else
            _buildSuggestedFriendButtons(),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: ClipOval(child: _buildImageWidget()),
    );
  }

  Widget _buildImageWidget() {
    if (profileImageUrl == null || profileImageUrl!.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: const Icon(Icons.person, color: Colors.grey, size: 30),
      );
    }

    // Check if it's a base64 data URL
    if (profileImageUrl!.startsWith('data:image/')) {
      try {
        // Extract base64 data from data URL
        final base64Data = profileImageUrl!.split(',').last;
        final imageBytes = base64.decode(base64Data);

        return Image.memory(
          imageBytes,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading base64 image: $error');
            return Container(
              color: Colors.grey[300],
              child: const Icon(Icons.person, color: Colors.grey, size: 30),
            );
          },
        );
      } catch (e) {
        print('Error decoding base64 image: $e');
        return Container(
          color: Colors.grey[300],
          child: const Icon(Icons.person, color: Colors.grey, size: 30),
        );
      }
    }
    // Regular HTTP/HTTPS URL
    else if (profileImageUrl!.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: profileImageUrl!,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[300],
          child: const Icon(Icons.person, color: Colors.grey, size: 30),
        ),
        errorWidget: (context, url, error) {
          print('Error loading network image: $error');
          return Container(
            color: Colors.grey[300],
            child: const Icon(Icons.person, color: Colors.grey, size: 30),
          );
        },
      );
    }
    // Invalid URL format
    else {
      return Container(
        color: Colors.grey[300],
        child: const Icon(Icons.person, color: Colors.grey, size: 30),
      );
    }
  }

  Widget _buildRequestButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text(
              'Confirm',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: onDelete,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[700],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              side: BorderSide(color: Colors.grey.shade400),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestedFriendButtons() {
    if (isRequestSent) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[700],
                side: BorderSide(color: Colors.grey.shade400),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Cancel Request',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Add Friend',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: onDelete,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                side: BorderSide(color: Colors.grey.shade400),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Remove',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      );
    }
  }
}
