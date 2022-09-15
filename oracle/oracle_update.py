import oracledb
import oracle_config
import time

connection = None
try:
    connection = oracledb.connect(
        user        = oracle_config.username,
        password    = oracle_config.password,
        dsn         = oracle_config.dsn,
        port        = oracle_config.port) 

    cursor = connection.cursor()
    print("Showing Customer's table...")
    statement = "select * from CUSTOMERS where first_name = :1"
    cursor.execute(statement, ["Rica"])
    results = cursor.fetchall()
    for result in results:
        print(result)
    
    print("")
    time.sleep(1)

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

except oracledb.Error as error:
    print(error)
finally:
    # release the connection
    if connection:
        connection.close()


