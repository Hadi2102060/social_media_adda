class PostModel {
  final String postId;
  final String authorId;
  final String? text;
  final String? imageUrl;
  final int createdAt; // millisecondsSinceEpoch
  final int likesCount;
  final int commentsCount;
  final int sharesCount;

  PostModel({
    required this.postId,
    required this.authorId,
    this.text,
    this.imageUrl,
    required this.createdAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
  });

  factory PostModel.fromMap(String id, Map<dynamic, dynamic> m) {
    return PostModel(
      postId: id,
      authorId: m['authorId'] ?? '',
      text: m['text'],
      imageUrl: m['imageUrl'],
      createdAt: (m['createdAt'] ?? 0) as int,
      likesCount: (m['likesCount'] ?? 0) as int,
      commentsCount: (m['commentsCount'] ?? 0) as int,
      sharesCount: (m['sharesCount'] ?? 0) as int,
    );
  }
}
