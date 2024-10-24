from names_generator import generate_name
import random
from datetime import datetime
import json

mails = [
    "gmail.com", "yahoo.com", "outlook.com", "wp.pl", "tlen.pl", "onet.pl", "example.com"
]

def random_mail():
    return random.choice(mails)

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


start_year = 2018
end_year = 2023

table_name = 'Reader'
data_sql = []

for index in range(100001):
    name = generate_name(style='capital')
    split_name = str(name).split()
    join_date = str(generate_random_date(start_year, end_year))
    email = str(split_name[0]).lower() + '.' + str(split_name[1]).lower() + str(random.randint(100, 2010)) + '@' + str(random_mail())
    data_sql.append({'ReaderID': index, 'FirstName': split_name[0], 'LastName': split_name[1], 'Email': email, 'JoinDate': join_date})


with open(f'{table_name}.json', 'w', encoding='utf-8') as file:
    json.dump(data_sql, file, indent=4, ensure_ascii=False)
