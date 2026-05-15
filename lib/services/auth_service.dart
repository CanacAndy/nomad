import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Inscription
  Future<User?> signUp(String email, String password) async {
    UserCredential result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }

  // Connexion
  Future<User?> signIn(String email, String password) async {
    UserCredential result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }

  // Déconnexion
  Future<void> signOut() async => await _auth.signOut();

  // Stream pour savoir si l'utilisateur est connecté
  Stream<User?> get user => _auth.authStateChanges();
}
