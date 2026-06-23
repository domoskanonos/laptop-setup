#!/bin/bash

# 1. Paketquellen aktualisieren
echo "Aktualisiere Paketquellen..."
sudo apt update

# 2. Sicherstellen, dass snapd (der Snap-Dienst) installiert ist
if ! command -v snap &> /dev/null; then
    echo "Snap ist nicht installiert. Installiere snapd..."
    sudo apt install -y snapd
fi

# 3. WhatsDev aus dem Snap Store installieren
echo "Installiere whatsdev aus dem Ubuntu/Snap Store..."
sudo snap install whatsdev

echo "Installation abgeschlossen!"