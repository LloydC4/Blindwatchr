import 'package:flutter/material.dart';
import 'package:final_project/View/RecScreen.dart';
import '../Controller/firebase.dart';
import '../Model/MovieRating.dart';
import 'Widgets/CustomDialog.dart';
import 'package:loader_overlay/loader_overlay.dart';

// screen shown after user registers(or logs in without completing this screen first). Prompts user to rate popular
// movies, so we have data to generate recommendations from.
class InitialRatingScreen extends StatefulWidget {
  const InitialRatingScreen({Key? key}) : super(key: key);

  @override
  _InitialRatingScreenState createState() => _InitialRatingScreenState();
}

class _InitialRatingScreenState extends State<InitialRatingScreen> {
  // list of 50 popular movies the user will be prompted to rate upon registering to generate recommendations,
  // user must rate at least 1, so model has some data to work with
  List<MovieRating> initialMovies = [
    MovieRating("Shawshank Redemption, The (1994)"),
    MovieRating("Love Actually (2003)"),
    MovieRating("Dark Knight, The (2008)"),
    MovieRating("Inception (2010)"),
    MovieRating("Titanic (1997)"),
    MovieRating("Fight Club (1999)"),
    MovieRating("Pulp Fiction (1994)"),
    MovieRating("Eternal Sunshine of the Spotless Mind (2004)"),
    MovieRating("Toy Story 2 (1999)"),
    MovieRating("Forrest Gump (1994)"),
    MovieRating("Matrix, The (1999)"),
    MovieRating("Lord of the Rings: The Fellowship of the Ring, The (2001)"),
    MovieRating("Godfather, The (1972)"),
    MovieRating("Finding Nemo (2003)"),
    MovieRating("Interstellar (2014)"),
    MovieRating("Notting Hill (1999)"),
    MovieRating("Seven (a.k.a. Se7en) (1995)"),
    MovieRating("Django Unchained (2012)"),
    MovieRating("Gladiator (2000)"),
    MovieRating("Lion King, The (1994)"),
    MovieRating("Inglourious Basterds (2009)"),
    MovieRating("Silence of the Lambs, The (1991)"),
    MovieRating("Saving Private Ryan (1998)"),
    MovieRating("Star Wars: Episode IV - A New Hope (1977)"),
    MovieRating("Wolf of Wall Street, The (2013)"),
    MovieRating("Schindler's List (1993)"),
    MovieRating("Prestige, The (2006)"),
    MovieRating("Departed, The (2006)"),
    MovieRating("Green Mile, The (1999)"),
    MovieRating("Shutter Island (2010)"),
    MovieRating("Memento (2000)"),
    MovieRating("Up (2009)"),
    MovieRating("Back to the Future (1985)"),
    MovieRating("American Beauty (1999)"),
    MovieRating("LÃ©on: The Professional (a.k.a. The Professional) (LÃ©on) (1994)"),
    MovieRating("Goodfellas (1990)"),
    MovieRating("American History X (1998)"),
    MovieRating("WALLÂ·E (2008)"),
    MovieRating("Terminator 2: Judgment Day (1991)"),
    MovieRating("Usual Suspects, The (1995)"),
    MovieRating("Truman Show, The (1998)"),
    MovieRating("Braveheart (1995)"),
    MovieRating("Reservoir Dogs (1992)"),
    MovieRating("Avengers, The (2012)"),
    MovieRating("Shining, The (1980)"),
    MovieRating("Sixth Sense, The (1999)"),
    MovieRating("Raiders of the Lost Ark (Indiana Jones and the Raiders of the Lost Ark) (1981)"),
    MovieRating("Monsters, Inc. (2001)"),
    MovieRating("Good Will Hunting (1997)"),
    MovieRating("Die Hard (1988)")
  ];
  List<MovieRating> ratedMovies = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  "Please select all the movies you like from the list provided. You must select at least 1 movie. This data is used for generated recommendations");
            },
          )
        ],
      ),
      body: LoaderOverlay(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 20),
              child: Text(
                "Select All Movies You Liked\n\n From The Following 50",
                style: TextStyle(fontSize: 25),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: Scrollbar(
                child: ListView.builder(
                    itemCount: initialMovies.length,
                    itemBuilder: (BuildContext context, int index) {
                      return CheckboxListTile(
                        title: Text(initialMovies[index].movieName),
                        value: initialMovies[index].initialRating,
                        onChanged: (bool? value) {
                          // if selected, rate 5 and add to list, if unselected, remove from list.
                          if (value!) {
                            initialMovies[index].rating = 5;
                            ratedMovies.add(initialMovies[index]);
                          } else {
                            ratedMovies.remove(initialMovies[index]);
                            initialMovies[index].rating = 0;
                          }
                          setState(() {
                            initialMovies[index].initialRating = value;
                          });
                        },
                      );
                    }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
              child: ElevatedButton(
                  child: const Text('Get Recommendation'),
                  style:
                      ElevatedButton.styleFrom(fixedSize: const Size(200, 40)),
                  onPressed: () async {
                    // if at least 1 movie selected and connected to internet, send ratings to cloud function and
                    // move to rec screen
                    if (!await CheckConnection()) {
                      ShowDialog(context, "Error",
                          "You are not connected to the internet");
                    } else if (ratedMovies.isEmpty) {
                      ShowDialog(
                          context, "Error", "Please Select At Least 1 Movie");
                    } else {
                      context.loaderOverlay.show();
                      userSetup(ratedMovies);
                      while (!await hasRatings()) {}
                      movieRecs = generateRecs();
                      context.loaderOverlay.hide();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const RecScreen()),
                      );
                    }
                  }),
            ),
          ],
        ),
      ),
    );
  }
}
