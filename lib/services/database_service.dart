import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/post.dart';
import '../models/comment.dart';
import '../models/user_profile.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> addPost(String imagePath, String caption, String userId) async {
    final ref = _storage.ref().child('posts/${DateTime.now().toIso8601String()}.jpg');
    await ref.putFile(File(imagePath));
    final url = await ref.getDownloadURL();

    await _firestore.collection('posts').add({
      'userId': userId,
      'imageUrl': url,
      'caption': caption,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Post>> getPosts() async {
    QuerySnapshot snapshot = await _firestore.collection('posts').orderBy('createdAt', descending: true).get();
    List<Post> posts = [];

    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      String userId = data['userId'];
      
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      QuerySnapshot likesSnapshot = await _firestore.collection('likes').where('postId', isEqualTo: doc.id).get();
      QuerySnapshot commentsSnapshot = await _firestore.collection('comments').where('postId', isEqualTo: doc.id).get();

      posts.add(Post(
        id: doc.id,
        imageUrl: data['imageUrl'],
        caption: data['caption'],
        username: userData['username'],
        likeCount: likesSnapshot.docs.length,
        commentCount: commentsSnapshot.docs.length,
        userLiked: false, // You need to implement this based on the current user
      ));
    }

    return posts;
  }

  Future<void> likePost(String postId, String userId) async {
    await _firestore.collection('likes').add({
      'userId': userId,
      'postId': postId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unlikePost(String postId, String userId) async {
    QuerySnapshot snapshot = await _firestore.collection('likes')
        .where('userId', isEqualTo: userId)
        .where('postId', isEqualTo: postId)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> addComment(String postId, String userId, String content) async {
    await _firestore.collection('comments').add({
      'userId': userId,
      'postId': postId,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Comment>> getComments(String postId) async {
    QuerySnapshot snapshot = await _firestore.collection('comments')
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: true)
        .get();

    List<Comment> comments = [];

    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      String userId = data['userId'];
      
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      comments.add(Comment(
        id: doc.id,
        userId: userId,
        username: userData['username'],
        content: data['content'],
        createdAt: (data['createdAt'] as Timestamp).toDate(),
      ));
    }

    return comments;
  }

  Future<void> followUser(String followerId, String followedId) async {
    await _firestore.collection('follows').add({
      'followerId': followerId,
      'followedId': followedId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unfollowUser(String followerId, String followedId) async {
    QuerySnapshot snapshot = await _firestore.collection('follows')
        .where('followerId', isEqualTo: followerId)
        .where('followedId', isEqualTo: followedId)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<UserProfile> getUserProfile(String userId) async {
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

    QuerySnapshot postsSnapshot = await _firestore.collection('posts').where('userId', isEqualTo: userId).get();
    QuerySnapshot followerSnapshot = await _firestore.collection('follows').where('followedId', isEqualTo: userId).get();
    QuerySnapshot followingSnapshot = await _firestore.collection('follows').where('followerId', isEqualTo: userId).get();

    return UserProfile(
      id: userId,
      username: userData['username'],
      email: userData['email'],
      postCount: postsSnapshot.docs.length,
      followerCount: followerSnapshot.docs.length,
      followingCount: followingSnapshot.docs.length,
      isFollowing: false, // You need to implement this based on the current user
    );
  }
}