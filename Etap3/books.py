import requests
from bs4 import BeautifulSoup
import re
from tqdm import tqdm
import json
from datetime import datetime
import numpy as np
import pandas as pd

import random

book_genres = [
    "Science Fiction", "Fantasy", "Mystery", "Romance", "Historical Fiction", 
    "Thriller", "Horror", "Biography", "Self-Help", "Young Adult", 
    "Dystopian", "Adventure", "Graphic Novel", "Non-Fiction", "Classics",
    "Poetry", "Literary Fiction", "Western", "Crime", "Comedy"
]

def random_genre():
    return random.choice(book_genres)


def generate_random_date(start_year, end_year, year=0):
    if year == 0:
        year = random.randint(start_year, end_year)
    month = random.randint(1, 12)
    
    if month in [1, 3, 5, 7, 8, 10, 12]:
        day = random.randint(1, 31)
    elif month in [4, 6, 9, 11]:
        day = random.randint(1, 30)
    else:
        if (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0):
            day = random.randint(1, 29)
        else:
            day = random.randint(1, 28)


    return datetime(year, month, day)

# Przykład użycia:
start_year = 1950
end_year = 2024


r_books = requests.get('https://wolnelektury.pl/api/books/')
with open('Author.json', 'r', encoding='utf-8') as file:
    authors_data = json.load(file)

author_mapping= {}
for author in authors_data:
    name = str(author["FirstName"]) + ' ' + str(author["LastName"])
    author_mapping[name] = author["AuthorID"]

data = r_books.json()

table_name = 'Book'
data_sql = []
index = 1


for book in data:
    title = book['title']
    author = book['author']
    authorID = author_mapping.get(author, '')
    genre = book['genre']
    publication_date = str(generate_random_date(start_year, end_year))
    data_sql.append({'BookID': index, 'Title': title, 'PublicationDate': publication_date, 'Genre': genre, 'AuthorID': authorID})

    index += 1

df = pd.read_csv("./books.csv", encoding='ISO-8859-1', sep=';', on_bad_lines='skip')

books = df['Book-Title'].unique()
publication_year = df['Year-Of-Publication']
authors = df['Book-Author']

book_list = books.tolist()
author_list = authors.tolist()
publication_year_list = publication_year.tolist()

index_for_csv = 0
for book in book_list:
    author = author_list[index_for_csv]
    authorID = author_mapping.get(author, '')
    year = publication_year_list[index_for_csv]
    try:
        publication_date = str(generate_random_date(start_year, end_year, year))
    except:
        public_date = ''
    genre = str(random_genre())
    data_sql.append({'BookID': index, 'Title': book, 'PublicationDate': publication_date, 'Genre': genre, 'AuthorID': authorID})
    index_for_csv += 1
    index += 1



with open(f'{table_name}.json', 'w', encoding='utf-8') as file:
    json.dump(data_sql, file, indent=4, ensure_ascii=False)
