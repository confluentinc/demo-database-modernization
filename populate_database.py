import oracledb
import oracle_config

with oracledb.connect(
    user=oracle_config.username,
    password=oracle_config.password,
    dsn=oracle_config.dsn,
    port=oracle_config.port) as connection:

    cursor = connection.cursor()
    print("Populating CUSTOMERS table")
    with open("populate_database.sql") as statements:
        for statement in statements:
            statement = statement.strip().rstrip(";")
            print("executing statement:")
            print(f"{statement};")
            cursor.execute(statement)
    connection.commit()