import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event/statusuploadpage.dart';
import 'package:video_player/video_player.dart';
import 'package:status_view/status_view.dart';
import 'homepage.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:status_view/status_view.dart';
import 'homepage.dart';

class StatusViewPage extends StatefulWidget {
  @override
  _StatusViewPageState createState() => _StatusViewPageState();
}

class _StatusViewPageState extends State<StatusViewPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _navigateToHomePage() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage()));
  }

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Status Updates'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: _navigateToHomePage,
          ),
        ),
        body: Center(
          child: user == null
              ? Text('No user signed in')
              : StreamBuilder<QuerySnapshot>(
            stream: _firestore.collectionGroup('statuses').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Text('No statuses available');
              }

              // Map to hold statuses grouped by userId
              Map<String, List<DocumentSnapshot>> userStatuses = {};
              for (var status in snapshot.data!.docs) {
                String userId = status.reference.parent.parent!.id;
                if (userStatuses.containsKey(userId)) {
                  userStatuses[userId]!.add(status);
                } else {
                  userStatuses[userId] = [status];
                }
              }

              return ListView(
                scrollDirection: Axis.horizontal, // Horizontal scrolling
                children: userStatuses.entries.map((entry) {
                  String userId = entry.key;
                  List<DocumentSnapshot> statuses = entry.value;

                  // Example: Calculate seenCount based on your logic
                  int seenCount = statuses.where((status) =>
                  (status.data() as Map<String, dynamic>?)?['viewedById']?.contains(user!.uid) ?? false).length;

                  return FutureBuilder<DocumentSnapshot>(
                    future: _firestore.collection('social_users').doc(userId).get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      }
                      if (!snapshot.hasData) {
                        return Text('User not found');
                      }

                      String userName = snapshot.data!.get('name');

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0), // Adjust horizontal spacing as needed
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () => _showFullScreenStatusView(statuses, 0),
                              child: StatusView(
                                radius: 40,
                                spacing: 15,
                                strokeWidth: 2,
                                indexOfSeenStatus: seenCount,
                                numberOfStatus: statuses.length,
                                padding: 4,
                                seenColor: Colors.grey,
                                unSeenColor: Colors.red,
                                centerImageUrl: "https://picsum.photos/200/300",
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(userName), // Display user's name
                          ],
                        ),
                      );
                    },
                  );
                }).toList(),
              );

            },
          ),
        ),
      ),
    );
  }

  void _showFullScreenStatusView(List<DocumentSnapshot> statuses, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenStatusView(statuses: statuses, initialIndex: initialIndex, currentUser: _auth.currentUser),
      ),
    ).then((_) {
      setState(() {}); // Refresh the status view when returning from full screen
    });
  }
}


class FullScreenStatusView extends StatefulWidget {
  final List<DocumentSnapshot> statuses;
  final int initialIndex;
  final User? currentUser;

  FullScreenStatusView({required this.statuses, required this.initialIndex, required this.currentUser});

  @override
  _FullScreenStatusViewState createState() => _FullScreenStatusViewState();
}

class _FullScreenStatusViewState extends State<FullScreenStatusView> {
  late PageController _pageController;
  bool _isAutoSliding = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _markStatusAsViewed(widget.statuses[widget.initialIndex]);
      _preloadStatuses();
      _startAutoSlideShow();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _preloadStatuses() async {
    for (var status in widget.statuses) {
      var data = status.data() as Map<String, dynamic>?;

      if (data != null) {
        String? mediaUrl = data['mediaUrl'] as String?;
        String? mediaType = data['mediaType'] as String?;

        if (mediaType == 'image' && mediaUrl != null) {
          precacheImage(NetworkImage(mediaUrl), context);
        } else if (mediaType == 'video' && mediaUrl != null) {
          await VideoPlayerController.network(mediaUrl).initialize();
        }
      }
    }
  }

  void _startAutoSlideShow() {
    if (!_isAutoSliding) {
      _isAutoSliding = true;
      _autoSlideToNext();
    }
  }

  void _autoSlideToNext() async {
    Duration duration = await _getAutoSlideDuration(widget.statuses[_pageController.page!.round()]);
    await Future.delayed(duration);
    if (_pageController.page!.round() < widget.statuses.length - 1) {
      _pageController.nextPage(duration: Duration(milliseconds: 500), curve: Curves.ease);
      _autoSlideToNext();
    } else {
      _isAutoSliding = false;
    }
  }

  Future<Duration> _getAutoSlideDuration(DocumentSnapshot status) async {
    var data = status.data() as Map<String, dynamic>?;

    if (data != null) {
      String? mediaType = data['mediaType'] as String?;

      if (mediaType == 'video') {
        return _getVideoDuration(data['mediaUrl'] as String);
      } else if (mediaType == 'image') {
        return Duration(seconds: 3);
      } else {
        return Duration(seconds: 10);
      }
    }

    return Duration.zero;
  }

  Future<Duration> _getVideoDuration(String videoUrl) async {
    VideoPlayerController controller = VideoPlayerController.network(videoUrl);

    try {
      await controller.initialize(); // Initialize the video controller
      await controller.setVolume(0.0); // Mute the video
      return controller.value.duration; // Return the duration of the video
    } catch (e) {
      print('Failed to initialize video player: $e');
      return Duration(seconds: 0); // Return zero duration on failure
    } finally {
      controller.dispose(); // Dispose of the video controller
    }
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context); // Navigate back to previous screen (StatusUploadPage)
            },
          ),
        ),
        body: PageView.builder(
          controller: _pageController,
          itemCount: widget.statuses.length,
          onPageChanged: (index) {
            _markStatusAsViewed(widget.statuses[index]);
          },
          itemBuilder: (context, index) {
            DocumentSnapshot status = widget.statuses[index];
            _markStatusAsViewed(status);

            return StreamBuilder<DocumentSnapshot>(
              stream: status.reference.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                Map<String, dynamic>? data = snapshot.data!.data() as Map<String, dynamic>?;
                String? mediaUrl = data?['mediaUrl'] as String?;
                String? mediaType = data?['mediaType'] as String?;
                String? text = data?['text'] as String?;
                List<dynamic> likedBy = [];

                if (data != null && data['likedBy'] is List) {
                  likedBy = List.from(data['likedBy']);
                } else {
                  likedBy = [];
                }

                int likeCount = likedBy.length;
                bool isLiked = likedBy.contains(widget.currentUser!.uid);

                return StatusWidget(
                  mediaUrl: mediaUrl,
                  mediaType: mediaType,
                  text: text,
                  likeCount: likeCount,
                  isLiked: isLiked,
                  onLikePressed: () => _toggleLike(status),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _markStatusAsViewed(DocumentSnapshot status) async {
    if (widget.currentUser == null) return;

    DocumentReference statusRef = status.reference;

    try {
      // Fetch current user's name from 'users' collection
      DocumentSnapshot userSnapshot =
      await FirebaseFirestore.instance.collection('social_users').doc(widget.currentUser!.uid).get();
      String? currentUserName = userSnapshot.get('name');

      // Update viewedById and viewedByName
      await statusRef.update({
        'viewedById': FieldValue.arrayUnion([widget.currentUser!.uid]),
        'viewedByName': FieldValue.arrayUnion([currentUserName ?? '']),
      });
    } catch (e) {
      print("Failed to mark status as viewed: $e");
    }
  }

  void _toggleLike(DocumentSnapshot status) async {
    if (widget.currentUser == null) return;

    DocumentReference statusRef = status.reference;

    // Get current status data
    DocumentSnapshot snapshot = await statusRef.get();
    Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;

    // Check if user already liked the status
    List<dynamic> likedBy = List.from(data?['likedBy'] ?? []);

    if (likedBy.contains(widget.currentUser!.uid)) {
      // User already liked the status, so unlike it
      likedBy.remove(widget.currentUser!.uid);
    } else {
      // User has not liked the status, so like it
      likedBy.add(widget.currentUser!.uid);
    }

    // Update Firestore with new likedBy list and likeCount
    await statusRef.update({
      'likedBy': likedBy,
      'likeCount': likedBy.length,
    });
  }
}






class StatusWidget extends StatelessWidget {
  final String? mediaUrl;
  final String? mediaType;
  final String? text;
  final int likeCount;
  final bool isLiked;
  final VoidCallback onLikePressed;

  StatusWidget({
    this.mediaUrl,
    this.mediaType,
    this.text,
    required this.onLikePressed,
    required this.likeCount,
    required this.isLiked,
  });

  @override
  Widget build(BuildContext context) {
    Widget mediaWidget;
    if (mediaType == 'image' && mediaUrl != null) {
      mediaWidget = Image.network(mediaUrl!);
    } else if (mediaType == 'video' && mediaUrl != null) {
      mediaWidget = VideoWidget(mediaUrl: mediaUrl!);
    } else if (text != null && text!.isNotEmpty) {
      mediaWidget = Center(
        child: Text(
          text!,
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      );
    } else {
      mediaWidget = Center(child: Text('No media', style: TextStyle(color: Colors.white)));
    }

    return GestureDetector(
      onTap: onLikePressed,
      child: Container(
        color: Colors.black,
        child: Stack(
          children: [
            mediaWidget,
            Align(
              alignment: Alignment.topRight,
              child: Container(
                margin: EdgeInsets.all(8),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: Colors.red,
                    ),
                    SizedBox(width: 4),
                    Text(
                      likeCount.toString(),
                      style: TextStyle(color: Colors.white),
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
