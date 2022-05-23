import pandas
import json
import firebase_admin
import re
import requests
from imdb import Cinemagoer, IMDbError
from firebase_admin import credentials, firestore
firebase_admin.initialize_app()

class Movie:
   def __init__(self, name, recScore):
    # name is "[movie name] (release date)", so we need to extract the data to use for API search
    self.fullName = name
    self.dateReleased = name[-5:].replace(')', '')

    datelessName = name[0:-7]
    self.name = datelessName

    # movie names ending with ", the", were unable to be found, so remove it from the end and put it at the front
    if datelessName[-5:] == ', The':
        nameForSearch = datelessName.replace(', The', '')
        nameForSearch = 'The ' + nameForSearch
        self.searchName = re.sub("\(.*?\)","()",nameForSearch).replace(')', '').replace('(', '')
    else:
        self.searchName = re.sub("\(.*?\)","()",datelessName).replace(')', '').replace('(', '')
    
    self.recScore = recScore # compatibility score with the user
    self.imdbID = None 
    self.posterURL = None
    self.description = None
    self.streamingInfo = None # streaming availability
    self.trailer = None # youtube link for the trailer

def generate_recs(request):
    db = firestore.client() # used to get data from firestore
    ia = Cinemagoer() # used to get data from imdb API

    # used to get streaming info from API
    url = "https://streaming-availability.p.rapidapi.com/get/basic"

    headers = {
    'x-rapidapi-host': "streaming-availability.p.rapidapi.com",
    'x-rapidapi-key': "bbb551a542msh9c047206080d251p17fb2ejsn418d618e7d7b"
    }

    # getting the users existing movie ratings, then converting to a pandas dataframe
    ratings = db.collection(u'Users').document(request.args.get('uid')).get()
    tempDict = ratings.to_dict()
    listofdics = tempDict["movieRatings"]
    myRatings = pandas.DataFrame(list(eval(listofdics)))

    # retrieving the correlation matrix from google storage
    corrMatrix = pandas.read_pickle('gs://feisty-filament-336913.appspot.com/correlation_matrix')

    # finding the most compatible movies by using the correlation matrix and comparing each user rating with other rating pair correlation scores
    simCandidates = pandas.Series()
    for i in range(0, len(myRatings.index)):
        sims = corrMatrix[myRatings.movieName[i]].dropna()
        sims = sims.map(lambda x: x * myRatings.rating[i])
        simCandidates = simCandidates.append(sims)

    # returning all applicable movies, sorting for the most applicable and getting the top recommended movie
    simCandidates = simCandidates.groupby(simCandidates.index).sum()
    filteredSims = simCandidates.drop(myRatings.movieName, errors='ignore')
    filteredSims.sort_values(inplace = True, ascending = False)
    filteredSims = filteredSims.head(1)
    returnDict = filteredSims.to_dict()
    
    # creating movie object and getting the imdb ID of the top rated movie for streaming availability API
    movie = Movie(next(iter(returnDict.keys())), next(iter(returnDict.values())))
    imdbInfo = ia.search_movie(movie.searchName)

    # if movie has been found by searching for name, use imdbID to get streaming info
    if imdbInfo:
        movie.imdbID = 'tt' + imdbInfo[0].movieID
        # future feature that will change country code for streaming info API request, hard-coded for UK right now
        #querystring = {"country":request.args.get('countryCode'),"imdb_id":movie.imdbID,"output_language":"en"}
        querystring = {"country":"gb","imdb_id":movie.imdbID,"output_language":"en"}
        response = requests.request("GET", url, headers=headers, params=querystring)
        # if movie is found, create movie object and convert to JSON
        if response.status_code == 200:
            streamingAPIInfo = response.json()
            movie.posterURL = streamingAPIInfo["posterURLs"]["342"]
            movie.description = streamingAPIInfo["overview"]
            movie.streamingInfo = streamingAPIInfo["streamingInfo"]
            movie.trailer = "https://www.youtube.com/watch?v=" + streamingAPIInfo["video"]
            jsonString = json.dumps(movie.__dict__)
    
    # returning JSON to app if it exists
    if jsonString:
        return jsonString
    else:
        return