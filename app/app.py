from flask import Flask, request, redirect, render_template_string
import pymysql
import os

app = Flask(__name__)

DB_HOST = os.environ.get("DB_HOST")
DB_USER = os.environ.get("DB_USER")
DB_PASSWORD = os.environ.get("DB_PASSWORD")
DB_NAME = os.environ.get("DB_NAME")


def get_db_connection():
    return pymysql.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        cursorclass=pymysql.cursors.DictCursor
    )


HTML_PAGE = """
<!DOCTYPE html>
<html>
<head>
    <title>Employee Management System</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: #f4f6f8;
            padding: 30px;
        }

        h1 {
            color: #222;
        }

        .container {
            background: white;
            padding: 25px;
            border-radius: 10px;
            max-width: 900px;
            margin: auto;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
        }

        form {
            margin-bottom: 25px;
        }

        input {
            padding: 10px;
            margin: 5px;
            width: 220px;
        }

        button {
            padding: 10px 15px;
            background: #2563eb;
            color: white;
            border: none;
            cursor: pointer;
            border-radius: 5px;
        }

        button:hover {
            background: #1d4ed8;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 15px;
        }

        th, td {
            padding: 12px;
            border-bottom: 1px solid #ddd;
            text-align: left;
        }

        th {
            background: #2563eb;
            color: white;
        }

        .delete {
            background: #dc2626;
            padding: 7px 12px;
            color: white;
            text-decoration: none;
            border-radius: 4px;
        }

        .status {
            color: green;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Employee Management System</h1>
        <p class="status">Application running on AWS EC2 and connected to AWS RDS MySQL</p>

        <form method="POST" action="/add">
            <input type="text" name="name" placeholder="Employee Name" required>
            <input type="email" name="email" placeholder="Employee Email" required>
            <input type="text" name="department" placeholder="Department" required>
            <button type="submit">Add Employee</button>
        </form>

        <h2>Employee List</h2>

        <table>
            <tr>
                <th>ID</th>
                <th>Name</th>
                <th>Email</th>
                <th>Department</th>
                <th>Created At</th>
                <th>Action</th>
            </tr>

            {% for employee in employees %}
            <tr>
                <td>{{ employee.id }}</td>
                <td>{{ employee.name }}</td>
                <td>{{ employee.email }}</td>
                <td>{{ employee.department }}</td>
                <td>{{ employee.created_at }}</td>
                <td>
                    <a class="delete" href="/delete/{{ employee.id }}">Delete</a>
                </td>
            </tr>
            {% endfor %}
        </table>
    </div>
</body>
</html>
"""


@app.route("/")
def index():
    connection = get_db_connection()

    with connection.cursor() as cursor:
        cursor.execute("SELECT * FROM employees ORDER BY id DESC")
        employees = cursor.fetchall()

    connection.close()

    return render_template_string(HTML_PAGE, employees=employees)


@app.route("/add", methods=["POST"])
def add_employee():
    name = request.form["name"]
    email = request.form["email"]
    department = request.form["department"]

    connection = get_db_connection()

    try:
        with connection.cursor() as cursor:
            sql = "INSERT INTO employees (name, email, department) VALUES (%s, %s, %s)"
            cursor.execute(sql, (name, email, department))
            connection.commit()
    except Exception as e:
        print("Error:", e)
    finally:
        connection.close()

    return redirect("/")


@app.route("/delete/<int:employee_id>")
def delete_employee(employee_id):
    connection = get_db_connection()

    with connection.cursor() as cursor:
        sql = "DELETE FROM employees WHERE id = %s"
        cursor.execute(sql, (employee_id,))
        connection.commit()

    connection.close()

    return redirect("/")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
