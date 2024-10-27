import numpy as np
import random
from datetime import datetime
import json

# Funkcja do generowania losowych dat
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

# Możliwe lokalizacje książek
bookCopy_Loc = [
    "Główna aleja", "Boczna aleja", "Archiwum"
]

# Dostępność książki
# avability = ["Y", "N"]
avability = ["Y", "N", "Y", "Y", "Y", "N", "Y", "Y", "N", "Y"] # 70% na Y, 30% na N
# Funkcja do generowania losowych lokalizacji
def generateRandomLocation():
    location = random.choice(bookCopy_Loc)
    if location == "Boczna aleja":
        location += " " + str(random.randint(1, 15)) + "."

    location += ", skrzydło " + str(random.randint(1, 4)) + "."
    location += " sekcja " + str(random.randint(1, 10)) + "."

    return location

# Funkcja do generowania dostępności i daty pozyskania
def generateAvability():
    isAvaible = random.choice(avability)
    AcquisionDate = ""
    if isAvaible == "N":
        AcquisionDate = str(generate_random_date(2020, 2024))
    
    return isAvaible, AcquisionDate

# Liczba książek i pożądana liczba kopii
book_ids = np.arange(1, 249155)
desired_total_copies = 750862

# Parametry rozkładu normalnego
mean = 3  # ustalona średnia liczba kopii na książkę
std_dev = 2  # losowe odchylenie standardowe dla różnic w liczbie kopii

# Inicjalizacja z jedną kopią dla każdej książki
copies_per_book = np.ones(len(book_ids), dtype=int)

# Generowanie pozostałych kopii z rozkładu normalnego
remaining_copies_needed = desired_total_copies - len(book_ids)  # Zarezerwowane na jedną kopię na każdą książkę

# Generowanie losowych liczby kopii dla pozostałych
if remaining_copies_needed > 0:
    # Generowanie rozkładu normalnego ilości kopii dla dodatkowych książek
    additional_copies = np.random.normal(loc=mean - 1, scale=std_dev, size=len(book_ids))
    
    # Usuwamy wartości ujemne
    additional_copies = np.maximum(additional_copies, 0)
    
    # Zaokrąglamy do całkowitych
    additional_copies = np.round(additional_copies).astype(int)

    # Dodajemy dodatkowe kopie do inicjalnych (już jednego)
    copies_per_book += additional_copies

# Skalowanie liczby kopii tak, aby suma była równa desired_total_copies
scaling_factor = desired_total_copies / np.sum(copies_per_book)
scaled_copies_per_book = np.round(copies_per_book * scaling_factor).astype(int)

# Poprawka w przypadku, gdy suma nadal jest inna niż desired_total_copies
difference = desired_total_copies - np.sum(scaled_copies_per_book)

# Rozdzielanie różnicy na losowe książki
if difference > 0:
    indices = np.random.choice(len(book_ids), difference, replace=False)
    scaled_copies_per_book[indices] += 1
elif difference < 0:
    indices = np.random.choice(len(book_ids), -difference, replace=False)
    scaled_copies_per_book[indices] -= 1

# Finalna liczba kopii
total_copies = np.sum(scaled_copies_per_book)

# Tabela do przechowywania danych
data_sql = []
current_Book_index = 0

# Tworzenie wpisów dla każdej kopii
for numberOfCopy in range(total_copies):
    copyID = numberOfCopy + 1
    
    # Upewniamy się, że index książki nie przekracza dostępnych książek
    while current_Book_index < len(scaled_copies_per_book) and scaled_copies_per_book[current_Book_index] == 0:
        current_Book_index += 1
    
    # Sprawdzenie, czy jesteśmy poza zakresem
    if current_Book_index >= len(scaled_copies_per_book):
        break  # Przerywamy, jeśli nie ma więcej książek

    bookID = current_Book_index + 1  # Przypisujemy właściwe BookID (indeks + 1)
    
    location = generateRandomLocation()
    isAvailable, acquisitionDate = generateAvability()

    data_sql.append({
        'CopyID': copyID,
        'BookID': bookID,
        'Location': location,
        'isAvailable': isAvailable,
        'acquisitionDate': acquisitionDate
    })
    
    # Zmniejszamy liczbę kopii
    scaled_copies_per_book[current_Book_index] -= 1

# Sprawdzenie wyników
print("Total Copies Generated: ", total_copies)
print("Last Book ID: ", data_sql[-1]['BookID'])
print("First Entry: ", data_sql[0])
print("Last Entry: ", data_sql[-1])

# Zapis danych do pliku JSON
output_file = 'BookCopies.json'
with open(output_file, 'w', encoding='utf-8') as json_file:
    json.dump(data_sql, json_file, ensure_ascii=False, indent=4)

print(f"Dane zostały zapisane do pliku {output_file}.")

