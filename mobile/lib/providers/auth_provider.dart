import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum AuthStatus {
  initial,
  loading,
  codeSent,
  roleSelectionRequired,
  success,
  failure,
}

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final String? verificationId;
  final User? user;
  final String? role; // 'Patient' or 'Clinic Staff'

  AuthState({
    required this.status,
    this.errorMessage,
    this.verificationId,
    this.user,
    this.role,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    String? verificationId,
    User? user,
    String? role,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      verificationId: verificationId ?? this.verificationId,
      user: user ?? this.user,
      role: role ?? this.role,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthNotifier() : super(AuthState(status: AuthStatus.initial)) {
    _initializeAuthListener();
  }

  void _initializeAuthListener() {
    try {
      // Check if user is already logged in
      _auth.authStateChanges().listen((User? user) async {
        if (user != null) {
          state = state.copyWith(status: AuthStatus.loading, user: user);
          await _checkUserRole(user.uid);
        } else {
          state = AuthState(status: AuthStatus.initial);
        }
      });
    } catch (e) {
      print('[Auth] Error initializing auth listener: $e');
    }
  }

  // Verification helper for sending OTP
  Future<void> sendOtp(String phoneNumber) async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-resolution (often on physical Android devices)
          final userCredential = await _auth.signInWithCredential(credential);
          if (userCredential.user != null) {
            await _checkUserRole(userCredential.user!.uid);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          state = state.copyWith(
            status: AuthStatus.failure,
            errorMessage: e.message ?? 'Phone verification failed',
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          state = state.copyWith(
            status: AuthStatus.codeSent,
            verificationId: verificationId,
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          state = state.copyWith(verificationId: verificationId);
        },
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.toString(),
      );
    }
  }

  // Verifying OTP SMS code
  Future<void> verifyOtp(String smsCode) async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: state.verificationId ?? '',
        smsCode: smsCode,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user != null) {
        await _checkUserRole(userCredential.user!.uid);
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.failure,
        errorMessage: 'Invalid OTP Code. Please try again.',
      );
    }
  }

  // Check role in Firestore
  Future<void> _checkUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null && doc.data()!['role'] != null) {
        final role = doc.data()!['role'] as String;
        state = state.copyWith(
          status: AuthStatus.success,
          role: role,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.roleSelectionRequired,
        );
      }
    } catch (e) {
      // In case Firestore fails due to network/configuration, route to role selection
      state = state.copyWith(
        status: AuthStatus.roleSelectionRequired,
      );
    }
  }

  // Save selected role to Firestore
  Future<void> saveRole(String role) async {
    state = state.copyWith(status: AuthStatus.loading);
    final uid = _auth.currentUser?.uid ?? '';
    final phone = _auth.currentUser?.phoneNumber ?? '';

    try {
      if (uid.isEmpty) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'phone': phone,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      state = state.copyWith(
        status: AuthStatus.success,
        role: role,
      );
    } catch (e) {
      // Fallback locally so the app keeps functioning even under strict rules
      state = state.copyWith(
        status: AuthStatus.success,
        role: role,
      );
    }
  }

  // Log Out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('[Auth] Sign out error: $e');
    }
    state = AuthState(status: AuthStatus.initial);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
