import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../shared/models/models.dart';
import '../../../core/errors/app_exception.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Future<UserModel> signUpWithEmail(String name, String email, String phone, String password, UserRole role) async {
    try {
      final phoneQuery = await _firestore.collection('users').where('phone', isEqualTo: phone).get();
      if (phoneQuery.docs.isNotEmpty) {
        throw AppException.auth('Phone number is already in use by another account.');
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final user = userCredential.user;
      if (user == null) {
        throw AppException.auth('User creation failed.');
      }

      final userModel = UserModel(
        uid: user.uid,
        name: name,
        email: email,
        phone: phone,
        role: role,
        address: Address(street: '', city: '', state: '', pincode: '', lat: 0, lng: 0),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
      return userModel;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw AppException.auth('Email is already occupied by another account.');
      }
      throw AppException.auth(e.message ?? 'An error occurred during sign up.');
    } catch (e) {
      throw AppException.auth('An unknown error occurred.');
    }
  }

  Future<UserModel> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final user = userCredential.user;
      if (user == null) {
        throw AppException.auth('Sign in failed.');
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        throw AppException.auth('User record not found.');
      }

      return UserModel.fromFirestore(doc);
    } on FirebaseAuthException catch (e) {
      throw AppException.auth(e.message ?? 'Invalid email or password.');
    } catch (e) {
      throw AppException.auth('An unknown error occurred.');
    }
  }

  Future<UserModel> signInWithGoogle() async {
    try {
      await _googleSignIn.initialize(
        serverClientId: dotenv.env['GOOGLE_SERVER_CLIENT_ID'] ?? '',
      );
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        throw AppException.auth('Google sign-in failed.');
      }

      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();

      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      } else {
        // Create new user record for Google sign in, defaulting to client
        final userModel = UserModel(
          uid: user.uid,
          name: user.displayName ?? 'Unknown',
          email: user.email ?? '',
          phone: user.phoneNumber ?? '',
          profilePhoto: user.photoURL,
          role: UserRole.client, // default role
          address: Address(street: '', city: '', state: '', pincode: '', lat: 0, lng: 0),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await docRef.set(userModel.toMap());
        return userModel;
      }
    } on FirebaseAuthException catch (e) {
      throw AppException.auth(e.message ?? 'Google sign-in failed.');
    } catch (e) {
      throw AppException.auth('Google sign-in error: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw AppException.auth(e.message ?? 'Failed to sign out.');
    } catch (e) {
      throw AppException.auth('An unknown error occurred.');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AppException.auth(e.message ?? 'Failed to send password reset email.');
    } catch (e) {
      throw AppException.auth('An unknown error occurred.');
    }
  }

  Future<void> updateFcmToken(String uid, String token) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw AppException.firestore('Failed to update FCM token.');
    }
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      throw AppException.firestore('Failed to update profile.');
    }
  }
}
