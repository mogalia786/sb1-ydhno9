const express = require('express');
const admin = require('firebase-admin');
const multer = require('multer');
const path = require('path');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 3000;

// Initialize Firebase Admin SDK
const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: process.env.FIREBASE_STORAGE_BUCKET
});

const db = admin.firestore();
const bucket = admin.storage().bucket();

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Multer configuration for file uploads
const storage = multer.memoryStorage();
const upload = multer({ storage: storage });

// Authentication middleware
async function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (token == null) return res.sendStatus(401);

  try {
    const decodedToken = await admin.auth().verifyIdToken(token);
    req.user = decodedToken;
    next();
  } catch (error) {
    return res.sendStatus(403);
  }
}

// Routes
app.post('/signup', async (req, res) => {
  try {
    const { username, email, password } = req.body;
    const userRecord = await admin.auth().createUser({
      email: email,
      password: password,
      displayName: username,
    });
    await db.collection('users').doc(userRecord.uid).set({
      username: username,
      email: email,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    res.status(201).json({ message: 'User created successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Error creating user' });
  }
});

app.post('/posts', authenticateToken, upload.single('image'), async (req, res) => {
  try {
    const { caption } = req.body;
    const file = req.file;

    const fileName = `${Date.now()}_${file.originalname}`;
    const fileUpload = bucket.file(fileName);

    const blobStream = fileUpload.createWriteStream({
      metadata: {
        contentType: file.mimetype
      }
    });

    blobStream.on('error', (error) => {
      res.status(500).json({ error: 'Error uploading image' });
    });

    blobStream.on('finish', async () => {
      const imageUrl = `https://storage.googleapis.com/${bucket.name}/${fileName}`;
      
      const postRef = await db.collection('posts').add({
        userId: req.user.uid,
        imageUrl: imageUrl,
        caption: caption,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });

      res.status(201).json({ message: 'Post created successfully', postId: postRef.id, imageUrl });
    });

    blobStream.end(file.buffer);
  } catch (error) {
    res.status(500).json({ error: 'Error creating post' });
  }
});

app.get('/posts', authenticateToken, async (req, res) => {
  try {
    const postsSnapshot = await db.collection('posts').orderBy('createdAt', 'desc').get();
    const posts = [];

    for (const doc of postsSnapshot.docs) {
      const post = doc.data();
      post.id = doc.id;

      const userDoc = await db.collection('users').doc(post.userId).get();
      post.username = userDoc.data().username;

      const likesSnapshot = await db.collection('likes').where('postId', '==', doc.id).get();
      post.likeCount = likesSnapshot.size;

      const userLikeSnapshot = await db.collection('likes')
        .where('postId', '==', doc.id)
        .where('userId', '==', req.user.uid)
        .get();
      post.userLiked = !userLikeSnapshot.empty;

      const commentsSnapshot = await db.collection('comments').where('postId', '==', doc.id).get();
      post.commentCount = commentsSnapshot.size;

      posts.push(post);
    }

    res.json(posts);
  } catch (error) {
    res.status(500).json({ error: 'Error fetching posts' });
  }
});

app.post('/posts/:postId/like', authenticateToken, async (req, res) => {
  try {
    const { postId } = req.params;
    await db.collection('likes').add({
      userId: req.user.uid,
      postId: postId,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    res.json({ message: 'Post liked successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Error liking post' });
  }
});

app.delete('/posts/:postId/like', authenticateToken, async (req, res) => {
  try {
    const { postId } = req.params;
    const likeSnapshot = await db.collection('likes')
      .where('userId', '==', req.user.uid)
      .where('postId', '==', postId)
      .get();
    
    if (!likeSnapshot.empty) {
      await likeSnapshot.docs[0].ref.delete();
    }
    res.json({ message: 'Post unliked successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Error unliking post' });
  }
});

app.post('/posts/:postId/comment', authenticateToken, async (req, res) => {
  try {
    const { postId } = req.params;
    const { content } = req.body;
    await db.collection('comments').add({
      userId: req.user.uid,
      postId: postId,
      content: content,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    res.json({ message: 'Comment added successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Error adding comment' });
  }
});

app.get('/posts/:postId/comments', authenticateToken, async (req, res) => {
  try {
    const { postId } = req.params;
    const commentsSnapshot = await db.collection('comments')
      .where('postId', '==', postId)
      .orderBy('createdAt', 'desc')
      .get();
    
    const comments = [];
    for (const doc of commentsSnapshot.docs) {
      const comment = doc.data();
      comment.id = doc.id;
      const userDoc = await db.collection('users').doc(comment.userId).get();
      comment.username = userDoc.data().username;
      comments.push(comment);
    }
    
    res.json(comments);
  } catch (error) {
    res.status(500).json({ error: 'Error fetching comments' });
  }
});

app.post('/users/:userId/follow', authenticateToken, async (req, res) => {
  try {
    const { userId } = req.params;
    await db.collection('follows').add({
      followerId: req.user.uid,
      followedId: userId,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    res.json({ message: 'User followed successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Error following user' });
  }
});

app.delete('/users/:userId/follow', authenticateToken, async (req, res) => {
  try {
    const { userId } = req.params;
    const followSnapshot = await db.collection('follows')
      .where('followerId', '==', req.user.uid)
      .where('followedId', '==', userId)
      .get();
    
    if (!followSnapshot.empty) {
      await followSnapshot.docs[0].ref.delete();
    }
    res.json({ message: 'User unfollowed successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Error unfollowing user' });
  }
});

app.get('/users/:userId/profile', authenticateToken, async (req, res) => {
  try {
    const { userId } = req.params;
    const userDoc = await db.collection('users').doc(userId).get();
    const user = userDoc.data();

    const postsSnapshot = await db.collection('posts').where('userId', '==', userId).get();
    const followerSnapshot = await db.collection('follows').where('followedId', '==', userId).get();
    const followingSnapshot = await db.collection('follows').where('followerId', '==', userId).get();
    const isFollowingSnapshot = await db.collection('follows')
      .where('followerId', '==', req.user.uid)
      .where('followedId', '==', userId)
      .get();

    res.json({
      id: userId,
      username: user.username,
      email: user.email,
      postCount: postsSnapshot.size,
      followerCount: followerSnapshot.size,
      followingCount: followingSnapshot.size,
      isFollowing: !isFollowingSnapshot.empty
    });
  } catch (error) {
    res.status(500).json({ error: 'Error fetching user profile' });
  }
});

// Start the server
app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});