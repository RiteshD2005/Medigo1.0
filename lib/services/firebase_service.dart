import 'package:firebase_core/firebase_core.dart';

class FirebaseService {

  static Future init() async {
    await Firebase.initializeApp();
  }

}