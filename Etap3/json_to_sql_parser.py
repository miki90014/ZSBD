import json

def open_json(filename):
    with open(filename, 'r', encoding='utf-8') as file:
        data = json.load(file)
    return data

def write_to_file(filename, sql_script):
    with open(filename, 'w', encoding='utf-8') as file:
        file.write(sql_script)


def json_to_sql(json_obj, table_name):
    sql_script = []

    for record in json_obj:
        columns = ", ".join(record.keys())
        values = ", ".join([f"'{str(v)}'" for v in record.values()])
        insert_stmt = f"INSERT INTO {table_name} ({columns}) VALUES ({values});"
        sql_script.append(insert_stmt)

    return "\n".join(sql_script)

author_data = open_json("Author.json")
book_data = open_json("Book.json")
reader_data = open_json("Reader.json")
review_data = open_json("Review.json")
sql_author = json_to_sql(author_data, "Author")
sql_book = json_to_sql(book_data, "Book")
sql_reader = json_to_sql(reader_data, "Reader")
sql_review = json_to_sql(review_data, "Review")



write_to_file("author.sql", sql_author)
write_to_file("book.sql", sql_book)
write_to_file("reader.sql", sql_reader)
write_to_file("review.sql", sql_review)
