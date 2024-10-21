import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/post.dart';
import 'comments_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Post>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = DatabaseService.getPosts();
  }

  void _refreshPosts() {
    setState(() {
      _postsFuture = DatabaseService.getPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Photo Feed'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshPosts();
        },
        child: FutureBuilder<List<Post>>(
          future: _postsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No posts available'));
            } else {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final post = snapshot.data![index];
                  return Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            child: Text(post.username[0].toUpperCase()),
                          ),
                          title: Text(post.username),
                        ),
                        Image.network('${DatabaseService.baseUrl}${post.imageUrl}'),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(post.caption),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            IconButton(
                              icon: Icon(
                                post.userLiked ? Icons.favorite : Icons.favorite_border,
                                color: post.userLiked ? Colors.red : null,
                              ),
                              onPressed: () async {
                                if (post.userLiked) {
                                  await DatabaseService.unlikePost(post.id);
                                  setState(() {
                                    post.likeCount--;
                                    post.userLiked = false;
                                  });
                                } else {
                                  await DatabaseService.likePost(post.id);
                                  setState(() {
                                    post.likeCount++;
                                    post.userLiked = true;
                                  });
                                }
                              },
                            ),
                            Text('${post.likeCount} likes'),
                            IconButton(
                              icon: Icon(Icons.comment),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CommentsScreen(postId: post.id),
                                  ),
                                );
                              },
                            ),
                            Text('${post.commentCount} comments'),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}