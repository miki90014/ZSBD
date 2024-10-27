import cx_Oracle
import os
from tqdm import tqdm

# Parametry połączenia z bazą danych
DB_USERNAME = "SYS"
DB_PASSWORD = "sudo"
DB_DSN = "localhost:1521/XEPDB1"

# Katalog zawierający pliki SQL
SQL_FILES_DIRECTORY = "./loans"  # Ścieżka do katalogu z plikami SQL

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
    with cx_Oracle.connect(DB_USERNAME, DB_PASSWORD, DB_DSN, mode=cx_Oracle.SYSDBA) as connection:
        with connection.cursor() as cursor:
            for sql_file in tqdm(sql_files, desc="Processing sql", unit="sql_file"):
            #for sql_file in sql_file:
                filepath = os.path.join(SQL_FILES_DIRECTORY, sql_file)
                execute_sql_file(cursor, filepath)
                connection.commit()  # Zatwierdza po wykonaniu każdego pliku

    print("Wszystkie pliki zostały wykonane.")

# Wywołanie głównej funkcji
execute_sql_scripts()
