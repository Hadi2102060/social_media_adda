import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/post_model.dart';

class FeedProvider with ChangeNotifier {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final String currentUserId;

  // state
  final Map<String, StreamSubscription<DatabaseEvent>> _friendPostSubs = {};
  StreamSubscription<DatabaseEvent>? _friendsSub;
  StreamSubscription<DatabaseEvent>? _trendingSub;

  final List<PostModel> _feed = [];
  final List<PostModel> _trending = [];

  List<PostModel> get feed =>
      _feed..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  List<PostModel> get trending =>
      _trending..sort((a, b) => b.likesCount.compareTo(a.likesCount));

  FeedProvider({required this.currentUserId});

  Future<void> start() async {
    _listenFriends();
    _listenTrending();
  }

  void _listenFriends() {
    // friends list live
    final friendsRef = _db.child('users/$currentUserId/friends');
    _friendsSub?.cancel();
    _friendsSub = friendsRef.onValue.listen((event) {
      final data = (event.snapshot.value as Map?) ?? {};
      final friendIds = <String>{currentUserId}; // নিজেও অন্তর্ভুক্ত
      data.forEach((k, v) {
        if (v == true) friendIds.add(k);
      });

      // remove old subscriptions
      _friendPostSubs.keys
          .where((id) => !friendIds.contains(id))
          .toList()
          .forEach((id) {
            _friendPostSubs[id]?.cancel();
            _friendPostSubs.remove(id);
          });

      // add listeners for new friends
      for (final uid in friendIds) {
        if (_friendPostSubs.containsKey(uid)) continue;
        final sub = _db
            .child('user_posts/$uid')
            .orderByChild('createdAt')
            .limitToLast(50) // recent posts only
            .onValue
            .listen((e) {
              // merge/replace that user's posts
              _feed.removeWhere((p) => p.authorId == uid);
              final map = (e.snapshot.value as Map?) ?? {};
              map.forEach((postId, val) {
                if (val is Map) {
                  _feed.add(PostModel.fromMap(postId, val));
                }
              });
              notifyListeners();
            });
        _friendPostSubs[uid] = sub;
      }
    });
  }

  void _listenTrending() {
    _trendingSub?.cancel();
    // likesCount ভিত্তিক ট্রেন্ডিং (top 20)
    _trendingSub = _db
        .child('posts')
        .orderByChild('likesCount')
        .limitToLast(20)
        .onValue
        .listen((e) {
          _trending.clear();
          final map = (e.snapshot.value as Map?) ?? {};
          map.forEach((postId, val) {
            if (val is Map) {
              _trending.add(PostModel.fromMap(postId, val));
            }
          });
          notifyListeners();
        });
  }

  @override
  void dispose() {
    _friendsSub?.cancel();
    _trendingSub?.cancel();
    for (final s in _friendPostSubs.values) {
      s.cancel();
    }
    _friendPostSubs.clear();
    super.dispose();
  }
}
