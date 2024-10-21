import 'package:flutter/foundation.dart';

class Post {
  final String imageUrl;
  final String caption;

  Post({required this.imageUrl, required this.caption});
}

class AppState extends ChangeNotifier {
  List<Post> _posts = [];

  List<Post> get posts => _posts;

  void addPost(Post post) {
    _posts.add(post);
    notifyListeners();
  }
}