import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _currentUserId;

  // Track which users have pending sent requests
  final Set<String> _pendingRequests = {};

  @override
  void initState() {
    super.initState();
    _currentUserId = _auth.currentUser?.uid;
    _loadPendingRequests();
  }

  // Load existing pending requests
  Future<void> _loadPendingRequests() async {
    if (_currentUserId == null) return;

    try {
      final sentRequestsSnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('sentRequests')
          .get();

      setState(() {
        _pendingRequests.addAll(sentRequestsSnapshot.docs.map((doc) => doc.id));
      });
    } catch (e) {
      print('Error loading pending requests: $e');
    }
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

  // Stream for suggested friends (users who are not friends and haven't sent/received requests)
  Stream<List<DocumentSnapshot>> _getSuggestedFriends() {
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

        // Get current user's friend requests (both sent and received)
        final receivedRequestsSnapshot = await _firestore
            .collection('users')
            .doc(_currentUserId)
            .collection('friendRequests')
            .get();

        final sentRequestsSnapshot = await _firestore
            .collection('users')
            .doc(_currentUserId)
            .collection('sentRequests')
            .get();

        // Get list of user IDs to exclude
        final friendIds = friendsSnapshot.docs.map((doc) => doc.id).toSet();
        final receivedRequestIds = receivedRequestsSnapshot.docs
            .map((doc) => doc.id)
            .toSet();
        final sentRequestIds = sentRequestsSnapshot.docs
            .map((doc) => doc.id)
            .toSet();

        final excludedIds = {
          ...friendIds,
          ...receivedRequestIds,
          ...sentRequestIds,
          _currentUserId!,
        };

        // Filter out excluded users from all users
        final suggestedUsers = allUsersSnapshot.docs.where((userDoc) {
          return !excludedIds.contains(userDoc.id);
        }).toList();

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

      // Update local state to show "Request Sent"
      setState(() {
        _pendingRequests.add(targetUserId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Friend request sent!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      print('Error sending friend request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send request'),
          backgroundColor: Colors.red,
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
    // In a real app, you might want to store hidden suggestions in Firestore
    setState(() {});
  }

  // Cancel sent friend request
  Future<void> _cancelFriendRequest(String targetUserId) async {
    if (_currentUserId == null) return;

    try {
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

      // Update local state
      setState(() {
        _pendingRequests.remove(targetUserId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Friend request cancelled'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      print('Error cancelling friend request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel request'),
          backgroundColor: Colors.red,
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
                                return FriendRequestItem(
                                  name: 'Loading...',
                                  mutualFriends: 0,
                                  isRequest: true,
                                  isRequestSent: false,
                                  onConfirm: () {},
                                  onDelete: () {},
                                  onCancel: () {},
                                );
                              }

                              if (!userSnapshot.hasData ||
                                  !userSnapshot.data!.exists) {
                                return SizedBox(); // Skip if user doesn't exist
                              }

                              final userData =
                                  userSnapshot.data!.data()
                                      as Map<String, dynamic>;
                              final name = userData['name'] ?? 'Unknown User';

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
                                    onCancel: () {}, // Not used for requests
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
                  StreamBuilder<List<DocumentSnapshot>>(
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
                          final userDoc = suggestedUsers[index];
                          final userData =
                              userDoc.data() as Map<String, dynamic>;
                          final name = userData['name'] ?? 'Unknown User';
                          final isRequestSent = _pendingRequests.contains(
                            userDoc.id,
                          );

                          return FutureBuilder<int>(
                            future: _getMutualFriendsCount(userDoc.id),
                            builder: (context, mutualSnapshot) {
                              final mutualFriends = mutualSnapshot.data ?? 0;

                              return FriendRequestItem(
                                name: name,
                                mutualFriends: mutualFriends,
                                isRequest: false,
                                isRequestSent: isRequestSent,
                                onConfirm: () => _sendFriendRequest(userDoc.id),
                                onDelete: () =>
                                    _removeSuggestedFriend(userDoc.id),
                                onCancel: () =>
                                    _cancelFriendRequest(userDoc.id),
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
}

class FriendRequestItem extends StatelessWidget {
  final String name;
  final int mutualFriends;
  final bool isRequest;
  final bool isRequestSent;
  final VoidCallback onConfirm;
  final VoidCallback onDelete;
  final VoidCallback onCancel;

  const FriendRequestItem({
    super.key,
    required this.name,
    required this.mutualFriends,
    required this.isRequest,
    required this.isRequestSent,
    required this.onConfirm,
    required this.onDelete,
    required this.onCancel,
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
              // Profile Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.grey, size: 30),
              ),
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
            // Friend Request Buttons (Confirm/Delete)
            _buildRequestButtons()
          else
            // Suggested Friend Buttons (Add Friend/Request Sent)
            _buildSuggestedFriendButtons(),
        ],
      ),
    );
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
            ),
            child: const Text('Confirm', style: TextStyle(fontSize: 14)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: onDelete,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: const Text('Delete', style: TextStyle(fontSize: 14)),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestedFriendButtons() {
    if (isRequestSent) {
      // Request Sent State
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onCancel,
              icon: Icon(Icons.pending, size: 16),
              label: Text('Request Sent', style: TextStyle(fontSize: 14)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: BorderSide(color: Colors.orange.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: onDelete,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: const Text('Remove', style: TextStyle(fontSize: 14)),
            ),
          ),
        ],
      );
    } else {
      // Add Friend State
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
              ),
              child: const Text('Add Friend', style: TextStyle(fontSize: 14)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: onDelete,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: const Text('Remove', style: TextStyle(fontSize: 14)),
            ),
          ),
        ],
      );
    }
  }
}
