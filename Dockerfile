FROM python:3.10-slim

WORKDIR /app

RUN pip install flask requests

# ====== CREATE BACKEND + HTML DIRECTLY IN THE DOCKERFILE ======
RUN cat << 'EOF' > app.py
from flask import Flask, request, render_template_string, redirect, session
import os, requests

app = Flask(__name__)
app.secret_key = "super-secret"

USERNAME = "admin"
PASSWORD = "123456"

fake_ports = []

login_html = """
<!DOCTYPE html>
<html>
<head><title>Login</title></head>
<body>
    <h2>Đăng nhập Panel</h2>
    {% if error %}<p style='color:red;'>{{ error }}</p>{% endif %}
    <form method="POST">
        <input type="text" name="username" placeholder="username"><br><br>
        <input type="password" name="password" placeholder="password"><br><br>
        <button>Login</button>
    </form>
</body>
</html>
"""

panel_html = """
<!DOCTYPE html>
<html>
<head><title>Panel</title></head>
<body>
    <h2>Ubuntu Web Panel</h2>

    <p><b>IPv4 Public:</b> {{ ipv4 }}</p>

    <h3>Thêm port</h3>
    <form method="POST" action="/add_port">
        <input type="text" name="port" placeholder="Nhập port"><br><br>
        <button>Thêm</button>
    </form>

    <h3>Danh sách port đã thêm</h3>
    {% for p in ports %}
        <p>Port: {{ p }}</p>
    {% endfor %}
</body>
</html>
"""

def get_public_ipv4():
    try:
        return requests.get("https://api.ipify.org").text
    except:
        return "Unknown"


@app.route("/", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        if request.form["username"] == USERNAME and request.form["password"] == PASSWORD:
            session["logged"] = True
            return redirect("/panel")
        else:
            return render_template_string(login_html, error="Sai tài khoản hoặc mật khẩu!")

    return render_template_string(login_html)


@app.route("/panel")
def panel():
    if not session.get("logged"):
        return redirect("/")

    return render_template_string(panel_html,
                                  ipv4=get_public_ipv4(),
                                  ports=fake_ports)


@app.route("/add_port", methods=["POST"])
def add_port():
    if not session.get("logged"):
        return redirect("/")
        
    port = request.form["port"]
    if port not in fake_ports:
        fake_ports.append(port)

    return redirect("/panel")


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 10000))
    app.run(host="0.0.0.0", port=port)
EOF

# ====== RUN APP ======
EXPOSE 10000
CMD ["python3", "app.py"]
