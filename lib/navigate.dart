// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:pixelfield/screens/profile_edit/profile_screen.dart';
// import 'package:pixelfield/screens/user_address/user_address_page.dart';
// import 'package:pixelfield/shop/shop_page.dart';
// import 'api/apis.dart';
// import 'more.dart';
// import 'my_collection/favourite_page.dart'; // Import your FavouritesPage
//
// class NavigatePage extends StatefulWidget {
//
//
//   @override
//   _NavigatePageState createState() => _NavigatePageState();
// }
//
// class _NavigatePageState extends State<NavigatePage> {
//   int _selectedIndex = 0;
//
//   static List<Widget> _widgetOptions = <Widget>[
//
//     FavouritesPage(userId: FirebaseAuth.instance.currentUser!.uid),
//     ShopFlowersPage(),
//     MorePage(),
//   ];
//
//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: _widgetOptions.elementAt(_selectedIndex),
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         items: const <BottomNavigationBarItem>[
//           // BottomNavigationBarItem(
//           //   icon: Icon(Icons.document_scanner_rounded),
//           //   label: 'Scan',
//           // ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.collections),
//             label: 'Collection',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.sell),
//             label: 'Shop',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.settings),
//             label: 'Settings',
//           ),
//         ],
//         currentIndex: _selectedIndex,
//         onTap: _onItemTapped,
//       ),
//
//
//     );
//   }
// }
