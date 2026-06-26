---
name: core-skillmaker
description: Unterstützt bei der Erstellung von hochqualitativen OpenCode-Skills gemäß Konventionen.
---
## Was ich tue
- Unterstütze bei der Definition von Zweck und Umfang eines neuen Skills.
- Generiere valides YAML-Frontmatter und Grundstruktur für eine `SKILL.md`.
- Validiere Skill-Namen gegen das Regex-Muster (`^[a-z0-9]+(-[a-z0-9]+)*$`).
- Biete Vorlagen für die Konfiguration von Berechtigungen an.
- **Iterativer Review-Prozess:** Ich entwerfe den Skill und hole aktiv Feedback ein (HITL), um Anpassungen vorzunehmen, bis der Skill deinen Anforderungen entspricht. Vor der finalen Erstellung frage ich dich, ob der Skill global oder projekt-lokal gespeichert werden soll. Erst nach deiner expliziten Bestätigung wird der Skill fertiggestellt.

## Struktur eines Skills
Erstelle für jeden Skill ein eigenes Verzeichnis: `[pfad]/skills/[name]/SKILL.md`.

Die `SKILL.md` muss mit folgendem YAML-Frontmatter beginnen:
---
name: mein-skill
description: Kurze, präzise Beschreibung (1-1024 Zeichen)
license: MIT
compatibility: opencode
metadata:
  audience: maintainers
---

## Berechtigungen konfigurieren
Damit der neue Skill aktiv genutzt werden kann, muss er in der `opencode.json` konfiguriert werden. Um den Skill standardmäßig überall zu erlauben, füge dies zur `opencode.json` hinzu:

{
  "permission": {
    "skill": {
      "mein-skill": "allow"
    }
  }
}

## Wann du mich verwendest
Verwende mich, wenn du einen neuen, gut dokumentierten und konformen OpenCode-Skill erstellen möchtest.