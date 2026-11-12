#!/usr/bin/env python3
"""Fabrique le fichier public d'une journée à partir d'un fichier "brut" (réponses en clair).

Usage : python3 scripts/make_day.py brut.json
- Le fichier brut n'est JAMAIS commité (il contient les réponses en clair).
- Écrit data/days/<id>.json et met à jour data/days.json (index, plus récent en premier).

Format du fichier brut :
{
  "id": "2026-11-12", "label": "Nuit du 11 au 12 novembre 2026", "games": 10,
  "riddles": [   # exactement 3, dans l'ordre MVP, Frenchie, Révélation
    {"cat": "MVP de la nuit", "desc": "...",
     "line": [["PTS","32"], ["TIR","13/18"], ...], "result": "Victoire",
     "answer": "Victor Wembanyama", "team": "San Antonio Spurs",
     "accepts": ["wembanyama", "wemby"],          # le nom complet et le nom de famille sont ajoutés d'office
     "hints": ["34 min", "Pivot · Conférence Ouest", "Victoire 124-119 à Chicago"],  # exactement 3
     "why": "Pourquoi ce choix, en une ou deux phrases."}
  ],
  "notes": ["Source des stats...", "Moyennes : ..."]
}
"""
import base64, hashlib, json, re, sys, unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

def norm(s: str) -> str:
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if unicodedata.category(c) != "Mn").lower()
    s = re.sub(r"[^a-z ]", " ", s)
    return re.sub(r"\s+", " ", s).strip()

def h(s: str) -> str:
    return hashlib.sha256(norm(s).encode()).hexdigest()

def hide(obj) -> str:
    raw = base64.b64encode(json.dumps(obj, ensure_ascii=False).encode()).decode()
    return raw[::-1]

def main(path):
    raw = json.loads(Path(path).read_text())
    assert len(raw["riddles"]) == 3, "il faut 3 devinettes"
    out = {k: raw[k] for k in ("id", "label", "games")}
    out["notes"] = raw.get("notes", [])
    out["riddles"] = []
    for r in raw["riddles"]:
        assert len(r["hints"]) == 3, "il faut 3 indices par devinette"
        accepts = {norm(a) for a in r.get("accepts", [])}
        accepts.add(norm(r["answer"]))
        accepts.add(norm(r["answer"]).split(" ")[-1])
        out["riddles"].append({
            "cat": r["cat"], "desc": r["desc"], "line": r["line"], "result": r["result"],
            "check": sorted(h(a) for a in accepts if a),
            "secret": hide({"answer": r["answer"], "team": r["team"], "hints": r["hints"], "why": r["why"],
                            "accepts": sorted(a for a in accepts if a)}),
        })
    (ROOT / "data/days" / f"{out['id']}.json").write_text(json.dumps(out, ensure_ascii=False, indent=1))
    idx_path = ROOT / "data/days.json"
    idx = json.loads(idx_path.read_text()) if idx_path.exists() else []
    idx = [d for d in idx if d["id"] != out["id"]] + [{"id": out["id"], "label": out["label"]}]
    idx.sort(key=lambda d: d["id"], reverse=True)
    idx_path.write_text(json.dumps(idx, ensure_ascii=False, indent=1))
    print("ok", out["id"])

if __name__ == "__main__":
    main(sys.argv[1])
