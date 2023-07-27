# -*- coding: utf-8 -*-
import subprocess
import sys

print('Hello from ReLis')

def install(package):
    try:
        __import__(package)
    except:
        subprocess.check_call([sys.executable, "-m", "pip", "install", package])
        
install("pandas")      
install("numpy")
install("matplotlib")
install("sklearn")
install("json")
install("ast")

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import json
import ast

print("Arg1: ",sys.argv[1])
print("")
print("")
print("Arg2: ",type(sys.argv[2]))
# print("Arg2: ",sys.argv[2])
print("")
print("")
data = sys.argv[2].replace("\'", "\"")
print("data: ",type(data))
print("data: ",data)
# books = json.loads(data)
books = ast.literal_eval(data)
print("books: ",type(books))
print("books: ",books)

# bookDf = pd.DataFrame(dict(sys.argv[2]))
# print("bookDf: ",bookDf)

# #3 csv files and Reading these csv.
# books = pd.read_csv('./models/BX-CSV-Dump/BX-Books.csv', sep=';', error_bad_lines=False, encoding="latin-1", engine='python')
# users = pd.read_csv('./models/BX-CSV-Dump/BX-Users.csv', sep=';', error_bad_lines=False, encoding="latin-1")
# ratings = pd.read_csv('./models/BX-CSV-Dump/BX-Book-Ratings.csv', sep=';', error_bad_lines=False, encoding="latin-1")
# books.columns = ['ISBN', 'bookTitle', 'bookAuthor', 'yearOfPublication', 'publisher', 'imageUrlS', 'imageUrlM', 'imageUrlL']
# users.columns = ['userID', 'Location', 'Age']
# ratings.columns = ['userID', 'ISBN', 'bookRating']

# print('Imported from ReLis',str(sys.argv[1]))
# #Printing the datasets
# ratings.head()
# books.head()
# users.head()

# # print(ratings.head(5))
# # print(books.head(5))
# # print(users.head(5))

# #Understand Rating information using shape.
# # print(ratings.shape)
# # print(list(ratings.columns))

# #Understand Books information using shape.
# # print(books.shape)
# # print(list(books.columns))

# #Understand User information using shape.
# # print(users.shape)
# # print(list(users.columns))

# #Understanding rating with Histogram.
# # plt.rc("font", size=15)
# # ratings.bookRating.value_counts(sort=False).plot(kind='bar')
# # plt.title('Rating Distribution\n')
# # plt.xlabel('Rating')
# # plt.ylabel('Count')
# # plt.savefig('system1.png', bbox_inches='tight')
# # plt.show()

# #Rating distribution sa per Age of Users.
# # users.Age.hist(bins=[0, 10, 20, 30, 40, 50, 100])
# # plt.title('Age Distribution\n')
# # plt.xlabel('Age')
# # plt.ylabel('Count')
# # plt.savefig('system2.png', bbox_inches='tight')
# # plt.show()

# counts1 = ratings['userID'].value_counts()
# ratings = ratings[ratings['userID'].isin(counts1[counts1 >= 100].index)]
# counts = ratings['bookRating'].value_counts()
# ratings = ratings[ratings['bookRating'].isin(counts[counts >= 50].index)]

# combine_book_rating = pd.merge(ratings, books, on='ISBN')
# columns = ['yearOfPublication', 'publisher', 'bookAuthor', 'imageUrlS', 'imageUrlM', 'imageUrlL']
# combine_book_rating = combine_book_rating.drop(columns, axis=1)
# #combine_book_rating.head()

# combine_book_rating = combine_book_rating.dropna(axis = 0, subset = ['bookTitle'])

# book_ratingCount = (combine_book_rating.
#      groupby(by = ['bookTitle'])['bookRating'].
#      count().
#      reset_index().
#      rename(columns = {'bookRating': 'totalRatingCount'})
#      [['bookTitle', 'totalRatingCount']]
#     )
# #book_ratingCount.head()

# rating_with_totalRatingCount = combine_book_rating.merge(book_ratingCount, left_on = 'bookTitle', right_on = 'bookTitle', how = 'left')
# #rating_with_totalRatingCount.head()

# pd.set_option('display.float_format', lambda x: '%.3f' % x)
# #print(book_ratingCount['totalRatingCount'].describe())

# #print(book_ratingCount['totalRatingCount'].quantile(np.arange(.9, 1, .01)))

# #Creating threshold for rating >=50
# #So all books having less popularity than 50 will be removed, as they may not be much popular.
# popularity_threshold = 50
# rating_popular_book = rating_with_totalRatingCount.query('totalRatingCount >= @popularity_threshold')
# #rating_popular_book.head()

# rating_popular_book.shape

# combined = rating_popular_book.merge(users, left_on = 'userID', right_on = 'userID', how = 'left')

# #Based on user location we can combine users, but not required now.
# #us_canada_user_rating = combined[combined['Location'].str.contains("usa|canada")]
# all_user_rating=combined.drop('Age', axis=1)
# #all_user_rating.head()

# # -------Cosine Similarity and KNN-------
# from scipy.sparse import csr_matrix
# all_user_rating = all_user_rating.drop_duplicates(['userID', 'bookTitle'])
# all_user_rating_pivot = all_user_rating.pivot(index = 'bookTitle', columns = 'userID', values = 'bookRating').fillna(0)
# all_user_rating_matrix = csr_matrix(all_user_rating_pivot.values)

# #Took p=3, bydefault value is p=2. Can choose as per accuracy.
# from sklearn.neighbors import NearestNeighbors
# model_knn = NearestNeighbors(metric = 'cosine', algorithm = 'brute', p=3)
# model_knn.fit(all_user_rating_matrix)

# #all_user_rating_pivot

# all_user_rating_pivot.iloc[:].values.reshape(1,-1)

# query_index = np.random.choice(all_user_rating_pivot.shape[0])
# print(query_index)
# distances, indices = model_knn.kneighbors(all_user_rating_pivot.iloc[query_index,:].values.reshape(1, -1), n_neighbors = 6)

# all_user_rating_pivot.index[query_index]

# for i in range(0, len(distances.flatten())):
#     if i == 0:
#         print('Recommendations for {0}:\n'.format(all_user_rating_pivot.index[query_index]))
#     else:
#         print('{0}: {1}, with distance of {2}:'.format(i, all_user_rating_pivot.index[indices.flatten()[i]], distances.flatten()[i]))



# print('Exit from ReLis',str(sys.argv[1]))