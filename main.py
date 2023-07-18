from flask import *
import os
import psutil
from config import creds, vpn
from hashlib import sha256
import logging

username = creds["username"]
password = creds["password"]


log = logging.getLogger("werkzeug")
log.setLevel(logging.ERROR)

app = Flask(
    f"{vpn.vpnName} Admin",
    static_folder=os.path.abspath("frontend/build/static"),
    template_folder=os.path.abspath("frontend/build"),
)

app.logger.disabled = True
log.disabled = True


def isAdmin(reqArgs):
    adminUserName = reqArgs.get("username")
    adminPassWord = reqArgs.get("password")
    
    hashedInput = sha256(adminPassWord.encode('utf-8')).hexdigest()
    
    return adminUserName == username and hashedInput == password


@app.route("/")
def homePage():
    return render_template("index.html")


@app.route("/type")
def vpnType():
    return {"type": vpn.vpnName}


@app.route("/login")
def loginCheck():
    return {
        "success": isAdmin(request.args),
        "memory": max(
            (psutil.swap_memory().used + psutil.virtual_memory().used)
            / (psutil.swap_memory().total + psutil.virtual_memory().total)
            * 100,
            5,
        ),
        "cpu": max(psutil.cpu_percent(), 5),
    }


@app.route("/list")
def listUsers():
    if isAdmin(request.args):
        return vpn.listUsers()
    else:
        return []


@app.route("/create/<path:name>")
def createUser(name):
    if isAdmin(request.args):
        vpn.createUser(name)
        return {"success": True}
    else:
        return {"success": False}


@app.route("/remove/<path:name>")
def removeUser(name):
    if isAdmin(request.args):
        vpn.removeUser(name)
        return {"success": True}
    else:
        return {"success": False}


@app.route("/getConfig/<path:name>")
def getConfig(name):
    if isAdmin(request.args):
        return Response(
            vpn.getConfig(name),
            mimetype=f"text/x-{vpn.vpnExtension}",
            headers={
                "Content-Disposition": f"attachment;filename={name}.{vpn.vpnExtension}"
            },
        )
    else:
        return {"error": "Incorrect admin credentials!"}


if __name__ == "__main__":
    app.run(port=5000)
