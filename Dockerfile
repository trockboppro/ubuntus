FROM python:3.10-slim

WORKDIR /app

RUN pip install flask docker requests

# ==== GENERATE APP =====
RUN cat << 'EOF' > app.py
from flask import Flask, request, render_template_string, redirect, session
import docker, random, requests, os

app = Flask(__name__)
app.secret_key = "pluscloud-super-key"

USERNAME = "pluscloud"
PASSWORD = "admin123"

client = docker.from_env()
CONTAINERS = {}

def get_public_ipv4():
    try:
        return requests.get("https://api.ipify.org").text
    except:
        return "UNKNOWN"

dashboard_html = """
<!DOCTYPE html>
<html>
<head>
<title>PlusCloud Panel</title>
<style>
body { font-family: Arial; background:#f2f6ff; margin:0; padding:0; }
.topbar { background:#4a79ff; padding:15px; color:white; font-size:20px; }
.card { background:white; padding:20px; margin:20px; border-radius:10px; box-shadow:0 2px 6px #0002; }
.btn { padding:8px 15px; border:none; background:#4a79ff; color:white; border-radius:5px; cursor:pointer; }
.table { width:100%; border-collapse:collapse; }
.table td, .table th { padding:10px; border-bottom:1px solid #ddd; }
</style>
</head>
<body>

<div class="topbar">PlusCloud Panel</div>

<div class="card">
<h2>Tạo VPS Ubuntu Server</h2>
<form method="POST" action="/create">
<button class="btn">Tạo VPS Mới</button>
</form>
</div>

<div class="card">
<h2>Danh sách VPS</h2>
<table class="table">
<tr><th>ID</th><th>SSH Port</th><th>Action</th></tr>
{% for cid, data in containers.items() %}
<tr>
<td>{{ cid[:12] }}</td>
<td>{{ data['port'] }}</td>
<td>
<form method="POST" action="/stop" style="display:inline;"><input type="hidden" name="id" value="{{ cid }}"><button class="btn">Stop</button></form>
<form method="POST" action="/start" style="display:inline;"><input type="hidden" name="id" value="{{ cid }}"><button class="btn">Start</button></form>
<form method="POST" action="/delete" style="display:inline;"><input type="hidden" name="id" value="{{ cid }}"><button class="btn" style="background:#ff3b3b;">Delete</button></form>
</td>
</tr>
{% endfor %}
</table>
</div>

<div class="card">
<b>Public IPv4:</b> {{ ipv4 }}
</div>

</body>
</html>
"""

login_html = """
<!DOCTYPE html>
<html>
<head><title>Login</title></head>
<body style="background:#f2f6ff; font-family:Arial;">
<div style="width:300px;margin:100px auto;background:white;padding:20px;border-radius:10px;box-shadow:0 2px 6px #0003;">
<h2 style="text-align:center;">PlusCloud Login</h2>
{% if error %}<p style="color:red;">{{ error }}</p>{% endif %}
<form method="POST">
<input name="username" placeholder="username" style="width:100%;padding:8px;"><br><br>
<input name="password" type="password" placeholder="password" style="width:100%;padding:8px;"><br><br>
<button style="width:100%;padding:10px;background:#4a79ff;color:white;border:none;">Login</button>
</form>
</div>
</body>
</html>
"""

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
    return render_template_string(dashboard_html, containers=CONTAINERS, ipv4=get_public_ipv4())

@app.route("/create", methods=["POST"])
def create():
    port = random.randint(20000, 40000)
    container = client.containers.run(
        "ubuntu:22.04",
        "bash -c 'apt update && apt install -y openssh-server && service ssh start && tail -f /dev/null'",
        detach=True,
        ports={"22/tcp": port}
    )
    CONTAINERS[container.id] = {"port": port}
    return redirect("/panel")

@app.route("/stop", methods=["POST"])
def stop():
    cid = request.form["id"]
    client.containers.get(cid).stop()
    return redirect("/panel")

@app.route("/start", methods=["POST"])
def start():
    cid = request.form["id"]
    client.containers.get(cid).start()
    return redirect("/panel")

@app.route("/delete", methods=["POST"])
def delete():
    cid = request.form["id"]
    client.containers.get(cid).remove(force=True)
    CONTAINERS.pop(cid, None)
    return redirect("/panel")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=10000)
EOF

EXPOSE 10000

CMD ["python3", "app.py"]
