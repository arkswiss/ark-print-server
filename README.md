# 🖨️ ARK Print Server

Print Server pour imprimantes ZPL - Compatible avec ARK Stock

[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![Node.js](https://img.shields.io/badge/node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)](https://nodejs.org/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=for-the-badge)](LICENSE)

## 📖 À propos

ARK Print Server est un serveur d'impression léger qui permet d'imprimer sur des imprimantes ZPL (Zebra Programming Language) depuis n'importe où sur Internet de manière sécurisée. Il est conçu pour fonctionner avec **ARK Stock** en mode cloud.

### Cas d'usage typique

```
Instance ARK Stock (cloud)
         ↓
   Cloudflare Tunnel (sécurisé)
         ↓
   Print Server (réseau local)
         ↓
   Imprimante ZPL (locale)
```

## ✨ Fonctionnalités

- 🐳 **Installation Docker simplifiée** - Un seul script pour tout installer
- 🔐 **Authentification par token** - Sécurisé par défaut
- 🌐 **Compatible Cloudflare Tunnel** - Exposition sécurisée sans ouvrir de ports
- 📊 **Interface web de monitoring** - Visualisation en temps réel
- 🔄 **Retry automatique** - Gestion des erreurs réseau
- 📝 **Logs détaillés** - Débogage facile
- 🏥 **Health checks** - Monitoring Docker intégré

## 🚀 Installation rapide

### Prérequis

- Docker Desktop installé ([télécharger](https://www.docker.com/products/docker-desktop))
- Une imprimante ZPL sur le réseau local
- (Optionnel) Un compte Cloudflare pour le tunnel

### Installation en une commande

```bash
curl -sSL https://raw.githubusercontent.com/schmidmatthieu/ark-print-server/main/install.sh | bash
```

Le script vous demandera :
- L'adresse IP de votre imprimante (ex: `10.1.55.150`)
- Le port (généralement `9100`)
- Il génèrera automatiquement un token sécurisé

## 📦 Installation manuelle

### Option 1 : Docker Compose (recommandé)

```bash
# Cloner le repository
git clone https://github.com/schmidmatthieu/ark-print-server.git
cd ark-print-server

# Copier et configurer .env
cp .env.example .env
nano .env  # Éditer avec vos paramètres

# Démarrer
docker compose up -d
```

### Option 2 : Docker Run

```bash
docker run -d \
  --name ark-print-server \
  --restart unless-stopped \
  -p 8099:8099 \
  -e PRINTER_IP=10.1.55.150 \
  -e PRINTER_PORT=9100 \
  -e AUTH_TOKEN=$(openssl rand -hex 32) \
  -v $(pwd)/logs:/app/logs \
  schmidmatthieu/ark-print-server:latest
```

### Option 3 : Node.js natif

```bash
# Cloner et installer
git clone https://github.com/schmidmatthieu/ark-print-server.git
cd ark-print-server
npm install

# Configurer
cp .env.example .env
nano .env

# Démarrer
npm start
```

## ⚙️ Configuration

### Variables d'environnement

| Variable | Description | Défaut | Requis |
|----------|-------------|---------|---------|
| `PRINTER_IP` | Adresse IP de l'imprimante ZPL | `10.1.55.150` | ✅ |
| `PRINTER_PORT` | Port de l'imprimante | `9100` | ✅ |
| `AUTH_TOKEN` | Token d'authentification | - | ✅ |
| `PORT` | Port du serveur | `8099` | ❌ |
| `HOST` | Host d'écoute | `0.0.0.0` | ❌ |
| `LOG_LEVEL` | Niveau de logs | `info` | ❌ |
| `MAX_RETRIES` | Tentatives max | `3` | ❌ |
| `RETRY_DELAY_MS` | Délai entre tentatives | `2000` | ❌ |

### Générer un token sécurisé

```bash
# macOS / Linux
openssl rand -hex 32

# Windows (PowerShell)
-join ((65..90) + (97..122) + (48..57) | Get-Random -Count 64 | % {[char]$_})
```

## 🌐 Cloudflare Tunnel

Pour exposer votre Print Server local de manière sécurisée :

### 1. Installer cloudflared

```bash
# macOS (Homebrew)
brew install cloudflare/cloudflare/cloudflared

# Linux
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb

# Windows (Chocolatey)
choco install cloudflared
```

### 2. Configurer le tunnel

```bash
# Login
cloudflared tunnel login

# Créer un tunnel
cloudflared tunnel create ark-print

# Configurer (créer config.yml)
cat > ~/.cloudflared/config.yml << EOF
tunnel: <tunnel-id>
credentials-file: /Users/your-user/.cloudflared/<tunnel-id>.json

ingress:
  - hostname: ark-print.votredomaine.com
    service: http://localhost:8099
  - service: http_status:404
EOF

# Router DNS
cloudflared tunnel route dns ark-print ark-print.votredomaine.com

# Démarrer
cloudflared tunnel run ark-print
```

### 3. Automatiser avec systemd (Linux)

```bash
sudo cloudflared service install
sudo systemctl start cloudflared
sudo systemctl enable cloudflared
```

## 🔧 Utilisation

### Interface Web

Accédez à l'interface de monitoring :

```
http://localhost:8099
```

### API REST

#### Imprimer une étiquette

```bash
curl -X POST http://localhost:8099/api/print \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "zpl": "^XA^FO50,50^ADN,36,20^FDTest^FS^XZ",
    "jobId": "test-001",
    "metadata": {
      "productId": "PROD-123",
      "timestamp": "2025-10-10T14:00:00Z"
    }
  }'
```

#### Healthcheck

```bash
curl http://localhost:8099/health
```

Réponse :
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "uptime": 3600,
  "printer": {
    "ip": "10.1.55.150",
    "port": 9100,
    "status": "connected"
  }
}
```

## 📊 Monitoring

### Docker

```bash
# Voir les logs
docker logs ark-print-server -f

# Statut du container
docker ps | grep ark-print-server

# Statistiques
docker stats ark-print-server
```

### Logs

Les logs sont stockés dans `./logs/` :
- `combined.log` - Tous les logs
- `error.log` - Erreurs uniquement

```bash
# Suivre les logs en temps réel
tail -f logs/combined.log

# Filtrer les erreurs
grep ERROR logs/combined.log
```

## 🔍 Dépannage

### L'imprimante n'est pas trouvée

```bash
# Tester la connectivité
ping 10.1.55.150

# Tester le port
nc -zv 10.1.55.150 9100
# ou
telnet 10.1.55.150 9100
```

### Docker ne démarre pas

```bash
# Vérifier les logs
docker logs ark-print-server

# Redémarrer
docker restart ark-print-server

# Rebuild complet
docker compose down
docker compose up -d --build
```

### Erreur d'authentification

- Vérifiez que le token dans ARK Stock correspond exactement
- Pas d'espaces avant/après le token
- Le token ne doit pas contenir de caractères spéciaux

### Timeout lors de l'impression

- Vérifiez que l'imprimante est allumée et en réseau
- Vérifiez que le câble réseau est branché
- Essayez d'augmenter `MAX_RETRIES` et `RETRY_DELAY_MS`

## 🛠️ Développement

### Lancer en mode développement

```bash
npm install
npm run dev
```

### Tests

```bash
npm test
```

### Build Docker local

```bash
docker build -t ark-print-server:dev .
docker run -p 8099:8099 --env-file .env ark-print-server:dev
```

## 📚 Documentation

- [Guide d'installation complet](https://docs.ark.swiss/print-server)
- [Documentation API](https://docs.ark.swiss/print-server/api)
- [FAQ](https://docs.ark.swiss/print-server/faq)
- [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)

## 🤝 Support

- 📧 Email : [info@ark.swiss](mailto:info@ark.swiss)
- 🐛 Issues : [GitHub Issues](https://github.com/schmidmatthieu/ark-print-server/issues)
- 💬 Discussions : [GitHub Discussions](https://github.com/schmidmatthieu/ark-print-server/discussions)

## 📝 License

MIT © 2025 ARK Stock

## 🙏 Remerciements

- [Zebra Technologies](https://www.zebra.com/) pour le langage ZPL
- [Cloudflare](https://www.cloudflare.com/) pour Cloudflare Tunnel
- [Docker](https://www.docker.com/) pour la conteneurisation

---

Fait avec ❤️ par [ARK Stock](https://ark.swiss)
