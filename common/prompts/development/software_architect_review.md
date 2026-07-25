### Kontext

Dieser Prompt steuert eine automatisierte Analyse und Refaktorierung eines Softwareprojekts. Das Projekt liegt unter `<projekt_verzeichnis>` und wird primär in `<programmiersprache>` entwickelt (spezifische Technologievorgaben in `<technologie_stack>`).

### Aufgabe

Analysiere Architektur und Code des Projekts anhand der nachfolgenden Kriterien. Erstelle einen detaillierten Refactoring-Architekturplan, den ein Code-Agent direkt umsetzen kann. Die bestehende Funktionalität darf nicht verändert werden. Bei unklaren Anforderungen stelle gezielte Rückfragen.

### Analysebereiche

**Architektur**
- Designschwächen, Optimierungspotenzial, Fehlerquellen erkennen
- Separation of Concerns: Sind API-Layer, Business-Logik und Infrastruktur sauber getrennt?
- Abstraktion & Entkopplung: Werden Interfaces / abstrakte Basisklassen genutzt, um externe Provider austauschbar zu machen?
- Asynchronität & Performance: Wird das Concurrency-Modell effizient genutzt?
- Datenvalidierung & Typisierung: Sind Request/Response-Modelle strikt von internen Strukturen getrennt?
- Fokus-Prüfung: Löst das Programm zu viele Probleme gleichzeitig?
- Error Handling & Resilienz: Gibt es eine zentrale Exception- und Ausfallstrategie?
- Logging: Gibt es eine zentrale Logging-Strategie?

**Code**
- Best Practices und aktuelle Sprach-/Framework-Idiome
- Separation of Concerns, Abstraktion, Entkopplung, Asynchronität, Datenvalidierung
- Error Handling, Duplikate, ungenutzter Code (entfernen)
- Testing: Standard-Framework, Testabdeckung maximieren, sinnvolle Tests, gleiche Ordnerstruktur wie Source
- Inline-Dokumentation: komplexe Abschnitte dokumentieren, öffentliche Methoden kommentieren

**Dokumentation**
- Erstelle Systemdokumentation nach arc42-Standard mit PlantUML-Diagrammen aufbereitet als HTML
- Aktualisiere die Projektdokumentation bei jeder Änderung

### Technologie-Vorgaben

Diese Angaben gelten, falls `<programmiersprache>` = Python (`<technologie_stack>` überschreibt):

| Bereich | Tool |
|---|---|
| Paketmanager | UV (toml) |
| API-Entwicklung | FastAPI |
| Datenbank | SQLAlchemy |
| Datenvalidierung | Pydantic |
| Testing | Pytest |
| Typsicherheit | MyPy (nur relevante Regeln) |
| Code-Formatierung | Ruff |
| Code-Analyse | Flake8 |
| Import-Sortierung | isort |
| Qualitätssicherung | Pre-Commit |
| CI/CD | GitHub Actions |
| Containerisierung | Docker |

### Abschluss

Nach allen Änderungen prüfen: Tests, Linting, Formatierung und Build-Skripte laufen fehlerfrei durch.

### Eingabedaten
