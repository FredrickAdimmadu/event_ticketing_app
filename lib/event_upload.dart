import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'homepage.dart';


class EventUploadPage extends StatefulWidget {
  @override
  _EventUploadPageState createState() => _EventUploadPageState();
}

class _EventUploadPageState extends State<EventUploadPage> {
  final _formKey = GlobalKey<FormState>();
  File? _image;
  final picker = ImagePicker();

  String _eventType = 'INDOORS';
  String _eventCategory = 'ENTERTAINMENT';
  String _eventPaymentType = 'FREE';
  String? _price;

  String _eventName = '';
  String _eventCountry = '';
  String _eventCity = '';
  String _eventRegion = '';
  String _eventPostcode = '';
  String _eventDateTime = '';
  String? _userId;
  String _uploadDate = '';
  String _uploadTime = '';
  String _phoneNumber = '';
  String _websiteURL = '';

  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _uploadStatusMessage = '';

  TextEditingController _organizerNameController = TextEditingController();
  TextEditingController _organizerEmailController = TextEditingController();
  TextEditingController _eventDateTimeController = TextEditingController(); // Controller for Event Date & Time

  @override
  void initState() {
    super.initState();
    _loadOrganizerDetails();
  }

  Future<void> _loadOrganizerDetails() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userId = user.uid;
      });

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('social_users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          _organizerNameController.text = userDoc['name'] ?? 'No Name Available';
          _organizerEmailController.text = userDoc['email'] ?? 'No Email Available';
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });
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

  Future<void> _uploadEvent() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
        _uploadStatusMessage = 'Uploading...';
      });

      try {
        DateTime now = DateTime.now();
        _uploadDate = DateFormat('yyyy-MM-dd').format(now);
        _uploadTime = DateFormat('HH:mm').format(now);

        String ticketId = Uuid().v4();

        Uint8List qrImage = await _generateQRCode(ticketId);

        String qrImageJson = jsonEncode(qrImage);

        String imageUrl = '';
        if (_image != null && _userId != null) {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('event_images')
              .child('$_userId${DateTime.now().millisecondsSinceEpoch}');
          UploadTask uploadTask = storageRef.putFile(_image!);

          uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
            setState(() {
              _uploadProgress = snapshot.bytesTransferred.toDouble() / snapshot.totalBytes.toDouble();
            });
          });

          TaskSnapshot storageSnapshot = await uploadTask.whenComplete(() {
            setState(() {
              _uploadStatusMessage = 'Upload completed!';
            });
          });

          imageUrl = await storageSnapshot.ref.getDownloadURL();
        }

        if (_userId != null) {
          // Sanitize the event name to use as a collection path
          String sanitizedEventName = _eventName.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_');

          // Reference to the dynamically created collection
          CollectionReference eventCollection = FirebaseFirestore.instance
              .collection('events')
              .doc(sanitizedEventName)
              .collection('details');

          await eventCollection.add({
            'eventName': _eventName,
            'eventCountry': _eventCountry,
            'eventCity': _eventCity,
            'eventRegion': _eventRegion,
            'eventPostcode': _eventPostcode,
            'eventDateTime': _eventDateTime,
            'eventType': _eventType,
            'eventCategory': _eventCategory,
            'eventPaymentType': _eventPaymentType,
            'price': _price,
            'organizerName': _organizerNameController.text,
            'organizerEmail': _organizerEmailController.text,
            'imageUrl': imageUrl,
            'ticket_id': ticketId,
            'QrCode': qrImageJson,
            'user_id': _userId,
            'event_upload_date': _uploadDate,
            'event_upload_time': _uploadTime,
            'phoneNumber': _phoneNumber,
            'websiteURL': _websiteURL,
          });

          _formKey.currentState?.reset();
          setState(() {
            _image = null;
            _eventPaymentType = 'FREE';
            _price = null;
            _eventDateTimeController.clear(); // Clear the date-time controller
            _uploadDate = '';
            _uploadTime = '';
            _eventType = 'INDOORS';
            _eventCategory = 'ENTERTAINMENT';
            _phoneNumber = '';
            _websiteURL = '';
          });
        }
      } catch (e) {
        print('Failed to upload event: $e');
        setState(() {
          _uploadStatusMessage = 'Upload failed. Please try again.';
        });
      }

      setState(() {
        _isUploading = false;
      });
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
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => HomePage(),
                ),
              );
            },
          ),
          title: Text('Upload Event'),
        ),
        body: _isUploading
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LinearProgressIndicator(
                value: _uploadProgress,
                minHeight: 8.0,
              ),
              SizedBox(height: 20.0),
              Text('${(_uploadProgress * 100).toStringAsFixed(1)}%'),
              SizedBox(height: 20.0),
              Text(_uploadStatusMessage),
            ],
          ),
        )
            : SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: _image == null
                        ? Center(child: Text('Tap to pick an image'))
                        : Image.file(_image!, fit: BoxFit.cover),
                  ),
                ),
                SizedBox(height: 16.0),
                DropdownButtonFormField<String>(
                  value: _eventPaymentType,
                  items: ['FREE', 'PAID'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _eventPaymentType = newValue!;
                      _price = null;
                    });
                  },
                  decoration: InputDecoration(labelText: 'Payment Type'),
                ),
                if (_eventPaymentType == 'PAID')
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Price'),
                    keyboardType: TextInputType.number,
                    onSaved: (value) => _price = value!,
                    validator: (value) =>
                    _eventPaymentType == 'PAID' && value!.isEmpty
                        ? 'Enter price'
                        : null,
                  ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Event Name'),
                  onSaved: (value) => _eventName = value!,
                  validator: (value) =>
                  value!.isEmpty ? 'Enter event name' : null,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Event Country'),
                  onSaved: (value) => _eventCountry = value!,
                  validator: (value) =>
                  value!.isEmpty ? 'Enter event country' : null,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Event City'),
                  onSaved: (value) => _eventCity = value!,
                  validator: (value) =>
                  value!.isEmpty ? 'Enter event city' : null,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Event Region'),
                  onSaved: (value) => _eventRegion = value!,
                  validator: (value) =>
                  value!.isEmpty ? 'Enter event region' : null,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Event Postcode'),
                  onSaved: (value) => _eventPostcode = value!,
                  validator: (value) =>
                  value!.isEmpty ? 'Enter event postcode' : null,
                ),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Organizer Name',
                  ),
                  controller: _organizerNameController,
                  readOnly: true,
                ),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Organizer Email',
                  ),
                  controller: _organizerEmailController,
                  readOnly: true,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Event Date & Time'),
                  readOnly: true,
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null) {
                      TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (pickedTime != null) {
                        setState(() {
                          _eventDateTime =
                          '${DateFormat('yyyy-MM-dd').format(pickedDate)} ${pickedTime.format(context)}';
                          _eventDateTimeController.text = _eventDateTime;
                        });
                      }
                    }
                  },
                  controller: _eventDateTimeController,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                  onSaved: (value) => _phoneNumber = value!,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Enter phone number';
                    }
                    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                      return 'Enter digits only';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Website URL'),
                  keyboardType: TextInputType.url,
                  onSaved: (value) => _websiteURL = value!,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Enter website URL';
                    }

                    return null;
                  },
                ),
                DropdownButtonFormField<String>(
                  value: _eventType,
                  items: ['INDOORS', 'OUTDOORS'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _eventType = newValue!;
                    });
                  },
                  decoration: InputDecoration(labelText: 'Event Type'),
                ),
                DropdownButtonFormField<String>(
                  value: _eventCategory,
                  items: [
                    'ENTERTAINMENT',
                    'PARTY',
                    'TECHNOLOGY',
                    'ENTREPRENEURSHIP'
                  ].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _eventCategory = newValue!;
                    });
                  },
                  decoration: InputDecoration(labelText: 'Event Category'),
                ),
                SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: _uploadEvent,
                  child: Text('Upload Event'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
