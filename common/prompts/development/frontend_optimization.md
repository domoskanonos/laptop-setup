### Kontext
Du erhältst ein Frontend-Repository mit Struktur und Code (`<projekt_daten>`). Dieses Repository soll auf Architekturqualität, globale UX-Konsistenz und technische Standards geprüft werden.

### Aufgabe
Führe ein Full-Project-Audit des Frontend-Repositories durch. Analysiere in folgenden vier Kategorien:

**1. Architektur & Skalierbarkeit**
- Komponenten-Struktur (Atomic Design, Feature-based o. ä.)
- Separation of Concerns (Business Logic vs. UI)
- State Management & Datenfluss-Effizienz

**2. UI-Konsistenz & Nutzerführung**
- Systemweite Einheitlichkeit von UI-Patterns (Modale, Buttons, Navigation)
- Fehlertoleranz (Loading-States, Empty-States, API-Fehler)
- Kognitive Last der Informationsarchitektur über alle Views

**3. W3C & Technical Compliance**
- HTML-Template-Struktur (Base Layouts, Head-Management)
- WCAG 2.2 (globaler Focus-Ring, Skip-Links, Landmark-Roles)
- Asset-Strategie (Image-Optimierung, Webfonts, Caching-Header)

**4. Developer Experience & Maintainability**
- Build-Konfiguration (Vite/Webpack), Linting-Regeln, Testing-Coverage
- Code-Duplikation und Technical Debt in Stylesheets (CSS/SCSS/Tailwind)

### Akzeptanzkriterien
- Alle vier Kategorien sind vollständig analysiert.
- Befunde sind direkt auf das gelieferte `<projekt_daten>` bezogen.
- Output folgt strikt dem unten definierten Format.

### Ausgabeformat
1. **Executive Summary:** Die 3 kritischsten Hebel für Performance & Usability.
2. **Detaillierter Audit-Report:** Kategorisiert in 'Architektur', 'UX/UI' und 'Standards'.
3. **Roadmap:** Priorisierte Schritte (Quick-Wins vs. langfristige Refactorings).

### Daten
<projekt_daten>
[PROJEKT-STRUKTUR ODER REPOSITORY-CODES HIER EINFÜGEN]
</projekt_daten>

KEINE Einleitungen, KEINE Zusammenfassungen am Ende, KEINE Höflichkeitsfloskeln. Beginne direkt mit dem Executive Summary.
