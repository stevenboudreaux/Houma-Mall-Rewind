#!/usr/bin/env python3
"""Refuse commits that add a secret. Used by .githooks/pre-commit and .github/workflows/secret-scan.yml.

    python3 .githooks/secret_check.py --staged          # the index (pre-commit)
    python3 .githooks/secret_check.py --range A..B      # every commit in a range (CI)
    python3 .githooks/secret_check.py --commits SHA...  # these commits
    python3 .githooks/secret_check.py --tree [REV]      # every tracked text file at REV (default HEAD)

It reads only ADDED lines (and the tree mode's files) and the names of added files. It never prints a
value: a finding is file, line, kind, and the value's first 4 characters. A false positive is let through
by putting `secret-check: allow` on the same line. Pure standard library; runs in well under a second on a
normal commit. Where the secrets live and what to do on a finding: CLAUDE-CLOUD.md "Secrets".
"""
import os
import re
import subprocess
import sys

ALLOW = "secret-check: allow"

# Files that only ever hold credentials. Matched against the path's last part, case-insensitive.
BAD_NAMES = re.compile(
    r"^(rclone[^/]*\.conf|\.env(\..+)?|.*\.pem|.*\.key|.*\.p12|.*\.pfx|.*\.keystore|.*\.jks|"
    r"id_(rsa|dsa|ecdsa|ed25519)(\.pub)?|\.netrc|\.git-credentials|\.pypirc|credentials\.json|secrets\.json|"
    r"export_credentials\.cfg)$",
    re.I,
)
# id_*.pub is a public key, but it sits next to the private one: still refused, on purpose.

# (kind, regex); group 1 is the value.
PATTERNS = [
    ("github-token", r"\b(gh[pousr]_[A-Za-z0-9]{36,255})\b"),
    ("github-fine-grained-token", r"\b(github_pat_[A-Za-z0-9_]{60,255})\b"),
    ("aws-style-access-key", r"\b((?:AKIA|ASIA|ABIA|ACCA)[0-9A-Z]{16})\b"),
    ("private-key-block", r"(-----BEGIN (?:[A-Z]+ )*PRIVATE KEY(?: BLOCK)?-----)"),
    ("secret_access_key", r"(?i)secret_access_key[\"']?\s*[:=]\s*[\"']?([A-Za-z0-9/+=_\-]{16,})"),
    ("access_key_id", r"(?i)access_key_id[\"']?\s*[:=]\s*[\"']?([A-Za-z0-9/+=_\-]{16,})"),
    ("password-in-url", r"\b[a-z][a-z0-9+.\-]*://[^\s/:@\"'<>$]+:([^\s/@\"'<>${}]{3,})@[A-Za-z0-9.\-]+"),
    ("google-api-key", r"\b(AIza[0-9A-Za-z_\-]{35})\b"),
    ("slack-token", r"\b(xox[baprs]-[A-Za-z0-9\-]{10,})"),
    ("cloudflare-api-token", r"(?i)(?:cf|cloudflare)[_-]?(?:api)?[_-]?token[\"']?\s*[:=]\s*[\"']?([A-Za-z0-9_\-]{40})\b"),
    # R2 keys are bare hex (32 for the id, 64 for the secret): only when a credential word is on the line
    ("hex-key-near-credential-word",
     r"(?i)(?:secret|access[_ -]?key|api[_ -]?key|key[_ -]?id|token|passw(?:or)?d|\br2[_ ])[^\n]{0,60}?[\"'=:\s]([0-9a-f]{32}|[0-9a-f]{64})\b"),
    ("admin-key-assigned", r"ADMIN_KEY\s*[:=]\s*[\"']((?!PICK)[^\"'\s]{6,})[\"']"),
    ("token-assigned", r"(?i)\b(?:api[_-]?key|token|secret|passphrase|password)[\"']?\s*[:=]\s*[\"']([A-Za-z0-9/+=_\-]{24,})[\"']"),
]
PATTERNS = [(k, re.compile(v)) for k, v in PATTERNS]

# Values that look like keys but are not: placeholders and this repo's own public ids.
NOT_SECRET = re.compile(r"^(PASTE|YOUR|EXAMPLE|PLACEHOLDER|PICK|xxxx|XXXX|0{16,}|<)", re.I)
PUBLIC_IDS = {
    "c5bce683f9f04dba760f624d1558a984",  # the Cloudflare account id (design/godot-build-hosting.md)
    "848b5102ea0e4d78999797a799545451",  # the public r2.dev host
}

# The live values, when this machine has them: an exact match is always a finding.
LIVE = {k: os.environ[k] for k in ("R2_ACCESS_KEY_ID", "R2_SECRET_ACCESS_KEY", "GITHUB_TOKEN", "GH_TOKEN")
        if len(os.environ.get(k, "")) >= 12}


def mask(v):
    return "%s… (%d chars)" % (v[:4], len(v))


def check_line(text):
    """Return [(kind, masked value)] for one added line."""
    if ALLOW in text:
        return []
    out = []
    for name, v in LIVE.items():
        if v in text:
            out.append(("the live value of $" + name, mask(v)))
    for kind, rx in PATTERNS:
        for m in rx.finditer(text):
            v = m.group(1)
            if NOT_SECRET.match(v) or v.lower() in PUBLIC_IDS:
                continue
            out.append((kind, mask(v)))
    return out


def git(*args):
    return subprocess.run(["git", *args], check=True, stdout=subprocess.PIPE).stdout


def stream(*args):
    """Yield git's output line by line (a whole history's diff does not fit in memory)."""
    p = subprocess.Popen(["git", *args], stdout=subprocess.PIPE)
    for raw in p.stdout:
        yield raw.rstrip(b"\n")
    if p.wait():
        raise SystemExit("secret-check: git %s failed" % args[0])


def scan_patch(patch, where, findings):
    """Walk a unified diff (-U0) and check every added line and every added file's name."""
    path, line = None, 0
    for raw in patch:
        if raw.startswith(b"commit "):
            where = raw[7:].decode()[:12]
        elif raw.startswith(b"+++ "):
            p = raw[4:].decode("utf-8", "replace")
            path = None if p == "/dev/null" else p[2:] if p.startswith("b/") else p
        elif raw.startswith(b"new file mode") or raw.startswith(b"rename to "):
            pass
        elif raw.startswith(b"diff --git "):
            parts = raw.decode("utf-8", "replace").split(" b/", 1)
            name = parts[1] if len(parts) == 2 else ""
            if BAD_NAMES.match(os.path.basename(name)):
                findings.append((where, name, 0, "credential file name", "-"))
        elif raw.startswith(b"@@"):
            m = re.search(rb"\+(\d+)", raw)
            line = int(m.group(1)) if m else 0
        elif raw.startswith(b"+") and path is not None:
            for kind, v in check_line(raw[1:].decode("utf-8", "replace")):
                findings.append((where, path, line, kind, v))
            line += 1
    return findings


# no --text: binary files show as "Binary files differ" (their names are still checked)
DIFF = ["--no-color", "--no-ext-diff", "--no-renames", "-U0"]


def main(argv):
    findings = []
    mode = argv[1] if len(argv) > 1 else "--staged"
    if mode == "--staged":
        scan_patch(stream("diff", "--cached", *DIFF), "staged", findings)
    elif mode in ("--range", "--commits"):
        revs = argv[2:] if mode == "--range" else ["--no-walk"] + argv[2:]
        # every commit's own change against its first parent; a root commit against the empty tree
        scan_patch(stream("log", "-p", "--format=commit %H", "--diff-merges=first-parent", *DIFF, *revs),
                   "?", findings)
    elif mode == "--tree":
        rev = argv[2] if len(argv) > 2 else "HEAD"
        for name in git("ls-tree", "-r", "--name-only", "-z", rev).split(b"\0"):
            if not name:
                continue
            n = name.decode("utf-8", "replace")
            if BAD_NAMES.match(os.path.basename(n)):
                findings.append((rev, n, 0, "credential file name", "-"))
            data = git("cat-file", "-p", "%s:%s" % (rev, n))
            if len(data) > 8_000_000 or b"\0" in data[:8000]:
                continue  # binary or huge; the history scan covers those
            for i, t in enumerate(data.decode("utf-8", "replace").split("\n"), 1):
                for kind, v in check_line(t):
                    findings.append((rev, n, i, kind, v))
    else:
        print(__doc__)
        return 2
    if not findings:
        print("secret-check: no secrets found (%s)" % mode)
        return 0
    print("secret-check: %d possible secret(s). Nothing was committed or pushed by this check." % len(findings))
    for where, path, line, kind, v in findings:
        print("  %s %s:%s  %s  starts %s" % (where, path, line, kind, v))
    print("If one is real: remove it, and rotate the key (CLAUDE-CLOUD.md \"Secrets\"). "
          "If it is not a secret, add `%s` to that line." % ALLOW)
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
