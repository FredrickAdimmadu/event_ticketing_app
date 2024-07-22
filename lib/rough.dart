// import 'dart:convert';
// import 'dart:math';
// import 'dart:typed_data';
// import 'package:event/payment/stripe_service.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter_paypal_checkout/flutter_paypal_checkout.dart';
// import 'package:qr_flutter/qr_flutter.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:webview_flutter/webview_flutter.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'dart:io';
//
// import 'homepage.dart';
//
//
//
//
//
// class EventDashboardPage extends StatefulWidget {
//   @override
//   _EventDashboardPageState createState() => _EventDashboardPageState();
// }
//
// class _EventDashboardPageState extends State<EventDashboardPage> with SingleTickerProviderStateMixin {
//   late Stream<QuerySnapshot> _eventsStream;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   late AnimationController _animationController;
//   Map<String, String> _eventPaymentStatus = {};
//
//
//   @override
//   void initState() {
//     super.initState();
//     _eventsStream = _getEventsStream();
//     _animationController = AnimationController(
//       duration: const Duration(seconds: 10),
//       vsync: this,
//     )..repeat(reverse: false);
//
//   }
//
//
//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }
//
//   Stream<QuerySnapshot> _getEventsStream() {
//     return FirebaseFirestore.instance
//         .collectionGroup('details')
//         .snapshots();
//   }
//
//   void _showDetailsDialog(BuildContext context, String title, String content) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(title),
//         content: Text(content),
//         actions: [
//           TextButton(
//             child: Text('Close'),
//             onPressed: () => Navigator.of(context).pop(),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showQRCodeDialog(BuildContext context, dynamic qrCodeData) {
//     Uint8List? qrCode;
//
//     if (qrCodeData is String) {
//       try {
//         qrCode = Uint8List.fromList(jsonDecode(qrCodeData).cast<int>());
//       } catch (e) {
//         print('Error decoding QR code data: $e');
//       }
//     } else if (qrCodeData is Uint8List) {
//       qrCode = qrCodeData;
//     }
//
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('QR Code'),
//           content: SizedBox(
//             height: 300,
//             width: 300,
//             child: qrCode != null ? Image.memory(qrCode) : Text('No QR Code available'),
//           ),
//           actions: [
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: Text('Close'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   String _generateTicketId() {
//     const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
//     Random rand = Random();
//     return List.generate(7, (index) => chars[rand.nextInt(chars.length)]).join();
//   }
//
//   Future<void> _handleAttendButton(BuildContext context, Map<String, dynamic> eventData) async {
//     User? user = _auth.currentUser;
//
//     if (user == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('You must be logged in to attend an event.')),
//       );
//       return;
//     }
//
//     DocumentReference socialUserDocRef = _firestore.collection('social_users').doc(user.uid);
//     DocumentSnapshot socialUserDoc = await socialUserDocRef.get();
//
//     if (!socialUserDoc.exists) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('User data not found.')),
//       );
//       return;
//     }
//
//     Map<String, dynamic> userData = socialUserDoc.data() as Map<String, dynamic>;
//     String userName = userData['name'] ?? 'No Name';
//     String userEmail = userData['email'] ?? 'No Email';
//     String userImage = userData['image'] ?? '';
//
//     String eventName = eventData['eventName'];
//     String eventTicketId = eventData['ticketId'];
//     DocumentReference attendantsDocRef = _firestore.collection('event_attendants').doc(eventName).collection('attendants').doc(user.uid);
//
//     DocumentSnapshot attendantDoc = await attendantsDocRef.get();
//
//     if (attendantDoc.exists) {
//       await attendantsDocRef.delete();
//       await _firestore.collection('details').doc(eventName).update({
//         'user_ticket_id': FieldValue.arrayRemove([user.uid]),
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Attendance Cancelled')),
//       );
//     } else {
//       String ticketId = _generateTicketId();
//       Uint8List qrImage = await _generateQRCode(ticketId);
//       String qrImageJson = jsonEncode(qrImage);
//
//
//       await attendantsDocRef.set({
//         'user_id': user.uid,
//         'name': userName,
//         'email': userEmail,
//         'image': userImage,
//         'attendance_date': DateTime.now().toIso8601String(),
//         'user_ticket_id': ticketId,
//         'payment_type' : 'FREE',
//         'present' : '',
//         'clockIn_time': '',
//         'clockIn_date': '',
//         'user_ticket_id_qr_code' : qrImageJson,
//         'eventName' : eventName,
//         'eventTicketId' : eventTicketId,
//       });
//       await _firestore.collection('details').doc(eventName).update({
//         'user_ticket_id': FieldValue.arrayUnion([user.uid]),
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('ATTENDANCE RECORDED')),
//       );
//     }
//   }
//
//   Future<void> _launchEmail(String email) async {
//     final Uri emailLaunchUri = Uri(
//       scheme: 'mailto',
//       path: email,
//     );
//     await launchUrl(emailLaunchUri);
//   }
//
//   Future<void> _launchCaller(String number) async {
//     final Uri callLaunchUri = Uri(
//       scheme: 'tel',
//       path: number,
//     );
//     await launchUrl(callLaunchUri);
//   }
//
//   Future<void> _launchWebsite(String url) async {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => WebViewContainer(url),
//       ),
//     );
//   }
//
//   Future<void> _toggleFavorite(BuildContext context, Map<String, dynamic> eventData) async {
//     User? user = _auth.currentUser;
//     if (user == null) return;
//
//     CollectionReference favCollection = _firestore.collection('favourites').doc(user.uid).collection('favourite_details');
//     DocumentReference favRef = favCollection.doc(eventData['eventName']);
//     DocumentSnapshot favDoc = await favRef.get();
//
//     if (favDoc.exists) {
//       await favRef.delete();
//     } else {
//       await favRef.set({
//         'eventData': eventData,
//         'savedAt': DateTime.now().toIso8601String(),
//       });
//     }
//   }
//
//
//
//   Future<Uint8List> _generateQRCode(String qrData) async {
//     try {
//       final qrImage = await QrPainter(
//         data: qrData,
//         version: QrVersions.auto,
//         gapless: false,
//         color: Colors.black,
//         emptyColor: Colors.white,
//       ).toImageData(300);
//       return qrImage!.buffer.asUint8List();
//     } catch (e) {
//       print('Failed to generate QR code: $e');
//       return Uint8List(0);
//     }
//   }
//
//   Widget _buildSlidingText(String text) {
//     return AnimatedBuilder(
//       animation: _animationController,
//       builder: (context, child) {
//         return Transform.translate(
//           offset: Offset(_animationController.value * MediaQuery.of(context).size.width, 0),
//           child: Text(
//             text,
//             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0, color: Colors.orange),
//           ),
//         );
//       },
//     );
//   }
//
//
//   Future<Future<bool?>> showDeleteEventDialog(BuildContext context, String ticketId) async {
//     return showDialog<bool>(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Delete Event'),
//           content: Text('Are you sure you want to delete this event?'),
//           actions: [
//             TextButton(
//               onPressed: () async {
//                 Navigator.of(context).pop(true);
//                 await deleteEvent(ticketId);
//               },
//               child: Text('DELETE'),
//             ),
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(false),
//               child: Text('CANCEL'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   Future<void> deleteEvent(String ticketId) async {
//     try {
//       // Create a reference to the Firestore collection group
//       final collectionRef = FirebaseFirestore.instance.collectionGroup('details');
//
//       // Query to find the document with the specific ticketId
//       final querySnapshot = await collectionRef.where('ticket_id', isEqualTo: ticketId).get();
//
//       // Check if the document exists and delete it
//       if (querySnapshot.docs.isNotEmpty) {
//         for (final doc in querySnapshot.docs) {
//           await doc.reference.delete();
//         }
//       } else {
//         print('No document found with ticket_id: $ticketId');
//       }
//     } catch (e) {
//       print('Error deleting document: $e');
//     }
//   }
//
//
//
//   Widget _buildEventCard(Map<String, dynamic> eventData) {
//     User? user = _auth.currentUser;
//
//     // Retrieve the user_id from eventData
//     String? eventUserId = eventData['user_id'];
//
//     // Check if the user is logged in and if the user_id in the event data matches the current user's ID
//     if (user == null || eventUserId != user.uid) {
//       return SizedBox.shrink(); // Return an empty widget if the IDs don't match or user is not logged in
//     }
//
//     String eventName = eventData['eventName'];
//     bool isPaid = _eventPaymentStatus[eventName] != null;
//     bool isFreeEvent = eventData['eventPaymentType'] == 'FREE';
//
//     return Card(
//       margin: EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Stack(
//             children: [
//               Container(
//                 width: double.infinity,
//                 height: 200,
//                 decoration: BoxDecoration(
//                   image: DecorationImage(
//                     image: NetworkImage(eventData['imageUrl'] ?? ''),
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//                 child: Container(
//                   color: Colors.black.withOpacity(0.4),
//                 ),
//               ),
//             ],
//           ),
//           Padding(
//             padding: EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 SingleChildScrollView(
//                   scrollDirection: Axis.horizontal,
//                   child: Text(
//                     eventData['organizerName'] ?? 'No Name',
//                     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
//                   ),
//                 ),
//                 SizedBox(height: 4.0),
//                 SingleChildScrollView(
//                   scrollDirection: Axis.horizontal,
//                   child: _buildSlidingText(eventData['eventName'] ?? 'No Event'),
//                 ),
//                 SizedBox(height: 4.0),
//                 SingleChildScrollView(
//                   scrollDirection: Axis.horizontal,
//                   child: Row(
//                     children: [
//                       if (eventData['organizerEmail'] != null && eventData['organizerEmail'].isNotEmpty)
//                         IconButton(
//                           icon: Icon(Icons.email),
//                           onPressed: () => _launchEmail(eventData['organizerEmail']),
//                         )
//                       else
//                         IconButton(
//                           icon: Icon(Icons.email, color: Colors.grey),
//                           onPressed: null, // Disabled state
//                         ),
//                       SizedBox(width: 16.0),
//                       if (eventData['organizerNumber'] != null && eventData['organizerNumber'].isNotEmpty)
//                         IconButton(
//                           icon: Icon(Icons.call),
//                           onPressed: () => _launchCaller(eventData['organizerNumber']),
//                         )
//                       else
//                         IconButton(
//                           icon: Icon(Icons.call, color: Colors.grey),
//                           onPressed: null, // Disabled state
//                         ),
//                       SizedBox(width: 16.0),
//                       if (eventData['organizerWebsite'] != null && eventData['organizerWebsite'].isNotEmpty)
//                         IconButton(
//                           icon: Icon(Icons.web),
//                           onPressed: () => _launchWebsite(eventData['organizerWebsite']),
//                         )
//                       else
//                         IconButton(
//                           icon: Icon(Icons.web, color: Colors.grey),
//                           onPressed: null, // Disabled state
//                         ),
//                       StreamBuilder<DocumentSnapshot>(
//                         stream: user != null
//                             ? _firestore
//                             .collection('favourites')
//                             .doc(user.uid)
//                             .collection('favourite_details')
//                             .doc(eventData['eventName'])
//                             .snapshots()
//                             : Stream<DocumentSnapshot>.empty(),
//                         builder: (context, snapshot) {
//                           bool isFavorited = snapshot.hasData && snapshot.data!.exists;
//
//                           return IconButton(
//                             icon: Icon(
//                               Icons.bookmark,
//                               color: isFavorited ? Colors.blue : Colors.grey,
//                             ),
//                             onPressed: () => _toggleFavorite(context, eventData),
//                           );
//                         },
//                       ),
//                       SizedBox(width: 16.0),
//
//                       IconButton(
//                         icon: Icon(Icons.qr_code),
//                         onPressed: () => _showQRCodeDialog(context, eventData['QrCode']),
//                       ),
//                       SizedBox(width: 16.0),
//                       PopupMenuButton<String>(
//                         onSelected: (value) async {
//                           if (value == 'profile') {
//                             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PROFILE')));
//                           } else if (value == 'report') {
//                             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('REPORT')));
//                           } else if (value == 'delete') {
//                             // Show delete confirmation dialog
//                             Future<Future<bool?>> shouldDelete =  showDeleteEventDialog(context, eventData['ticketId']);
//                             if (shouldDelete == true) {
//                               // Handle event deletion
//                               await deleteEvent(eventData['ticketId']);
//                               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Event deleted')));
//                             }
//                           } else if (value == 'edit') {
//                             // Navigate to EditEventPage
//                             Navigator.of(context).push(
//                               MaterialPageRoute(
//                                 builder: (context) => EditEventPage(eventData: eventData),
//                               ),
//                             );
//                           } else if (value == 'sendNotification') {
//                             // Navigate to SendNotificationPage
//                             Navigator.of(context).push(
//                               MaterialPageRoute(
//                                 builder: (context) => SendNotificationPage(eventId: eventData['ticketId']),
//                               ),
//                             );
//                           } else if (value == 'viewAttendees') {
//                             // Navigate to EventAttendantsPage
//                             Navigator.of(context).push(
//                               MaterialPageRoute(
//                                 builder: (context) => EventAttendantsPage(eventId: eventData['ticketId']),
//                               ),
//                             );
//                           }
//                         },
//                         itemBuilder: (BuildContext context) {
//                           return [
//                             PopupMenuItem<String>(
//                               value: 'profile',
//                               child: Text('PROFILE'),
//                             ),
//                             PopupMenuItem<String>(
//                               value: 'report',
//                               child: Text('REPORT'),
//                             ),
//                             PopupMenuItem<String>(
//                               value: 'delete',
//                               child: Text('DELETE'),
//                             ),
//                             PopupMenuItem<String>(
//                               value: 'edit',
//                               child: Text('EDIT'),
//                             ),
//                             PopupMenuItem<String>(
//                               value: 'sendNotification',
//                               child: Text('SEND NOTIFICATION'),
//                             ),
//                             PopupMenuItem<String>(
//                               value: 'viewAttendees',
//                               child: Text('VIEW ATTENDEES'),
//                             ),
//                           ];
//                         },
//                         icon: Icon(Icons.more_vert),
//                       ),
//
//                     ],
//                   ),
//                 ),
//                 SizedBox(height: 16.0),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: _buildEventIcons(eventData),
//                 ),
//                 if (isFreeEvent)
//                   StreamBuilder<DocumentSnapshot>(
//                     stream: user != null
//                         ? _firestore
//                         .collection('event_attendants')
//                         .doc(eventData['eventName'])
//                         .collection('attendants')
//                         .doc(user.uid)
//                         .snapshots()
//                         : Stream<DocumentSnapshot>.empty(),
//                     builder: (context, snapshot) {
//                       bool isAttending = snapshot.hasData && snapshot.data!.exists;
//
//                       return Row(
//                         children: [
//                           ElevatedButton(
//                             onPressed: () => _handleAttendButton(context, eventData),
//                             child: Text(isAttending ? 'UNATTEND' : 'ATTEND'),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: isAttending ? Colors.red : Colors.blue,
//                               textStyle: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
//                             ),
//                           ),
//
//                           Spacer(),
//                           IconButton(
//                             icon: Icon(Icons.favorite_border, color: Colors.grey),
//                             onPressed: null, // Disabled state
//                           ),
//                           IconButton(
//                             icon: Icon(Icons.notifications, color: Colors.grey),
//                             onPressed: null, // Disabled state
//                           ),
//                         ],
//                       );
//                     },
//                   ),
//                 StreamBuilder<DocumentSnapshot>(
//                   stream: user != null
//                       ? _firestore
//                       .collection('event_attendants')
//                       .doc(eventData['eventName'])
//                       .collection('attendants')
//                       .doc(user.uid)
//                       .snapshots()
//                       : Stream<DocumentSnapshot>.empty(),
//                   builder: (context, snapshot) {
//                     bool isAttending = snapshot.hasData && snapshot.data!.exists;
//                     bool isPaid = isAttending; // Assume isPaid is true if the user is attending
//
//                     return Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         if (eventData['eventPaymentType'] == 'PAID')
//                           if (!isPaid)
//                             ElevatedButton(
//                               onPressed: () => _showPaymentOptions(context, eventData),
//                               child: Text('PAY (\$${eventData['price']})'),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.green,
//                                 textStyle: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
//                               ),
//                             )
//                           else
//                             ElevatedButton(
//                               onPressed: null, // Disabled state
//                               child: Text('PAID'),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.grey, // Use grey or another color to indicate disabled
//                                 textStyle: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
//                               ),
//                             ),
//                       ],
//                     );
//                   },
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//
//   void _showPaymentOptions(BuildContext context, Map<String, dynamic> eventData) {
//     double price = double.tryParse(eventData['price'].toString()) ?? 0.0;
//
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Choose Payment Method'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//
//             ElevatedButton(
//               onPressed: () async {
//                 Navigator.of(context).push(MaterialPageRoute(
//                   builder: (BuildContext context) => PaypalCheckout(
//                     sandboxMode: true,
//                     clientId: "Ab99Av6a70Az6C-DpXoAuI3rHiLtjWEPTmrtZLCO4wVyZ5tnYPcyU4vOKxttFQtvpqIQ8qdn2ON-4BFy",
//                     secretKey: "EPsBQSP1Xfcj4v_8f29WNRnkDU-S8lHeFqsBzMHlLyoAdiRQgOIYvYBq752_fhflhkTKcTI9e7ZZTSJE",
//                     returnURL: "success.snippetcoder.com",
//                     cancelURL: "cancel.snippetcoder.com",
//                     transactions:  [
//                       {
//                         "amount": {
//                           "total": price.toString(), // Use the passed price
//                           "currency": "GBP",
//
//                         },
//                         "description": "Thank you.",
//                       }
//                     ],
//                     note: "Contact us for any questions on your order.",
//                     onSuccess: (Map params) async {
//                       print("onSuccess: $params");
//
//                       // Mark the event as paid and handle attendance
//                       await _handlePaymentSuccess(context, eventData, 'PayPal');
//                     },
//                     onError: (error) {
//                       print("onError: $error");
//                       Navigator.pop(context);
//                     },
//                     onCancel: () {
//                       print('cancelled:');
//                     },
//                   ),
//                 ));
//               },
//               child: Text('Pay with PAYPAL'),
//               style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
//             ),
//
//
//             ElevatedButton(
//               onPressed: () async {
//
//                 // Prepare the items list for Stripe payment checkout
//                 final items = [
//                   {
//                     "productPrice": price,
//                     "productName": "Checkout", // Name/description of the product based on selected duration
//                     "qty": 1,
//                   },
//                 ];
//
//                 // Calculate the total amount
//                 final totalAmount = price * 1;
//
//
//                 // Now call StripeService to handle the payment
//                 StripeService.stripePaymentCheckout(
//                   items,
//                   totalAmount, // Pass the calculated total amount
//                   context,
//                   mounted,
//                   onSuccess: () {
//                     print("SUCCESS");
//
//                     // Mark the event as paid and handle attendance
//                     _handlePaymentSuccess(context, eventData, 'Stripe');
//                   },
//                   onCancel: () {
//                     print("Cancel");
//                     // Handle cancellation
//                   },
//                   onError: (e) {
//                     print("Error: " + e.toString());
//                     // Handle error
//                   },
//                 );
//               },
//               child: Text('Pay with STRIPE'),
//               style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             child: Text('Close'),
//             onPressed: () => Navigator.of(context).pop(),
//           ),
//         ],
//       ),
//     );
//   }
//
//
//
//   Future<void> _handlePaymentSuccess(BuildContext context, Map<String, dynamic> eventData, String paymentMethod) async {
//     User? user = _auth.currentUser;
//     if (user == null) return;
//
//     String eventName = eventData['eventName'];
//     String eventTicketId = eventData['ticketId'];
//     DocumentReference attendantsDocRef = _firestore.collection('event_attendants').doc(eventName).collection('attendants').doc(user.uid);
//
//     DocumentSnapshot socialUserDoc = await _firestore.collection('social_users').doc(user.uid).get();
//     if (!socialUserDoc.exists) return;
//
//     Map<String, dynamic> userData = socialUserDoc.data() as Map<String, dynamic>;
//     String userName = userData['name'] ?? 'No Name';
//     String userEmail = userData['email'] ?? 'No Email';
//     String userImage = userData['image'] ?? '';
//
//     String ticketId = _generateTicketId();
//     Uint8List qrImage = await _generateQRCode(ticketId);
//     String qrImageJson = jsonEncode(qrImage);
//
//     await attendantsDocRef.set({
//       'user_id': user.uid,
//       'name': userName,
//       'email': userEmail,
//       'image': userImage,
//       'attendance_date': DateTime.now().toIso8601String(),
//       'user_ticket_id': ticketId,
//       'payment_type' : 'PAID',
//       'present' : '',
//       'clockIn_time': '',
//       'clockIn_date': '',
//       'user_ticket_id_qr_code' : qrImageJson,
//       'eventName' : eventName,
//       'eventTicketId' : eventTicketId,
//
//     });
//
//     await _firestore.collection('details').doc(eventName).update({
//       'user_ticket_id': FieldValue.arrayUnion([user.uid]),
//     });
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Payment Successful with $paymentMethod')),
//     );
//
//     setState(() {
//       _eventPaymentStatus[eventName] = paymentMethod; // Track payment status
//     });
//
//     Navigator.of(context).pop(); // Close the payment options dialog
//   }
//
//
//   List<Widget> _buildEventIcons(Map<String, dynamic> eventData) {
//     return [
//       _buildEventIcon(
//         icon: Icons.location_on,
//         title: 'Address Details',
//         content: '${eventData['eventCountry']}, ${eventData['eventCity']}, ${eventData['eventRegion']}, ${eventData['eventPostcode']}',
//       ),
//       _buildEventIcon(
//         icon: Icons.info,
//         title: 'Event Name',
//         content: eventData['eventName'] ?? 'No Name',
//       ),
//       _buildEventIcon(
//         icon: Icons.category,
//         title: 'Category',
//         content: eventData['eventCategory'] ?? 'No Category',
//       ),
//       _buildEventIcon(
//         icon: Icons.access_time,
//         title: 'Date & Time',
//         content: eventData['eventDateTime'] ?? 'No Date & Time',
//       ),
//       if (eventData['eventPaymentType'] == 'PAID')
//         _buildEventIcon(
//           icon: Icons.payment,
//           title: 'Payment Type',
//           content: 'Payment Type: ${eventData['eventPaymentType']}\nPrice: ${eventData['price'] ?? 'No Price'}',
//         ),
//     ];
//   }
//
//   Widget _buildEventIcon({required IconData icon, required String title, required String content}) {
//     return IconButton(
//       icon: Icon(icon),
//       onPressed: () => _showDetailsDialog(context, title, content),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Events Dashboard'),
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back),
//           onPressed: () {
//             Navigator.of(context).pushReplacement(
//               MaterialPageRoute(builder: (context) => HomePage()),
//             );
//           },
//         ),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _eventsStream,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(child: CircularProgressIndicator());
//           }
//
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }
//
//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return Center(child: Text('No events found.'));
//           }
//
//           return ListView(
//             children: snapshot.data!.docs.map((eventDoc) {
//               Map<String, dynamic> eventData = eventDoc.data() as Map<String, dynamic>;
//               return _buildEventCard(eventData);
//             }).toList(),
//           );
//         },
//       ),
//     );
//   }
// }
//
// class WebViewContainer extends StatelessWidget {
//   final String url;
//
//   WebViewContainer(this.url);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(),
//       body: WebView(
//         initialUrl: url,
//         javascriptMode: JavascriptMode.unrestricted,
//       ),
//     );
//   }
// }
//
//
// class EditEventPage extends StatefulWidget {
//   final Map<String, dynamic> eventData;
//
//   EditEventPage({required this.eventData});
//
//   @override
//   _EditEventPageState createState() => _EditEventPageState();
// }
//
// class _EditEventPageState extends State<EditEventPage> {
//   final _titleController = TextEditingController();
//   final _descriptionController = TextEditingController();
//   final _priceController = TextEditingController();
//   File? _selectedImage;
//   String _uploadedImageUrl = '';
//   bool _isPaidEvent = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchEventDetails();
//   }
//
//   Future<void> _fetchEventDetails() async {
//     var query = await FirebaseFirestore.instance
//         .collectionGroup('details')
//         .where('ticketId', isEqualTo: widget.eventData['ticketId'])
//         .get();
//
//     if (query.docs.isNotEmpty) {
//       var doc = query.docs.first;
//       var data = doc.data();
//       setState(() {
//         _titleController.text = data['eventName'];
//         _descriptionController.text = data['eventCountry'];
//         _uploadedImageUrl = data['imageUrl'];
//         if (data['eventPaymentType'] == 'PAID') {
//           _isPaidEvent = true;
//           _priceController.text = data['priceText']?.toString() ?? '';
//         }
//       });
//     }
//   }
//
//   Future<void> _updateEvent() async {
//     String imageUrl = _uploadedImageUrl;
//     if (_selectedImage != null) {
//       // Upload the image to Firebase Storage
//       String fileName = widget.eventData['ticketId'] + '_image';
//       Reference firebaseStorageRef = FirebaseStorage.instance.ref().child('event_images/$fileName');
//       UploadTask uploadTask = firebaseStorageRef.putFile(_selectedImage!);
//       TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() {});
//       imageUrl = await taskSnapshot.ref.getDownloadURL();
//     }
//
//     await FirebaseFirestore.instance
//         .collectionGroup('details')
//         .where('ticketId', isEqualTo: widget.eventData['ticketId'])
//         .get()
//         .then((query) {
//       if (query.docs.isNotEmpty) {
//         var doc = query.docs.first;
//         var updateData = {
//           'eventName': _titleController.text,
//           'eventCountry': _descriptionController.text,
//           'imageUrl': imageUrl,
//         };
//         if (_isPaidEvent) {
//           updateData['price'] = _priceController.text;
//         }
//         doc.reference.update(updateData);
//       }
//     });
//
//     Navigator.of(context).pop();
//   }
//
//   Future<void> _pickImage() async {
//     final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
//
//     setState(() {
//       if (pickedFile != null) {
//         _selectedImage = File(pickedFile.path);
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Edit Event Page')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             TextField(
//               controller: _titleController,
//               decoration: InputDecoration(labelText: 'Event Name'),
//             ),
//             TextField(
//               controller: _descriptionController,
//               decoration: InputDecoration(labelText: 'Event Country'),
//             ),
//             if (_isPaidEvent)
//               TextField(
//                 controller: _priceController,
//                 decoration: InputDecoration(labelText: 'Price'),
//                 keyboardType: TextInputType.number,
//               ),
//             SizedBox(height: 20),
//             GestureDetector(
//               onTap: _pickImage,
//               child: CircleAvatar(
//                 radius: 50,
//                 backgroundImage: _selectedImage != null
//                     ? FileImage(_selectedImage!)
//                     : _uploadedImageUrl.isNotEmpty
//                     ? NetworkImage(_uploadedImageUrl) as ImageProvider
//                     : AssetImage('assets/add_image.png'),
//                 child: Icon(
//                   Icons.camera_alt,
//                   size: 30,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//             SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _updateEvent,
//               child: Text('Update Event'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
//
// class SendNotificationPage extends StatefulWidget {
//   final String eventId;
//
//   SendNotificationPage({required this.eventId});
//
//   @override
//   _SendNotificationPageState createState() => _SendNotificationPageState();
// }
//
// class _SendNotificationPageState extends State<SendNotificationPage> {
//   final _titleController = TextEditingController();
//   final _descriptionController = TextEditingController();
//   File? _selectedImage;
//   String _uploadedImageUrl = '';
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchNotificationDetails();
//   }
//
//   Future<void> _fetchNotificationDetails() async {
//     // Get the Firestore instance
//     final firestore = FirebaseFirestore.instance;
//
//     // Query the collectionGroup 'details' where 'ticket_id' matches the eventId
//     final querySnapshot = await firestore
//         .collectionGroup('details')
//         .where('ticket_id', isEqualTo: widget.eventId)
//         .get();
//
//     if (querySnapshot.docs.isNotEmpty) {
//       // Assume that there is only one matching document and get its ID
//       final documentId = querySnapshot.docs.first.id;
//
//       // Query the 'notifications' collection of the found document
//       final notificationsSnapshot = await firestore
//           .collection('details')
//           .doc(documentId)
//           .collection('notifications')
//           .get();
//
//       if (notificationsSnapshot.docs.isNotEmpty) {
//         var notificationDoc = notificationsSnapshot.docs.first;
//         var data = notificationDoc.data();
//         setState(() {
//           _titleController.text = data['notificationTitle'] ?? '';
//           _descriptionController.text = data['notificationDescription'] ?? '';
//           _uploadedImageUrl = data['imageUrl'] ?? '';
//         });
//       }
//     } else {
//       // Handle the case where no document was found
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('No matching event found.')),
//       );
//     }
//   }
//
//
//   Future<void> _sendNotification() async {
//     // Get the Firestore instance
//     final firestore = FirebaseFirestore.instance;
//
//     String imageUrl = _uploadedImageUrl;
//     if (_selectedImage != null) {
//       // Upload the image to Firebase Storage
//       String fileName = widget.eventId + '_image';
//       Reference firebaseStorageRef = FirebaseStorage.instance.ref().child('notification_images/$fileName');
//       UploadTask uploadTask = firebaseStorageRef.putFile(_selectedImage!);
//       TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() {});
//       imageUrl = await taskSnapshot.ref.getDownloadURL();
//     }
//
//
//     // Query the collectionGroup 'details' where 'ticket_id' matches the eventId
//     final querySnapshot = await firestore
//         .collectionGroup('details')
//         .where('ticket_id', isEqualTo: widget.eventId)
//         .get();
//
//     if (querySnapshot.docs.isEmpty) {
//       // Handle the case where no document was found
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('No matching event found.')),
//       );
//       return;
//     }
//
//     // Assume that there is only one matching document and get its ID
//     final documentId = querySnapshot.docs.first.id;
//
//     // Add the notification to the 'notifications' collection of the found document
//     await firestore
//         .collection('details')
//         .doc(documentId)
//         .collection('notifications')
//         .add({
//       'notificationTitle': _titleController.text,
//       'notificationDescription': _descriptionController.text,
//       'imageUrl': imageUrl,
//       'views_count': 0,
//       'viewer_name' : '',
//       'viewer_email' : '',
//       'viewer_image' : '',
//     });
//
//     // Notify the user and pop the page
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Notification sent successfully!')),
//     );
//     Navigator.of(context).pop();
//   }
//
//
//   Future<void> _pickImage() async {
//     final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
//
//     setState(() {
//       if (pickedFile != null) {
//         _selectedImage = File(pickedFile.path);
//       }
//     });
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Send Notification')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//
//             SizedBox(height: 20),
//             TextField(
//               controller: _titleController,
//               decoration: InputDecoration(labelText: 'Notification Title'),
//             ),
//             SizedBox(height: 20),
//             TextField(
//               controller: _descriptionController,
//               decoration: InputDecoration(labelText: 'Description'),
//             ),
//             SizedBox(height: 20),
//             GestureDetector(
//               onTap: _pickImage,
//               child: CircleAvatar(
//                 radius: 50,
//                 backgroundImage: _selectedImage != null
//                     ? FileImage(_selectedImage!)
//                     : _uploadedImageUrl.isNotEmpty
//                     ? NetworkImage(_uploadedImageUrl) as ImageProvider
//                     : AssetImage('assets/add_image.png'),
//                 child: Icon(
//                   Icons.camera_alt,
//                   size: 30,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//             SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _sendNotification,
//               child: Text('Send Notification'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
//
// class EventAttendantsPage extends StatelessWidget {
//   final String eventId;
//
//   EventAttendantsPage({required this.eventId});
//
//
//
//   void _showQRCodeDialog(BuildContext context, dynamic qrCodeData) {
//     Uint8List? qrCode;
//     if (qrCodeData is String) {
//       try {
//         qrCode = Uint8List.fromList(jsonDecode(qrCodeData).cast<int>());
//       } catch (e) {
//         print('Error decoding QR code data: $e');
//       }
//     } else if (qrCodeData is Uint8List) {
//       qrCode = qrCodeData;
//     }
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('QR Code'),
//           content: SizedBox(
//             height: 300,
//             width: 300,
//             child: qrCode != null ? Image.memory(qrCode) : Text('No QR Code available'),
//           ),
//           actions: [
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: Text('Close'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Event Attendants')),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collectionGroup('attendants')
//             .where('eventTicketId', isEqualTo: eventId)
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(child: CircularProgressIndicator());
//           }
//
//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return Center(child: Text('No attendants found.'));
//           }
//
//           final attendants = snapshot.data!.docs;
//
//           return ListView.builder(
//             itemCount: attendants.length,
//             itemBuilder: (context, index) {
//               final data = attendants[index].data() as Map<String, dynamic>;
//
//               // Extract the additional fields with default values if they don't exist
//               final clockInTime = data['clockIn_time'] ?? 'N/A';
//               final clockInDate = data['clockIn_date'] ?? 'N/A';
//               final present = data['present'] ?? 'NO';
//               final attendanceDate = data['attendance_date'] ?? 'N/A';
//               final paymentType = data['payment_type'] ?? 'N/A';
//               final userTicketId = data['user_ticket_id'] ?? 'N/A';
//               final userTicketIdQrCode = data['user_ticket_id_qr_code'] ?? 'N/A';
//
//               return ListTile(
//                 title: Text(data['name'] ?? 'No name'),
//                 subtitle: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('Email: ${data['email'] ?? 'No email'}'),
//                     Text('Clock In Time: $clockInTime'),
//                     Text('Clock In Date: $clockInDate'),
//                     Text('Present: $present'),
//                     Text('Attendance Date: $attendanceDate'),
//                     Text('Payment Type: $paymentType'),
//                     Text('User Ticket ID: $userTicketId'),
//                   ],
//                 ),
//                 leading: CircleAvatar(
//                   backgroundImage: NetworkImage(data['profilePicture'] ?? ''),
//                 ),
//                 trailing: IconButton(
//                   icon: Icon(Icons.qr_code),
//                   onPressed: () => _showQRCodeDialog(context, userTicketIdQrCode),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
//
