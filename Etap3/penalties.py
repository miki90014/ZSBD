import json
import random
from datetime import datetime

# Funkcja porównująca dwie daty
def is_later(date_str1, date_str2, date_format="%Y-%m-%d %H:%M:%S"):
    """
    Porównuje dwie daty podane jako stringi w określonym formacie
    i zwraca True, jeśli pierwsza data jest późniejsza niż druga.
    
    :param date_str1: Pierwsza data jako string.
    :param date_str2: Druga data jako string.
    :param date_format: Format daty (domyślnie "%Y-%m-%d %H:%M:%S").
    :return: True, jeśli date_str1 jest późniejsza niż date_str2, w przeciwnym razie False.
    """
    date1 = datetime.strptime(date_str1, date_format)
    date2 = datetime.strptime(date_str2, date_format)
    return date1 > date2


# Funkcja obliczająca wysokość kary
def calculate_penalty(return_date_str, due_date_str, rate_per_day=1, date_format="%Y-%m-%d %H:%M:%S"):
    return_date = datetime.strptime(return_date_str, date_format)
    due_date = datetime.strptime(due_date_str, date_format)
    delay_days = (return_date - due_date).days
    if delay_days > 0:
        return delay_days * rate_per_day
    return 0  # Jeśli nie ma opóźnienia, brak kary

# Wczytywanie danych z Loans.json
with open('Loans.json', 'r', encoding='utf-8') as file:
    loans_data = json.load(file)

data_sql = []
index = 1

# Sprawdzanie każdej pożyczki
for loan in loans_data:
    return_date = loan["ReturnDate"]
    due_date = loan["DueDate"]
    
    #Sprawdzenie czy książka oddana
    if return_date and due_date:
        # Sprawdzenie, czy ReturnDate jest późniejsza niż DueDate
        if is_later(return_date, due_date):
            penalty_amount = calculate_penalty(return_date, due_date)
            
            # Losowy wybór dla isPaid z 30% szansą na "Y" i 70% na "N"
            is_paid = random.choices(["Y", "N"], weights=[0.3, 0.7], k=1)[0]
            
            data_sql.append({
                'PenaltyID': index,
                'ReaderID': loan["ReaderID"],
                'Amount': penalty_amount,
                'IssueDate': return_date,
                'DueDate': due_date,
                'isPaid': is_paid
            })
            index += 1



# Zapis danych do pliku JSON
output_file = 'Penalties.json'
with open(output_file, 'w', encoding='utf-8') as json_file:
    json.dump(data_sql, json_file, ensure_ascii=False, indent=4)

print(f"Dane zostały zapisane do pliku {output_file}.")

