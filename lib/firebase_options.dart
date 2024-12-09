import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Dependiendo de la plataforma, este es el código de configuración que usas
    return const FirebaseOptions(
      apiKey: 'AIzaSyA7XFjPZTilwjnBmZj-S-OOu_Mb90ihLT4',
      appId: '1:649966460288:android:91ba3a2842d004306bf565',
      messagingSenderId: '649966460288',
      projectId: 'mykeikoapp',
      storageBucket: 'mykeikoapp.firebasestorage.app',
      authDomain: 'mykeikoapp.firebaseapp.com',
      databaseURL: 'https://mykeikoapp-default-rtdb.firebaseio.com/',
    );
  }
}
