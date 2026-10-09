# syntax=docker/dockerfile:1
FROM node:22-bookworm-slim AS builder

# Install build dependencies for native modules (node-pty)
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    make \
    g++ \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install project dependencies
COPY package*.json ./
RUN npm ci --omit=dev

FROM node:22-bookworm-slim AS runner

# Install security certificates and dumb-init for clean process signal handling
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    dumb-init \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy dependencies and application files
COPY --from=builder /app/node_modules ./node_modules
COPY package*.json ./
COPY frontend/ ./frontend/
COPY sidecar/ ./sidecar/
COPY shared/ ./shared/
COPY skills-catalog/ ./skills-catalog/

# Create persistent storage folder and assign ownership to non-root user
RUN mkdir -p /home/node/.local/share/ai.skynet.harness \
    && chown -R node:node /home/node /app

USER node

ENV STARNET_HOST=0.0.0.0

# StarNet HTTP & SSE UI port
EXPOSE 8787

# Persistent volume for station state, memory, transcripts, and ledgers
VOLUME ["/home/node/.local/share/ai.skynet.harness"]

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["node", "sidecar/index.js"]

