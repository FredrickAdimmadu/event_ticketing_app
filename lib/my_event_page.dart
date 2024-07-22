import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'homepage.dart';

class MyEventPage extends StatefulWidget {
  @override
  _MyEventPageState createState() => _MyEventPageState();
}

class _MyEventPageState extends State<MyEventPage> with SingleTickerProviderStateMixin {
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
    return FirebaseFirestore.instance.collectionGroup('attendants').snapshots();
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

  void _showTicketDialog(BuildContext context, String ticketId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Your Ticket ID'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  ticketId,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: ticketId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ticket ID copied to clipboard')),
                  );
                },
              ),
            ],
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

  Future<void> _launchEmail(String email) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      throw 'Could not launch $emailLaunchUri';
    }
  }

  Future<void> _launchCaller(String number) async {
    final Uri callLaunchUri = Uri(
      scheme: 'tel',
      path: number,
    );
    if (await canLaunchUrl(callLaunchUri)) {
      await launchUrl(callLaunchUri);
    } else {
      throw 'Could not launch $callLaunchUri';
    }
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

    // Retrieve the user_id from eventData
    String? eventUserId = eventData['user_id'] as String?;

    // Check if the user is logged in and if the user_id in the event data matches the current user's ID
    if (user == null || eventUserId != user.uid) {
      return SizedBox.shrink(); // Return an empty widget if the IDs don't match or user is not logged in
    }

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
                    eventData['name'] ?? 'No Name',
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
                      if (eventData['email'] != null && eventData['email']!.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.email),
                          onPressed: () => _launchEmail(eventData['email']!),
                        )
                      else
                        IconButton(
                          icon: Icon(Icons.email, color: Colors.grey),
                          onPressed: null, // Disabled state
                        ),
                      SizedBox(width: 16.0),
                      if (eventData['phoneNumber'] != null && eventData['phoneNumber']!.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.call),
                          onPressed: () => _launchCaller(eventData['phoneNumber']!),
                        )
                      else
                        IconButton(
                          icon: Icon(Icons.call, color: Colors.grey),
                          onPressed: null, // Disabled state
                        ),
                      SizedBox(width: 16.0),
                      if (eventData['websiteURL'] != null && eventData['websiteURL']!.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.web),
                          onPressed: () => _launchWebsite(eventData['websiteURL']!),
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
                        onPressed: () => _showQRCodeDialog(context, eventData['user_ticket_id_qr_code']),
                      ),
                      SizedBox(width: 16.0),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'profile') {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PROFILE')));
                          } else if (value == 'report') {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('REPORT')));
                          } else if (value == 'ticket') {
                            _showTicketDialog(context, eventData['user_ticket_id'] ?? 'No Ticket ID');
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
                            PopupMenuItem<String>(
                              value: 'ticket',
                              child: Text('MY EVENT TICKET'),
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
                SizedBox(height: 16.0),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.favorite_border, color: Colors.grey),
                      onPressed: null, // Disabled state
                    ),
                    IconButton(
                      icon: Icon(Icons.notifications, color: Colors.grey),
                      onPressed: null, // Disabled state
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildEventIcons(Map<String, dynamic> eventData) {
    return [
      _buildEventIcon(
        icon: Icons.location_on,
        title: 'Address Details',
        content: '${eventData['eventCountry'] ?? 'Unknown'}, ${eventData['eventCity'] ?? 'Unknown'}, ${eventData['eventRegion'] ?? 'Unknown'}, ${eventData['eventPostcode'] ?? 'Unknown'}',
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
        title: Text('My Attending Events'),
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
