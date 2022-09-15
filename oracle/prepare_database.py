import oracledb
import oracle_config
from pathlib import Path

def execute_file(connection: oracledb.Connection, sql_file: str) -> None:
    cursor = connection.cursor()
    with open(sql_file) as statements:
        for statement in statements:
            statement = statement.strip().rstrip(";")
            if statement.startswith("--") or not statement:
                continue
            print("\nexecuting statement:")
            print(f"{statement};")
            try:
                if "rdsadmin" in statement:
                    cursor.execute(f"{statement};")
                else:
                    cursor.execute(statement)
            except oracledb.DatabaseError as e:
                error, = e.args
                print(error.message)
                print("skipping\n")
    connection.commit()

if __name__=="__main__":

    sql_populate_database = Path(__file__).absolute().with_name("populate_database.sql")
    sql_enable_cdc = Path(__file__).absolute().with_name("enable_cdc.sql")
    with oracledb.connect(
        user=oracle_config.username,
        password=oracle_config.password,
        dsn=oracle_config.dsn,
        port=oracle_config.port) as connection:

        print("Populating CUSTOMERS table")
        execute_file(connection, sql_populate_database)

        print("\nEnabling Change Data Capture on CUSTOMERS table")
        execute_file(connection, sql_enable_cdc)