import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'homepage.dart';

class AllQrCodeScannerPage extends StatefulWidget {
  @override
  _AllQrCodeScannerPageState createState() => _AllQrCodeScannerPageState();
}

class _AllQrCodeScannerPageState extends State<AllQrCodeScannerPage> {
  String _qrCodeResult = '';
  bool _isProcessing = false;
  Map<String, dynamic>? _eventData;
  Map<String, dynamic>? _attendantData;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Scan QR Code'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => HomePage()),
            ),
          ),
        ),
        body: Center(
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: _isProcessing ? null : _scanQRCode,
          child: Text('Start QR Scan'),
        ),
        SizedBox(height: 20),
        if (_qrCodeResult.isNotEmpty) ...[
          _buildResultDisplay(),
          if (_eventData != null) _buildEventDetails(),
          if (_attendantData != null) _buildAttendantDetails(),
        ],
      ],
    );
  }

  Widget _buildResultDisplay() {
    return Column(
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
      ],
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
    try {
      String qrCodeResult = await FlutterBarcodeScanner.scanBarcode(
        '#FF0000',
        'Cancel',
        true,
        ScanMode.QR,
      );

      if (!mounted || qrCodeResult == '-1') return;

      setState(() {
        _qrCodeResult = qrCodeResult;
      });
    } catch (e) {
      print('Error scanning QR code: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error scanning QR code: $e'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _processScannedData(String qrData) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      String ticketId = qrData;

      // Try to fetch the attendant data first
      bool attendantFound = await _fetchAttendantData(ticketId);

      // If no attendant data is found, then fetch the event data
      if (!attendantFound) {
        await _fetchEventData(ticketId);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data processed successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error processing scanned data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing scanned data: $e'),
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

  Future<bool> _fetchAttendantData(String ticketId) async {
    try {
      final attendantsSnapshot = await FirebaseFirestore.instance
          .collection('attendants')
          .where('user_ticket_id', isEqualTo: ticketId)
          .limit(1)
          .get();

      if (attendantsSnapshot.docs.isNotEmpty) {
        setState(() {
          _attendantData = attendantsSnapshot.docs.first.data() as Map<String, dynamic>;
        });
        return true; // Indicate that data was found
      } else {
        // No attendant data found, return false
        return false;
      }
    } catch (e) {
      print('Failed to fetch attendant data: $e');
      throw e;
    }
  }

  Future<void> _fetchEventData(String ticketId) async {
    try {
      final eventSnapshot = await FirebaseFirestore.instance
          .collectionGroup('details')
          .where('ticket_id', isEqualTo: ticketId)
          .limit(1)
          .get();

      if (eventSnapshot.docs.isNotEmpty) {
        setState(() {
          _eventData = eventSnapshot.docs.first.data() as Map<String, dynamic>;
        });
      } else {
        throw Exception('Document with ticketId $ticketId does not exist in events');
      }
    } catch (e) {
      print('Failed to fetch event data: $e');
      throw e;
    }
  }

  Widget _buildEventDetails() {
    if (_eventData == null) {
      return Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('NO DATA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );
    }

    final eventData = _eventData!;
    return Card(
      margin: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            )
          else
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/add_image.png'),
                  fit: BoxFit.cover,
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
                SizedBox(height: 20),
                IconButton(
                  icon: Icon(Icons.qr_code),
                  onPressed: () => _showQRCodeDialog(context, eventData['user_ticket_id_qr_code']),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendantDetails() {
    if (_attendantData == null) {
      return Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('NO DATA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );
    }

    final attendantData = _attendantData!;
    return Card(
      margin: EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (attendantData['image'] != null)
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(attendantData['image']),
            )
          else
            CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/add_image.png'),
            ),
          ListTile(
            title: Text(attendantData['name'] ?? 'NO DATA'),
            subtitle: Text(attendantData['email'] ?? 'NO DATA'),
            trailing: IconButton(
              icon: Icon(Icons.qr_code),
              onPressed: () => _showQRCodeDialog(context, attendantData['user_ticket_id_qr_code']),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Payment Type: ${attendantData['payment_type'] ?? 'NO DATA'}'),
                Text('Present: ${attendantData['present'] ?? 'NO DATA'}'),
                Text('Clock In Date: ${attendantData['clockIn_date'] ?? 'NO DATA'}'),
                Text('Clock In Time: ${attendantData['clockIn_time'] ?? 'NO DATA'}'),
                Text('User Ticket ID: ${attendantData['user_ticket_id'] ?? 'NO DATA'}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showQRCodeDialog(BuildContext context, String? qrCode) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('QR Code'),
          content: qrCode != null && qrCode.isNotEmpty
              ? Image.network(qrCode)
              : Text('No QR Code available'),
          actions: [
            TextButton(
              child: Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}
