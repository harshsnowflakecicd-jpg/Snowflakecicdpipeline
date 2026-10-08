"""Fail CI if a migration script breaks schemachange naming rules or versions collide."""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "migrations"
VERSIONED = re.compile(r"^V\d+(\.\d+)*__[A-Za-z0-9_]+\.sql$")
REPEATABLE = re.compile(r"^R__[A-Za-z0-9_]+\.sql$")
ALWAYS = re.compile(r"^A__[A-Za-z0-9_]+\.sql$")

errors, versions = [], {}
for f in sorted(ROOT.rglob("*.sql")):
    if not (VERSIONED.match(f.name) or REPEATABLE.match(f.name) or ALWAYS.match(f.name)):
        errors.append(f"Bad name: {f.relative_to(ROOT)} (use V1.2.3__desc.sql, R__desc.sql or A__desc.sql)")
    if f.name.startswith("V"):
        v = f.name.split("__")[0]
        if v in versions:
            errors.append(f"Duplicate version {v}: {f.name} and {versions[v]}")
        versions[v] = f.name

if errors:
    print("\n".join(errors))
    sys.exit(1)
print(f"{len(versions)} versioned scripts OK")
