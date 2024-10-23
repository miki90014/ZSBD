import requests
from bs4 import BeautifulSoup
import re
from tqdm import tqdm
import json
from datetime import datetime

import random

def generate_random_date(start_year, end_year):
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

print(data_sql[0:10])


with open(f'{table_name}.json', 'w', encoding='utf-8') as file:
    json.dump(data_sql, file, indent=4, ensure_ascii=False)
