import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Model/MovieRating.dart';
import '../Model/Movie.dart';

CollectionReference users = FirebaseFirestore.instance.collection('Users');
FirebaseAuth auth = FirebaseAuth.instance;
FirebaseFunctions functions = FirebaseFunctions.instance;
User? user = FirebaseAuth.instance.currentUser;
var instance = FirebaseAuth.instance;

// creates user in firebase and stores initial ratings
Future<void> userSetup(List<MovieRating> movieRatings) async {
  String uid = auth.currentUser!.uid.toString();
  String movieRatingsJson = json.encode(movieRatings);
  users.doc(uid).set({'movieRatings': movieRatingsJson});
}

// checks to see if user has any ratings in firebase
Future<bool> hasRatings() async {
  String uid = auth.currentUser!.uid.toString();
  var document = await FirebaseFirestore.instance.doc('Users/' + uid).get();
  var data = document.data();
  if (data == null) {
    return false;
  } else {
    return true;
  }
}

// retrieves ratings from firebase
Future<Map<String, dynamic>> getRatings() async {
  String uid = auth.currentUser!.uid.toString();
  var document = await FirebaseFirestore.instance.doc('Users/' + uid).get();
  var data = document.data();
  return data!;
}

// adds new ratings to firebase
Future<void> addRating(MovieRating rating) async {
  String uid = auth.currentUser!.uid.toString();
  Map<String, dynamic> ratings = await getRatings();
  List<dynamic> ratingsList = jsonDecode(ratings["movieRatings"]);
  ratingsList.add(rating.toJson());
  String ratingsString = jsonEncode(ratingsList);
  await users.doc(uid).set({"movieRatings": ratingsString});
}

// uses recommendations in firebase to generate new recommendations and formats streaming availability data
Future<Movie> generateRecs() async {
  String uid = auth.currentUser!.uid.toString();
  final response = await http.get(Uri.parse(
      'https://europe-west2-feisty-filament-336913.cloudfunctions.net/function-5?uid=' +
          uid));

  if (response.statusCode == 200) {
    var movieJSON = json.decode(response.body);
    Movie movie = Movie.fromJson(movieJSON);

    var streamingPlatformList = [];
    movie.streamingInfo.keys.forEach((key) {
      streamingPlatformList.add(key);
    });
    if (streamingPlatformList.isEmpty) {
      movie.streamingInfo = "Not available on any streaming platforms.";
    } else {
      movie.streamingInfo = "Available to stream on: " +
          streamingPlatformList.toString().replaceAll("[", "").replaceAll("]", "") +
          ".";
    }

    return movie;
  } else {
    throw Exception('Failed to load recs');
  }
}

// used to check if user is connected to internet
Future<bool> CheckConnection() async
{
  try
  {
    final result = await InternetAddress.lookup('google.com');
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  }
  on SocketException catch (_)
  {
    return false;
  }
}
