// import 'package:flutter/material.dart';
// import 'package:social/signallingservice.dart';
// import 'callscreen.dart';
//
// class JoinScreen extends StatefulWidget {
//   final String selfCallerId;
//   final String remoteCallerId;
//
//   const JoinScreen({Key? key, required this.selfCallerId, required this.remoteCallerId}) : super(key: key);
//
//   @override
//   State<JoinScreen> createState() => _JoinScreenState();
// }
//
// class _JoinScreenState extends State<JoinScreen> {
//   dynamic incomingSDPOffer;
//   TextEditingController remoteCallerIdTextEditingController = TextEditingController();
//
//   @override
//   void initState() {
//     super.initState();
//
//     // Listen for incoming video call
//     SignallingService.instance.socket!.on("newCall", (data) {
//       if (mounted) {
//         // Set SDP Offer of incoming call
//         setState(() => incomingSDPOffer = data);
//       }
//     });
//
//     // Set initial value for remote caller ID
//     remoteCallerIdTextEditingController.text = widget.remoteCallerId;
//   }
//
//   // Join Call
//   void _joinCall({
//     required String callerId,
//     required String calleeId,
//     dynamic offer,
//   }) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => CallScreen(
//           callerId: callerId,
//           calleeId: calleeId,
//           offer: offer,
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Theme.of(context).colorScheme.background,
//       appBar: AppBar(
//         centerTitle: true,
//         title: Text("P2P Call App"),
//       ),
//       body: SafeArea(
//         child: Stack(
//           children: [
//             Center(
//               child: SizedBox(
//                 width: MediaQuery.of(context).size.width * 0.9,
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     TextField(
//                       controller: TextEditingController(
//                         text: widget.selfCallerId,
//                       ),
//                       readOnly: true,
//                       textAlign: TextAlign.center,
//                       enableInteractiveSelection: false,
//                       decoration: InputDecoration(
//                         labelText: "Your Caller ID",
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(10.0),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     TextField(
//                       controller: remoteCallerIdTextEditingController,
//                       textAlign: TextAlign.center,
//                       decoration: InputDecoration(
//                         hintText: "Remote Caller ID",
//                         alignLabelWithHint: true,
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(10.0),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 24),
//                     ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         side: BorderSide(color: Colors.white30),
//                       ),
//                       child: Text(
//                         "Invite",
//                         style: TextStyle(
//                           fontSize: 18,
//                           color: Colors.white,
//                         ),
//                       ),
//                       onPressed: () {
//                         _joinCall(
//                           callerId: widget.selfCallerId,
//                           calleeId: remoteCallerIdTextEditingController.text,
//                         );
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             if (incomingSDPOffer != null)
//               Positioned(
//                 child: ListTile(
//                   title: Text(
//                     "Incoming Call from ${incomingSDPOffer["callerId"]}",
//                   ),
//                   trailing: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       IconButton(
//                         icon: Icon(Icons.call_end),
//                         color: Colors.redAccent,
//                         onPressed: () {
//                           setState(() => incomingSDPOffer = null);
//                         },
//                       ),
//                       IconButton(
//                         icon: Icon(Icons.call),
//                         color: Colors.greenAccent,
//                         onPressed: () {
//                           _joinCall(
//                             callerId: incomingSDPOffer["callerId"]!,
//                             calleeId: widget.selfCallerId,
//                             offer: incomingSDPOffer["sdpOffer"],
//                           );
//                         },
//                       )
//                     ],
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
