import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../shared/models/models.dart';
import '../../../core/errors/app_exception.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Future<UserModel> signUpWithEmail(String name, String email, String phone, String password, UserRole role) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final user = userCredential.user;
      if (user == null) {
        throw AppException.auth('User creation failed.');
      }

      // Wait a moment for the new auth token to propagate to the Firestore SDK to avoid PERMISSION_DENIED
      await Future.delayed(const Duration(milliseconds: 1000));

      // Check if phone number is already in use (done after auth creation so we pass Firestore rules)
      final phoneQuery = await _firestore.collection('users').where('phone', isEqualTo: phone).get();
      if (phoneQuery.docs.isNotEmpty) {
        await user.delete(); // Rollback auth creation
        throw AppException.auth('Phone number is already in use by another account.');
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
      
      try {
        await user.sendEmailVerification();
      } catch (e) {
        // Ignore email verification failure so it doesn't break user creation
      }

      return userModel;
    } on FirebaseAuthException {
      rethrow;
    } on FirebaseException {
      rethrow;
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException.auth('An unknown error occurred: $e');
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
    } on FirebaseAuthException {
      rethrow;
    } on FirebaseException {
      rethrow;
    } catch (e) {
      throw AppException.auth('An unknown error occurred.');
    }
  }

  Future<UserModel?> signInWithGoogle({UserRole role = UserRole.client}) async {
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
        // Create new user record automatically with the provided role
        final userModel = UserModel(
          uid: user.uid,
          name: user.displayName ?? 'Unknown',
          email: user.email ?? '',
          phone: user.phoneNumber ?? '',
          profilePhoto: user.photoURL,
          role: role,
          address: Address(street: '', city: '', state: '', pincode: '', lat: 0, lng: 0),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await docRef.set(userModel.toMap());
        return userModel;
      }
    } on FirebaseAuthException {
      rethrow;
    } on FirebaseException {
      rethrow;
    } catch (e) {
      throw AppException.auth('Google sign-in error: $e');
    }
  }

  Future<UserModel> completeGoogleSignup({required UserRole role}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AppException.auth('No authenticated user found for Google sign-up completion.');
    }

    final docRef = _firestore.collection('users').doc(user.uid);
    final userModel = UserModel(
      uid: user.uid,
      name: user.displayName ?? 'Unknown',
      email: user.email ?? '',
      phone: user.phoneNumber ?? '',
      profilePhoto: user.photoURL,
      role: role,
      address: Address(street: '', city: '', state: '', pincode: '', lat: 0, lng: 0),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await docRef.set(userModel.toMap());
    return userModel;
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } on FirebaseAuthException {
      rethrow;
    } on FirebaseException {
      rethrow;
    } catch (e) {
      throw AppException.auth('An unknown error occurred.');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException {
      rethrow;
    } on FirebaseException {
      rethrow;
    } catch (e) {
      throw AppException.auth('An unknown error occurred.');
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } on FirebaseAuthException {
      rethrow;
    } on FirebaseException {
      rethrow;
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
