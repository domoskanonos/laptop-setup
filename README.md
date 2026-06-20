# 💻 Laptop Setup (Ubuntu 26.04 LTS)

Dieses Repository enthält mein persönliches Post-Installation-Skript, um ein frisches Ubuntu-System blitzschnell in eine voll einsatzbereite Entwicklungsumgebung zu verwandeln. 

Das Skript ist **idempotent** ausgelegt – es kann also jederzeit erneut ausgeführt werden, um fehlende Tools nachzuinstallieren oder Konfigurationen zu aktualisieren, ohne bestehende Setups zu beschädigen.

---

## 🚀 Schnellstart (One-Liner)

Um das Setup auf einem frisch installierten Ubuntu-System direkt auszuführen, öffne ein Terminal und füge einen der folgenden Befehle ein:

### Option A: Direkt ausführen (Empfohlen)
Lädt das Skript herunter, macht es ausführbar und startet den interaktiven Prozess:

    wget [https://raw.githubusercontent.com/domoskanonos/laptop-setup/main/setup.sh](https://raw.githubusercontent.com/domoskanonos/laptop-setup/main/setup.sh) -O setup.sh && chmod +x setup.sh && ./setup.sh


### Option B: Direkt via Pipe streamen
Falls du das Skript nicht lokal als Datei speichern möchtest:

    curl -fsSL [https://raw.githubusercontent.com/domoskanonos/laptop-setup/main/setup.sh](https://raw.githubusercontent.com/domoskanonos/laptop-setup/main/setup.sh) | bash