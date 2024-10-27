import json
import re
import os

def open_json(filename):
    with open(filename, 'r', encoding='utf-8') as file:
        data = json.load(file)
    return data


def write_to_multiple_files(base_filename, sql_script):
    chunk_count = 1
    current_chunk = []

    if not os.path.exists(base_filename):
        os.makedirs(base_filename)

    for line in sql_script.splitlines():
        current_chunk.append(line)
        
        if "COMMIT;" in line:
            chunk_filename = f"{base_filename}/{base_filename}_{chunk_count}.sql"
            with open(chunk_filename, 'w', encoding='utf-8') as file:
                file.write("\n".join(current_chunk))
            chunk_count += 1
            current_chunk = []
    if current_chunk:
        chunk_filename = f"{base_filename}_chunk_{chunk_count}.sql"
        with open(chunk_filename, 'w', encoding='utf-8') as file:
            file.write("\n".join(current_chunk))

def clean_description(description):
    return re.sub(r"[^\w\s,.]", "", description)


def json_to_sql_with_commit(json_obj, table_name, batch_size=200):
    sql_script = []

    for idx, record in enumerate(json_obj):
        columns = ", ".join(record.keys())
        values = []

        for key, value in record.items():
            if key in ["DateOfBirth", "PublicationDate", "ReviewDate", "JoinDate", "DueDate", "LoanDate", "ReturnDate", "IssueDate", "acquisitionDate"]:
                if " " in value:
                    values.append(f"TO_DATE('{value.split()[0]}', 'YYYY-MM-DD')")
                else:
                    values.append("''")
            elif key == "Description":
                cleaned_value = clean_description(value)
                values.append(f"'{cleaned_value}'")
            else:
                values.append(f"'{str(value)}'")

        insert_stmt = f"INSERT INTO {table_name} ({columns}) VALUES ({', '.join(values)});"
        sql_script.append(insert_stmt)

        if (idx + 1) % batch_size == 0:
            sql_script.append("COMMIT;")  # Zatwierdza co `batch_size` wierszy

    sql_script.append("COMMIT;")  # Zatwierdzenie pozostałych wierszy na końcu
    return "\n".join(sql_script)

author_data = open_json("Author.json")
book_data = open_json("Book.json")
reader_data = open_json("Reader.json")
review_data = open_json("Review.json")
bookcopies_data = open_json("BookCopies.json")
penalties_data = open_json("Penalties.json")
loans_data = open_json("Loans.json")


sql_author = json_to_sql_with_commit(author_data, "Authors")
sql_book = json_to_sql_with_commit(book_data, "Books")
sql_reader = json_to_sql_with_commit(reader_data, "Readers")
sql_review = json_to_sql_with_commit(review_data, "Reviews")
sql_bookcopies = json_to_sql_with_commit(bookcopies_data, "BookCopies")
sql_penalties = json_to_sql_with_commit(penalties_data, "Penalties")
sql_loans = json_to_sql_with_commit(loans_data, "Loans")



write_to_multiple_files("author", sql_author)
write_to_multiple_files("book", sql_book)
write_to_multiple_files("reader", sql_reader)
write_to_multiple_files("review", sql_review)
write_to_multiple_files("book_copies", sql_bookcopies)
write_to_multiple_files("penalties", sql_penalties)
write_to_multiple_files("loans", sql_loans)
