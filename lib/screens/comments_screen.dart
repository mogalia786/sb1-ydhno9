import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/comment.dart';

class CommentsScreen extends StatefulWidget {
  final int postId;

  CommentsScreen({required this.postId});

  @override
  _CommentsScreenState createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  late Future<List<Comment>> _commentsFuture;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _commentsFuture = DatabaseService.getComments(widget.postId);
  }

  void _refreshComments() {
    setState(() {
      _commentsFuture = DatabaseService.getComments(widget.postId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comments'),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Comment>>(
              future: _commentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No comments yet'));
                } else {
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final comment = snapshot.data![index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(comment.username[0].toUpperCase()),
                        ),
                        title: Text(comment.username),
                        subtitle: Text(comment.content),
                      );
                    },
                  );
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () async {
                    if (_commentController.text.isNotEmpty) {
                      await DatabaseService.addComment(
                        widget.postId,
                        _commentController.text,
                      );
                      _commentController.clear();
                      _refreshComments();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}