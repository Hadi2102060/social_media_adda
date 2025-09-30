import 'package:flutter/material.dart';

class PeopleScreen extends StatelessWidget {
  const PeopleScreen({super.key});

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
                  ListView(
                    children: const [
                      FriendRequestItem(
                        name: 'Sabbir Ahmed',
                        mutualFriends: 1,
                        isRequest: true,
                      ),
                      FriendRequestItem(
                        name: 'Shamima Akter',
                        mutualFriends: 2,
                        isRequest: true,
                      ),
                      FriendRequestItem(
                        name: 'Chironjet Dash',
                        mutualFriends: 1,
                        isRequest: true,
                      ),
                      FriendRequestItem(
                        name: 'Afrin Jahan',
                        mutualFriends: 0,
                        isRequest: true,
                      ),
                    ],
                  ),

                  // Suggested Friends Section
                  ListView(
                    children: const [
                      FriendRequestItem(
                        name: 'Imdad Miran',
                        mutualFriends: 107,
                        isRequest: false,
                      ),
                      FriendRequestItem(
                        name: 'AH Sabbir',
                        mutualFriends: 140,
                        isRequest: false,
                      ),
                      FriendRequestItem(
                        name: 'Mehedi Hasan Tanvir',
                        mutualFriends: 96,
                        isRequest: false,
                      ),
                    ],
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

  const FriendRequestItem({
    super.key,
    required this.name,
    required this.mutualFriends,
    required this.isRequest,
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

          // Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Handle confirm/add friend action
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    isRequest ? 'Confirm' : 'Add Friend',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // Handle delete/remove action
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    isRequest ? 'Delete' : 'Remove',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
