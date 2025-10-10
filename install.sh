#!/bin/bash

# ============================================
# Script d'installation ARK Print Server
# ============================================

set -e

echo "╔════════════════════════════════════════════════════════╗"
echo "║                                                        ║"
echo "║       🖨️  Installation ARK Print Server  🖨️            ║"
echo "║                                                        ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

# Vérifier Docker
info "Vérification de Docker..."
if ! command -v docker &> /dev/null; then
    error "Docker n'est pas installé. Veuillez l'installer depuis https://docs.docker.com/get-docker/"
fi
success "Docker est installé"

# Vérifier Docker Compose
info "Vérification de Docker Compose..."
if ! docker compose version &> /dev/null; then
    error "Docker Compose n'est pas installé ou n'est pas à jour."
fi
success "Docker Compose est installé"

# Créer le répertoire d'installation
INSTALL_DIR="${HOME}/ark-print-server"
info "Création du répertoire d'installation: ${INSTALL_DIR}"
mkdir -p "${INSTALL_DIR}"
cd "${INSTALL_DIR}"

# Télécharger les fichiers nécessaires
info "Téléchargement des fichiers de configuration..."

# docker-compose.yml
curl -sSL https://raw.githubusercontent.com/schmidmatthieu/ark-print-server/main/docker-compose.yml -o docker-compose.yml
success "docker-compose.yml téléchargé"

# .env.example
curl -sSL https://raw.githubusercontent.com/schmidmatthieu/ark-print-server/main/.env.example -o .env.example
success ".env.example téléchargé"

# Créer le répertoire logs
mkdir -p logs

# Configuration interactive
echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║                 Configuration                          ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Demander l'IP de l'imprimante
read -p "Adresse IP de votre imprimante ZPL (par défaut: 10.1.55.150): " PRINTER_IP
PRINTER_IP=${PRINTER_IP:-10.1.55.150}

# Demander le port
read -p "Port de l'imprimante (par défaut: 9100): " PRINTER_PORT
PRINTER_PORT=${PRINTER_PORT:-9100}

# Générer un token sécurisé
info "Génération d'un token de sécurité..."
if command -v openssl &> /dev/null; then
    AUTH_TOKEN=$(openssl rand -hex 32)
    success "Token généré avec succès"
else
    warning "OpenSSL non trouvé. Veuillez générer un token manuellement."
    read -p "Entrez un token sécurisé (ou laissez vide pour en générer un simple): " AUTH_TOKEN
    if [ -z "$AUTH_TOKEN" ]; then
        AUTH_TOKEN=$(cat /dev/urandom | LC_ALL=C tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
    fi
fi

# Créer le fichier .env
cat > .env <<EOF
# Configuration ARK Print Server
PRINTER_IP=${PRINTER_IP}
PRINTER_PORT=${PRINTER_PORT}
AUTH_TOKEN=${AUTH_TOKEN}
PORT=8099
HOST=0.0.0.0
LOG_LEVEL=info
MAX_RETRIES=3
RETRY_DELAY_MS=2000
EOF

success "Fichier .env créé"

# Afficher le token
echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║          🔐 Token d'authentification                   ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "Votre token (à copier dans ARK Stock):"
echo ""
echo -e "${GREEN}${AUTH_TOKEN}${NC}"
echo ""
warning "⚠️  IMPORTANT: Sauvegardez ce token dans un endroit sûr!"
echo ""

# Demander si on doit démarrer maintenant
read -p "Voulez-vous démarrer le Print Server maintenant? (o/N): " START_NOW

if [[ "$START_NOW" =~ ^[Oo]$ ]]; then
    info "Démarrage du Print Server..."
    docker compose pull
    docker compose up -d

    # Attendre que le service soit prêt
    sleep 3

    # Vérifier le statut
    if docker compose ps | grep -q "running"; then
        success "Print Server démarré avec succès!"
        echo ""
        echo "📍 URL locale: http://localhost:8099"
        echo "🔌 API: http://localhost:8099/api/print"
        echo ""
        info "Pour voir les logs: cd ${INSTALL_DIR} && docker compose logs -f"
    else
        error "Échec du démarrage. Vérifiez les logs avec: cd ${INSTALL_DIR} && docker compose logs"
    fi
else
    info "Pour démarrer plus tard: cd ${INSTALL_DIR} && docker compose up -d"
fi

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║              Prochaines étapes                         ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "1. ✅ Configurez Cloudflare Tunnel pour exposer le serveur"
echo "2. ✅ Connectez-vous à ARK Stock"
echo "3. ✅ Allez dans Profil → Paramètres d'impression"
echo "4. ✅ Configurez:"
echo "   - URL: https://votre-tunnel.com (ou http://localhost:8099 en local)"
echo "   - Token: ${AUTH_TOKEN}"
echo ""
echo "📚 Documentation complète: https://github.com/schmidmatthieu/ark-print-server"
echo ""
success "Installation terminée!"
