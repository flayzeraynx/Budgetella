import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';
import { getStorage } from 'firebase/storage';

// Firebase configuration
// Replace these values with your actual Firebase project configuration
const firebaseConfig = {
    apiKey: "AIzaSyARjmNVwHJxEmiZT7e15ft6aeRsRTZaLVk",
    authDomain: "budgetella.app",
    projectId: "budgetella-d1d41",
    storageBucket: "budgetella-d1d41.firebasestorage.app",
    messagingSenderId: "523687846942",
    appId: "1:523687846942:web:ed1e0c2113eb07f7e37a0f",
    measurementId: "G-93JNEYMKHT"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);
const storage = getStorage(app);

export { app, auth, db, storage };
