<context>
Ein Open-Source-Projekt soll auf Produktionsreife gebracht werden. Dazu gehören Dokumentation, Qualitätssicherung, CI/CD-Pipeline und automatisierte Deployments.
</context>

<task>
Alle Lücken in den folgenden Akzeptanzkriterien schließen. Prüfe jedes Kriterium gegen das Projekt aus `<projekt_daten>`, dokumentiere den Status, führe die notwendigen Änderungen durch und verifiziere das Ergebnis.
</task>

<acceptance_criteria>

<documentation>
- README.md: Projektbeschreibung, Funktionsumfang, Start/Ausführung, CLI-Referenz (exakt wie `--help`), Konfigurationsoptionen
- docs/arc42/: alle 12 arc42-Abschnitte
- CHANGELOG.md (Semantic Versioning, aktuell)
- CONTRIBUTING.md, SECURITY.md, CODE_OF_CONDUCT.md, .editorconfig
- .github/ISSUE_TEMPLATE/, PULL_REQUEST_TEMPLATE.md
</documentation>

<quality>
- Testabdeckung ≥ 80 % (projektspezifisches Tool)
- Lockfile aktuell (uv.lock / package-lock.json / go.sum / Cargo.lock / etc.)
- Keine veralteten Major-Versionen bei Abhängigkeiten
- Keine bekannten CVEs (Tool: pip-audit / npm audit / trivy / cargo audit)
- Pre-commit-Hooks: alle `rev:` auf neustem Stand, fehlerfrei über das gesamte Projekt
- Git-Verlauf frei von Secrets (API-Keys, Tokens, Passwörter)
- Keine Build-Artefakte oder generierten Dateien im Repository
</quality>

<ci_cd>
- CI-Workflow: lint, typecheck, test bei jedem Push/PR – läuft auf GitHub fehlerfrei
- CI-Caching für Abhängigkeiten (Job-Laufzeiten optimieren)
- Sprachversions-Matrix auf aktuell supported Releases (z. B. Python 3.11–3.13, Node 20–22, Go 1.22–1.23)
- GitHub Pages Deploy-Job: mkdocs-gerenderte arc42-Dokumentation
- Pages-URL nach Deploy erreichbar
- Docker-Image (falls vorhanden): Basis-Image aktuell, Build getestet
- Version erhöhen
- Docker Image wird auf Docker Hub gepusht und ist vorhanden
</ci_cd>

</acceptance_criteria>

<procedure>
1. Vollständige Bestandsaufnahme: README, Tests, CI, Docs, Pages, Dependencies, Pre-commit, Docker, Secrets – Abweichungen zu `<projekt_daten>` notieren
2. Lücken schließen: Doku aktualisieren, Tests ergänzen, Dependencies updaten, Hooks erneuern
3. Lokal testen: Lockfile aktualisieren, `pre-commit run --all-files`, Tests + Coverage, ggf. Docker-Build
4. Commit + Push auf GitHub
5. GitHub Actions über MCP triggern, Status prüfen, Fehler fixen, wiederholen bis grün
6. GitHub Pages-URL aufrufen und Verfügbarkeit bestätigen
7. GitHub Release (optional) mit aktuellem Changelog vorbereiten
8. Docker-Hub- und Docker-Compose-Dokumentation in README.md sowie auf Docker Hub pflegen
</procedure>

<output_format>
Pro Kriterium eine Zeile: [ERFUELLT | FEHLT | FIXED] Kriterium. Am Ende eine Zusammenfassung: X/Y Kriterien erfüllt, Z offene Punkte.
</output_format>

<projekt_daten>
Projektpfad:
Sprache/Stack: Python
Verwendete Tools (Test, Coverage, Lint, Audit, Build):
Docker-Image vorhanden (ja/nein):
GitHub-Repo-URL: git@github.com:domoskanonos/radioripper.git
Pages-Branch: main
</projekt_daten>
