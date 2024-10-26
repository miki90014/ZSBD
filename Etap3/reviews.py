import random
import json
import datetime
from tqdm import tqdm
import string

with open('Book.json', 'r', encoding='utf-8') as file:
    books_data = json.load(file)
with open('Reader.json', 'r', encoding='utf-8') as file:
    readers_data = json.load(file)

num_users = len(readers_data)
num_books = len(books_data)
max_reviews_per_user = 50
max_reviews_per_book = 100

start_year = 2018
end_year = 2023

sample_review_texts = [
    "Loved the book! Highly recommend it.",
    "Not my cup of tea, but others might like it.",
    "Fantastic read! Couldn t put it down.",
    "Pretty average, nothing special.",
    "Didn t enjoy it much, but the writing was okay.",
    "Great plot and character development.",
    "I found the story hard to follow.",
    "One of the best books I ve read this year.",
    "The pacing was too slow for me.",
    "Wonderful and emotional. A great experience."
]

reader_mapping = {}
for reader in readers_data:
    reader_mapping[reader["ReaderID"]] = datetime.datetime.strptime(reader["JoinDate"], "%Y-%m-%d %H:%M:%S")

book_mapping = {}
for book in books_data:
    book_mapping[book["BookID"]] = datetime.datetime.strptime(book["PublicationDate"], "%Y-%m-%d %H:%M:%S")

def random_string(length):
    letters = string.ascii_lowercase
    return ''.join(random.choice(letters) for i in range(length))

def generate_random_link():
    domain = random_string(8)
    path = random_string(6)
    return f"https://www.{domain}.com/{path}"

def generate_random_date(publication_date, join_date, end_year):
    earliest_date = max(publication_date, join_date)
    latest_date = datetime.datetime(end_year, 12, 31)
    if earliest_date > latest_date:
        return earliest_date
    delta = (latest_date - earliest_date).days
    random_days = random.randint(0, delta)
    random_date = earliest_date + datetime.timedelta(days=random_days)
    # Set time to 00:00:00
    return random_date.replace(hour=0, minute=0, second=0)

end_year = 2024

def generate_reviews(num_users, num_books, max_reviews_per_user):
    reviews = []
    review_id = 1

    for user_id in range(1, num_users):
        if len(reviews) > 200000:
            break
        num_reviews = random.randint(0, max_reviews_per_user)

        reviewed_books = set()
        for _ in range(num_reviews):
            while True:
                book_id = random.randint(1, num_books)
                if book_id not in reviewed_books:
                    reviewed_books.add(book_id)
                    break
            
            publication_date = book_mapping[book_id]
            join_date = reader_mapping[user_id]

            review_date = generate_random_date(publication_date, join_date, end_year)
            review = {
                "ReviewID": review_id,
                "ReaderID": user_id,
                "BookID": book_id,
                "Rating": random.randint(1, 5),  # Rating between 1 and 5
                "ReviewText": random.choice(sample_review_texts),
                # Format date to "YYYY-MM-DD HH:MM:SS"
                "ReviewDate": review_date.strftime("%Y-%m-%d %H:%M:%S")
            }
            
            reviews.append(review)
            review_id += 1

    return reviews

reviews_data = generate_reviews(num_users, num_books, max_reviews_per_user)

num_reviews_to_select = int(len(reviews_data) * 0.05)

selected_reviews = random.sample(reviews_data, num_reviews_to_select)

# Spam generator
id = 1
reviews_data_copy = reviews_data.copy()
for review in tqdm(reviews_data_copy, desc="Processing review spam generator", unit="review"):
    if review in selected_reviews:
        reviews_data[id]["ReviewDate"] = str(reader_mapping[reviews_data[id]["ReaderID"]])
        if random.randint(1, 5) == 2:
            review_text = reviews_data[id]["ReviewText"]
            review_text += generate_random_link()
            reviews_data[id]["ReviewText"] = review_text

    id += 1

with open("Review.json", "w", encoding='utf-8') as f:
    json.dump(reviews_data, f, indent=4, ensure_ascii=False)
