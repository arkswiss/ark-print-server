#!/bin/bash
set -e

# Script pour extraire ark-print-server en repository séparé
# Usage: ./extract-to-repo.sh [destination_directory]

DESTINATION=${1:-"../ark-print-server-standalone"}
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "============================================"
echo "ARK Print Server - Repository Extraction"
echo "============================================"
echo ""
echo "Source: $SOURCE_DIR"
echo "Destination: $DESTINATION"
echo ""

# Vérifier si la destination existe déjà
if [ -d "$DESTINATION" ]; then
    read -p "⚠️  Le répertoire $DESTINATION existe déjà. Écraser? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Extraction annulée."
        exit 1
    fi
    rm -rf "$DESTINATION"
fi

echo "📦 Création du répertoire de destination..."
mkdir -p "$DESTINATION"

echo "📋 Copie des fichiers..."
# Copier tous les fichiers sauf .git et node_modules
rsync -av --progress \
    --exclude='.git' \
    --exclude='node_modules' \
    --exclude='dist' \
    --exclude='.DS_Store' \
    --exclude='*.log' \
    --exclude='.env' \
    "$SOURCE_DIR/" "$DESTINATION/"

echo ""
echo "🔧 Initialisation du repository Git..."
cd "$DESTINATION"
git init
git add .
git commit -m "chore: initial commit - ARK Print Server standalone

ARK Print Server is a standalone service that allows secure printing
to ZPL printers over HTTPS, enabling cloud instances to connect
to local network printers.

Features:
- REST API with token authentication
- TCP communication with ZPL printers (port 9100)
- Web UI for configuration and testing
- Retry mechanism and error handling
- Cross-platform executables (Windows, macOS, Linux)

Stack:
- Node.js + Express
- Pure JavaScript (no framework dependencies)

This repository was extracted from ark.stock project to provide
a standalone, reusable solution for all clients."

echo ""
echo "✅ Extraction terminée avec succès!"
echo ""
echo "📁 Repository créé dans: $DESTINATION"
echo ""
echo "📝 Prochaines étapes:"
echo "   1. cd $DESTINATION"
echo "   2. npm install"
echo "   3. Créer un repository sur GitHub"
echo "   4. git remote add origin <your-github-url>"
echo "   5. git push -u origin master"
echo ""
echo "🔗 Pour créer le repository GitHub:"
echo "   gh repo create ark-print-server --public --source=. --remote=origin --push"
echo ""
