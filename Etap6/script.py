import cx_Oracle
import os
from tqdm import tqdm
import time
import json

# Parametry połączenia z bazą danych
DB_USERNAME = "SYS"
DB_PASSWORD = "sudo"
DB_DSN = "localhost:1521/XEPDB1"

SQL_FILES_DIRECTORY = "./sql_scripts"  # Ścieżka do katalogu z plikami SQL
RESULTS_FILE = "./results.json"

results = {
    "sql1.sql": [],
    "sql2.sql": [],
    "sql3.sql": [],
    "sql4.sql": [],
    "sql5.sql": [],
    "sql6.sql": []
}

final_results = {}

# Funkcja do wykonywania poleceń SQL z plików
def execute_sql_file(cursor, filename):
    with open(filename, 'r', encoding='utf-8') as file:
        sql_script = file.read()

        # Podziel skrypt SQL na poszczególne polecenia według średnika
        sql_commands = sql_script.split(';')
        
        for command in sql_commands:
            command = command.strip()  # Usuń nadmiarowe białe znaki
            if command:  # Wykonuj tylko, jeśli polecenie nie jest puste
                try:
                    cursor.execute(command)
                except cx_Oracle.DatabaseError as e:
                    print(f"Błąd przy wykonywaniu polecenia w pliku {filename}: {command}: {e}")
                    continue

# Połączenie z bazą danych
def execute_sql_scripts():
    sql_files = [f for f in os.listdir(SQL_FILES_DIRECTORY) if f.endswith(".sql")]
        # Ustanawiamy połączenie z bazą danych z uprawnieniami SYSDBA
    iteration = 0
    with cx_Oracle.connect(DB_USERNAME, DB_PASSWORD, DB_DSN, mode=cx_Oracle.SYSDBA) as connection:
        while (iteration < 10):
            with connection.cursor() as cursor:
                for sql_file in tqdm(sql_files, desc="Processing sql", unit="sql_file"):
                    filepath = os.path.join(SQL_FILES_DIRECTORY, sql_file)
                    start = time.time_ns()
                    execute_sql_file(cursor, filepath)
                    end = time.time_ns()
                    execution_time = end - start
                    results[sql_file].append(execution_time)
                    connection.rollback()  # Rollback po wykonaniu każdego pliku
                # TODO: dodać jakiś bufor
            iteration += 1

for result in results.keys():
    max_time = 0
    min_time = 999999
    avg_time = 0
    for res in results[result]:
        if res > max_time:
            max_time = res
        if res < min_time:
            min_time = res
        avg_time += res
    avg_time = avg_time/len(results[result])
    print(f"Script {result}:")
    print(f"- min time {min_time}:")
    print(f"- max time {max_time}:")
    print(f"- avg time {avg_time}:")
    final_results[result] = {}
    final_results[result]["min_time"] = min_time
    final_results[result]["max_time"] = max_time
    final_results[result]["avg_time"] = avg_time

with open(f'results.json', 'w', encoding='utf-8') as file:
    json.dump(results, file, indent=4, ensure_ascii=False)

with open(f'time_results.json', 'w', encoding='utf-8') as file:
    json.dump(final_results, file, indent=4, ensure_ascii=False)
