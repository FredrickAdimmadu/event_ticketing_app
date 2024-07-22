import 'package:event/qrcode_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event/statusuploadpage.dart';
import 'package:event/statusviewpage.dart';
import 'all_qr_code.dart';
import 'callscreen.dart';
import 'event_dashboard.dart';
import 'event_page.dart';
import 'event_upload.dart';
import 'favourite_page.dart';
import 'loginpage.dart';
import '../helper/dialogs.dart';
import 'my_event_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _searchResults = [];

  dynamic incomingSDPOffer;



  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    String query = _searchController.text.trim();
    if (query.isNotEmpty) {
      _searchUsers(query);
    } else {
      setState(() {
        _searchResults.clear();
      });
    }
  }

  void _searchUsers(String query) {
    _firestore
        .collection('social_users')
        .where('name', isEqualTo: query)
        .get()
        .then((QuerySnapshot snapshot) {
      setState(() {
        _searchResults = snapshot.docs;
      });
    }).catchError((error) {
      print('Error searching users: $error');
    });
  }

  void _joinCall({
    required String callerId,
    required String calleeId,
    dynamic offer,
    bool isAudioOnly = false,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          callerId: callerId,
          calleeId: calleeId,
          offer: offer,
          isAudioOnly: isAudioOnly,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Home'),
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[

              ListTile(
                  leading: Icon(Icons.upload),
                  title: Text('Event Upload'),
                  onTap: () async {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventUploadPage(),
                      ),
                    );
                  }
              ),


              ListTile(
                  leading: Icon(Icons.dashboard),
                  title: Text('Event Dashboard'),
                  onTap: () async {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventDashboardPage(),
                      ),
                    );
                  }
              ),




              ListTile(
                leading: Icon(Icons.event),
                title: Text('Events'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EventPage(),
                    ),
                  );
                },
              ),

              ListTile(
                  leading: Icon(Icons.upload),
                  title: Text('Status Upload'),
                  onTap: () async {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StatusUploadPage(),
                      ),
                    );
                  }
              ),


              ListTile(
                  leading: Icon(Icons.view_carousel),
                  title: Text('Status View'),
                  onTap: () async {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StatusViewPage(),
                      ),
                    );
                  }
              ),


              ListTile(
                  leading: Icon(Icons.favorite),
                  title: Text('Favourite'),
                  onTap: () async {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FavouritePage(),
                      ),
                    );
                  }
              ),


              ListTile(
                  leading: Icon(Icons.event_available),
                  title: Text('My Events'),
                  onTap: () async {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MyEventPage(),
                      ),
                    );
                  }
              ),


              ListTile(
                  leading: Icon(Icons.document_scanner),
                  title: Text('All QR Code Scanner'),
                  onTap: () async {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AllQrCodeScannerPage(),
                      ),
                    );
                  }
              ),


              ListTile(
                  leading: Icon(Icons.document_scanner_outlined),
                  title: Text('QR Code Scanner'),
                  onTap: () async {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QrCodeScannerPage(),
                      ),
                    );
                  }
              ),

              ListTile(
                leading: Icon(Icons.logout),
                title: Text('Logout'),
                onTap: () async {
                  Dialogs.showProgressBar(context);
                  FirebaseAuth.instance.signOut().then((value) {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LoginPage(),
                      ),
                    );
                  }).catchError((error) {
                    print('Error during logout: $error');
                  });
                },
              ),
            ],
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search users...',
                    ),
                  ),
                ),
                Expanded(
                  child:StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('social_users')
                        .where('name', isEqualTo: _searchController.text.trim())
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }

                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      _searchResults = snapshot.data!.docs;

                      return ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          DocumentSnapshot user = _searchResults[index];

                          bool isCurrentUser =
                              user.id == FirebaseAuth.instance.currentUser!.uid;

                          return ListTile(
                            title: Text(user['name']),
                            onTap: () {
                              //  _navigateToUserProfile(user.id);
                            },

                            subtitle: Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.call, color: Colors.blue),
                                  onPressed: isCurrentUser
                                      ? null
                                      : () {
                                    _joinCall(
                                      callerId: FirebaseAuth.instance.currentUser!.uid,
                                      calleeId: user.id,
                                      isAudioOnly: true,
                                    );
                                  },
                                ),
                                SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(Icons.video_call, color: Colors.blue),
                                  onPressed: isCurrentUser
                                      ? null
                                      : () {
                                    _joinCall(
                                      callerId: FirebaseAuth.instance.currentUser!.uid,
                                      calleeId: user.id,
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            if (incomingSDPOffer != null)
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: ListTile(
                  tileColor: Colors.white,
                  title: Text(
                    "Incoming Call from ${incomingSDPOffer["callerId"]}",
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.call_end),
                        color: Colors.redAccent,
                        onPressed: () {
                          setState(() => incomingSDPOffer = null);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.call),
                        color: Colors.greenAccent,
                        onPressed: () {
                          _joinCall(
                            callerId: incomingSDPOffer["callerId"]!,
                            calleeId: FirebaseAuth.instance.currentUser!.uid,
                            offer: incomingSDPOffer["sdpOffer"],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}