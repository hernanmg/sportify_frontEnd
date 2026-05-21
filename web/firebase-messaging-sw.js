/* Service worker para FCM en Flutter Web */
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyCgDBeYseOkjDTtyYzx4UGmMcWhDiiavs4',
  authDomain: 'sportify-amateur-dev.firebaseapp.com',
  projectId: 'sportify-amateur-dev',
  storageBucket: 'sportify-amateur-dev.firebasestorage.app',
  messagingSenderId: '489565755634',
  appId: '1:489565755634:web:2afb8876385e4e83fd586b',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const title = payload.notification?.title ?? 'Sportify';
  const options = {
    body: payload.notification?.body ?? '',
    icon: '/icons/Icon-192.png',
    data: payload.data,
  };
  self.registration.showNotification(title, options);
});
