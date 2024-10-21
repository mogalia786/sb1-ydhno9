class Post {
  final int id;
  final String imageUrl;
  final String caption;
  final String username;
  int likeCount;
  int commentCount;
  bool userLiked;

  Post({
    required this.id,
    required this.imageUrl,
    required this.caption,
    required this.username,
    required this.likeCount,
    required this.commentCount,
    required this.userLiked,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      imageUrl: json['image_url'],
      caption: json['caption'],
      username: json['username'],
      likeCount: json['like_count'],
      commentCount: json['comment_count'],
      userLiked: json['user_liked'] == 1,
    );
  }
}