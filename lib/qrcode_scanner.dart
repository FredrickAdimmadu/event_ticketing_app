import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'homepage.dart';

class QrCodeScannerPage extends StatefulWidget {
  @override
  _QrCodeScannerPageState createState() => _QrCodeScannerPageState();
}

class _QrCodeScannerPageState extends State<QrCodeScannerPage> {
  String _qrCodeResult = '';
  bool _isProcessing = false;
  Map<String, dynamic>? _eventData;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Scan QR Code'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => HomePage()),
              );
            },
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _isProcessing ? null : _scanQRCode,
                child: Text('Start QR Scan'),
              ),
              SizedBox(height: 20),
              if (_qrCodeResult.isNotEmpty)
                Column(
                  children: [
                    Text(
                      'Scanned QR Code Result:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(_qrCodeResult),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _qrCodeResult.isEmpty ? null : () => _processScannedData(_qrCodeResult),
                      child: _buildButtonChild(),
                    ),
                    if (_eventData != null && _eventData!['eventPaymentType'] == 'FREE')
                      ..._buildEventDetails(),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButtonChild() {
    if (_isProcessing) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Processing...'),
          SizedBox(width: 10),
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      );
    } else {
      return Text('PROCEED');
    }
  }

  Future<void> _scanQRCode() async {
    String qrCodeResult;
    try {
      qrCodeResult = await FlutterBarcodeScanner.scanBarcode(
        '#FF0000', // Scanner color
        'Cancel', // Cancel button text
        true, // Show flash icon
        ScanMode.QR, // Scan mode (default is QR)
      );
    } catch (e) {
      print('Error scanning QR code: $e');
      return;
    }

    if (!mounted || qrCodeResult == '-1') return;

    setState(() {
      _qrCodeResult = qrCodeResult;
    });
  }

  Future<void> _processScannedData(String qrData) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // qrData is the scanned ticketId
      String ticketId = qrData;

      // Fetch and update event data based on ticketId
      await _fetchEventData(ticketId);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Event data fetched successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error processing scanned data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing scanned data'),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
        _qrCodeResult = ''; // Clear QR code result to reset the button state
      });
    }
  }

  Future<void> _fetchEventData(String ticketId) async {
    try {
      // Fetch the event data using the ticket ID
      final eventSnapshot = await FirebaseFirestore.instance
          .collectionGroup('details')
          .where('ticket_id', isEqualTo: ticketId)
          .limit(1)
          .get();

      if (eventSnapshot.docs.isNotEmpty) {
        final eventDoc = eventSnapshot.docs.first;
        setState(() {
          _eventData = eventDoc.data() as Map<String, dynamic>;
        });
      } else {
        print('Error: Document with ticketId $ticketId does not exist in events');
        throw Exception('Document with ticketId $ticketId does not exist in events');
      }
    } catch (e) {
      print('Failed to fetch event data: $e');
      throw e;
    }
  }

  List<Widget> _buildEventDetails() {
    if (_eventData == null) return [];

    Map<String, dynamic> eventData = _eventData!;
    return [
      Card(
        margin: EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (eventData['imageUrl'] != null)
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(eventData['imageUrl']),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eventData['organizerName'] ?? 'No Name',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          eventData['organizerEmail'] ?? 'No Email',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Event Name: ${eventData['eventName'] ?? 'N/A'}'),
                  Text('Event Country: ${eventData['eventCountry'] ?? 'N/A'}'),
                  Text('Event City: ${eventData['eventCity'] ?? 'N/A'}'),
                  Text('Event Region: ${eventData['eventRegion'] ?? 'N/A'}'),
                  Text('Event Postcode: ${eventData['eventPostcode'] ?? 'N/A'}'),
                  Text('Event DateTime: ${eventData['eventDateTime'] ?? 'N/A'}'),
                  Text('Event Type: ${eventData['eventType'] ?? 'N/A'}'),
                  Text('Event Category: ${eventData['eventCategory'] ?? 'N/A'}'),
                  Text('Payment Type: ${eventData['eventPaymentType'] ?? 'N/A'}'),
                  if (eventData['eventPaymentType'] == 'PAID')
                    Text('Price: ${eventData['price'] ?? 'N/A'}'),
                ],
              ),
            ),
          ],
        ),
      ),
    ];
  }
}
