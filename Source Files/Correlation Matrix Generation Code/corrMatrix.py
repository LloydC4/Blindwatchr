import pandas

# reading grouplens data .csv files in to dataframes and merging
r_cols = ['user_id', 'movie_id', 'rating']
ratings = pandas.read_csv('project/ratings.csv', sep=',', names=r_cols, usecols=range(3), encoding="ISO-8859-1")

m_cols = ['movie_id', 'title']
movies = pandas.read_csv('project/movies.csv', sep=',', names=m_cols, usecols=range(2), encoding="ISO-8859-1")

ratings = pandas.merge(movies, ratings)

# creating a pivot table
userRatings = ratings.pivot_table(index=['user_id'],columns=['title'],values='rating')

# generating correlation matrix in which rating pairs must have at least 
# 30 ratings to be included to prevent spurious recommendations
corrMatrix = userRatings.corr(method='pearson', min_periods=30)

# exporting correlation matrix to be uploaded for use in cloud function
corrMatrix.to_pickle('correlation_matrix') 