extends Node
## Simulated cyber network — 100% FICTIONAL, runs entirely inside the game.
## No real hosts, no real traffic, no real credentials. See docs/SECURITY.md.

const LAB_NET := "TRAINING-NET 10.10.0.0/24 (simulated)"

var lab_token: String = "HL{f1rst_c0nnect10n_ok}"
var hosts: Dictionary = {}

func _ready() -> void:
        reset()

func reset() -> void:
        hosts = {
                "TEST-PC-01": {
                        "ip": "10.10.0.11",
                        "os": "NyxLite 2.1 (sim)",
                        "purpose": "Beginner training workstation",
                        "services": {
                                22: {"name": "ssh", "banner": "NyxSSH-2.1 training node"},
                                80: {"name": "http", "banner": "NyxHTTPd training page"},
                        },
                        "auth": {"user": "student", "pass": "learn3r"},
                        "files": {
                                "readme.txt": "TRAINING WORKSTATION\nThis machine belongs to the OpenShell Academy beginner lab.\nIf you are reading this, your login worked. Well done.\nHint: listing files is done with: ls",
                                "flag.txt": "CONGRATULATIONS\nToken: HL{f1rst_c0nnect10n_ok}\nSubmit it from the lab workstation terminal: submit HL{f1rst_c0nnect10n_ok}",
                                "logs/auth.log": "[08:12] sshd: session opened for user student (training)\n[08:12] sshd: accepted password auth from 10.10.0.5\n[08:12] note: all activity in this lab is simulated and logged for learning",
                        },
                },
                "TEST-WEB-01": {
                        "ip": "10.10.0.12",
                        "os": "NyxServer 3.0 (sim)",
                        "purpose": "Web fundamentals lab (locked in prototype)",
                        "services": {
                                80: {"name": "http", "banner": "NyxHTTPd lab-web"},
                                443: {"name": "https", "banner": "NyxHTTPd TLS lab-web"},
                        },
                        "auth": {"user": "", "pass": ""},
                        "files": {},
                },
                "TEST-SRV-01": {
                        "ip": "10.10.0.13",
                        "os": "NyxCore 4.2 (sim)",
                        "purpose": "Advanced lab (locked in prototype)",
                        "services": {
                                22: {"name": "ssh", "banner": "NyxSSH-4.2 hardened"},
                                3389: {"name": "rdp", "banner": "restricted"},
                        },
                        "auth": {"user": "", "pass": ""},
                        "files": {},
                },
        }

# ---------------- queries used by terminal / lab UI ----------------
func net_summary() -> Array:
        var out: Array = []
        for id in hosts.keys():
                var h: Dictionary = hosts[id]
                var locked: bool = str(h["purpose"]).contains("locked")
                out.append({"host": id, "ip": h["ip"], "locked": locked})
        return out

func host_exists(id: String) -> bool:
        return hosts.has(id.to_upper())

func scan_host(id: String) -> Dictionary:
        var key := id.to_upper()
        if not hosts.has(key):
                return {"ok": false, "msg": "scan: unknown or unreachable host '%s'" % id}
        var h: Dictionary = hosts[key]
        var ports: Array = []
        for p in h["services"].keys():
                ports.append({"port": int(p), "name": h["services"][p]["name"], "banner": h["services"][p]["banner"]})
        ports.sort_custom(func(a, b): return a["port"] < b["port"])
        return {"ok": true, "host": key, "ip": h["ip"], "os": h["os"], "ports": ports}

func try_login(id: String, user: String, password: String) -> Dictionary:
        var key := id.to_upper()
        if not hosts.has(key):
                return {"ok": false, "msg": "connect: unknown host '%s'" % id}
        var h: Dictionary = hosts[key]
        var a: Dictionary = h["auth"]
        if str(a["user"]) == "" :
                return {"ok": false, "msg": "auth: this lab node is locked in the prototype."}
        if user == str(a["user"]) and password == str(a["pass"]):
                return {"ok": true, "msg": "auth ok. session established with %s (%s)." % [key, h["ip"]]}
        return {"ok": false, "msg": "auth failed for %s@%s (attempt logged in lab auth.log)." % [user, key]}

func remote_files(id: String) -> Array:
        var key := id.to_upper()
        if not hosts.has(key):
                return []
        var h: Dictionary = hosts[key]
        var out: Array = []
        for f in h["files"].keys():
                out.append(f)
        out.sort()
        return out

func read_remote_file(id: String, fname: String) -> Dictionary:
        var key := id.to_upper()
        if not hosts.has(key):
                return {"ok": false, "msg": "read: not connected"}
        var h: Dictionary = hosts[key]
        if not h["files"].has(fname):
                return {"ok": false, "msg": "read: no such file '%s' (try: ls)" % fname}
        return {"ok": true, "content": str(h["files"][fname])}

func is_locked(id: String) -> bool:
        var key := id.to_upper()
        if not hosts.has(key):
                return true
        return str(hosts[key]["purpose"]).contains("locked")

# ---------------- player PC local files ----------------
func local_files() -> Dictionary:
        return {
                "notes.txt": """ARi'S BEGINNER NOTES (read me first!)
-------------------------------------
The CyberLab connects my PC to a safe TRAINING network.
Every machine there is a simulated practice target.

BASIC TERMINAL COMMANDS
  help        list commands
  whoami      who am i
  network     show the training network
  scan <host> probe a machine for open ports
  connect <host>   open a session (it will ask for login)
  ls          list files on the connected machine
  read <file> read a file
  disconnect  close the session
  exit        close the terminal

LAB LOGIN (given to students)
  user: student
  password: learn3r

Plan for FIRST CONNECTION:
  1) network          2) scan TEST-PC-01
  3) connect TEST-PC-01 (use student login)
  4) ls, read flag.txt   5) submit the token
""",
                "first_connection.txt": """MISSION: FIRST CONNECTION
From: Ghost (OpenShell Academy mentor)

Welcome to the Academy lab, kid.
Your first exercise is simple: reach TEST-PC-01 over the
training network, look around, and bring back the token
from flag.txt.

Steps:
 1. Open the terminal
 2. Run: help      (learn the basics)
 3. Run: network   (see the lab)
 4. Run: scan TEST-PC-01
 5. Run: connect TEST-PC-01   (creds are in notes.txt)
 6. Run: ls  then  read flag.txt
 7. Run: submit <token>

Rewards: XP + your first credits. Legal, safe, fictional.
""",
                "journal.txt": """Day 1 - Got the old PC running again.
School is boring, but this CyberLab thing feels different.
Ghost says hackers are just people who refuse to stop asking WHY.
Today: first connection. Tomorrow: who knows.
""",
                "lab_guide.txt": """CYBERLAB GUIDE (prototype)
Targets:
  TEST-PC-01    beginner workstation   [OPEN]
  TEST-WEB-01   web fundamentals       [LOCKED - future update]
  TEST-SRV-01   advanced scenarios     [LOCKED - future update]

Everything in the lab is a simulation for learning.
Real systems, real IPs and real credentials are never touched.
""",
        }

# ---------------- serialization (token could change) ----------------
func to_dict() -> Dictionary:
        return {"lab_token": lab_token}

func from_dict(d: Dictionary) -> void:
        lab_token = str(d.get("lab_token", lab_token))
