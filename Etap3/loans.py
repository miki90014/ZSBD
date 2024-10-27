import numpy as np
import random
from datetime import datetime, timedelta  
import json
from dateutil.relativedelta import relativedelta

# Funkcja do przesuwania daty o określoną liczbę miesięcy
def shift_date(date_string, months):
    # Konwersja stringa do obiektu datetime
    date_obj = datetime.strptime(date_string, "%Y-%m-%d %H:%M:%S")
    new_date = date_obj + relativedelta(months=months)
    return new_date.strftime("%Y-%m-%d %H:%M:%S")

# Wczytaj dane z pliku BookCopies.json
with open('BookCopies.json', 'r', encoding='utf-8') as file:
    bookCopies_data = json.load(file)

# Parametry rozkładu normalnego dla ReaderID
mean = 50000    # Średnia liczba użytkowników powinna wynosić około 50000 (środek przedziału)
stddev = 20000  # Odchylenie standardowe określające, jak bardzo różnią się wypożyczenia

data_sql = []
index = 1
count_late_returns = 0
target_late_returns = 20000  # Docelowa liczba książek zwróconych po terminie

for copy in bookCopies_data:
    if copy["isAvailable"] == "N":
        reader_id = int(np.random.normal(mean, stddev))
        reader_id = max(0, min(reader_id, 100000))  # Zakres [0, 100000]
        
        loan_date = copy["acquisitionDate"]
        due_date = shift_date(loan_date, 1)  # Termin oddania
        
        # Losowanie czy `ReturnDate` będzie ustawione, a jeśli tak, to w jakiej relacji do `DueDate`
        return_date = ""
        return_probability = random.random()
        
        if return_probability < 0.4:
            # Około 40% książek bez `ReturnDate`
            return_date = ""
        elif return_probability < 0.8:
            # Około 40% książek zwróconych przed terminem
            due_date_obj = datetime.strptime(due_date, "%Y-%m-%d %H:%M:%S")
            return_date_obj = due_date_obj - timedelta(days=random.randint(1, 15))
            return_date = return_date_obj.strftime("%Y-%m-%d %H:%M:%S")
        else:
            # Około 20% książek zwróconych po terminie, z czego maksymalnie 20,000
            if count_late_returns < target_late_returns:
                due_date_obj = datetime.strptime(due_date, "%Y-%m-%d %H:%M:%S")
                return_date_obj = due_date_obj + timedelta(days=random.randint(1, 55))
                return_date = return_date_obj.strftime("%Y-%m-%d %H:%M:%S")
                count_late_returns += 1
            else:
                # Jeśli osiągnięto limit, losowo wybieramy datę przed terminem
                due_date_obj = datetime.strptime(due_date, "%Y-%m-%d %H:%M:%S")
                return_date_obj = due_date_obj - timedelta(days=random.randint(1, 15))
                return_date = return_date_obj.strftime("%Y-%m-%d %H:%M:%S")

        data_sql.append({
            'LoanID': index,
            'CopyID': copy["CopyID"],
            'ReaderID': reader_id,
            'LoanDate': loan_date,
            'DueDate': due_date,
            'ReturnDate': return_date
        })
        index += 1

# Zapis danych do pliku JSON
output_file = 'Loans.json'
with open(output_file, 'w', encoding='utf-8') as json_file:
    json.dump(data_sql, json_file, ensure_ascii=False, indent=4)

print(f"Dane zostały zapisane do pliku {output_file}.")
