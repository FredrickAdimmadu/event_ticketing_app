import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:event/payment/stripe_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_paypal_checkout/flutter_paypal_checkout.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'homepage.dart';

class EventPage extends StatefulWidget {
  @override
  _EventPageState createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> with SingleTickerProviderStateMixin {
  late Stream<QuerySnapshot> _eventsStream;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late AnimationController _animationController;
  Map<String, String> _eventPaymentStatus = {};


  @override
  void initState() {
    super.initState();
    _eventsStream = _getEventsStream();
    _animationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: false);

  }


  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _getEventsStream() {
    return FirebaseFirestore.instance
        .collectionGroup('details')
        .snapshots();
  }

  void _showDetailsDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            child: Text('Close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showQRCodeDialog(BuildContext context, dynamic qrCodeData) {
    Uint8List? qrCode;

    if (qrCodeData is String) {
      try {
        qrCode = Uint8List.fromList(jsonDecode(qrCodeData).cast<int>());
      } catch (e) {
        print('Error decoding QR code data: $e');
      }
    } else if (qrCodeData is Uint8List) {
      qrCode = qrCodeData;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('QR Code'),
          content: SizedBox(
            height: 300,
            width: 300,
            child: qrCode != null ? Image.memory(qrCode) : Text('No QR Code available'),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _generateTicketId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rand = Random();
    return List.generate(7, (index) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<void> _handleAttendButton(BuildContext context, Map<String, dynamic> eventData) async {
    User? user = _auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You must be logged in to attend an event.')),
      );
      return;
    }
    DocumentReference socialUserDocRef = _firestore.collection('social_users').doc(user.uid);
    DocumentSnapshot socialUserDoc = await socialUserDocRef.get();

    if (!socialUserDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User data not found.')),
      );
      return;
    }

    Map<String, dynamic> userData = socialUserDoc.data() as Map<String, dynamic>;
    String userName = userData['name'] ?? 'No Name';
    String userEmail = userData['email'] ?? 'No Email';
    String userImage = userData['image'] ?? '';

    String eventName = eventData['eventName'];
    String eventTicketId = eventData['ticket_id'];

    String phoneNumber = eventData['phoneNumber'];
    String websiteURL = eventData['websiteURL'];
    String event_upload_date = eventData['event_upload_date'];
    String event_upload_time = eventData['event_upload_time'];
    String eventCategory = eventData['eventCategory'];
    String eventDate_Time = eventData['eventDateTime'];
    String eventCountry = eventData['eventCountry'];
    String eventCity = eventData['eventCity'];
    String eventRegion = eventData['eventRegion'];
    String eventPostcode = eventData['eventPostCode'];



    DocumentReference attendantsDocRef = _firestore.collection('event_attendants').doc(eventName).collection('attendants').doc(user.uid);

    DocumentSnapshot attendantDoc = await attendantsDocRef.get();

    if (attendantDoc.exists) {
      await attendantsDocRef.delete();
      await _firestore.collection('details').doc(eventName).update({
        'user_ticket_id': FieldValue.arrayRemove([user.uid]),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Attendance Cancelled')),
      );
    } else {
      String ticketId = _generateTicketId();
      Uint8List qrImage = await _generateQRCode(ticketId);
      String qrImageJson = jsonEncode(qrImage);


      await attendantsDocRef.set({
        'user_id': user.uid,
        'name': userName,
        'email': userEmail,
        'image': userImage,
        'attendance_date': DateTime.now().toIso8601String(),
        'user_ticket_id': ticketId,
        'payment_type' : 'FREE',
        'present' : '',
        'clockIn_time': '',
        'clockIn_date': '',
        'user_ticket_id_qr_code' : qrImageJson,
        'eventName' : eventName,
        'eventTicketId' : eventTicketId,

        'phoneNumber' : phoneNumber,
        'websiteURL'  : websiteURL,
        'event_upload_date' :  event_upload_date,
        'event_upload_time' : event_upload_time,
        'eventCategory' : eventCategory,
        'eventDateTime' : eventDate_Time,
        'eventCountry' : eventCountry,
        'eventCity' : eventCity,
        'eventRegion' : eventRegion,
        'eventPostcode' : eventPostcode,


      });
      await _firestore.collection('details').doc(eventName).update({
        'user_ticket_id': FieldValue.arrayUnion([user.uid]),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ATTENDANCE RECORDED')),
      );
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    await launchUrl(emailLaunchUri);
  }

  Future<void> _launchCaller(String number) async {
    final Uri callLaunchUri = Uri(
      scheme: 'tel',
      path: number,
    );
    await launchUrl(callLaunchUri);
  }

  Future<void> _launchWebsite(String url) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebViewContainer(url),
      ),
    );
  }

  Future<void> _toggleFavorite(BuildContext context, Map<String, dynamic> eventData) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    CollectionReference favCollection = _firestore.collection('favourites').doc(user.uid).collection('favourite_details');
    DocumentReference favRef = favCollection.doc(eventData['eventName']);
    DocumentSnapshot favDoc = await favRef.get();

    if (favDoc.exists) {
      await favRef.delete();
    } else {
      await favRef.set({
        'eventData': eventData,
        'savedAt': DateTime.now().toIso8601String(),
      });
    }
  }



  Future<Uint8List> _generateQRCode(String qrData) async {
    try {
      final qrImage = await QrPainter(
        data: qrData,
        version: QrVersions.auto,
        gapless: false,
        color: Colors.black,
        emptyColor: Colors.white,
      ).toImageData(300);
      return qrImage!.buffer.asUint8List();
    } catch (e) {
      print('Failed to generate QR code: $e');
      return Uint8List(0);
    }
  }

  Widget _buildSlidingText(String text) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_animationController.value * MediaQuery.of(context).size.width, 0),
          child: Text(
            text,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0, color: Colors.orange),
          ),
        );
      },
    );
  }

  Widget _buildEventCard(Map<String, dynamic> eventData) {
    User? user = _auth.currentUser;
    String eventName = eventData['eventName'];
    bool isPaid = _eventPaymentStatus[eventName] != null;
    bool isFreeEvent = eventData['eventPaymentType'] == 'FREE';

    return Card(
      margin: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(eventData['imageUrl'] ?? ''),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  color: Colors.black.withOpacity(0.4),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    eventData['organizerName'] ?? 'No Name',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                  ),
                ),
                SizedBox(height: 4.0),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _buildSlidingText(eventData['eventName'] ?? 'No Event'),
                ),
                SizedBox(height: 4.0),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (eventData['organizerEmail'] != null && eventData['organizerEmail'].isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.email),
                          onPressed: () => _launchEmail(eventData['organizerEmail']),
                        )
                      else
                        IconButton(
                          icon: Icon(Icons.email, color: Colors.grey),
                          onPressed: null, // Disabled state
                        ),
                      SizedBox(width: 16.0),
                      if (eventData['phoneNumber'] != null && eventData['phoneNumber'].isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.call),
                          onPressed: () => _launchCaller(eventData['phoneNumber']),
                        )
                      else
                        IconButton(
                          icon: Icon(Icons.call, color: Colors.grey),
                          onPressed: null, // Disabled state
                        ),
                      SizedBox(width: 16.0),
                      if (eventData['websiteURL'] != null && eventData['websiteURL'].isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.web),
                          onPressed: () => _launchWebsite(eventData['websiteURL']),
                        )
                      else
                        IconButton(
                          icon: Icon(Icons.web, color: Colors.grey),
                          onPressed: null, // Disabled state
                        ),
                      StreamBuilder<DocumentSnapshot>(
                        stream: user != null
                            ? _firestore
                            .collection('favourites')
                            .doc(user.uid)
                            .collection('favourite_details')
                            .doc(eventData['eventName'])
                            .snapshots()
                            : Stream<DocumentSnapshot>.empty(),
                        builder: (context, snapshot) {
                          bool isFavorited = snapshot.hasData && snapshot.data!.exists;

                          return IconButton(
                            icon: Icon(
                              Icons.bookmark,
                              color: isFavorited ? Colors.blue : Colors.grey,
                            ),
                            onPressed: () => _toggleFavorite(context, eventData),
                          );
                        },
                      ),
                      SizedBox(width: 16.0),

                      IconButton(
                        icon: Icon(Icons.qr_code),
                        onPressed: () => _showQRCodeDialog(context, eventData['QrCode']),
                      ),
                      SizedBox(width: 16.0),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'profile') {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PROFILE')));
                          } else if (value == 'report') {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('REPORT')));
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          return [
                            PopupMenuItem<String>(
                              value: 'profile',
                              child: Text('PROFILE'),
                            ),
                            PopupMenuItem<String>(
                              value: 'report',
                              child: Text('REPORT'),
                            ),
                          ];
                        },
                        icon: Icon(Icons.more_vert),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _buildEventIcons(eventData),
                ),
                if (isFreeEvent)
                  StreamBuilder<DocumentSnapshot>(
                    stream: user != null
                        ? _firestore
                        .collection('event_attendants')
                        .doc(eventData['eventName'])
                        .collection('attendants')
                        .doc(user.uid)
                        .snapshots()
                        : Stream<DocumentSnapshot>.empty(),
                    builder: (context, snapshot) {
                      bool isAttending = snapshot.hasData && snapshot.data!.exists;

                      return Row(
                        children: [
                          ElevatedButton(
                            onPressed: () => _handleAttendButton(context, eventData),
                            child: Text(isAttending ? 'UNATTEND' : 'ATTEND'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isAttending ? Colors.red : Colors.blue,
                              textStyle: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                            ),
                          ),


                          Spacer(),
                          IconButton(
                            icon: Icon(Icons.favorite_border, color: Colors.grey),
                            onPressed: null, // Disabled state
                          ),
                          IconButton(
                            icon: Icon(Icons.notifications, color: Colors.grey),
                            onPressed: null, // Disabled state
                          ),
                        ],
                      );
                    },
                  ),
                StreamBuilder<DocumentSnapshot>(
                  stream: user != null
                      ? _firestore
                      .collection('event_attendants')
                      .doc(eventData['eventName'])
                      .collection('attendants')
                      .doc(user.uid)
                      .snapshots()
                      : Stream<DocumentSnapshot>.empty(),
                  builder: (context, snapshot) {
                    bool isAttending = snapshot.hasData && snapshot.data!.exists;
                    bool isPaid = isAttending; // Assume isPaid is true if the user is attending

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (eventData['eventPaymentType'] == 'PAID')
                          if (!isPaid)
                            ElevatedButton(
                              onPressed: () => _showPaymentOptions(context, eventData),
                              child: Text('PAY (\$${eventData['price']})'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                textStyle: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                              ),
                            )


                          else
                            ElevatedButton(
                              onPressed: null, // Disabled state
                              child: Text('PAID'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey, // Use grey or another color to indicate disabled
                                textStyle: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                              ),
                            ),


                      ],
                    );

                  },
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }





  void _showPaymentOptions(BuildContext context, Map<String, dynamic> eventData) {
    double price = double.tryParse(eventData['price'].toString()) ?? 0.0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Choose Payment Method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (BuildContext context) => PaypalCheckout(
                    sandboxMode: true,
                    clientId: "Ab99Av6a70Az6C-DpXoAuI3rHiLtjWEPTmrtZLCO4wVyZ5tnYPcyU4vOKxttFQtvpqIQ8qdn2ON-4BFy",
                    secretKey: "EPsBQSP1Xfcj4v_8f29WNRnkDU-S8lHeFqsBzMHlLyoAdiRQgOIYvYBq752_fhflhkTKcTI9e7ZZTSJE",
                    returnURL: "success.snippetcoder.com",
                    cancelURL: "cancel.snippetcoder.com",
                    transactions:  [
                      {
                        "amount": {
                          "total": price.toString(), // Use the passed price
                          "currency": "GBP",

                        },
                        "description": "Thank you.",
                      }
                    ],
                    note: "Contact us for any questions on your order.",
                    onSuccess: (Map params) async {
                      print("onSuccess: $params");

                      // Mark the event as paid and handle attendance
                      await _handlePaymentSuccess(context, eventData, 'PayPal');
                    },
                    onError: (error) {
                      print("onError: $error");
                      Navigator.pop(context);
                    },
                    onCancel: () {
                      print('cancelled:');
                    },
                  ),
                ));
              },
              child: Text('Pay with PAYPAL'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ),


            ElevatedButton(
              onPressed: () async {

                // Prepare the items list for Stripe payment checkout
                final items = [
                  {
                    "productPrice": price,
                    "productName": "Checkout", // Name/description of the product based on selected duration
                    "qty": 1,
                  },
                ];

                // Calculate the total amount
                final totalAmount = price * 1;


                // Now call StripeService to handle the payment
                StripeService.stripePaymentCheckout(
                  items,
                  totalAmount, // Pass the calculated total amount
                  context,
                  mounted,
                  onSuccess: () {
                    print("SUCCESS");

                    // Mark the event as paid and handle attendance
                    _handlePaymentSuccess(context, eventData, 'Stripe');
                  },
                  onCancel: () {
                    print("Cancel");
                    // Handle cancellation
                  },
                  onError: (e) {
                    print("Error: " + e.toString());
                    // Handle error
                  },
                );
              },
              child: Text('Pay with STRIPE'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }



  Future<void> _handlePaymentSuccess(BuildContext context, Map<String, dynamic> eventData, String paymentMethod) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    String eventName = eventData['eventName'];
    String eventTicketId = eventData['ticket_id'];

    String phoneNumber = eventData['phoneNumber'];
    String websiteURL = eventData['websiteURL'];
    String event_upload_date = eventData['event_upload_date'];
    String event_upload_time = eventData['event_upload_time'];
    String eventCategory = eventData['eventCategory'];
    String eventDate_Time = eventData['eventDateTime'];
    String eventCountry = eventData['eventCountry'];
    String eventCity = eventData['eventCity'];
    String eventRegion = eventData['eventRegion'];
    String eventPostcode = eventData['eventPostCode'];

    DocumentReference attendantsDocRef = _firestore.collection('event_attendants').doc(eventName).collection('attendants').doc(user.uid);

    DocumentSnapshot socialUserDoc = await _firestore.collection('social_users').doc(user.uid).get();
    if (!socialUserDoc.exists) return;

    Map<String, dynamic> userData = socialUserDoc.data() as Map<String, dynamic>;
    String userName = userData['name'] ?? 'No Name';
    String userEmail = userData['email'] ?? 'No Email';
    String userImage = userData['image'] ?? '';

    String ticketId = _generateTicketId();
    Uint8List qrImage = await _generateQRCode(ticketId);
    String qrImageJson = jsonEncode(qrImage);

    await attendantsDocRef.set({
      'user_id': user.uid,
      'name': userName,
      'email': userEmail,
      'image': userImage,
      'attendance_date': DateTime.now().toIso8601String(),
      'user_ticket_id': ticketId,
      'payment_type' : 'PAID',
      'present' : '',
      'clockIn_time': '',
      'clockIn_date': '',
      'user_ticket_id_qr_code' : qrImageJson,
      'eventName' : eventName,
      'eventTicketId' : eventTicketId,

      'phoneNumber' : phoneNumber,
      'websiteURL'  : websiteURL,
      'event_upload_date' :  event_upload_date,
      'event_upload_time' : event_upload_time,
      'eventCategory' : eventCategory,
      'eventDateTime' : eventDate_Time,
      'eventCountry' : eventCountry,
      'eventCity' : eventCity,
      'eventRegion' : eventRegion,
      'eventPostcode' : eventPostcode,

    });

    await _firestore.collection('details').doc(eventName).update({
      'user_ticket_id': FieldValue.arrayUnion([user.uid]),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Successful with $paymentMethod')),
    );

    setState(() {
      _eventPaymentStatus[eventName] = paymentMethod; // Track payment status
    });

    Navigator.of(context).pop(); // Close the payment options dialog
  }





  List<Widget> _buildEventIcons(Map<String, dynamic> eventData) {
    return [
      _buildEventIcon(
        icon: Icons.location_on,
        title: 'Address Details',
        content: '${eventData['eventCountry']}, ${eventData['eventCity']}, ${eventData['eventRegion']}, ${eventData['eventPostcode']}',
      ),
      _buildEventIcon(
        icon: Icons.info,
        title: 'Event Name',
        content: eventData['eventName'] ?? 'No Name',
      ),
      _buildEventIcon(
        icon: Icons.category,
        title: 'Category',
        content: eventData['eventCategory'] ?? 'No Category',
      ),
      _buildEventIcon(
        icon: Icons.access_time,
        title: 'Date & Time',
        content: eventData['eventDateTime'] ?? 'No Date & Time',
      ),
      if (eventData['eventPaymentType'] == 'PAID')
        _buildEventIcon(
          icon: Icons.payment,
          title: 'Payment Type',
          content: 'Payment Type: ${eventData['eventPaymentType']}\nPrice: ${eventData['price'] ?? 'No Price'}',
        ),
    ];
  }

  Widget _buildEventIcon({required IconData icon, required String title, required String content}) {
    return IconButton(
      icon: Icon(icon),
      onPressed: () => _showDetailsDialog(context, title, content),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Events'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => HomePage()),
              );
            },
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _eventsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
      
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
      
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text('No events found.'));
            }
      
            return ListView(
              children: snapshot.data!.docs.map((eventDoc) {
                Map<String, dynamic> eventData = eventDoc.data() as Map<String, dynamic>;
                return _buildEventCard(eventData);
              }).toList(),
            );
          },
        ),
      );

  }
}

class WebViewContainer extends StatelessWidget {
  final String url;

  WebViewContainer(this.url);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: WebView(
        initialUrl: url,
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }
}