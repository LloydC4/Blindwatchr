class Movie
{
  String fullName; // full name of the movie including release date
  String name; // name with release date removed
  String dateReleased; // date released
  double recScore; // compatibility with user calculated by algorithm
  String posterURL; // url of the poster image of the movie
  String trailer; // youtube url of the trailer
  String description; // description of movie plot
  var streamingInfo; // map detailing which streaming services movie is available on

  Movie(this.fullName, this.name, this.dateReleased, this.recScore, this.posterURL, this.trailer, this.description, [this.streamingInfo]);

  Movie.fromJson(Map<String, dynamic> json)
      : fullName = json['fullName'],
        name = json['name'],
        dateReleased = json['dateReleased'],
        recScore = json['recScore'],
        posterURL = json['posterURL'],
        trailer = json['trailer'],
        description = json['description'],
        streamingInfo = json['streamingInfo'];
}