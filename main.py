from flask import *
import os
import openvpn
import psutil
from creds import creds

username = creds["username"]
password = creds["password"]


app = Flask(
    "OpenVpn Admin",
    static_folder=os.path.abspath("frontend/build/static"),
    template_folder=os.path.abspath("frontend/build"),
)


def isAdmin(reqArgs):
    adminUserName = reqArgs.get("username")
    adminPassWord = reqArgs.get("password")
    return adminUserName == username and adminPassWord == password


@app.route("/")
def hello():
    return render_template("index.html")


@app.route("/login")
def loginCheck():
    return {
        "success": isAdmin(request.args),
        "memory": max(psutil.virtual_memory().percent, 5),
        "cpu": max(psutil.cpu_percent(), 5),
    }


@app.route("/list")
def listUsers():
    if isAdmin(request.args):
        return openvpn.listUsers()
    else:
        return []


@app.route("/create/<path:name>")
def createUser(name):
    if isAdmin(request.args):
        openvpn.createUser(name)
        return {"success": True}
    else:
        return {"success": False}


@app.route("/remove/<path:name>")
def removeUser(name):
    if isAdmin(request.args):
        openvpn.removeUser(name)
        return {"success": True}
    else:
        return {"success": False}


@app.route("/getConfig/<path:name>")
def getConfig(name):
    if isAdmin(request.args):
        return Response(
            openvpn.getConfig(name),
            mimetype="text/plain",
            headers={"Content-Disposition": f"attachment;filename={name}.ovpn"},
        )
    else:
        return {"error": "Incorrect admin credentials!"}


if __name__ == "__main__":
    app.run(port=5000)
