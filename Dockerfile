# Utilisation d'une image Node.js officielle comme base
FROM node:18-alpine AS base

# Installation de pnpm globalement
RUN npm install -g pnpm

# Définition du répertoire de travail
WORKDIR /app

# Étape de construction
FROM base AS builder

# Copie des fichiers de configuration des dépendances
COPY package.json pnpm-lock.yaml ./

# Installation des dépendances de production et de développement
RUN pnpm install --frozen-lockfile

# Copie du code source
COPY src/ ./src/
COPY tsconfig.json ./

# Construction de l'application
RUN pnpm run build

# Étape de production
FROM base AS production

# Création d'un utilisateur non-root pour la sécurité
RUN addgroup -g 1001 -S nodejs && \
    adduser -S mcpserver -u 1001

# Copie des fichiers de configuration des dépendances
COPY package.json pnpm-lock.yaml ./

# Installation uniquement des dépendances de production (ignorer le script prepare)
RUN pnpm install --frozen-lockfile --prod --ignore-scripts

# Copie des fichiers construits depuis l'étape builder
COPY --from=builder /app/build ./build

# Changement de propriétaire des fichiers
RUN chown -R mcpserver:nodejs /app

# Passage à l'utilisateur non-root
USER mcpserver

# Exposition du port (optionnel, le serveur utilise stdio par défaut)
# EXPOSE 3000

# Variables d'environnement
ENV NODE_ENV=production

# Commande par défaut pour démarrer le serveur
CMD ["node", "build/index.js"]

# Labels pour les métadonnées
LABEL maintainer="zhsama <torvalds@linux.do>"
LABEL description="DuckDuckGo MCP Server - A TypeScript-based Model Context Protocol server"
LABEL version="0.1.2"