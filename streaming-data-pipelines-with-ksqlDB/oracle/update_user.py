import oracledb
import config
import time

def print_current_row(cursor: oracledb.Cursor, first_name: str = "Rica") -> None:
    print(f"{first_name}'s current information")
    statement = "select * from CUSTOMERS where first_name = :1"
    cursor.execute(statement, [first_name])
    results = cursor.fetchall()
    for result in results:
        print(result)

def update_row(cursor: oracledb.Cursor,
               connection: oracledb.Connection,
               first_name: str = "Rica") -> None:
    statement = "update CUSTOMERS set avg_credit_spend = avg_credit_spend+1 where first_name = :1"
    print(f"increasing {first_name}'s average credit spend by $1")
    cursor.execute(statement, [first_name])
    connection.commit()

if __name__=="__main__":

    with oracledb.connect(
        user        = config.username,
        password    = config.password,
        dsn         = config.dsn,
        port        = config.port) as connection:
        
        cursor = connection.cursor()

        try:
            while True:
                print_current_row(cursor)
                update_row(cursor, connection)
                time.sleep(5)
        except KeyboardInterrupt:
            print("\nclosing")



