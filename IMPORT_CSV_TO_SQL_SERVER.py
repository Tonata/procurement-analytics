import pandas as pd
import pyodbc

# Define your SQL Server connection parameters
server = 'your_server_name'  # e.g. 'localhost' or 'server_address'
database = 'your_database_name'  # e.g. 'mydb'
username = 'your_username'  # e.g. 'sa'
password = 'your_password'  # e.g. 'password'

# Set up the connection string
conn_str = f'DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={server};DATABASE={database};UID={username};PWD={password}'

# Establish connection to SQL Server
conn = pyodbc.connect(conn_str)
cursor = conn.cursor()

# List of CSV files to import
csv_files = [
    'file1.csv',
    'file2.csv',
    'file3.csv',
    'file4.csv',
    'file5.csv'
]

# Function to import CSV to SQL Server
def import_csv_to_sql(csv_file, table_name):
    # Read the CSV file into a DataFrame
    df = pd.read_csv(csv_file)

    # Create the table if it doesn't exist (optional, depends on your setup)
    columns = ', '.join(df.columns)
    values = ', '.join(['?'] * len(df.columns))

    create_table_sql = f"""
    IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='{table_name}' AND xtype='U')
    CREATE TABLE {table_name} ({', '.join([f'{col} VARCHAR(255)' for col in df.columns])});
    """
    cursor.execute(create_table_sql)
    conn.commit()

    # Insert the data from the DataFrame into the SQL Server table
    for row in df.itertuples(index=False, name=None):
        insert_sql = f"INSERT INTO {table_name} ({columns}) VALUES ({values})"
        cursor.execute(insert_sql, row)
    conn.commit()

# Loop through the CSV files and import them
for i, csv_file in enumerate(csv_files, start=1):
    table_name = f'table_{i}'  # You can customize the table name based on the CSV
    print(f"Importing {csv_file} into table {table_name}...")
    import_csv_to_sql(csv_file, table_name)

# Close the connection
cursor.close()
conn.close()
print("Data import completed.")
