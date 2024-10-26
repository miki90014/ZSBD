# How to generate data

1. Go into dir `Etap3`
2. Run command `python authors.py`
3. Run command `python books.py`
4. Run command `python readers.py`
5. Run command `python reviews.py`

At the end run:
Run command `python json_to_sql_parser.py`
Then in file `Etap3\insert.py` add your credentials and path to dir in `SQL_FILES_DIRECTORY = `
Change `SQL_FILES_DIRECTORY = ` and run it with `python insert.py` in folowing order: `./author`, `./book`, `./reader`, `./review`