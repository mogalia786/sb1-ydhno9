class UserProfile {
  final int id;
  final String username;
  final String email;
  final int postCount;
  final int followerCount;
  final int followingCount;
  bool isFollowing;

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.postCount,
    required this.followerCount,
    required this.followingCount,
    required this.isFollowing,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      postCount: json['postCount'],
      followerCount: json['followerCount'],
      followingCount: json['followingCount'],
      isFollowing: json['isFollowing'],
    );
  }
}