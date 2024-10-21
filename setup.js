const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function setup() {
  try {
    // Create users collection
    await db.collection('users').add({
      username: 'testuser',
      email: 'testuser@example.com',
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    console.log('Users collection created successfully');

    // Create posts collection
    await db.collection('posts').add({
      userId: 'testUserId',
      imageUrl: 'https://example.com/image.jpg',
      caption: 'Test post',
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    console.log('Posts collection created successfully');

    // Create likes collection
    await db.collection('likes').add({
      userId: 'testUserId',
      postId: 'testPostId',
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    console.log('Likes collection created successfully');

    // Create comments collection
    await db.collection('comments').add({
      userId: 'testUserId',
      postId: 'testPostId',
      content: 'Test comment',
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    console.log('Comments collection created successfully');

    // Create follows collection
    await db.collection('follows').add({
      followerId: 'testFollowerId',
      followedId: 'testFollowedId',
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    console.log('Follows collection created successfully');

    console.log('Setup completed successfully');
    process.exit(0);
  } catch (error) {
    console.error('Error during setup:', error);
    process.exit(1);
  }
}

setup();