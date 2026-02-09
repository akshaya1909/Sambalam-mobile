// web/firebase-messaging-sw.js
importScripts('https://www.gstatic.com/firebasejs/10.14.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyBqi0z_jlIIKyoF61526YVWh5lnbKTGPeI",
  authDomain: "salarybox-95a05.firebaseapp.com",
  projectId: "salarybox-95a05",
  storageBucket: "salarybox-95a05.firebasestorage.app",
  messagingSenderId: "995064371618",
  appId: "1:995064371618:web:5e240660042d17e4b47afb",
});

const messaging = firebase.messaging();
