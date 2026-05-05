#!/usr/bin/env python3
"""
org_viewer.py — 编制树可视化工具
用法: python tools/org_viewer.py
      → 浏览器打开 http://localhost:8080
      → Ctrl+C 停止
"""
import http.server
import json
import os
import urllib.parse
import webbrowser
import sys

TOOLS_DIR = os.path.dirname(__file__)
DATA_DIR = os.path.join(os.path.dirname(TOOLS_DIR), "data")
HTML_FILE = os.path.join(TOOLS_DIR, "org_viewer.html")

print("数据目录:", DATA_DIR)
print("HTML文件:", HTML_FILE, "存在:", os.path.isfile(HTML_FILE))

_cache = {}

def load_nation(nation):
    if nation in _cache:
        return _cache[nation]
    base = os.path.join(DATA_DIR, nation)
    try:
        weapons = json.load(open(os.path.join(base, "weapons.json"), encoding="utf-8"))
        units   = json.load(open(os.path.join(base, "units.json"),   encoding="utf-8"))
        tree    = json.load(open(os.path.join(base, "tree.json"),    encoding="utf-8"))
        equip   = json.load(open(os.path.join(base, "equipment.json"), encoding="utf-8"))
    except FileNotFoundError as e:
        print("加载失败:", e)
        return None

    w_map = {w["id"]: w for w in weapons}
    u_map = {u["id"]: u for u in units}
    e_map = {e["id"]: e for e in equip}

    roots = []
    children_map = {}
    for n in tree:
        pid = n.get("parent_id")
        if pid is None:
            roots.append(n)
        else:
            children_map.setdefault(pid, []).append(n)

    types = {}
    for u in units:
        t = u.get("type", "?")
        types[t] = types.get(t, 0) + 1

    result = {
        "weapons": weapons, "units": units, "tree": tree, "equip": equip,
        "w_map": w_map, "u_map": u_map, "e_map": e_map,
        "roots": roots, "children": children_map,
        "types": types,
        "summary": "%d weapons, %d units, %d tree, %d equip" % (
            len(weapons), len(units), len(tree), len(equip))
    }
    _cache[nation] = result
    return result

class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path
        params = urllib.parse.parse_qs(parsed.query)

        if path == "/":
            self._serve_file(HTML_FILE, "text/html; charset=utf-8")
        elif path == "/favicon.ico":
            self.send_response(204)
            self.end_headers()
        elif path.startswith("/api/"):
            self._handle_api(path, params)
        else:
            self.send_error(404)

    def _serve_file(self, filepath, content_type):
        try:
            with open(filepath, "r", encoding="utf-8") as f:
                content = f.read()
            self.send_response(200)
            self.send_header("Content-Type", content_type)
            self.send_header("Cache-Control", "no-cache")
            self.end_headers()
            self.wfile.write(content.encode("utf-8"))
        except FileNotFoundError:
            self.send_error(404)

    def _handle_api(self, path, params):
        parts = path.split("/")
        if len(parts) == 4 and parts[2] == "tree":
            nation = parts[3]
            data = load_nation(nation)
            if data is None:
                self._json({"error": "not found"})
                return
            tree_nodes = self._build_subtree(data["roots"], data["children"])
            self._json({"tree": tree_nodes, "summary": data["summary"], "types": data["types"],
                        "units": {u["id"]: {"name": u["name"], "type": u["type"], "cost": u["cost"]} for u in data["units"]}})

        elif len(parts) == 5 and parts[2] == "unit":
            nation, uid = parts[3], parts[4]
            data = load_nation(nation)
            if data is None or uid not in data["u_map"]:
                self._json({"error": "not found"})
                return
            unit = data["u_map"][uid]
            members = []
            for m in unit.get("members", []):
                m_detail = dict(m)
                m_detail["weapon_details"] = [data["w_map"].get(w, {"id": w, "name": w}) for w in m.get("weapons", [])]
                members.append(m_detail)
            result = dict(unit)
            result["members"] = members
            tn = next((n for n in data["tree"] if n["id"] == uid), None)
            if tn:
                result["is_equipment"] = tn.get("equipment") and tn.get("equipment") is not False
            self._json(result)

        elif len(parts) == 5 and parts[2] == "weapon":
            nation, wid = parts[3], parts[4]
            data = load_nation(nation)
            if data is None or wid not in data["w_map"]:
                self._json({"error": "not found"})
                return
            self._json(data["w_map"][wid])

        elif len(parts) == 3 and parts[2] == "search":
            q = params.get("q", [""])[0].lower()
            nation = params.get("nation", ["germany"])[0]
            data = load_nation(nation)
            if data is None:
                self._json({"error": "not found"})
                return
            results = []
            for u in data["units"]:
                if q in u["id"].lower() or q in u.get("name", "").lower():
                    results.append({"id": u["id"], "name": u["name"], "type": "unit", "cost": u.get("cost")})
            for w in data["weapons"]:
                if q in w["id"].lower() or q in w.get("name", "").lower():
                    results.append({"id": w["id"], "name": w["name"], "type": "weapon", "pen": w.get("penetration")})
            self._json({"results": results[:30]})
        else:
            self._json({"error": "bad api path"})

    def _build_subtree(self, nodes, children, indent=0):
        result = []
        for n in sorted(nodes, key=lambda x: (x.get("tech_tier_required", 0), x.get("unlock_xp", 0), x["id"])):
            equip = n.get("equipment")
            result.append({"id": n["id"], "tier": n.get("tech_tier_required", 0),
                           "equip": bool(equip and equip is not False), "depth": indent})
            kids = children.get(n["id"], [])
            if kids:
                result.extend(self._build_subtree(kids, children, indent + 1))
        return result

    def _json(self, obj):
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(json.dumps(obj, ensure_ascii=False).encode("utf-8"))

    def log_message(self, format, *args):
        print("[%s] %s" % (self.client_address[0], format % args))

if __name__ == "__main__":
    for port in [8080, 8081, 8082]:
        try:
            server = http.server.HTTPServer(("127.0.0.1", port), Handler)
            break
        except OSError:
            continue
    else:
        print("错误: 无法绑定端口 (8080-8082 均被占用)")
        sys.exit(1)

    print("编制树浏览器已启动 → http://127.0.0.1:%d" % port)
    print("关闭窗口或 Ctrl+C 停止")
    webbrowser.open("http://127.0.0.1:%d" % port)
    try:
        server.serve_forever()
    except (KeyboardInterrupt, SystemExit):
        print("\n已停止")
        server.server_close()
    except:
        pass
