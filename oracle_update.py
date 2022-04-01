import cx_Oracle
import oracle_config
import time

connection = None
count = 3
try:
    connection = cx_Oracle.connect(
        oracle_config.username,
        oracle_config.password,
        oracle_config.dsn,
        encoding=oracle_config.encoding)

    cursor = connection.cursor()
    print("Showing Customer's table...")
    statement = "select * from CUSTOMERS where first_name = :1"
    cursor.execute(statement, ["Rica"])
    results = cursor.fetchall()
    for result in results:
        print(result)
    
    print("")
    time.sleep(1)

    # Increase the credit increase
    print("Increasing Rica Blaisdell's average credit spend by 5000")
    statement = "update CUSTOMERS set avg_credit_spend = avg_credit_spend+5000 where first_name = :1"
    cursor.execute(statement, ["Rica"])
    connection.commit()

    print("")
    time.sleep(1)

    statement = "select * from CUSTOMERS where first_name = :1"
    cursor.execute(statement, ["Rica"])
    results = cursor.fetchall()
    print("Updated results are...")
    for result in results:
        print(result)


except cx_Oracle.Error as error:
    print(error)
finally:
    # release the connection
    if connection:
        connection.close()


