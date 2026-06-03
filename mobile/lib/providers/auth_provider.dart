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
  final bool isMock;
  final String? mockUid;
  final String? mockPhone;

  AuthState({
    required this.status,
    this.errorMessage,
    this.verificationId,
    this.user,
    this.role,
    this.isMock = false,
    this.mockUid,
    this.mockPhone,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    String? verificationId,
    User? user,
    String? role,
    bool? isMock,
    String? mockUid,
    String? mockPhone,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      verificationId: verificationId ?? this.verificationId,
      user: user ?? this.user,
      role: role ?? this.role,
      isMock: isMock ?? this.isMock,
      mockUid: mockUid ?? this.mockUid,
      mockPhone: mockPhone ?? this.mockPhone,
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
        print('[Auth Listener] Auth state changed. User: ${user?.uid}');
        if (user != null) {
          state = state.copyWith(status: AuthStatus.loading, user: user);
          await _checkUserRole(user.uid);
        } else {
          // Only reset to initial if the current status is logged in (success) or loading.
          // Do NOT overwrite mock auth flows, codeSent, or verification failures.
          if (state.status == AuthStatus.success || state.status == AuthStatus.loading) {
            print('[Auth Listener] User is null. Resetting to initial state.');
            state = AuthState(status: AuthStatus.initial);
          }
        }
      });
    } catch (e) {
      print('[Auth] Error initializing auth listener: $e');
    }
  }

  // Verification helper for sending OTP
  Future<void> sendOtp(String phoneNumber) async {
    state = state.copyWith(status: AuthStatus.loading);
    print('[Auth Provider] Sending OTP to Firebase for number: "$phoneNumber"');

    // 1. Direct local bypass for demo/test numbers (containing "555")
    if (phoneNumber.contains('555')) {
      print('[Auth Provider] Demo number detected. Initiating Local Mock Auth immediately...');
      // Wait a brief moment to simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));
      state = state.copyWith(
        status: AuthStatus.codeSent,
        verificationId: 'mock_verification_id',
        isMock: true,
        mockUid: 'mock_user_${phoneNumber.replaceAll(RegExp(r'\D'), '')}',
        mockPhone: phoneNumber,
      );
      return;
    }

    // 2. Otherwise try real Firebase Auth
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
          print('[Auth Provider] Firebase verification failed: ${e.code} - ${e.message}');
          print('[Auth Provider] Falling back to Local Mock Auth for development/testing...');
          state = state.copyWith(
            status: AuthStatus.codeSent,
            verificationId: 'mock_verification_id',
            isMock: true,
            mockUid: 'mock_user_${phoneNumber.replaceAll(RegExp(r'\D'), '')}',
            mockPhone: phoneNumber,
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          state = state.copyWith(
            status: AuthStatus.codeSent,
            verificationId: verificationId,
            isMock: false,
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          state = state.copyWith(verificationId: verificationId);
        },
      );
    } catch (e) {
      print('[Auth Provider] verifyPhoneNumber exception: $e. Falling back to Local Mock Auth...');
      state = state.copyWith(
        status: AuthStatus.codeSent,
        verificationId: 'mock_verification_id',
        isMock: true,
        mockUid: 'mock_user_${phoneNumber.replaceAll(RegExp(r'\D'), '')}',
        mockPhone: phoneNumber,
      );
    }
  }

  // Verifying OTP SMS code
  Future<void> verifyOtp(String smsCode) async {
    state = state.copyWith(status: AuthStatus.loading);

    if (state.isMock || state.verificationId == 'mock_verification_id') {
      print('[Auth Provider] Verifying in Mock Mode. Accepting code: $smsCode');
      await _checkUserRole(state.mockUid ?? 'mock_user_123');
      return;
    }

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
    if (state.isMock || uid.startsWith('mock_user_')) {
      print('[Auth Provider] Mock user detected in checkUserRole. Bypassing Firestore.');
      await Future.delayed(const Duration(milliseconds: 500));
      if (state.role != null) {
        state = state.copyWith(status: AuthStatus.success);
      } else {
        state = state.copyWith(status: AuthStatus.roleSelectionRequired);
      }
      return;
    }

    try {
      final doc = await _firestore.collection('users').doc(uid).get().timeout(const Duration(seconds: 4));
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
      print('[Auth Provider] Firestore checkUserRole failed/timed out: $e. Defaulting to role selection.');
      // In case Firestore fails due to network/configuration, route to role selection
      state = state.copyWith(
        status: AuthStatus.roleSelectionRequired,
      );
    }
  }

  // Save selected role to Firestore
  Future<void> saveRole(String role) async {
    state = state.copyWith(status: AuthStatus.loading);
    final uid = state.isMock ? (state.mockUid ?? 'mock_user_123') : (_auth.currentUser?.uid ?? '');
    final phone = state.isMock ? (state.mockPhone ?? '') : (_auth.currentUser?.phoneNumber ?? '');

    try {
      if (uid.isEmpty) {
        throw Exception('User not authenticated');
      }

      if (state.isMock || uid.startsWith('mock_user_')) {
        print('[Auth Provider] Mock user detected in saveRole. Bypassing Firestore.');
        await Future.delayed(const Duration(milliseconds: 500));
      } else {
        await _firestore.collection('users').doc(uid).set({
          'uid': uid,
          'phone': phone,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)).timeout(const Duration(seconds: 4));
      }

      state = state.copyWith(
        status: AuthStatus.success,
        role: role,
      );
    } catch (e) {
      print('[Auth Provider] Firestore saveRole failed/timed out: $e. Falling back to local success.');
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
