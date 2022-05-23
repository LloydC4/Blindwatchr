class MovieRating
{
  int rating; // rating user has given, either 1 for dislike or 5 for like
  String movieName; // name of movie
  bool? initialRating; // used for the checklist of 50 movies when user signs up

  MovieRating(this.movieName, [this.rating = 0, this.initialRating = false]);

  Map toJson() => {
    'movieName': movieName,
    'rating': rating,
  };
}