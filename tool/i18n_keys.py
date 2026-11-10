"""Lists every English sentence the app translates (4.7): the first argument of tr('...'), the API fallback and
ApiException messages (translated where shown), and the label lists defined once (translated where shown).
Writes them, sorted, to assets/i18n/keys.json; tool/i18n_check.py checks every language has them all.
Usage: python tool/i18n_keys.py
"""
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIT = r"(?:'(?:[^'\\\n]|\\.)*'|\"(?:[^\"\\\n]|\\.)*\")"
SEQ = LIT + r"(?:\s*" + LIT + r")*"
PATTERNS = [
    re.compile(r"\btr\(\s*(" + SEQ + r")\s*[,)]"),
    re.compile(r"\bfallbackError:\s*(?:\w+\s*\?\s*)?(" + SEQ + r")(?:\s*:\s*(" + SEQ + r"))?"),
    re.compile(r"\bApiException\(\s*(" + SEQ + r")"),
    re.compile(r"\b_get\(\s*'[^']*',\s*(" + SEQ + r")"),
    re.compile(r"(?m)^\s*(" + SEQ + r"),\s*$"),
]
# Lists and labels defined once, translated where they are shown.
LIST_FILES = (
    "features/06_destinationInfo/utils/card_meta.dart", "features/06_destinationInfo/widgets/travel_loader.dart",
    "features/11_notifications/screens/notification_settings_screen.dart", "features/09_profile/screens/user_profile.dart",
    "core/wanderbook/wanderbook_models.dart", "core/legal/legal_pages.dart", "features/08_wanderbook/screens/people_screen.dart",
    "global_widgets/book/results_layout.dart", "features/01_auth_register/screens/forgot_password_screen.dart",
    "features/01_auth_register/services/auth_service.dart", "core/api/api_exception.dart",
)
EXTRA = ["1 day", "{0} days", "1 passenger", "{0} passengers", "1 guest", "{0} guests", "1 room", "{0} rooms", "Edit"]
NOT_TEXT = re.compile(r"^(GoAwayGo|Wanderbook|WANDERBOOK|Backend\.configure\(\) was not called\.|GoAwayGo app Sentry .*|"
                      r"/.*|assets/.*|[a-z][A-Za-z]*|[a-z_]+|GET|POST|PUT|DELETE|.*\[websiteUrl\].*)$")


def text_of(seq):
    out = ""
    for lit in re.findall(LIT, seq):
        body = lit[1:-1]
        body = re.sub(r"\\(.)", lambda m: {"n": "\n"}.get(m.group(1), m.group(1)), body)
        out += body
    return out


keys = set(EXTRA)
sure = set()
for root, _, files in os.walk(os.path.join(ROOT, "lib")):
    for f in files:
        if not f.endswith(".dart"):
            continue
        path = os.path.join(root, f)
        rel = os.path.relpath(path, os.path.join(ROOT, "lib")).replace(os.sep, "/")
        if rel.startswith("core/i18n/"):
            continue
        src = open(path, encoding="utf-8").read()
        for i, p in enumerate(PATTERNS):
            if i == 4:
                continue
            for m in p.finditer(src):
                for g in m.groups():
                    if g and "$" not in g:
                        # Whatever tr() is given is a sentence, however short ("now", "{0} h").
                        (sure if i == 0 else keys).add(text_of(g))
        if rel in LIST_FILES:
            for m in re.finditer(SEQ, src):
                t = text_of(m.group(0))
                line_start = src.rfind(chr(10), 0, m.start()) + 1
                if src[line_start:m.start()].strip().startswith(("//", "///")):
                    continue
                before = src[max(0, m.start() - 30): m.start()]
                if ("$" in m.group(0) or "import" in before or "/" in t or not re.search(r"[A-Z]", t)
                        or not re.search(r"[a-z]{2}", t)):
                    continue
                keys.add(t)
keys = sorted({k for k in keys if re.search(r"[A-Za-z]{2}", k) and not NOT_TEXT.match(k) and "$" not in k} | sure)
json.dump(keys, open(os.path.join(ROOT, "assets", "i18n", "keys.json"), "w", encoding="utf-8", newline="\n"),
          ensure_ascii=False, indent=2)
print(len(keys), "sentences")
