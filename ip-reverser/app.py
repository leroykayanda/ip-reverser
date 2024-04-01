import os
from flask import Flask, jsonify, request
import pymysql

app = Flask(__name__)

def initialize_mysql():
    hostname = os.environ.get("MYSQL_HOST")
    user = os.environ.get("MYSQL_USER")
    password = os.environ.get("MYSQL_PASSWORD")
    database = os.environ.get("MYSQL_DATABASE")

    # Initializing connection
    db = pymysql.connections.Connection(
        host=hostname,
        user=user,
        password=password,
        database=database
    )

    # Creating cursor object and IPs table
    cursor = db.cursor()
    cursor.execute('''CREATE TABLE IF NOT EXISTS ips(id INT AUTO_INCREMENT PRIMARY KEY, ip VARCHAR(40), reversed_ip VARCHAR(40) )''')

    return cursor

def save_ip(ip,reversed_ip,cursor):
    if ip is not None and "10.0" not in ip:
        # ignore private ips starting with the VPC CIDR 10.0
        insert_query = "INSERT INTO ips (ip, reversed_ip) VALUES (%s, %s)"
        cursor.execute(insert_query, (ip, reversed_ip))
        cursor.connection.commit() # Commit the changes

def reverse_ip(ip):
    if ip is not None and "10.0" not in ip:
        # use split function to make a python list from the ip string, using . as the delimitter
        ip_list = ip.split('.')

        # use rerverse function to reverse the order of the list
        ip_list.reverse()

        # convert the list containing the reversed IP back to a string
        reversed_ip = '.'.join(ip_list)
    else:
        reversed_ip = ''

    return reversed_ip

def get_ip_count(cursor):
    count_query = "SELECT ip, COUNT(*) AS count, reversed_ip FROM ips GROUP BY ip,reversed_ip"
    cursor.execute(count_query)
    ip_counts = cursor.fetchall()
    ip_counts_data = [{"ip": ip, "reversed_ip": reversed_ip,"count": count} for ip, count, reversed_ip in ip_counts]
    return ip_counts_data

@app.route("/")
def home():
    # get IP from X-Forwarded-For header
    ip = request.headers.get("Host")
    all_headers = dict(request.headers)

    # initialize MySQL connection
    cursor = initialize_mysql()

    # reverse the IP
    reversed_ip = reverse_ip(ip)

    # Insert the ip into the ips table
    save_ip(ip,reversed_ip,cursor)

    # retrieve the count of all IPs in the database
    ip_counts = get_ip_count(cursor)

    return jsonify({
        "IP": ip,
        "IP Reversed": reversed_ip,
        "ip_counts": ip_counts
    })

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=8080)
