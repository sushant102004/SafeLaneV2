// ignore_for_file: library_private_types_in_public_api, avoid_print
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:safelane/maps/line_string.dart';
import 'package:safelane/maps/maps_helper.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:custom_marker/marker_icon.dart';
import 'dart:math' show cos, sqrt, asin;

class MapView extends StatefulWidget {
  // const MapView({super.key});
  const MapView(
      {super.key, required startAddController, required destiAddController});

  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final CameraPosition _initialLocation =
      const CameraPosition(target: LatLng(28.7041, 77.1025));
  late GoogleMapController mapController;

  late Position _currentPosition;
  String _currentAddress = '';

  final startAddressController = TextEditingController();
  final destinationAddressController = TextEditingController();

  final startAddressFocusNode = FocusNode();
  final desrinationAddressFocusNode = FocusNode();

  String _startAddress = '';
  String _destinationAddress = '';
  String? _placeDistance;
  List<Location> _destinationPosition = [];
  bool isFirstSearch = true;

  var distance = 0.0;

  Set<Marker> markers = {};

  // late PolylinePoints polylinePoints;
  final Set<Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  Widget _textField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required double width,
    required Icon prefixIcon,
    Widget? suffixIcon,
    required Function(String) locationCallback,
  }) {
    return SizedBox(
      width: width * 0.8,
      child: TextField(
        onChanged: (value) {
          locationCallback(value);
        },
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(
              Radius.circular(10.0),
            ),
            borderSide: BorderSide(
              color: Colors.grey.shade400,
              width: 2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(
              Radius.circular(10.0),
            ),
            borderSide: BorderSide(
              color: Colors.blue.shade300,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.all(15),
          hintText: hint,
        ),
      ),
    );
  }

  _getCurrentLocation() async {
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) async {
      setState(() {
        _currentPosition = position;
        // print('CURRENT POS: $_currentPosition');
        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 18.0,
            ),
          ),
        );
      });
      await _getAddress();
      addCurrentLocationMark();
    }).catchError((e) {
      print(e);
    });
  }

  _getAddress() async {
    try {
      List<Placemark> p = await placemarkFromCoordinates(
          _currentPosition.latitude, _currentPosition.longitude);

      Placemark place = p[0];

      setState(() {
        _currentAddress =
            "${place.name}, ${place.locality}, ${place.postalCode}, ${place.country}";
        startAddressController.text = _currentAddress;
        _startAddress = _currentAddress;
      });
    } catch (e) {
      print(e);
    }
  }

  Future<dynamic> addCurrentLocationMark() async {
    setState(() {
      markers.add(Marker(
          markerId: const MarkerId('startPosition'),
          position:
              LatLng(_currentPosition.latitude, _currentPosition.longitude),
          icon: BitmapDescriptor.defaultMarker));
    });
  }

  Future<dynamic> addDestinationMark() async {
    List<Location> destinationCoordinates =
        await locationFromAddress(_destinationAddress);

    setState(() {
      _destinationPosition = destinationCoordinates;
    });

    setState(() {
      markers.add(Marker(
          markerId: const MarkerId('endPosition'),
          position: LatLng(_destinationPosition[0].latitude,
              _destinationPosition[0].longitude),
          icon: BitmapDescriptor.defaultMarker));
    });
  }

  void calculateDistance() {
    double distanceInMeters = Geolocator.distanceBetween(
            _currentPosition.latitude,
            _currentPosition.longitude,
            _destinationPosition[0].latitude,
            _destinationPosition[0].longitude) /
        1000;

    setState(() {
      distance = double.parse(distanceInMeters.toStringAsFixed(2));
    });

    print('Distance: $distance KMs.');
  }

  void getPolyPoints() async {
    MapsHelper mapsHelper = MapsHelper(
        startLng: _currentPosition.latitude,
        startLat: _currentPosition.latitude,
        endLng: _destinationPosition[0].latitude,
        endLat: _destinationPosition[0].latitude);

    try {
      var data = await mapsHelper.getPolylineData();
      LineString ls =
          LineString(data['features'][0]['geometry']['coordinates']);

      for (int i = 0; i < ls.lineString.length; i++) {
        print(
            'Latitude: ${ls.lineString[i][0]} && Longitude: ${ls.lineString[i][1]}');
        polylines.add(Polyline(
            polylineId: const PolylineId('2'),
            points: [LatLng(ls.lineString[i][0], ls.lineString[i][1])]));
      }
    } catch (err) {
      print('Error: $err');
    }
  }

  Future<dynamic> showRoute() async {
    if (startAddressController.text.isEmpty ||
        destinationAddressController.text.isEmpty) {
      return const AlertDialog(
        content: Text('Please enter start and end address.'),
      );
    }
    await addDestinationMark();
    calculateDistance();
    getPolyPoints();
  }

  Future getDocuments() async {
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('potholes').get();

    for (int i = 0; i < querySnapshot.docs.length; i++) {
      markers.add(Marker(
          markerId: MarkerId(querySnapshot.docs[i]['downloadLink']),
          position: LatLng(querySnapshot.docs[i]['latitude'],
              querySnapshot.docs[i]['longitude']),
          icon: await MarkerIcon.pictureAsset(
              assetPath: 'assets/images/logo.png', width: 80, height: 100)));
    }
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    getDocuments();
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    return SizedBox(
      height: height,
      width: width,
      child: Scaffold(
        key: _scaffoldKey,
        body: Stack(
          children: <Widget>[
            GoogleMap(
              markers: Set<Marker>.from(markers),
              initialCameraPosition: _initialLocation,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              mapType: MapType.normal,
              zoomGesturesEnabled: true,
              zoomControlsEnabled: false,
              polylines: polylines,
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
              },
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    ClipOval(
                      child: Material(
                        color: Colors.blue.shade100,
                        child: InkWell(
                          splashColor: Colors.blue,
                          child: const SizedBox(
                            width: 50,
                            height: 50,
                            child: Icon(Icons.add),
                          ),
                          onTap: () {
                            mapController.animateCamera(
                              CameraUpdate.zoomIn(),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ClipOval(
                      child: Material(
                        color: Colors.blue.shade100,
                        child: InkWell(
                          splashColor: Colors.blue,
                          child: const SizedBox(
                            width: 50,
                            height: 50,
                            child: Icon(Icons.remove),
                          ),
                          onTap: () {
                            mapController.animateCamera(
                              CameraUpdate.zoomOut(),
                            );
                          },
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xB3FFFFFF),
                      borderRadius: BorderRadius.all(
                        Radius.circular(20.0),
                      ),
                    ),
                    width: width * 0.9,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Text(
                            'Places',
                            style: TextStyle(fontSize: 20.0),
                          ),
                          const SizedBox(height: 10),
                          _textField(
                              label: 'Start',
                              hint: 'Choose starting point',
                              prefixIcon: const Icon(Icons.looks_one),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.my_location),
                                onPressed: () {
                                  startAddressController.text = _currentAddress;
                                  _startAddress = _currentAddress;
                                },
                              ),
                              controller: startAddressController,
                              focusNode: startAddressFocusNode,
                              width: width,
                              locationCallback: (String value) {
                                setState(() {
                                  _startAddress = value;
                                });
                              }),
                          const SizedBox(height: 10),
                          _textField(
                              label: 'Destination',
                              hint: 'Choose destination',
                              prefixIcon: const Icon(Icons.looks_two),
                              controller: destinationAddressController,
                              focusNode: desrinationAddressFocusNode,
                              width: width,
                              locationCallback: (String value) {
                                setState(() {
                                  _destinationAddress = value;
                                });
                              }),
                          const SizedBox(height: 10),
                          Visibility(
                            visible: _placeDistance == null ? false : true,
                            child: Text(
                              'DISTANCE: $_placeDistance km',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          ElevatedButton(
                            onPressed: () {
                              showRoute();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Show Route'.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 20.0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10.0, bottom: 10.0),
                  child: ClipOval(
                    child: Material(
                      color: Colors.blue.shade100,
                      child: InkWell(
                        splashColor: const Color.fromARGB(255, 144, 200, 246),
                        child: const SizedBox(
                          width: 56,
                          height: 56,
                          child: Icon(Icons.my_location),
                        ),
                        onTap: () {
                          mapController.animateCamera(
                            CameraUpdate.newCameraPosition(
                              CameraPosition(
                                target: LatLng(
                                  _currentPosition.latitude,
                                  _currentPosition.longitude,
                                ),
                                zoom: 18.0,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
