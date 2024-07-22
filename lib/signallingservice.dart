import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer';

class SignallingService {
  // Singleton instance
  static final SignallingService _instance = SignallingService._();
  factory SignallingService() => _instance;

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Private constructor
  SignallingService._();

  // Initialize the signalling service
  void init({required String selfCallerID}) {
    // Perform any initialization tasks here

    // For example, you might want to set up Firestore listeners
    _setUpFirestoreListeners(selfCallerID);
  }

  // Set up Firestore listeners
  void _setUpFirestoreListeners(String selfCallerID) {
    _firestore.collection('signalling').where('callerId', isEqualTo: selfCallerID)
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      snapshot.docChanges.forEach((change) {
        if (change.type == DocumentChangeType.added) {
          // Handle new signalling data
          var data = change.doc.data();
          log('Received signalling data: $data');
          // Implement your logic here to respond to new signalling data
        }
        // You can handle other types of changes (modified, removed) as needed
      });
    });
  }

  // Example method to send signalling data
  void sendSignallingData(Map<String, dynamic> data) {
    // Add a document to the 'signalling' collection
    _firestore.collection('signalling').add(data)
        .then((value) => log('Signalling data sent: $data'))
        .catchError((error) => log('Error sending signalling data: $error'));
  }
}
