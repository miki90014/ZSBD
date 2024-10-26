import requests
from bs4 import BeautifulSoup
import re
from tqdm import tqdm
import json
from datetime import datetime
import random
#from names_generator import generate_name fajny do generowania imion
import numpy as np
import pandas as pd

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

r_authors = requests.get('https://wolnelektury.pl/api/authors/')


months_mapping = {
    "stycznia": 1,
    "lutego": 2,
    "marca": 3,
    "kwietnia": 4,
    "maja": 5,
    "czerwca": 6,
    "lipca": 7,
    "sierpnia": 8,
    "września": 9,
    "października": 10,
    "listopada": 11,
    "grudnia": 12
}

data = r_authors.json()

table_name = 'Author'
data_sql = []
index = 1
for author in data:
    author_name = author['name']
    author_name = author_name.replace("'", "")
    author_name = author_name.replace("\\", "\\\\")
    author_name = author_name.replace("%", "\\%")
    author_name = author_name.replace("_", "\\_")
    author_name = author_name.replace(";", "")
    author_name = author_name.replace("&", " and ")
    slug = author['slug']
    split_name = author_name.split()
    if len(split_name) >= 2:
        data_sql.append({'AuthorID': index, 'FirstName': split_name[0][:50], 'LastName': ' '.join(split_name[1:])[:50], 'DateOfBirth': slug})
    else:
        data_sql.append({'AuthorID': index, 'FirstName': author_name[:50], 'LastName': '', 'DateOfBirth': slug})
    index += 1

index = 0

data_sql_copy = data_sql.copy()
for data in tqdm(data_sql_copy, desc="Processing authors", unit="author"):
    r_author = requests.get(f'https://wolnelektury.pl/api/authors/{data["DateOfBirth"]}')
    author_data = r_author.json()
    description_data = ''
    try:
        description_data = BeautifulSoup(author_data['description_pl'], 'html.parser').get_text()
        description_data = description_data.replace('\n', '').replace('\r', '').replace('  ', ' ')
        description_data = re.sub(r'\s+', ' ', description_data)
        description_data = description_data[:800]

        description_data = description_data.replace("'", "")
        description_data = description_data.replace("\\", "\\\\")
        description_data = description_data.replace("%", "\\%")
        description_data = description_data.replace("_", "\\_")
        description_data = description_data.replace("´", "")
        description_data = description_data.replace(";", "")
        description_data = description_data.replace("&", " and ")
    except:
        description_data = ''
    
    data['Description'] = description_data
    
    try:
        soup = BeautifulSoup(author_data['description_pl'], 'html')
        date_element = soup.find('dd')
        if date_element:
            date_text = date_element.get_text(strip=True)

            date_pattern = r'(\d{1,2} \w+ \d{4})'
            match = re.search(date_pattern, date_text)

            if match:
                birth_date = match.group(0)
                parts = birth_date.split()
                day = int(parts[0]) 
                month_name = parts[1]
                year = int(parts[2])
                month = months_mapping.get(month_name)
                date_object = datetime(year, month, day)
                data['DateOfBirth'] = str(date_object)
            else:
                data['DateOfBirth'] = ''
        else:
            data['DateOfBirth'] = ''
    except:
        data['DateOfBirth'] = ''
    
    data_sql[index] = data
    index += 1

start_year = 1600
end_year = 1970

df = pd.read_csv("./books.csv", encoding='ISO-8859-1', sep=';', on_bad_lines='skip')

unique_authors = df['Book-Author'].unique()
unique_authors_list = unique_authors.tolist()

for author in unique_authors_list:
    author = str(author).replace("'", "")
    author = author.replace("\\", "\\\\")
    author = author.replace("%", "\\%")
    author = author.replace("_", "\\_")
    author = author.replace("´", "")
    author = author.replace(";", "")
    author = author.replace("&", " and ")
    split_name = author.split()
    if len(split_name) >= 2:
        data_sql.append({'AuthorID': index, 'FirstName': split_name[0][:50], 'LastName': ' '.join(split_name[1:])[:50], 'DateOfBirth': str(generate_random_date(start_year, end_year)), 'Description': ''})
    else:
        data_sql.append({'AuthorID': index, 'FirstName': author_name[:50], 'LastName': '', 'DateOfBirth': str(generate_random_date(start_year, end_year)), 'Description': ''})
    index += 1


with open(f'{table_name}.json', 'w', encoding='utf-8') as file:
    json.dump(data_sql, file, indent=4, ensure_ascii=False)

