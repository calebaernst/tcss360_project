# TCSS 360 - CSV to SQLite Database Converter
# Renzo Aquino

# This is the .csv file parser. To use the program, make sure you have a
# .csv file in the same directory as the program.
# The program will prompt you for the input CSV file name, the output database file name, and the table name.
# Since I have a skill issue, you need to include the file type, as specified during the prompts.

# import stuff!!!
import sqlite3
import csv

# take da user input for csv file name
input_file = input("Enter the name of the CSV file (with .csv extension): ")

# read da CSV data (.csv)
with open(input_file, newline='', encoding='utf-8') as csvfile:
    reader = csv.reader(csvfile)
    headers = [h.strip() for h in next(reader)]  # clean up header
    rows = [row for row in reader]

# prompt user for name of da output database file (.db)
output_file = input("Enter the name of the output database file (with .db extension): ")
conn = sqlite3.connect(output_file)
cursor = conn.cursor()

# prompt user for the fuggin table name 
table_name = input("Enter the name of the table to create in the database: ")

# create table with AUTOINCREMENT PRIMARY KEY for "id" column, TEXT otherwise
def get_column_definitions(headers):
    columns = []
    id_found = False
    for col in headers:
        if col.strip().lower() == "id":
            columns.append(f'"{col}" INTEGER PRIMARY KEY AUTOINCREMENT')
            id_found = True
        else:
            columns.append(f'"{col}" TEXT')
    return columns, id_found

columns, id_found = get_column_definitions(headers)
cursor.execute(f'DROP TABLE IF EXISTS "{table_name}"')  # remove old table if exists
cursor.execute(f'CREATE TABLE "{table_name}" ({", ".join(columns)})')

# insert dem rows
placeholders = ', '.join(['?'] * len(headers))
quoted_headers = ', '.join([f'"{col}"' for col in headers])

# If "id" column is present, let SQLite do all of da work (autoincrement)
if id_found:
    id_index = [i for i, col in enumerate(headers) if col.strip().lower() == "id"][0]
    insert_headers = [col for i, col in enumerate(headers) if i != id_index]
    insert_placeholders = ', '.join(['?'] * len(insert_headers))
    quoted_insert_headers = ', '.join([f'"{col}"' for col in insert_headers])
    insert_rows = [[value for i, value in enumerate(row) if i != id_index] for row in rows]
    cursor.executemany(
        f'INSERT INTO "{table_name}" ({quoted_insert_headers}) VALUES ({insert_placeholders})',
        insert_rows
    )
else:
    cursor.executemany(
        f'INSERT INTO "{table_name}" ({quoted_headers}) VALUES ({placeholders})',
        rows
    )

# close it!
conn.commit()
conn.close()