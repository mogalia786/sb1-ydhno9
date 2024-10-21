import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/user_profile.dart';
import '../models/post.dart';

class ProfileScreen extends StatefulWidget {
  final int userId;

  ProfileScreen({required this.userId});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<UserProfile> _profileFuture;
  late Future<List<Post>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = DatabaseService.getUserProfile(widget.userId);
    _postsFuture = DatabaseService.getPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            FutureBuilder<UserProfile>(
              future: _profileFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData) {
                  return Center(child: Text('No profile data available'));
                } else {
                  final profile = snapshot.data!;
                  return Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        child: Text(profile.username[0].toUpperCase()),
                      ),
                      SizedBox(height: 10),
                      Text(profile.username, style: Theme.of(context).textTheme.headline6),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatColumn(profile.postCount, 'Posts'),
                          _buildStatColumn(profile.followerCount, 'Followers'),
                          _buildStatColumn(profile.followingCount, 'Following'),
                        ],
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () async {
                          if (profile.isFollowing) {
                            await DatabaseService.unfollowUser(profile.id);
                          } else {
                            await DatabaseService.followUser(profile.id);
                          }
                          setState(() {
                            _profileFuture = DatabaseService.getUserProfile(widget.userId);
                          });
                        },
                        child: Text(profile.isFollowing ? 'Unfollow' : 'Follow'),
                      ),
                    ],
                  );
                }
              },
            ),
            SizedBox(height: 20),
            FutureBuilder<List<Post>>(
              future: _postsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No posts available'));
                } else {
                  final userPosts = snapshot.data!.where((post) => post.username == snapshot.data![0].username).toList();
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: userPosts.length,
                    itemBuilder: (context, index) {
                      return Image.network(
                        '${DatabaseService.baseUrl}${userPosts[index].imageUrl}',
                        fit: BoxFit.cover,
                      );
                    },
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(int count, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(count.toString(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey)),
      ],
    );
  }
}