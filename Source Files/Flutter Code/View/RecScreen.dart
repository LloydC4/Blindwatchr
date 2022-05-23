import 'dart:async';
import 'package:flutter/material.dart';
import 'package:swipe/swipe.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../Controller/firebase.dart';
import '../Model/MovieRating.dart';
import '../Model/Movie.dart';
import 'Widgets/CustomDialog.dart';

// future used for future builder
late Future<Movie> movieRecs;

// recommendation screen for displaying and rating recommended movies
class RecScreen extends StatefulWidget {
  const RecScreen({Key? key}) : super(key: key);

  @override
  _RecScreenState createState() => _RecScreenState();
}

class _RecScreenState extends State<RecScreen> {
  // allows user's smartphone to navigate to the URL passed to the function
  void _launchURL(String url) async {
    if (!await launch(url)) throw 'Could not launch $url';
  }

  // generates new movie recommendations
  void GetNewRecommendation() {
    movieRecs = generateRecs();
  }

  // adds movie to ratings list, then generates new recommendation
  void RateMovie(MovieRating rating) async {
    await addRating(rating);
    GetNewRecommendation();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // disallows user from pressing back button
    return WillPopScope(
      onWillPop: () => Future.value(false),
      child: Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        title: Center(
          child: Image.asset(
            "graphics/logo.jpg",
            height: 30,
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(
              Icons.help,
              size: 30.0,
              color: Colors.black,
            ),
            onPressed: () {
              ShowDialog(context, "Help",
                  "If you liked the movie you were recommended, either swipe right on the picture, or press the thumbs up.\n\n If you didn't like it, swipe left on the picture or press the thumbs down.\n\n Press the i button for more information about the movie.");
            },
          )
        ],
      ),
      body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder<Movie>(
              future: movieRecs,
              builder: (context, snapshot) {
                // returns loading screen while fetching data
                if (snapshot.connectionState != ConnectionState.done) {
                  return Center(
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height / 1.3,
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            LoadingAnimationWidget.halfTriangleDot(
                              color: Colors.green,
                              size: 100,
                            ),
                            const Text('Generating Recommendation...'),
                          ]),
                    ),
                  );
                }
                // displays rec screen when recommendation is generated
                if (snapshot.hasData) {
                  // displays if no recommendations are able to be generated
                  // user can swipe picture or press button to generate another
                  if (snapshot.data == null) {
                    return Expanded(
                      child: Column(children: [
                        Swipe(
                            horizontalMaxHeightThreshold: 50,
                            horizontalMinDisplacement: 100,
                            horizontalMinVelocity: 300,
                            child: Center(
                              child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20.0),
                                  child: Image.asset('graphics/Untitled-1.png',
                                      fit: BoxFit.cover)),
                            ),
                            onSwipeLeft: () async {
                              if (await CheckConnection()) {
                                GetNewRecommendation();
                              } else {
                                ShowDialog(context, "Error",
                                    "You are not connected to the internet.");
                              }
                            },
                            onSwipeRight: () async {
                              if (await CheckConnection()) {
                                GetNewRecommendation();
                              } else {
                                ShowDialog(context, "Error",
                                    "You are not connected to the internet.");
                              }
                            }),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            ElevatedButton(
                                child: const Text('Or Tap Me!'),
                                onPressed: () async {
                                  if (await CheckConnection()) {
                                    GetNewRecommendation();
                                  } else {
                                    ShowDialog(context, "Error",
                                        "You are not connected to the internet.");
                                  }
                                }),
                          ],
                        ),
                      ]),
                    );
                  }
                  // otherwise display recommendation and swipe buttons
                  else {
                    return Expanded(
                        child: Column(
                            children: [
                          Swipe(
                            horizontalMaxHeightThreshold: 50,
                            horizontalMinDisplacement: 100,
                            horizontalMinVelocity: 300,
                            child: Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20.0),
                                  child: Image.network(
                                    snapshot.data!.posterURL,
                                    fit: BoxFit.fill,
                                    height: MediaQuery.of(context).size.height / 1.5,
                                  ),
                                ),
                              ),
                            onSwipeLeft: () async {
                              if (await CheckConnection()) {
                                MovieRating rating =
                                MovieRating(snapshot.data!.fullName, 1);
                                RateMovie(rating);
                              } else {
                                ShowDialog(context, "Error",
                                    "You are not connected to the internet.");
                              }
                            },
                            onSwipeRight: () async {
                              if (await CheckConnection()) {
                                MovieRating rating =
                                MovieRating(snapshot.data!.fullName, 5);
                                RateMovie(rating);
                              } else {
                                ShowDialog(context, "Error",
                                    "You are not connected to the internet.");
                              }
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                ElevatedButton(
                                    child: const Icon(Icons.thumb_down),
                                    style: ElevatedButton.styleFrom(
                                      fixedSize: const Size(52, 52),
                                      shape: const CircleBorder(),
                                      primary: Colors.red,
                                    ),
                                    onPressed: () async {
                                      if (await CheckConnection()) {
                                        MovieRating rating =
                                        MovieRating(snapshot.data!.fullName, 1);
                                        RateMovie(rating);
                                      } else {
                                        ShowDialog(context, "Error",
                                            "You are not connected to the internet.");
                                      }
                                    }),
                                PopupMenuButton(
                                  icon: const Icon(Icons.info),
                                  iconSize: 60.0,
                                  itemBuilder: (BuildContext context) =>
                                      <PopupMenuEntry>[
                                    PopupMenuItem(
                                      onTap: () {
                                        Future.delayed(
                                          const Duration(seconds: 0),
                                          () => ShowDialog(
                                              context,
                                              snapshot.data!.name,
                                              snapshot.data!.description),
                                        );
                                      },
                                      child: const ListTile(
                                        leading: Icon(Icons.description),
                                        title: Text('Description'),
                                      ),
                                    ),
                                    PopupMenuItem(
                                      onTap: () async {
                                        if (await CheckConnection()) {
                                          _launchURL(snapshot
                                              .data!.trailer);
                                        } else if (snapshot
                                            .data!.trailer.isEmpty) {
                                          ShowDialog(context, "Error",
                                              "No Trailer Available");
                                        } else {
                                          ShowDialog(context, "Error",
                                              "You are not connected to the internet.");
                                        }
                                      },
                                      child: const ListTile(
                                        leading: Icon(Icons.movie),
                                        title: Text('Trailer'),
                                      ),
                                    ),
                                    PopupMenuItem(
                                      onTap: () {
                                        Future.delayed(
                                          const Duration(seconds: 0),
                                          () => ShowDialog(
                                              context,
                                              "Streaming Availability",
                                              snapshot
                                                  .data!.streamingInfo),
                                        );
                                      },
                                      child: const ListTile(
                                        leading: Icon(Icons.stream_rounded),
                                        title: Text('Streaming'),
                                      ),
                                    ),
                                  ],
                                ),
                                ElevatedButton(
                                    child: const Icon(Icons.thumb_up),
                                    style: ElevatedButton.styleFrom(
                                      fixedSize: const Size(52, 52),
                                      shape: const CircleBorder(),
                                      primary: Colors.green,
                                    ),
                                    onPressed: () async {
                                      if (await CheckConnection()) {
                                        MovieRating rating =
                                        MovieRating(snapshot.data!.fullName, 5);
                                        RateMovie(rating);
                                      } else {
                                        ShowDialog(context, "Error",
                                            "You are not connected to the internet.");
                                      }
                                    }),
                              ],
                            ),
                          ),
                        ]),
                    );
                  }
                }
                // display error message if error and allow user to try to generate recommendations again
                else if (snapshot.hasError) {
                  return Center(
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height / 1.3,
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Failed to Generate Recommendation'),
                            TextButton(
                              child: const Text(
                                'Press To Try Again',
                                style: TextStyle(fontSize: 20.0),
                              ),
                              onPressed: () async {
                                if (await CheckConnection()) {
                                  GetNewRecommendation();
                                } else {
                                  ShowDialog(context, "Error",
                                      "You are not connected to the internet.");
                                }
                              },
                            ),
                          ]),
                    ),
                  );
                }
                // return loading screen otherwise
                return Center(
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height / 1.3,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          LoadingAnimationWidget.halfTriangleDot(
                            color: Colors.green,
                            size: 100,
                          ),
                          const Text('Generating Recommendation...'),
                        ]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
