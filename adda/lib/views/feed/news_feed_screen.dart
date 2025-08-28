import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/post_model.dart';
import '../../providers/feed_provider.dart';

class NewsFeedScreen extends StatelessWidget {
  const NewsFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final feedProv = context.watch<FeedProvider>();
    final posts = feedProv.feed;          // friends + own
    final trending = feedProv.trending;   // top liked

    return RefreshIndicator(
      onRefresh: () async { /* no-op; realtime */ },
      child: ListView(
        children: [
          // Trending section (horizontal chips/cards)
          if (trending.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text('Trending', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: trending.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (ctx, i) => _TrendingCard(post: trending[i]),
              ),
            ),
            const Divider(),
          ],

          // Friends + own feed (reverse chrono)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: posts.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (ctx, i) => _PostTile(post: posts[i]),
          ),
        ],
      ),
    );
  }
}

class _PostTile extends StatelessWidget {
  final PostModel post;
  const _PostTile({required this.post});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Text(post.authorId.substring(0,1).toUpperCase())),
      title: Text(post.text ?? '(photo)'),
      subtitle: Text(DateTime.fromMillisecondsSinceEpoch(post.createdAt).toString()),
      // TODO: like/comment/share buttons hook with DB updates
    );
  }
}

class _TrendingCard extends StatelessWidget {
  final PostModel post;
  const _TrendingCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(blurRadius: 6, spreadRadius: 1, color: Colors.black12)]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(post.text ?? '—', maxLines: 2, overflow: TextOverflow.ellipsis),
          const Spacer(),
          Text('❤ ${post.likesCount}  💬 ${post.commentsCount}', style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
