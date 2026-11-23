import os
import re
import glob
import json
import hashlib
import subprocess
import http.server
import socketserver
import urllib.parse
from datetime import datetime

PORT = 4173
WORKSPACE = r"E:\code\parking_management"
TELEMETRY_DIR = os.path.join(WORKSPACE, ".agents", "telemetry")
EVENTS_FILE = os.path.join(TELEMETRY_DIR, "events.json")

# Dynamic deterministic palette & icons based on hashing identifier
HERO_AVATARS = ["🤖", "🛡️", "⚔️", "🔍", "⚡", "🌐", "🔧", "🏹", "🔮", "💎", "🧭", "🛸", "🚀", "🎯", "📜"]

def derive_avatar_and_color(identifier: str):
    """
    Pure algorithmic derivation without hardcoded if-else:
    Computes deterministic MD5 hash to pick avatar icon and HSL theme color.
    """
    h = int(hashlib.md5(identifier.encode("utf-8")).hexdigest(), 16)
    avatar = HERO_AVATARS[h % len(HERO_AVATARS)]
    hue = h % 360
    color = f"hsl({hue}, 80%, 55%)"
    return avatar, color

def get_registered_agent_catalog():
    """
    Dynamically discover all registered subagent definitions from:
    1. .agents/agents/*.md
    2. .agents/subagents/*/SUBAGENT.md
    3. Built-in Antigravity types (self, browser, research, image-generator)
    Zero hardcoding of role titles.
    """
    catalog = {}
    
    # Built-in types
    for builtin in ["self", "browser", "research", "image-generator"]:
        catalog[builtin] = {
            "type": builtin,
            "title": builtin.replace("-", " ").title()
        }
        
    # Discover markdown definitions in .agents/agents/*.md
    for md_path in glob.glob(os.path.join(WORKSPACE, ".agents", "agents", "*.md")):
        type_name = os.path.splitext(os.path.basename(md_path))[0]
        title = type_name.replace("-", " ").title()
        try:
            with open(md_path, "r", encoding="utf-8", errors="ignore") as f:
                for line in f:
                    if line.strip().startswith("name:"):
                        type_name = line.split(":", 1)[1].strip().strip("\"'")
                    elif "Subagent" in line and not line.startswith("---"):
                        # Extract first meaningful title sentence
                        cleaned = line.strip("# \t\r\n")
                        if cleaned:
                            title = cleaned
                            break
        except Exception:
            pass
        catalog[type_name] = {"type": type_name, "title": title}

    # Discover .agents/subagents/*/SUBAGENT.md
    for sub_path in glob.glob(os.path.join(WORKSPACE, ".agents", "subagents", "*", "SUBAGENT.md")):
        dir_name = os.path.basename(os.path.dirname(sub_path))
        title = dir_name.replace("-", " ").title()
        try:
            with open(sub_path, "r", encoding="utf-8", errors="ignore") as f:
                first_line = f.readline().strip("# \t\r\n")
                if first_line:
                    title = first_line.split("(")[0].strip()
        except Exception:
            pass
        catalog[dir_name] = {"type": dir_name, "title": title}
        
    return catalog

def parse_branch_metadata(branch: str, catalog: dict):
    """
    Dynamically resolve role, type, and hash identifier from branch name.
    Supports Antigravity conventions:
    - subagent-<Role>-<TypeName>-<hash>
    - swarm-<Role>-<hash>
    - custom-<name>
    """
    # 1. Standard subagent pattern: subagent-...-<hash>
    if branch.startswith("subagent-"):
        raw = branch[len("subagent-"):]
        m_hash = re.search(r"-([a-f0-9]{6,12})$", raw)
        if m_hash:
            subagent_id = m_hash.group(1)
            core = raw[:-len(m_hash.group(0))]
            # Match against dynamic catalog keys sorted by length descending
            matched_type = None
            role_name = None
            for k in sorted(catalog.keys(), key=len, reverse=True):
                if core.endswith("-" + k):
                    matched_type = k
                    role_part = core[:-len("-" + k)]
                    role_name = role_part.replace("-", " ").strip()
                    break
                elif core == k:
                    matched_type = k
                    role_name = catalog[k]["title"]
                    break
            
            if not matched_type:
                parts = core.rsplit("-", 1)
                role_name = parts[0].replace("-", " ").strip()
                matched_type = parts[1] if len(parts) > 1 else "worker"
                
            return subagent_id, role_name, matched_type

    # 2. Swarm pattern: swarm-<Role>-<hash>
    if branch.startswith("swarm-"):
        raw = branch[len("swarm-"):]
        m_hash = re.search(r"-([a-f0-9]{6,12})$", raw)
        if m_hash:
            subagent_id = m_hash.group(1)
            role_part = raw[:-len(m_hash.group(0))]
            return subagent_id, role_part.replace("-", " ").title(), f"swarm-{role_part.lower()}"

    # 3. Fallback generic branch
    parts = branch.split("-")
    subagent_id = parts[-1] if len(parts[-1]) >= 6 else branch[:8]
    return subagent_id, branch.replace("-", " ").replace("/", " : ").title(), "git-branch"

def get_live_worktrees():
    """Dynamically query git worktree list from machine OS"""
    try:
        output = subprocess.check_output(
            ["git", "worktree", "list", "--porcelain"],
            cwd=WORKSPACE,
            text=True,
            stderr=subprocess.DEVNULL
        )
        worktrees = []
        cur_wt = {}
        for line in output.splitlines():
            line = line.strip()
            if line.startswith("worktree "):
                cur_wt = {"path": line.split(" ", 1)[1]}
            elif line.startswith("HEAD "):
                cur_wt["head"] = line.split(" ", 1)[1][:7]
            elif line.startswith("branch "):
                branch_name = line.split(" ", 1)[1].replace("refs/heads/", "")
                cur_wt["branch"] = branch_name
                cur_wt["is_master"] = (branch_name == "master")
                worktrees.append(cur_wt)
                cur_wt = {}
        return worktrees
    except Exception as e:
        return [{"error": str(e)}]

def get_active_subagents(worktrees, recent_event=None):
    """
    Dynamically discover active/registered subagents from:
    1. Active Git Worktrees (isolated workspaces)
    2. Telemetry events / Subagent lifecycle (read-only subagents, browser subagents, tool calls)
    Zero hardcoding: all avatars, colors, types and names are computed algorithmically.
    """
    subagents = []
    seen_ids = set()
    catalog = get_registered_agent_catalog()
    
    # 1. Parse from active worktrees
    for wt in worktrees:
        if wt.get("is_master"):
            continue
        branch = wt.get("branch", "")
        path = wt.get("path", "")
        
        subagent_id, role_title, agent_type = parse_branch_metadata(branch, catalog)
        seen_ids.add(subagent_id)
        
        avatar, color = derive_avatar_and_color(f"{agent_type}:{role_title}")
        is_current_session = "7178e090" in path
        
        subagents.append({
            "id": subagent_id,
            "name": role_title,
            "role": agent_type,
            "branch": branch,
            "worktree_path": path,
            "commit": wt.get("head", "HEAD"),
            "avatar": avatar,
            "color": color,
            "is_current": is_current_session,
            "status": "ACTIVE WORKTREE" if is_current_session else "STANDBY WORKTREE"
        })

    # 2. Add telemetry subagents if launched (such as Browser agent or Read-only subagents without separate worktree)
    if recent_event and isinstance(recent_event, dict):
        tool_args = recent_event.get("toolArgs")
        if tool_args and isinstance(tool_args, dict):
            type_name = str(tool_args.get("TypeName", tool_args.get("typeName", ""))).strip("\"'")
            role_name = str(tool_args.get("Role", tool_args.get("role", ""))).strip("\"'")
            workspace_mode = str(tool_args.get("Workspace", tool_args.get("workspace", "inherit"))).strip("\"'")
            
            if type_name or role_name:
                synth_id = "rt-" + (type_name[:6] if type_name else "agent")
                if synth_id not in seen_ids:
                    display_name = role_name if role_name else (catalog.get(type_name, {}).get("title") or type_name)
                    avatar, color = derive_avatar_and_color(f"{type_name}:{display_name}")
                        
                    subagents.append({
                        "id": synth_id,
                        "name": display_name,
                        "role": type_name if type_name else "subagent",
                        "branch": f"runtime-{workspace_mode}",
                        "worktree_path": f"[Runtime Mode: {workspace_mode}]",
                        "commit": "LIVE-EXEC",
                        "avatar": avatar,
                        "color": color,
                        "is_current": True,
                        "status": "ACTIVE RUNTIME"
                    })
        
    return subagents

def get_telemetry_state():
    """Read dynamic telemetry from hooks + OS git worktrees"""
    recent_event = None
    if os.path.exists(EVENTS_FILE):
        try:
            with open(EVENTS_FILE, "r", encoding="utf-8-sig") as f:
                recent_event = json.load(f)
        except Exception:
            pass

    worktrees = get_live_worktrees()
    subagents = get_active_subagents(worktrees, recent_event)

    return {
        "timestamp": datetime.now().isoformat(),
        "worktrees": worktrees,
        "subagents": subagents,
        "recent_event": recent_event
    }

    return {
        "timestamp": datetime.now().isoformat(),
        "worktrees": worktrees,
        "subagents": subagents,
        "recent_event": recent_event
    }

class SubagentGameHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        
        if parsed.path == "/api/telemetry":
            data = get_telemetry_state()
            payload = json.dumps(data).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)
            return

        return super().do_GET()

if __name__ == "__main__":
    os.chdir(os.path.join(WORKSPACE, ".agents", "game_ui"))
    socketserver.TCPServer.allow_reuse_address = True
    print(f"[*] Subagent Game Server running on http://localhost:{PORT}")
    with socketserver.TCPServer(("", PORT), SubagentGameHandler) as httpd:
        httpd.serve_forever()
