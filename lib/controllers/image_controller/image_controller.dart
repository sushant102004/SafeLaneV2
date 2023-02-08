import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class ImageController extends GetxController {
  final cloudFirestore = FirebaseFirestore.instance;
  final firebaseStorage = FirebaseStorage.instance;
  final uuid = const Uuid();

  Future<dynamic> uploadImage(
      File? image, String obstacleType, String detail) async {
    RxString downloadLink = ''.obs;
    final storageInsance = firebaseStorage.ref();
    final user = FirebaseAuth.instance.currentUser;

    try {
      storageInsance.child('images/potholes').putFile(image!);
      downloadLink.value = await storageInsance.getDownloadURL();

      Position currentLocation = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      cloudFirestore.collection('potholes').doc(uuid.v1()).set({
        'latitude': currentLocation.latitude,
        'longitude': currentLocation.longitude,
        'downloadLink': downloadLink,
        'uploadedBy': user!.email,
        'obstacleType': obstacleType,
        'details': detail
      });
    } catch (err) {
      print('Error while uploading image');
    }
  }
}
