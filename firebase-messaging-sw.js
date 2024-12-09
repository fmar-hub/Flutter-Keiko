importScripts('https://www.gstatic.com/firebasejs/8.0.0/firebase-app.js');
importScripts('https://www.gstatic.com/firebasejs/8.0.0/firebase-messaging.js');

// Inicializar Firebase con tu configuración
firebase.initializeApp({
  apiKey: "AIzaSyA7XFjPZTilwjnBmZj-S-OOu_Mb90ihLT4",
  authDomain: "mykeikoapp.firebaseapp.com",
  projectId: "mykeikoapp",
  storageBucket: "mykeikoapp.appspot.com",
  messagingSenderId: "649966460288",
  appId: "1:649966460288:android:83f095c99b81d1246bf565",
});

const messaging = firebase.messaging();

// Escuchar mensajes en segundo plano
messaging.onBackgroundMessage(function (payload) {
  console.log('Background Message received: ', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: payload.notification.icon,
  };

  // Mostrar la notificación en segundo plano
  self.registration.showNotification(notificationTitle, notificationOptions);
});
