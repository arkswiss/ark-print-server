# Dockerfile pour ARK Print Server
FROM node:22-alpine@sha256:fe4f6d74e20370acb04ad889077d14d0f64a9c8ea6a42bc60cddf1e844699914

# Métadonnées
LABEL maintainer="ARK Stock <info@ark.swiss>"
LABEL description="Print Server pour imprimantes ZPL - ARK Stock"
LABEL version="1.0.0"

# Créer le répertoire de l'application
WORKDIR /app

# Copier les fichiers package
COPY package*.json ./

# Installer les dépendances (production seulement)
RUN npm ci --only=production

# Copier le code source
COPY src ./src

# Créer un utilisateur non-root pour la sécurité
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 && \
    chown -R nodejs:nodejs /app

# Utiliser l'utilisateur non-root
USER nodejs

# Exposer le port 8099
EXPOSE 8099

# Variables d'environnement par défaut
ENV NODE_ENV=production \
    PORT=8099 \
    HOST=0.0.0.0 \
    LOG_LEVEL=info

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:8099/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Lancer l'application
CMD ["node", "src/server.js"]
