#!/bin/bash

# ============================================
# Script de test de l'installation complète
# ============================================

set -e

echo "╔════════════════════════════════════════════════════════╗"
echo "║                                                        ║"
echo "║       🧪 Test Installation ARK Print Server  🧪       ║"
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

# Test 1: Vérifier Docker
info "Test 1: Vérification de Docker..."
if ! command -v docker &> /dev/null; then
    error "Docker n'est pas installé"
fi
success "Docker est installé"

# Test 2: Vérifier que Docker tourne
info "Test 2: Vérification que Docker Desktop tourne..."
if ! docker info &> /dev/null; then
    error "Docker Desktop n'est pas démarré"
fi
success "Docker Desktop est actif"

# Test 3: Vérifier que l'image existe localement
info "Test 3: Vérification de l'image locale..."
if ! docker images | grep -q "schmidmatthieu/ark-print-server"; then
    warning "Image locale non trouvée, elle sera téléchargée depuis Docker Hub"
else
    success "Image locale trouvée"
fi

# Test 4: Nettoyer les containers existants
info "Test 4: Nettoyage des containers existants..."
if docker ps -a | grep -q "ark-print-server"; then
    docker stop ark-print-server 2>/dev/null || true
    docker rm ark-print-server 2>/dev/null || true
    success "Ancien container supprimé"
else
    success "Aucun container à nettoyer"
fi

# Test 5: Lancer le container avec docker-compose
info "Test 5: Lancement avec docker-compose..."
if [ -f "docker-compose.yml" ]; then
    docker compose up -d
    success "Container lancé via docker-compose"
else
    error "docker-compose.yml introuvable"
fi

# Test 6: Attendre que le service démarre
info "Test 6: Attente du démarrage (10s)..."
sleep 10

# Test 7: Vérifier que le container tourne
info "Test 7: Vérification du statut du container..."
if docker ps | grep -q "ark-print-server"; then
    success "Container en cours d'exécution"
else
    error "Container non trouvé"
fi

# Test 8: Tester le healthcheck
info "Test 8: Test du healthcheck..."
HEALTH_RESPONSE=$(curl -s http://localhost:8099/health)
if echo "$HEALTH_RESPONSE" | grep -q "healthy"; then
    success "Healthcheck réussi"
    echo "$HEALTH_RESPONSE" | python3 -m json.tool
else
    error "Healthcheck échoué"
fi

# Test 9: Tester l'interface web
info "Test 9: Test de l'interface web..."
WEB_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8099)
if [ "$WEB_RESPONSE" = "200" ]; then
    success "Interface web accessible"
else
    warning "Interface web retourne le code: $WEB_RESPONSE"
fi

# Test 10: Vérifier les logs
info "Test 10: Affichage des logs..."
docker logs ark-print-server-ark-print-server-1 --tail 20

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║              🎉 Tests terminés avec succès  🎉         ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "📍 Interface web: http://localhost:8099"
echo "📊 Logs en temps réel: docker logs ark-print-server-ark-print-server-1 -f"
echo "🛑 Arrêter: docker compose down"
echo ""
